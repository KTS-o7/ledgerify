import 'package:csv/csv.dart';

class TransactionCsvCodec {
  TransactionCsvCodec._();

  static const String formatId = 'ledgerify_transactions_csv_v1';
  static const String commentLine = '# $formatId';

  static const List<String> exportHeader = [
    'id',
    'type',
    'amount',
    'currency',
    'date',
    'created_at',
    // Expense
    'expense_category',
    'custom_category_name',
    'custom_category_color_hex',
    'custom_category_icon_code_point',
    'merchant',
    'note',
    'expense_source',
    'tag_names',
    // Income
    'income_source',
    'description',
  ];

  static const Set<String> requiredColumns = {
    'type',
    'amount',
    'date',
  };

  static String normalizeHeader(String header) {
    return header.replaceAll('\uFEFF', '').trim().toLowerCase();
  }

  static String stripLeadingCommentLines(String input) {
    var csv = input;
    while (true) {
      final trimmedLeft = csv.trimLeft();
      if (!trimmedLeft.startsWith('#')) return csv;

      final idx = csv.indexOf('\n');
      if (idx == -1) return '';
      csv = csv.substring(idx + 1);
    }
  }

  static List<List<String>> decode(String input) {
    final csv = stripLeadingCommentLines(input)
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    if (csv.trim().isEmpty) return const [];

    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(csv);

    return rows
        .map(
          (row) => row.map((cell) => cell?.toString() ?? '').toList(),
        )
        .toList();
  }

  static String encode(List<List<String>> rows) {
    return const ListToCsvConverter().convert(rows);
  }

  static Map<String, int> buildHeaderIndex(List<String> headerRow) {
    final index = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final key = normalizeHeader(headerRow[i]);
      if (key.isEmpty) continue;
      index.putIfAbsent(key, () => i);
    }
    return index;
  }
}

/// Top-level wrapper for isolate parsing via `compute`.
List<List<String>> decodeTransactionCsvRows(String input) {
  return TransactionCsvCodec.decode(input);
}
