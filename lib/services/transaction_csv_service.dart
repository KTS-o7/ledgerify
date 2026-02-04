import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../services/custom_category_service.dart';
import '../services/expense_service.dart';
import '../services/income_service.dart';
import '../services/tag_service.dart';
import '../models/tag.dart';
import '../models/custom_category.dart';
import 'transaction_csv_codec.dart';

enum CsvIssueSeverity { warning, error }

class CsvImportIssue {
  final int rowNumber;
  final CsvIssueSeverity severity;
  final String message;

  const CsvImportIssue({
    required this.rowNumber,
    required this.severity,
    required this.message,
  });
}

enum CsvTransactionType { expense, income }

class CsvCustomCategorySpec {
  final String name;
  final String? colorHex;
  final int? iconCodePoint;

  const CsvCustomCategorySpec({
    required this.name,
    this.colorHex,
    this.iconCodePoint,
  });

  CsvCustomCategorySpec merge(CsvCustomCategorySpec other) {
    if (name.toLowerCase() != other.name.toLowerCase()) return this;
    return CsvCustomCategorySpec(
      name: name,
      colorHex: colorHex ?? other.colorHex,
      iconCodePoint: iconCodePoint ?? other.iconCodePoint,
    );
  }
}

class CsvImportPreview {
  final int totalDataRows;
  final int skippedExisting;
  final List<ParsedCsvTransaction> toImport;
  final List<CsvImportIssue> issues;
  final Map<String, CsvCustomCategorySpec> customCategoriesToCreate;
  final Map<String, String> tagsToCreate; // lower -> display name

  const CsvImportPreview({
    required this.totalDataRows,
    required this.skippedExisting,
    required this.toImport,
    required this.issues,
    required this.customCategoriesToCreate,
    required this.tagsToCreate,
  });

  int get errorCount =>
      issues.where((i) => i.severity == CsvIssueSeverity.error).length;
  int get warningCount =>
      issues.where((i) => i.severity == CsvIssueSeverity.warning).length;
}

class CsvImportResult {
  final int importedExpenses;
  final int importedIncomes;
  final int skippedExisting;
  final int createdTags;
  final int createdCustomCategories;

  const CsvImportResult({
    required this.importedExpenses,
    required this.importedIncomes,
    required this.skippedExisting,
    required this.createdTags,
    required this.createdCustomCategories,
  });
}

class TransactionCsvService {
  static const Uuid _uuid = Uuid();

  final ExpenseService expenseService;
  final IncomeService incomeService;
  final TagService tagService;
  final CustomCategoryService customCategoryService;

  const TransactionCsvService({
    required this.expenseService,
    required this.incomeService,
    required this.tagService,
    required this.customCategoryService,
  });

  Future<String> exportCsv() async {
    final tagsById = <String, Tag>{
      for (final t in tagService.box.values) t.id: t,
    };
    final customCategoriesById = <String, CustomCategory>{
      for (final c in customCategoryService.box.values) c.id: c,
    };

    final expenseRows = expenseService.getAllExpenses().map((e) {
      final tagNames = e.tagIds
          .map((id) => tagsById[id]?.name)
          .whereType<String>()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      final custom = e.customCategoryId != null
          ? customCategoriesById[e.customCategoryId!]
          : null;

      return <String, String>{
        'id': e.id,
        'type': 'expense',
        'amount': e.amount.toStringAsFixed(2),
        'currency': 'INR',
        'date': e.date.toIso8601String(),
        'created_at': e.createdAt.toIso8601String(),
        'expense_category': e.category.name,
        'custom_category_name': custom?.name ?? '',
        'custom_category_color_hex': custom?.colorHex ?? '',
        'custom_category_icon_code_point':
            custom != null ? custom.iconCodePoint.toString() : '',
        'merchant': e.merchant ?? '',
        'note': e.note ?? '',
        'expense_source': e.source.name,
        'tag_names': tagNames.join(';'),
      };
    }).toList();

    final incomeRows = incomeService.getAllIncomes().map((i) {
      return <String, String>{
        'id': i.id,
        'type': 'income',
        'amount': i.amount.toStringAsFixed(2),
        'currency': 'INR',
        'date': i.date.toIso8601String(),
        'created_at': i.createdAt.toIso8601String(),
        'income_source': i.source.name,
        'description': i.description ?? '',
      };
    }).toList();

    final allRows = [...expenseRows, ...incomeRows];
    allRows.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

    final rows = <List<String>>[
      TransactionCsvCodec.exportHeader,
      ...allRows.map(
        (m) => TransactionCsvCodec.exportHeader.map((h) => m[h] ?? '').toList(),
      ),
    ];

    final csv = TransactionCsvCodec.encode(rows);
    return '${TransactionCsvCodec.commentLine}\n$csv';
  }

