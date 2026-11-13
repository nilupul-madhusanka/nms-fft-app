import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Collection references ───
  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _db.collection('family_transactions');
  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _db.collection('categories');
  CollectionReference<Map<String, dynamic>> get _membersRef =>
      _db.collection('members');

  // ─── MEMBER MANAGEMENT ───

  /// Save/update member info on login
  Future<void> saveMember({
    required String uid,
    required String displayName,
    required String email,
    required String photoUrl,
  }) async {
    await _membersRef.doc(uid).set({
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─── TRANSACTION CRUD ───

  /// Add a new transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactionsRef.doc(transaction.id).set(transaction.toMap());
  }

  /// Update a transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _transactionsRef.doc(transaction.id).update(transaction.toMap());
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    await _transactionsRef.doc(id).delete();
  }

  /// Stream all transactions for a date range (family-wide)
  Stream<List<TransactionModel>> getTransactions({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _transactionsRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThan: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    TransactionModel.fromMap(doc.data(), documentId: doc.id),
              )
              .toList(),
        );
  }

  // ─── CATEGORY CRUD ───

  /// Add a new category
  Future<void> addCategory(CategoryModel category) async {
    await _categoriesRef.doc(category.id).set(category.toMap());
  }

  /// Delete a category
  Future<void> deleteCategory(String id) async {
    await _categoriesRef.doc(id).delete();
  }

  /// Stream all categories
  Stream<List<CategoryModel>> getCategories() {
    return _categoriesRef
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => CategoryModel.fromMap(doc.data(), documentId: doc.id),
              )
              .toList(),
        );
  }

  /// Seed default categories if collection is empty
  Future<void> seedDefaultCategories() async {
    final snapshot = await _categoriesRef
        .limit(1)
        .get(const GetOptions(source: Source.server));
    if (snapshot.docs.isNotEmpty) return; // already has categories

    final now = DateTime.now();
    final defaults = [
      // Income categories
      CategoryModel(
        id: 'cat_salary',
        name: 'Salary',
        icon: '💼',
        type: 'income',
        createdAt: now,
      ),
      CategoryModel(
        id: 'cat_freelance',
        name: 'Freelance',
        icon: '💻',
        type: 'income',
        createdAt: now,
      ),
      CategoryModel(
        id: 'cat_gift_in',
        name: 'Gift Received',
        icon: '🎁',
        type: 'income',
        createdAt: now,
      ),
      CategoryModel(
        id: 'cat_other_in',
        name: 'Other Income',
        icon: '💰',
        type: 'income',
        createdAt: now,
      ),
      // Expense categories
      CategoryModel(
        id: 'cat_food',
        name: 'Food & Grocery',
        icon: '🛒',
        type: 'expense',
        createdAt: now,
      ),
      CategoryModel(
        id: 'cat_transport',
        name: 'Transport',
        icon: '🚗',
        type: 'expense',
        createdAt: now,
      ),
      CategoryModel(
        id: 'cat_bills',
        name: 'Bills & Utilities',
        icon: '🔌',
        type: 'expense',
        createdAt: now,
      ),
      CategoryModel(
        id: 'cat_health',
        name: 'Health',
        icon: '🏥',
        type: 'expense',
        createdAt: now,
      ),
      CategoryModel(
        id: 'cat_education',
        name: 'Education',
        icon: '📚',
        type: 'expense',
        createdAt: now,
      ),
      CategoryModel(
        id: 'cat_shopping',
        name: 'Shopping',
        icon: '🛍️',
        type: 'expense',
        createdAt: now,
      ),
      CategoryModel(
        id: 'cat_entertainment',
        name: 'Entertainment',
        icon: '🎬',
        type: 'expense',
        createdAt: now,
      ),
      CategoryModel(
        id: 'cat_gift_out',
        name: 'Gift Given',
        icon: '🎀',
        type: 'expense',
        createdAt: now,
      ),
      CategoryModel(
        id: 'cat_other_exp',
        name: 'Other Expense',
        icon: '📦',
        type: 'expense',
        createdAt: now,
      ),
    ];

    final batch = _db.batch();
    for (final cat in defaults) {
      batch.set(_categoriesRef.doc(cat.id), cat.toMap());
    }
    await batch.commit();
  }

  /// Get family members
  Stream<List<Map<String, dynamic>>> getMembers() {
    return _membersRef.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => {...doc.data(), 'uid': doc.id}).toList(),
    );
  }
}
