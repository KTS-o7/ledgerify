// Verifies parser handles SMS samples correctly.
//
// This is intentionally lightweight: it asserts that for messages where
// `canParse` is true, `parse` returns a non-null result with a positive amount.
import 'package:ledgerify/parsers/generic_indian_bank_parser.dart';
import 'package:ledgerify/services/sms_test_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GenericIndianBankParser parses known samples', () {
    final parser = GenericIndianBankParser();
    final testMessages = SmsTestData.getTestMessages();

    expect(testMessages, isNotEmpty);

    var parsedCount = 0;

    for (final msg in testMessages) {
      final senderId = msg['address'] as String;
      final body = msg['body'] as String;
      final smsId = msg['id'] as String;
      final date = msg['date'] as DateTime;

      final canParse = parser.canParse(senderId, body);
      if (!canParse) continue;

      final result = parser.parse(
        senderId: senderId,
        body: body,
        smsId: smsId,
        date: date,
      );

      expect(result, isNotNull, reason: 'Expected parse() for $smsId');

      parsedCount += 1;
      expect(result!.smsId, smsId);
      expect(result.date, date);
      expect(result.senderId, senderId);
      expect(result.amount, greaterThan(0));
    }

    expect(parsedCount, greaterThan(0));
  });
}
