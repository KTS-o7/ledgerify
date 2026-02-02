import '../models/parsed_transaction.dart';
import '../parsers/generic_indian_bank_parser.dart';
import '../parsers/transaction_parser.dart';

/// Service that orchestrates SMS parsing using registered parsers.
///
/// Parsers are tried in order of registration. The first parser
/// that can handle the message and successfully parses it wins.
class TransactionParsingService {
  /// List of registered parsers (order matters)
  final List<TransactionParser> _parsers = [];

  TransactionParsingService() {
    // Register parsers in priority order
    // More specific parsers should come before generic ones
    _parsers.add(GenericIndianBankParser());

    // Future: Add bank-specific parsers here
    // _parsers.insert(0, HDFCParser());
    // _parsers.insert(0, ICICIParser());
  }

  /// Parse an SMS message into a ParsedTransaction.
  ///
  /// [senderId] - The SMS sender ID (e.g., "HD-HDFCBK")
  /// [body] - The SMS message body
  /// [smsId] - Unique identifier for this SMS
  /// [date] - When the SMS was received
  ///
  /// Returns null if no parser can handle the message.
  ParsedTransaction? parse({
    required String senderId,
    required String body,
    required String smsId,
    required DateTime date,
  }) {
    // Clean sender ID (remove common prefixes)
    final cleanSenderId = _cleanSenderId(senderId);

    for (final parser in _parsers) {
      if (parser.canParse(cleanSenderId, body)) {
        final result = parser.parse(
          senderId: cleanSenderId,
          body: body,
          smsId: smsId,
          date: date,
        );
        if (result != null) {
          return result;
        }
      }
    }

    return null;
  }

  /// Check if an SMS is likely a bank transaction message.
  ///
  /// This is a quick check before attempting full parsing.
  bool isLikelyBankSms(String senderId, String body) {
    final cleanSenderId = _cleanSenderId(senderId);
    return _parsers.any((p) => p.canParse(cleanSenderId, body));
  }

  /// Clean up sender ID by removing common prefixes
  String _cleanSenderId(String senderId) {
    // Remove common prefixes like "HD-", "VM-", "BZ-", etc.
    return senderId.replaceAll(RegExp(r'^[A-Z]{2}-'), '').toUpperCase();
  }

  /// Get list of registered parser names (for debugging/UI)
  List<String> get registeredParsers => _parsers.map((p) => p.name).toList();
}
