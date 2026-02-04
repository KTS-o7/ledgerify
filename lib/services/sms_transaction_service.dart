import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/parsed_transaction.dart';
import '../models/sms_transaction.dart';
import '../parsers/category_classifier.dart';
import 'expense_service.dart';
import 'income_service.dart';
import 'sms_service.dart';

/// Service for managing SMS transactions.
///
/// Handles importing SMS, storing parsed transactions,
/// and converting confirmed transactions to expenses/incomes.
class SmsTransactionService {
  static const String _boxName = 'sms_transactions';

  late Box<SmsTransaction> _box;
  final SmsService _smsService;
  final ExpenseService _expenseService;
  final IncomeService _incomeService;

  SmsTransactionService({
    required SmsService smsService,
    required ExpenseService expenseService,
    required IncomeService incomeService,
  })  : _smsService = smsService,
        _expenseService = expenseService,
        _incomeService = incomeService;

  /// Initialize the service and open Hive box
  Future<void> init() async {
    _box = await Hive.openBox<SmsTransaction>(
      _boxName,
      compactionStrategy: (entries, deletedEntries) =>
          deletedEntries > entries * 0.2,
    );
  }

  /// Import new SMS transactions from inbox.
  ///
  /// [since] - Only import messages after this date
  /// [limit] - Maximum number of messages to scan
  ///
  /// Returns list of newly imported transactions.
  Future<List<SmsTransaction>> importFromInbox({
    DateTime? since,
    int limit = 500,
  }) async {
    // Get parsed transactions from SMS
    final parsed = await _smsService.readAndParseBankSms(
      count: limit,
      since: since,
    );

    final imported = <SmsTransaction>[];
    final existingIds = _box.keys.cast<String>().toSet();
    final toPut = <String, SmsTransaction>{};

    for (final transaction in parsed) {
      // Skip if already processed
      if (existingIds.contains(transaction.smsId)) continue;

      // Create SmsTransaction record
      final smsTransaction = SmsTransaction(
        smsId: transaction.smsId,
        rawMessage: transaction.rawMessage,
        senderId: transaction.senderId,
        smsDate: transaction.date,
        amount: transaction.amount,
        transactionType:
            transaction.type == TransactionType.debit ? 'debit' : 'credit',
        merchant: transaction.merchant,
        accountNumber: transaction.accountNumber,
        confidence: transaction.confidence,
      );

      // Save to box (batch at end for performance)
      existingIds.add(smsTransaction.smsId);
      toPut[smsTransaction.smsId] = smsTransaction;
      imported.add(smsTransaction);
    }

    if (toPut.isNotEmpty) {
      await _box.putAll(toPut);
    }

    return imported;
  }

  /// Get all pending transactions (awaiting user review)
  List<SmsTransaction> getPendingTransactions() {
    return _box.values
        .where((t) => t.status == SmsTransactionStatus.pending)
        .toList()
      ..sort((a, b) => b.smsDate.compareTo(a.smsDate));
  }

  /// Get pending debit transactions (expenses)
  List<SmsTransaction> getPendingExpenses() {
    return getPendingTransactions().where((t) => t.isDebit).toList();
  }

  /// Get pending credit transactions (incomes)
  List<SmsTransaction> getPendingIncomes() {
    return getPendingTransactions().where((t) => t.isCredit).toList();
  }

  /// Get count of pending transactions
  int get pendingCount => getPendingTransactions().length;

  /// Confirm a transaction as an expense.
  ///
  /// [transaction] - The SMS transaction to confirm
  /// [category] - Category to assign (auto-classified if null)
  /// [note] - Optional note to add
  ///
  /// Returns the created Expense.
  Future<Expense> confirmAsExpense(
    SmsTransaction transaction, {
    ExpenseCategory? category,
    String? note,
  }) async {
    // Auto-classify if category not provided
    final finalCategory =
        category ?? CategoryClassifier.classify(transaction.merchant);

    // Create expense
    final expense = await _expenseService.addExpense(
      amount: transaction.amount,
      category: finalCategory,
      date: transaction.smsDate,
      note: note ?? transaction.merchant,
      source: ExpenseSource.sms,
      merchant: transaction.merchant,
    );

    // Update transaction status
    transaction.status = SmsTransactionStatus.confirmed;
    transaction.linkedExpenseId = expense.id;
    await transaction.save();

    return expense;
  }

