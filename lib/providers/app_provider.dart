import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/helpers.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<TransactionModel>>? _transactionsSubscription;
  StreamSubscription<List<CategoryModel>>? _categoriesSubscription;
  Stream<List<Map<String, dynamic>>>? membersStream;

  User? _user;
  User? get user => _user;
  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;
  bool _isSigningIn = false;
  bool get isSigningIn => _isSigningIn;
  bool _disposed = false;

  List<TransactionModel> _monthTransactions = [];
  List<TransactionModel> get transactions =>
      filterTransactions(_monthTransactions);
  List<CategoryModel> _categories = [];

  List<CategoryModel> get incomeCategories =>
      _categories.where((category) => category.type == 'income').toList();
  List<CategoryModel> get expenseCategories =>
      _categories.where((category) => category.type == 'expense').toList();

  bool _transactionsLoading = true;
  bool get transactionsLoading => _transactionsLoading;
  bool _transactionsFailed = false;
  bool get transactionsFailed => _transactionsFailed;
  bool _categoriesLoading = true;
  bool get categoriesLoading => _categoriesLoading;
  bool _categoriesFailed = false;
  bool get categoriesFailed => _categoriesFailed;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  String _filterMember = 'all';
  String get filterMember => _filterMember;

  double get totalIncome => transactions
      .where((transaction) => transaction.type == TransactionType.income)
      .fold(0.0, (sum, transaction) => sum + transaction.amount);
  double get totalExpense => transactions
      .where((transaction) => transaction.type == TransactionType.expense)
      .fold(0.0, (sum, transaction) => sum + transaction.amount);
  double get balance => totalIncome - totalExpense;

  AppProvider() {
    _authSubscription = _authService.authStateChanges.listen(
      (user) {
        _isInitializing = false;
        if (_user?.uid != user?.uid) {
          _cancelDataSubscriptions();
          _user = user;
          _monthTransactions = [];
          _categories = [];
          _filterMember = 'all';
          _selectedDate = DateTime.now();
          membersStream = null;

          if (user != null) {
            membersStream = _firestoreService.getMembers();
            _loadCategories();
            _loadTransactionsForMonth();
            unawaited(_saveMember(user));
          }
        }
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('Could not restore the sign-in session: $error');
        _isInitializing = false;
        notifyListeners();
      },
    );
  }

  Future<void> _saveMember(User user) async {
    try {
      await _firestoreService.saveMember(
        uid: user.uid,
        displayName: Helpers.displayName(user.displayName),
        email: user.email ?? '',
        photoUrl: user.photoURL ?? '',
      );
    } catch (error) {
      debugPrint('Could not sync the member profile: $error');
    }
  }

  void _loadCategories() {
    _categoriesLoading = true;
    _categoriesFailed = false;
    _categoriesSubscription = _firestoreService.getCategories().listen(
      (categories) {
        _categories = categories;
        _categoriesLoading = false;
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('Could not load categories: $error');
        _categoriesLoading = false;
        _categoriesFailed = true;
        notifyListeners();
      },
    );
    unawaited(_seedDefaultCategories());
  }

  Future<void> _seedDefaultCategories() async {
    try {
      await _firestoreService.seedDefaultCategories();
    } catch (error) {
      debugPrint('Could not create default categories: $error');
    }
  }

  void _loadTransactionsForMonth() {
    _transactionsSubscription?.cancel();
    _monthTransactions = [];
    _transactionsLoading = true;
    _transactionsFailed = false;
    _transactionsSubscription =
        watchTransactions(
          Helpers.startOfMonth(_selectedDate),
          Helpers.startOfNextMonth(_selectedDate),
        ).listen(
          (transactions) {
            _monthTransactions = transactions;
            _transactionsLoading = false;
            notifyListeners();
          },
          onError: (Object error) {
            debugPrint('Could not load transactions: $error');
            _transactionsLoading = false;
            _transactionsFailed = true;
            notifyListeners();
          },
        );
  }

  Stream<List<TransactionModel>> watchTransactions(
    DateTime start,
    DateTime end,
  ) => _firestoreService.getTransactions(startDate: start, endDate: end);

  List<TransactionModel> filterTransactions(
    List<TransactionModel> transactions,
  ) {
    if (_filterMember == 'all') return transactions;
    return transactions
        .where((transaction) => transaction.userId == _filterMember)
        .toList();
  }

  Future<void> signInWithGoogle() async {
    if (_isSigningIn) return;
    _isSigningIn = true;
    notifyListeners();
    try {
      await _authService.signInWithGoogle();
    } finally {
      _isSigningIn = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> signOut() => _authService.signOut();

  Future<void> addTransaction(TransactionModel transaction) =>
      _firestoreService.addTransaction(transaction);

  Future<void> updateTransaction(TransactionModel transaction) =>
      _firestoreService.updateTransaction(transaction);

  Future<void> deleteTransaction(String id) =>
      _firestoreService.deleteTransaction(id);

  Future<void> addCategory(CategoryModel category) =>
      _firestoreService.addCategory(category);

  Future<void> deleteCategory(String id) =>
      _firestoreService.deleteCategory(id);

  void setSelectedDate(DateTime date) {
    if (Helpers.startOfMonth(_selectedDate) == Helpers.startOfMonth(date)) {
      return;
    }
    _selectedDate = date;
    _loadTransactionsForMonth();
    notifyListeners();
  }

  void setFilterMember(String uid) {
    if (_filterMember == uid) return;
    _filterMember = uid;
    notifyListeners();
  }

  Map<String, List<TransactionModel>> get transactionsGroupedByDate {
    final grouped = <String, List<TransactionModel>>{};
    for (final transaction in transactions) {
      final day = Helpers.dayFormat.format(transaction.date);
      grouped.putIfAbsent(day, () => []).add(transaction);
    }
    return grouped;
  }

  void _cancelDataSubscriptions() {
    _transactionsSubscription?.cancel();
    _transactionsSubscription = null;
    _categoriesSubscription?.cancel();
    _categoriesSubscription = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    _cancelDataSubscriptions();
    super.dispose();
  }
}