  CsvImportPreview previewImportCsv(String csvContent) {
    final issues = <CsvImportIssue>[];
    final rows = TransactionCsvCodec.decode(csvContent);
    if (rows.isEmpty) {
      return const CsvImportPreview(
        totalDataRows: 0,
        skippedExisting: 0,
        toImport: [],
        issues: [
          CsvImportIssue(
            rowNumber: 0,
            severity: CsvIssueSeverity.error,
            message: 'CSV is empty or could not be parsed.',
          )
        ],
        customCategoriesToCreate: {},
        tagsToCreate: {},
      );
    }

    final headerIndex = TransactionCsvCodec.buildHeaderIndex(rows.first);
    for (final required in TransactionCsvCodec.requiredColumns) {
      if (!headerIndex.containsKey(required)) {
        issues.add(
          CsvImportIssue(
            rowNumber: 1,
            severity: CsvIssueSeverity.error,
            message: 'Missing required column: $required',
          ),
        );
      }
    }

    if (issues.any((i) => i.severity == CsvIssueSeverity.error)) {
      return CsvImportPreview(
        totalDataRows: rows.length - 1,
        skippedExisting: 0,
        toImport: const [],
        issues: issues,
        customCategoriesToCreate: const {},
        tagsToCreate: const {},
      );
    }

    final existingTagsByLower = <String, Tag>{
      for (final t in tagService.box.values) t.name.toLowerCase(): t,
    };
    final existingCustomCategoriesByLower = <String, CustomCategory>{
      for (final c in customCategoryService.box.values) c.name.toLowerCase(): c,
    };

    final seenExpenseIds = <String>{};
    final seenIncomeIds = <String>{};

    final toImport = <ParsedCsvTransaction>[];
    var skippedExisting = 0;

    final customCategoriesToCreate = <String, CsvCustomCategorySpec>{};
    final tagsToCreate = <String, String>{};

    for (var i = 1; i < rows.length; i++) {
      final rowNumber = i + 1; // 1-based, includes header row
      final row = rows[i];

      String readCell(String key) {
        final idx = headerIndex[key];
        if (idx == null) return '';
        if (idx < 0 || idx >= row.length) return '';
        return row[idx].trim();
      }

      final typeRaw = readCell('type').toLowerCase();
      final type = switch (typeRaw) {
        'expense' => CsvTransactionType.expense,
        'income' => CsvTransactionType.income,
        _ => null,
      };

      if (type == null) {
        issues.add(
          CsvImportIssue(
            rowNumber: rowNumber,
            severity: CsvIssueSeverity.error,
            message:
                'Invalid type "$typeRaw" (expected "expense" or "income").',
          ),
        );
        continue;
      }

      final rawId = readCell('id');
      final id = rawId.isEmpty ? _uuid.v4() : rawId;
      final idSet =
          type == CsvTransactionType.expense ? seenExpenseIds : seenIncomeIds;
      if (idSet.contains(id)) {
        issues.add(
          CsvImportIssue(
            rowNumber: rowNumber,
            severity: CsvIssueSeverity.error,
            message: 'Duplicate id "$id" within CSV.',
          ),
        );
        continue;
      }
      idSet.add(id);

      final amountRaw = readCell('amount').replaceAll(',', '');
      final amount = double.tryParse(amountRaw);
      if (amount == null || amount == 0) {
        issues.add(
          CsvImportIssue(
            rowNumber: rowNumber,
            severity: CsvIssueSeverity.error,
            message: 'Invalid amount "$amountRaw".',
          ),
        );
        continue;
      }

      final dateRaw = readCell('date');
      final date = DateTime.tryParse(dateRaw);
      if (date == null) {
        issues.add(
          CsvImportIssue(
            rowNumber: rowNumber,
            severity: CsvIssueSeverity.error,
            message: 'Invalid date "$dateRaw" (expected ISO-8601).',
          ),
        );
        continue;
      }

      final createdAtRaw = readCell('created_at');
      final createdAt =
          createdAtRaw.isNotEmpty ? DateTime.tryParse(createdAtRaw) : null;
      if (createdAtRaw.isNotEmpty && createdAt == null) {
        issues.add(
          CsvImportIssue(
            rowNumber: rowNumber,
            severity: CsvIssueSeverity.warning,
            message:
                'Invalid created_at "$createdAtRaw" (will use current time).',
          ),
        );
      }

      final existsInApp = type == CsvTransactionType.expense
          ? expenseService.box.containsKey(id)
          : incomeService.box.containsKey(id);
      if (existsInApp) {
        skippedExisting++;
        issues.add(
          CsvImportIssue(
            rowNumber: rowNumber,
            severity: CsvIssueSeverity.warning,
            message: 'Row skipped because id "$id" already exists.',
          ),
        );
        continue;
      }

      final parsed = ParsedCsvTransaction(
        type: type,
        id: id,
        amount: amount.abs(),
        date: date,
        createdAt: createdAt,
        expenseCategoryRaw: readCell('expense_category'),
        customCategoryName: readCell('custom_category_name'),
        customCategoryColorHex: readCell('custom_category_color_hex'),
        customCategoryIconCodePointRaw:
            readCell('custom_category_icon_code_point'),
        merchant: readCell('merchant'),
        note: readCell('note'),
        expenseSourceRaw: readCell('expense_source'),
        tagNamesRaw: readCell('tag_names'),
        incomeSourceRaw: readCell('income_source'),
        description: readCell('description'),
      );

      // Precompute "will create" sets for preview UX
      final customName = parsed.customCategoryName.trim();
      if (type == CsvTransactionType.expense && customName.isNotEmpty) {
        final lower = customName.toLowerCase();
        if (!existingCustomCategoriesByLower.containsKey(lower)) {
          final spec = CsvCustomCategorySpec(
            name: customName,
            colorHex: _sanitizeColorHex(parsed.customCategoryColorHex),
            iconCodePoint:
                _parseIntOrNull(parsed.customCategoryIconCodePointRaw),
          );
          customCategoriesToCreate[lower] =
              (customCategoriesToCreate[lower] ?? spec).merge(spec);
        }
      }

      final tagNames = _parseTagNamesPreserveCase(parsed.tagNamesRaw);
      for (final entry in tagNames.entries) {
        if (!existingTagsByLower.containsKey(entry.key)) {
          tagsToCreate.putIfAbsent(entry.key, () => entry.value);
        }
      }

      toImport.add(parsed);
    }

    final customToCreateByName = <String, CsvCustomCategorySpec>{};
    for (final spec in customCategoriesToCreate.values) {
      customToCreateByName[spec.name] = spec;
    }

    return CsvImportPreview(
      totalDataRows: rows.length - 1,
      skippedExisting: skippedExisting,
      toImport: toImport,
      issues: issues,
      customCategoriesToCreate: customToCreateByName,
      tagsToCreate: tagsToCreate,
    );
  }