  /// Confirm a transaction as income.
  ///
  /// [transaction] - The SMS transaction to confirm
  /// [source] - Income source to assign
  /// [description] - Optional description to add
  ///
  /// Returns the created Income.
  Future<Income> confirmAsIncome(
    SmsTransaction transaction, {
    IncomeSource source = IncomeSource.other,
    String? description,
  }) async {
    // Create income
    final income = await _incomeService.addIncome(
      amount: transaction.amount,
      source: source,
      date: transaction.smsDate,
      description: description ?? transaction.merchant ?? 'SMS Import',
    );

    // Update transaction status
    transaction.status = SmsTransactionStatus.confirmed;
    transaction.linkedIncomeId = income.id;
    await transaction.save();

    return income;
  }

  /// Skip a transaction (mark as skipped, won't show in pending)
  Future<void> skipTransaction(SmsTransaction transaction) async {
    transaction.status = SmsTransactionStatus.skipped;
    await transaction.save();
  }

  /// Delete a transaction record
  Future<void> deleteTransaction(SmsTransaction transaction) async {
    transaction.status = SmsTransactionStatus.deleted;
    await transaction.save();
  }

  /// Confirm multiple transactions as expenses (batch operation)
  Future<List<Expense>> confirmMultipleAsExpenses(
    List<SmsTransaction> transactions,
  ) async {
    final expenses = <Expense>[];

    for (final transaction in transactions) {
      if (transaction.isDebit && transaction.isPending) {
        final expense = await confirmAsExpense(transaction);
        expenses.add(expense);
      }
    }

    return expenses;
  }

  /// Confirm multiple credit transactions as incomes (batch operation)
  ///
  /// [transactions] - List of SMS transactions to confirm
  /// [sourceOverrides] - Optional map of smsId to IncomeSource for custom sources
  ///
  /// Returns the list of created Income records.
  Future<List<Income>> confirmMultipleAsIncomes(
    List<SmsTransaction> transactions, {
    Map<String, IncomeSource>? sourceOverrides,
  }) async {
    final incomes = <Income>[];

    for (final transaction in transactions) {
      if (transaction.isCredit && transaction.isPending) {
        final source =
            sourceOverrides?[transaction.smsId] ?? IncomeSource.other;
        final income = await confirmAsIncome(transaction, source: source);
        incomes.add(income);
      }
    }

    return incomes;
  }

  /// Confirm multiple debit transactions as expenses with category overrides
  ///
  /// [transactions] - List of SMS transactions to confirm
  /// [categoryOverrides] - Optional map of smsId to ExpenseCategory
  ///
  /// Returns the list of created Expense records.
  Future<List<Expense>> confirmMultipleAsExpensesWithOverrides(
    List<SmsTransaction> transactions, {
    Map<String, ExpenseCategory>? categoryOverrides,
  }) async {
    final expenses = <Expense>[];

    for (final transaction in transactions) {
      if (transaction.isDebit && transaction.isPending) {
        final category = categoryOverrides?[transaction.smsId];
        final expense = await confirmAsExpense(transaction, category: category);
        expenses.add(expense);
      }
    }

    return expenses;
  }

  /// Skip multiple transactions (batch operation)
  Future<void> skipMultiple(List<SmsTransaction> transactions) async {
    for (final transaction in transactions) {
      if (transaction.isPending) {
        await skipTransaction(transaction);
      }
    }
  }

  /// Get the date of the last imported SMS
  DateTime? getLastImportDate() {
    if (_box.isEmpty) return null;

    DateTime? latest;
    for (final transaction in _box.values) {
      if (latest == null || transaction.smsDate.isAfter(latest)) {
        latest = transaction.smsDate;
      }
    }
    return latest;
  }

  /// Get the Hive box for UI listening
  Box<SmsTransaction> get box => _box;

  /// Get total count of all transactions
  int get totalCount => _box.length;

  /// Get count of confirmed transactions
  int get confirmedCount => _box.values
      .where((t) => t.status == SmsTransactionStatus.confirmed)
      .length;
}
