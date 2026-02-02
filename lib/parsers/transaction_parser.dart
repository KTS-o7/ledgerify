import '../models/parsed_transaction.dart';

/// Base interface for transaction parsers.
///
/// Implement this interface to add support for specific bank SMS formats.
/// Parsers are tried in order until one successfully parses the message.
abstract class TransactionParser {
  /// Human-readable name of this parser (e.g., "HDFC Bank")
  String get name;

  /// Check if this parser can handle the given SMS.
  ///
  /// [senderId] - The SMS sender ID (e.g., "HDFCBK", "ICICIB")
  /// [body] - The SMS message body
  ///
  /// Returns true if this parser should attempt to parse the message.
  bool canParse(String senderId, String body);

  /// Parse the SMS message into a ParsedTransaction.
  ///
  /// [senderId] - The SMS sender ID
  /// [body] - The SMS message body
  /// [smsId] - Unique identifier for this SMS
  /// [date] - When the SMS was received
  ///
  /// Returns null if parsing fails.
  ParsedTransaction? parse({
    required String senderId,
    required String body,
    required String smsId,
    required DateTime date,
  });
}
