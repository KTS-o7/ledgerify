import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import '../models/parsed_transaction.dart';
import 'sms_permission_service.dart';
import 'transaction_parsing_service.dart';

/// Service for reading and filtering SMS messages.
///
/// Handles SMS inbox access and filters messages to find
/// bank transaction SMS.
class SmsService {
  final SmsQuery _query = SmsQuery();
  final SmsPermissionService _permissionService;
  final TransactionParsingService _parsingService;

  SmsService({
    required SmsPermissionService permissionService,
    required TransactionParsingService parsingService,
  })  : _permissionService = permissionService,
        _parsingService = parsingService;

  /// Read SMS messages from inbox.
  ///
  /// [count] - Maximum number of messages to read (default 500)
  /// [since] - Only read messages after this date (optional)
  ///
  /// Returns empty list if permission not granted.
  Future<List<SmsMessage>> readInbox({
    int count = 500,
    DateTime? since,
  }) async {
    // Check permission first
    final hasPermission = await _permissionService.isGranted();
    if (!hasPermission) {
      return [];
    }

    try {
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: count,
      );

      // Filter by date if specified
      if (since != null) {
        return messages.where((m) {
          final date = m.date;
          return date != null && date.isAfter(since);
        }).toList();
      }

      return messages;
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  /// Read and parse bank transaction SMS.
  ///
  /// [count] - Maximum number of SMS to read
  /// [since] - Only read messages after this date
  ///
  /// Returns list of successfully parsed transactions.
  Future<List<ParsedTransaction>> readAndParseBankSms({
    int count = 500,
    DateTime? since,
  }) async {
    final messages = await readInbox(count: count, since: since);
    final parsed = <ParsedTransaction>[];

    for (final message in messages) {
      final senderId = message.address ?? '';
      final body = message.body ?? '';
      final smsId = message.id?.toString() ?? '';
      final date = message.date ?? DateTime.now();

      // Skip if empty
      if (senderId.isEmpty || body.isEmpty) continue;

      // Quick check if this looks like a bank SMS
      if (!_parsingService.isLikelyBankSms(senderId, body)) continue;

      // Try to parse
      final transaction = _parsingService.parse(
        senderId: senderId,
        body: body,
        smsId: smsId,
        date: date,
      );

      if (transaction != null) {
        parsed.add(transaction);
      }
    }

    return parsed;
  }

  /// Get count of bank SMS in inbox (for UI display)
  Future<int> getBankSmsCount({int scanLimit = 500}) async {
    final messages = await readInbox(count: scanLimit);
    int count = 0;

    for (final message in messages) {
      final senderId = message.address ?? '';
      final body = message.body ?? '';

      if (_parsingService.isLikelyBankSms(senderId, body)) {
        count++;
      }
    }

    return count;
  }
}
