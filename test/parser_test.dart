// Quick test to verify parser handles SMS samples correctly
import 'package:ledgerify/parsers/generic_indian_bank_parser.dart';
import 'package:ledgerify/services/sms_test_data.dart';

void main() {
  final parser = GenericIndianBankParser();
  final testMessages = SmsTestData.getTestMessages();

  print('Testing ${testMessages.length} SMS samples:\n');

  for (final msg in testMessages) {
    final senderId = msg['address'] as String;
    final body = msg['body'] as String;
    final smsId = msg['id'] as String;
    final date = msg['date'] as DateTime;

    print('--- $smsId ---');
    print('Sender: $senderId');
    print('Body: ${body.substring(0, body.length > 80 ? 80 : body.length)}...');

    final canParse = parser.canParse(senderId, body);
    print('Can parse: $canParse');

    if (canParse) {
      final result = parser.parse(
        senderId: senderId,
        body: body,
        smsId: smsId,
        date: date,
      );

      if (result != null) {
        print('Type: ${result.type}');
        print('Amount: ${result.amount}');
        print('Merchant: ${result.merchant ?? "N/A"}');
        print('Account: ${result.accountNumber ?? "N/A"}');
        print('Balance: ${result.balance ?? "N/A"}');
        print('Confidence: ${(result.confidence * 100).toStringAsFixed(0)}%');
      } else {
        print('PARSE FAILED - returned null');
      }
    }
    print('');
  }
}
