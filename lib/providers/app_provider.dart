import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/helpers.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // ─── Stream subscriptions ───
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<TransactionModel>>? _transactionsSubscription;
  StreamSubscription<List<CategoryModel>>? _categoriesSubscription;
  bool _categoriesSeeded = false;

  // ─── Auth state ───
  User? _user;
  User? get user => _user;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ─── Data ───
  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => _transactions;

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  List<CategoryModel> get incomeCategories =>
      _categories.where((c) => c.type == 'income').toList();
  List<CategoryModel> get expenseCategories =>
      _categories.where((c) => c.type == 'expense').toList();

  // ─── Filters ───
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  String _filterMember = 'all'; // 'all' or user uid
  String get filterMember => _filterMember;

  // ─── Computed values ───
  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  List<TransactionModel> get todayTransactions {
    final today = Helpers.startOfDay(DateTime.now());
    final endToday = Helpers.endOfDay(DateTime.now());
    return _transactions
        .where((t) =>
            t.date.isAfter(today.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(endToday.add(const Duration(seconds: 1))))
        .toList();
  }

  // ─── Initialization ───
  AppProvider() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      _user = user;
      if (user != null) {
        _onUserLoggedIn(user);
      } else {
        _cancelDataSubscriptions();
        _transactions = [];
        _categories = [];
        _categoriesSeeded = false;
      }
      notifyListeners();
    });
  }

  void _onUserLoggedIn(User user) {
    // Save member info
    _firestoreService.saveMember(
      uid: user.uid,
      displayName: user.displayName ?? 'Unknown',
      email: user.email ?? '',
      photoUrl: user.photoURL ?? '',
    );

    // Seed default categories only once per session
    if (!_categoriesSeeded) {
      _categoriesSeeded = true;
      _firestoreService.seedDefaultCategories();
    }

    // Load categories (cancel previous listener first)
    _categoriesSubscription?.cancel();
    _categoriesSubscription = _firestoreService.getCategories().listen((cats) {
      _categories = cats;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error loading categories: $e');
    });

    // Load transactions for current selected day view (whole month by default)
    _loadTransactionsForMonth();
  }

  void _loadTransactionsForMonth() {
    // Cancel previous transaction listener to prevent memory leaks
    _transactionsSubscription?.cancel();

    final start = Helpers.startOfMonth(_selectedDate);
    final end = Helpers.endOfMonth(_selectedDate);

    if (_filterMember == 'all') {
      _transactionsSubscription = _firestoreService
          .getTransactions(startDate: start, endDate: end)
          .listen((txns) {
        _transactions = txns;
        notifyListeners();
      }, onError: (e) {
        debugPrint('Error loading transactions: $e');
      });
    } else {
      _transactionsSubscription = _firestoreService
          .getUserTransactions(
              userId: _filterMember, startDate: start, endDate: end)
          .listen((txns) {
        _transactions = txns;
        notifyListeners();
      }, onError: (e) {
        debugPrint('Error loading user transactions: $e');
      });
    }
  }

  // ─── Actions ───

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _firestoreService.addTransaction(transaction);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _firestoreService.updateTransaction(transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await _firestoreService.deleteTransaction(id);
  }

  Future<void> addCategory(CategoryModel category) async {
    await _firestoreService.addCategory(category);
  }

  Future<void> deleteCategory(String id) async {
    await _firestoreService.deleteCategory(id);
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    _loadTransactionsForMonth();
    notifyListeners();
  }

  void setFilterMember(String uid) {
    _filterMember = uid;
    _loadTransactionsForMonth();
    notifyListeners();
  }

  /// Get transactions grouped by date for display
  Map<String, List<TransactionModel>> get transactionsGroupedByDate {
    final Map<String, List<TransactionModel>> grouped = {};
    for (final t in _transactions) {
      final key = Helpers.dayFormat.format(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    return grouped;
  }

  /// Get transactions for a specific date range
  List<TransactionModel> getTransactionsInRange(
      DateTime start, DateTime end) {
    return _transactions
        .where((t) =>
            t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(end.add(const Duration(seconds: 1))))
        .toList();
  }

  /// Category-wise breakdown
  Map<String, double> getCategoryBreakdown(TransactionType type,
      {DateTime? start, DateTime? end}) {
    final filtered = (start != null && end != null
            ? getTransactionsInRange(start, end)
            : _transactions)
        .where((t) => t.type == type);

    final Map<String, double> breakdown = {};
    for (final t in filtered) {
      breakdown[t.category] = (breakdown[t.category] ?? 0) + t.amount;
    }
    return breakdown;
  }

  /// Member-wise breakdown
  Map<String, double> getMemberBreakdown(TransactionType type,
      {DateTime? start, DateTime? end}) {
    final filtered = (start != null && end != null
            ? getTransactionsInRange(start, end)
            : _transactions)
        .where((t) => t.type == type);

    final Map<String, double> breakdown = {};
    for (final t in filtered) {
      breakdown[t.userName] = (breakdown[t.userName] ?? 0) + t.amount;
    }
    return breakdown;
  }

  /// Daily totals for chart
  Map<DateTime, Map<String, double>> getDailyTotals(
      DateTime start, DateTime end) {
    final Map<DateTime, Map<String, double>> dailyTotals = {};
    final rangeTransactions = getTransactionsInRange(start, end);

    for (final t in rangeTransactions) {
      final day = Helpers.startOfDay(t.date);
      dailyTotals.putIfAbsent(day, () => {'income': 0, 'expense': 0});
      if (t.type == TransactionType.income) {
        dailyTotals[day]!['income'] =
            dailyTotals[day]!['income']! + t.amount;
      } else {
        dailyTotals[day]!['expense'] =
            dailyTotals[day]!['expense']! + t.amount;
      }
    }
    return dailyTotals;
  }

  /// Get family members stream
  Stream<List<Map<String, dynamic>>> get membersStream =>
      _firestoreService.getMembers();

  void _cancelDataSubscriptions() {
    _transactionsSubscription?.cancel();
    _transactionsSubscription = null;
    _categoriesSubscription?.cancel();
    _categoriesSubscription = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelDataSubscriptions();
    super.dispose();
  }
}