  Future<CsvImportResult> applyImport(CsvImportPreview preview) async {
    final existingTagsByLower = <String, Tag>{
      for (final t in tagService.box.values) t.name.toLowerCase(): t,
    };
    final existingCustomByLower = <String, CustomCategory>{
      for (final c in customCategoryService.box.values) c.name.toLowerCase(): c,
    };

    var createdTags = 0;
    var createdCustomCategories = 0;

    // Create custom categories first (so expenses can reference them).
    for (final spec in preview.customCategoriesToCreate.values) {
      final lower = spec.name.toLowerCase();
      if (existingCustomByLower.containsKey(lower)) continue;

      final colorHex = spec.colorHex ?? '#A8E6CF';
      final icon = spec.iconCodePoint ?? Icons.category_rounded.codePoint;
      final created = await customCategoryService.createCategory(
        name: spec.name.trim(),
        iconCodePoint: icon,
        colorHex: colorHex,
      );
      existingCustomByLower[lower] = created;
      createdCustomCategories++;
    }

    // Create tags
    for (final entry in preview.tagsToCreate.entries) {
      final lower = entry.key;
      if (existingTagsByLower.containsKey(lower)) continue;
      final created = await tagService.createTag(
        name: entry.value.trim(),
        colorHex: '#A8E6CF',
      );
      existingTagsByLower[lower] = created;
      createdTags++;
    }

    final expensesToPut = <String, Expense>{};
    final incomesToPut = <String, Income>{};

    for (final parsed in preview.toImport) {
      if (parsed.type == CsvTransactionType.expense) {
        final category = _parseExpenseCategory(parsed.expenseCategoryRaw);
        final source = _parseExpenseSource(parsed.expenseSourceRaw);

        final customName = parsed.customCategoryName.trim();
        final customId = customName.isNotEmpty
            ? existingCustomByLower[customName.toLowerCase()]?.id
            : null;

        final tagNames = _parseTagNamesPreserveCase(parsed.tagNamesRaw);
        final tagIds = tagNames.keys
            .map((lower) => existingTagsByLower[lower]?.id)
            .whereType<String>()
            .toList();

        final expense = Expense(
          id: parsed.id,
          amount: parsed.amount,
          category: category,
          date: parsed.date,
          note: _nullIfBlank(parsed.note),
          source: source,
          merchant: _nullIfBlank(parsed.merchant),
          createdAt: parsed.createdAt,
          customCategoryId: customId,
          tagIds: tagIds,
        );

        expensesToPut[expense.id] = expense;
      } else {
        final source = _parseIncomeSource(parsed.incomeSourceRaw);
        final income = Income(
          id: parsed.id,
          amount: parsed.amount,
          source: source,
          description: _nullIfBlank(parsed.description),
          date: parsed.date,
          createdAt: parsed.createdAt,
        );
        incomesToPut[income.id] = income;
      }
    }

    if (expensesToPut.isNotEmpty) {
      await expenseService.box.putAll(expensesToPut);
    }
    if (incomesToPut.isNotEmpty) {
      await incomeService.box.putAll(incomesToPut);
    }

    return CsvImportResult(
      importedExpenses: expensesToPut.length,
      importedIncomes: incomesToPut.length,
      skippedExisting: preview.skippedExisting,
      createdTags: createdTags,
      createdCustomCategories: createdCustomCategories,
    );
  }

