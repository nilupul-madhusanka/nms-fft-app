import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nms_fft_app/models/category_model.dart';
import 'package:nms_fft_app/models/transaction_model.dart';
import 'package:nms_fft_app/providers/app_provider.dart';
import 'package:nms_fft_app/screens/add_transaction_screen.dart';
import 'package:nms_fft_app/screens/login_screen.dart';
import 'package:nms_fft_app/screens/reports_screen.dart';
import 'package:nms_fft_app/utils/helpers.dart';
import 'package:nms_fft_app/widgets/transaction_card.dart';
import 'package:provider/provider.dart';

void main() {
  test('Calendar ranges include the entire final day', () {
    final date = DateTime(2026, 1, 31);
    final start = Helpers.startOfMonth(date);
    final end = Helpers.startOfNextMonth(date);

    expect(Helpers.isInRange(start, start, end), isTrue);
    expect(
      Helpers.isInRange(
        end.subtract(const Duration(microseconds: 1)),
        start,
        end,
      ),
      isTrue,
    );
    expect(Helpers.isInRange(end, start, end), isFalse);

    expect(Helpers.startOfWeek(date), DateTime(2026, 1, 26));
    expect(Helpers.startOfNextWeek(date), DateTime(2026, 2, 2));
  });

  testWidgets('Editing a transaction keeps its original author and amount', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = _TestProvider();
    final transaction = _transaction(
      date: DateTime(2020, 1, 1),
      amount: 12.345,
    );
    await tester.pumpWidget(
      _app(
        provider,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AddTransactionScreen(editTransaction: transaction),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // The original category is absent from the current categories list.
    expect(find.text(transaction.category), findsOneWidget);
    await tester.tap(find.text(Helpers.dateFormat.format(transaction.date)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    final updated = provider.updated!;
    expect(updated.id, transaction.id);
    expect(updated.userId, transaction.userId);
    expect(updated.userName, transaction.userName);
    expect(updated.userPhotoUrl, transaction.userPhotoUrl);
    expect(updated.category, transaction.category);
    expect(updated.amount, transaction.amount);
    expect(updated.createdAt, transaction.createdAt);
  });

  testWidgets('A failed swipe delete leaves the transaction available', (
    tester,
  ) async {
    final provider = _TestProvider();
    final transaction = _transaction(date: DateTime.now(), userName: '');
    await tester.pumpWidget(
      _app(provider, Scaffold(body: TransactionCard(transaction: transaction))),
    );

    await tester.drag(find.byType(Dismissible), const Offset(-650, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(provider.deletedId, transaction.id);
    expect(find.text(transaction.category), findsOneWidget);
    expect(
      find.text('Could not delete the transaction. Try again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Reports read their own date range and render transaction totals',
    (tester) async {
      final now = DateTime.now();
      final provider = _TestProvider()
        ..reportTransactions = [
          _transaction(date: now, amount: 125),
          _transaction(date: DateTime(now.year - 1), amount: 999),
        ];
      await tester.pumpWidget(_app(provider, const ReportsScreen()));
      await tester.pumpAndSettle();

      expect(provider.reportStart!.isAfter(Helpers.startOfWeek(now)), isFalse);
      expect(provider.reportStart!.isAfter(Helpers.startOfMonth(now)), isFalse);
      expect(
        provider.reportEnd!.isBefore(Helpers.startOfNextWeek(now)),
        isFalse,
      );
      expect(
        provider.reportEnd!.isBefore(Helpers.startOfNextMonth(now)),
        isFalse,
      );
      expect(find.text(Helpers.formatAmount(125)), findsWidgets);
      expect(find.text(Helpers.formatAmount(1124)), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Login can scroll on a small screen and show a sign-in error', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 480);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = _TestProvider();
    await tester.pumpWidget(_app(provider, const LoginScreen()));
    await tester.pumpAndSettle();

    final button = find.text('Sign in with Google');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Sign-in failed. Please try again.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(_TestProvider provider, Widget home) =>
    ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp(home: home),
    );

TransactionModel _transaction({
  required DateTime date,
  double amount = 25,
  String userName = 'Original Author',
}) => TransactionModel(
  id: 'transaction',
  userId: 'original-user',
  userName: userName,
  userPhotoUrl: '',
  type: TransactionType.expense,
  category: 'Old Category',
  amount: amount,
  date: date,
  createdAt: date,
);

class _TestProvider extends ChangeNotifier implements AppProvider {
  TransactionModel? updated;
  String? deletedId;
  DateTime? reportStart;
  DateTime? reportEnd;
  List<TransactionModel> reportTransactions = [];

  @override
  User get user => _EditingUser();

  @override
  List<CategoryModel> get expenseCategories => [];

  @override
  bool get categoriesLoading => false;

  @override
  bool get categoriesFailed => false;

  @override
  bool get isSigningIn => false;

  @override
  Future<void> signInWithGoogle() async => throw StateError('Sign-in failed');

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    updated = transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    deletedId = id;
    throw StateError('Delete denied');
  }

  @override
  Stream<List<TransactionModel>> watchTransactions(
    DateTime start,
    DateTime end,
  ) {
    reportStart = start;
    reportEnd = end;
    return Stream.value(reportTransactions);
  }

  @override
  List<TransactionModel> filterTransactions(
    List<TransactionModel> transactions,
  ) => transactions;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EditingUser implements User {
  @override
  String get uid => 'editing-user';

  @override
  String get displayName => 'Editing User';

  @override
  String? get photoURL => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
