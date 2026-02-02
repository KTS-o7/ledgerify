import 'package:hive/hive.dart';

part 'sms_transaction.g.dart';

/// Status of an SMS transaction
@HiveType(typeId: 16)
enum SmsTransactionStatus {
  @HiveField(0)
  pending, // Awaiting user review

  @HiveField(1)
  confirmed, // User confirmed, linked to expense/income

  @HiveField(2)
  skipped, // User chose to skip this transaction

  @HiveField(3)
  deleted, // User deleted this transaction
}

/// Represents a transaction parsed from SMS, stored in Hive.
///
/// This is persisted to track which SMS have been processed and
/// to allow users to review pending transactions.
@HiveType(typeId: 15)
class SmsTransaction extends HiveObject {
  /// Unique SMS ID from the system (prevents duplicates)
  @HiveField(0)
  final String smsId;

  /// Original SMS body
  @HiveField(1)
  final String rawMessage;

  /// SMS sender ID (e.g., "HDFCBK")
  @HiveField(2)
  final String senderId;

  /// When the SMS was received
  @HiveField(3)
  final DateTime smsDate;

  /// Parsed amount
  @HiveField(4)
  final double amount;

  /// Transaction type: 'debit' or 'credit'
  @HiveField(5)
  final String transactionType;

  /// Parsed merchant name (if any)
  @HiveField(6)
  final String? merchant;

  /// Last 4 digits of account/card
  @HiveField(7)
  final String? accountNumber;

  /// Current status of this transaction
  @HiveField(8)
  SmsTransactionStatus status;

  /// Linked expense ID (if confirmed as expense)
  @HiveField(9)
  String? linkedExpenseId;

  /// Linked income ID (if confirmed as income)
  @HiveField(10)
  String? linkedIncomeId;

  /// When this record was created
  @HiveField(11)
  final DateTime createdAt;

  /// Parsing confidence score (0.0 - 1.0)
  @HiveField(12)
  final double confidence;

  SmsTransaction({
    required this.smsId,
    required this.rawMessage,
    required this.senderId,
    required this.smsDate,
    required this.amount,
    required this.transactionType,
    this.merchant,
    this.accountNumber,
    this.status = SmsTransactionStatus.pending,
    this.linkedExpenseId,
    this.linkedIncomeId,
    DateTime? createdAt,
    this.confidence = 1.0,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Whether this is a debit (expense) transaction
  bool get isDebit => transactionType == 'debit';

  /// Whether this is a credit (income) transaction
  bool get isCredit => transactionType == 'credit';

  /// Whether this transaction is pending review
  bool get isPending => status == SmsTransactionStatus.pending;

  /// Whether this transaction has been processed (confirmed/skipped/deleted)
  bool get isProcessed => status != SmsTransactionStatus.pending;
}