  static String? _nullIfBlank(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static ExpenseCategory _parseExpenseCategory(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return ExpenseCategory.other;
    return ExpenseCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }

  static ExpenseSource _parseExpenseSource(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return ExpenseSource.manual;
    return ExpenseSource.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ExpenseSource.manual,
    );
  }

  static IncomeSource _parseIncomeSource(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return IncomeSource.other;
    return IncomeSource.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => IncomeSource.other,
    );
  }

  static Map<String, String> _parseTagNamesPreserveCase(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return const {};
    final out = <String, String>{};
    for (final part in value.split(';')) {
      final name = part.trim();
      if (name.isEmpty) continue;
      final lower = name.toLowerCase();
      out.putIfAbsent(lower, () => name);
    }
    return out;
  }

  static int? _parseIntOrNull(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }

  static String? _sanitizeColorHex(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final isValid =
        RegExp(r'^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(value);
    return isValid ? value : null;
  }
}

class ParsedCsvTransaction {
  final CsvTransactionType type;
  final String id;
  final double amount;
  final DateTime date;
  final DateTime? createdAt;

  // Expense-specific
  final String expenseCategoryRaw;
  final String customCategoryName;
  final String customCategoryColorHex;
  final String customCategoryIconCodePointRaw;
  final String merchant;
  final String note;
  final String expenseSourceRaw;
  final String tagNamesRaw;

  // Income-specific
  final String incomeSourceRaw;
  final String description;

  const ParsedCsvTransaction({
    required this.type,
    required this.id,
    required this.amount,
    required this.date,
    required this.createdAt,
    required this.expenseCategoryRaw,
    required this.customCategoryName,
    required this.customCategoryColorHex,
    required this.customCategoryIconCodePointRaw,
    required this.merchant,
    required this.note,
    required this.expenseSourceRaw,
    required this.tagNamesRaw,
    required this.incomeSourceRaw,
    required this.description,
  });
}
