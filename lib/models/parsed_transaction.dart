/// Represents a transaction parsed from an SMS message.
/// This is an intermediate model before user confirms it as Expense/Income.
class ParsedTransaction {
  /// Type of transaction
  final TransactionType type;

  /// Parsed amount
  final double amount;

  /// Merchant/payee name (if detected)
  final String? merchant;

  /// Last 4 digits of account/card number
  final String? accountNumber;

  /// Transaction reference number
  final String? referenceNumber;

  /// Available balance after transaction (if present)
  final double? balance;

  /// Date extracted from SMS (or SMS received date)
  final DateTime date;

  /// Original SMS body for reference
  final String rawMessage;

  /// SMS sender ID (e.g., "HDFCBK")
  final String senderId;

  /// Unique SMS ID to prevent duplicates
  final String smsId;

  /// Confidence score of parsing (0.0 - 1.0)
  final double confidence;

  const ParsedTransaction({
    required this.type,
    required this.amount,
    this.merchant,
    this.accountNumber,
    this.referenceNumber,
    this.balance,
    required this.date,
    required this.rawMessage,
    required this.senderId,
    required this.smsId,
    this.confidence = 1.0,
  });

  @override
  String toString() {
    return 'ParsedTransaction(type: $type, amount: $amount, merchant: $merchant, date: $date)';
  }
}

/// Type of parsed transaction
enum TransactionType {
  debit, // Expense
  credit, // Income
}
