import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerify/services/transaction_csv_codec.dart';

void main() {
  test('TransactionCsvCodec strips leading comments', () {
    const input = '''
# ledgerify_transactions_csv_v1
# another comment
type,amount,date
expense,12.34,2026-02-04
''';

    final rows = TransactionCsvCodec.decode(input);
    expect(rows.length, 2);
    expect(rows.first, ['type', 'amount', 'date']);
    expect(rows[1], ['expense', '12.34', '2026-02-04']);
  });

  test('TransactionCsvCodec parses quoted fields with commas/newlines', () {
    const input = '''
# ledgerify_transactions_csv_v1
type,amount,date,note
expense,12.34,2026-02-04,"coffee, bagel"
expense,5.00,2026-02-04,"line1
line2"
''';

    final rows = TransactionCsvCodec.decode(input);
    expect(rows.length, 3);
    expect(rows[1][3], 'coffee, bagel');
    expect(rows[2][3], 'line1\nline2');
  });

  test('TransactionCsvCodec round-trips encode/decode', () {
    final encoded = TransactionCsvCodec.encode([
      ['type', 'amount', 'date'],
      ['income', '1000.00', '2026-02-01T10:00:00'],
    ]);
    final decoded = TransactionCsvCodec.decode(encoded);
    expect(decoded, [
      ['type', 'amount', 'date'],
      ['income', '1000.00', '2026-02-01T10:00:00'],
    ]);
  });
}
