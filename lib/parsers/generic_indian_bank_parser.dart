import '../models/parsed_transaction.dart';
import 'transaction_parser.dart';

/// Generic parser for Indian bank SMS messages.
///
/// Uses common patterns found across most Indian banks:
/// - Keywords: debited, credited, spent, received, etc.
/// - Amount formats: Rs.500.00, INR 1,500, Rs 25,000.50
/// - Account formats: XX1234, *1234, A/c 1234
///
/// This parser catches most standard bank SMS formats.
class GenericIndianBankParser implements TransactionParser {
  @override
  String get name => 'Generic Indian Bank';

  /// Known bank sender ID patterns
  /// Note: Indian sender IDs follow format: XX-BANKCODE or XX-BANKCODE-S
  /// where -S suffix indicates service/promotional messages
  static const _bankSenderPatterns = [
    // Major banks
    'HDFC',
    'ICICI',
    'SBI',
    'SBIPSG', // SBI Payment Services Gateway
    'SBIINB', // SBI Internet Banking
    'SBIATM', // SBI ATM
    'AXIS',
    'KOTAK',
    'IDFC',
    'INDUS',
    'YES',
    'PNB',
    'BOB',
    'CANARA',
    'UNION',
    'FEDERAL',
    'FEDBK',
    'RBL',
    // International banks
    'AMEX',
    'CITI',
    'HSBC',
    'SCB',
    'DBS',
    // Fintech/Cards
    'ONECARD',
    'SLICE',
    'JUPITER',
    'FI-', // Fi Money
    'NIYO',
    // Wallets/UPI
    'PAYTM',
    'GPAY',
    'PHONEPE',
    'AMAZONPAY',
    'MOBIKWIK',
    'FREECHARGE',
    // Credit cards
    'AUBANK',
    'AUCC', // AU Small Finance Bank Credit Card
  ];

  /// Keywords indicating a debit transaction
  static const _debitKeywords = [
    'debited',
    'debit',
    'spent',
    'paid',
    'payment',
    'deducted',
    'withdrawn',
    'purchase',
    'txn',
    'amt sent',
    'transferred',
    'bill payment',
    'transaction of rs', // Slice credit card pattern
    'card transaction', // Credit card spend pattern
  ];

  /// Keywords indicating a credit transaction
  static const _creditKeywords = [
    'credited',
    'credit',
    'received',
    'deposited',
    'refund',
    'cashback',
    'reversed',
    'amt received',
  ];

  /// Regex to extract amount: Rs.500.00, Rs 1,500, INR 25,000.50, etc.
  static final _amountRegex = RegExp(
    r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  /// Regex to extract account/card number: XX1234, *1234, ending 1234
  static final _accountRegex = RegExp(
    r'(?:XX|x{2}|\*{1,2}|ending\s*|A/?c\s*(?:No\.?\s*)?(?:XX|\*)?)([\dX]{4,})',
    caseSensitive: false,
  );

  /// Regex to extract merchant/payee (common patterns)
  static final _merchantPatterns = [
    // "at MERCHANT NAME"
    RegExp(r'\bat\s+([A-Z][A-Z0-9\s\-\.]+?)(?:\s+on|\s+via|\s*$)',
        caseSensitive: false),
    // "to VPA merchant@upi"
    RegExp(r'to\s+(?:VPA\s+)?([a-zA-Z0-9\.\-]+@[a-zA-Z]+)',
        caseSensitive: false),
    // "to MERCHANT NAME"
    RegExp(r'\bto\s+([A-Z][A-Z0-9\s\-\.]+?)(?:\s+on|\s+ref|\s*$)',
        caseSensitive: false),
    // "on MERCHANT is successful" (Slice credit card pattern)
    RegExp(r'\bon\s+([A-Za-z][A-Za-z0-9\s\-\.]+?)\s+is\s+successful',
        caseSensitive: false),
    // "Rs.XXX on MERCHANT" (generic pattern)
    RegExp(
        r'Rs\.?\s*[\d,]+(?:\.\d+)?\s+on\s+([A-Za-z][A-Za-z0-9\s\-\.]+?)(?:\s+is|\s*$)',
        caseSensitive: false),
  ];

  /// Regex to extract balance
  static final _balanceRegex = RegExp(
    r'(?:Bal|Balance|Avl\.?\s*Bal)[:\s]*(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  @override
  bool canParse(String senderId, String body) {
    final upperSender = senderId.toUpperCase();
    final upperBody = body.toUpperCase();

    // Check if sender matches known bank patterns
    final isBankSender = _bankSenderPatterns.any(
      (pattern) => upperSender.contains(pattern),
    );

    // Check if body contains transaction keywords
    final hasDebitKeyword = _debitKeywords.any(
      (kw) => upperBody.contains(kw.toUpperCase()),
    );
    final hasCreditKeyword = _creditKeywords.any(
      (kw) => upperBody.contains(kw.toUpperCase()),
    );

    // Check if body contains amount pattern
    final hasAmount = _amountRegex.hasMatch(body);

    return isBankSender && (hasDebitKeyword || hasCreditKeyword) && hasAmount;
  }

  @override
  ParsedTransaction? parse({
    required String senderId,
    required String body,
    required String smsId,
    required DateTime date,
  }) {
    // Extract amount
    final amountMatch = _amountRegex.firstMatch(body);
    if (amountMatch == null) return null;

    final amountStr = amountMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return null;

    // Determine transaction type
    final upperBody = body.toUpperCase();

    // Special case: "credit card" in message indicates a DEBIT (spend on credit card)
    // Need to check this first to avoid false positive from "credit" keyword
    final hasCreditCard = upperBody.contains('CREDIT CARD');

    final isDebit =
        _debitKeywords.any((kw) => upperBody.contains(kw.toUpperCase()));

    // For credit keywords, exclude "credit" if it's part of "credit card"
    bool isCredit;
    if (hasCreditCard) {
      // Check if there's a standalone credit keyword (not "credit card")
      isCredit = _creditKeywords.any((kw) {
        if (kw.toLowerCase() == 'credit') {
          // Check if "credit" appears outside of "credit card"
          final creditIndex = upperBody.indexOf('CREDIT');
          final creditCardIndex = upperBody.indexOf('CREDIT CARD');
          // Only count as credit if "credit" appears separately from "credit card"
          return creditIndex >= 0 &&
              (creditCardIndex < 0 || creditIndex != creditCardIndex);
        }
        return upperBody.contains(kw.toUpperCase());
      });
    } else {
      isCredit =
          _creditKeywords.any((kw) => upperBody.contains(kw.toUpperCase()));
    }

    // If both or neither, try to infer from context
    TransactionType type;
    if (isDebit && !isCredit) {
      type = TransactionType.debit;
    } else if (isCredit && !isDebit) {
      type = TransactionType.credit;
    } else if (isDebit && isCredit) {
      // Both keywords present - check which comes first
      final debitIndex = _debitKeywords
          .map((kw) => upperBody.indexOf(kw.toUpperCase()))
          .where((i) => i >= 0)
          .fold<int>(body.length, (min, i) => i < min ? i : min);
      final creditIndex = _creditKeywords
          .map((kw) => upperBody.indexOf(kw.toUpperCase()))
          .where((i) => i >= 0)
          .fold<int>(body.length, (min, i) => i < min ? i : min);
      type = debitIndex < creditIndex
          ? TransactionType.debit
          : TransactionType.credit;
    } else if (hasCreditCard) {
      // Credit card message without other keywords - assume debit (spend)
      type = TransactionType.debit;
    } else {
      return null; // No transaction keywords
    }

    // Extract account number
    String? accountNumber;
    final accountMatch = _accountRegex.firstMatch(body);
    if (accountMatch != null) {
      accountNumber = accountMatch.group(1);
      // Keep only last 4 digits
      if (accountNumber != null && accountNumber.length > 4) {
        accountNumber = accountNumber.substring(accountNumber.length - 4);
      }
    }

    // Extract merchant
    String? merchant;
    for (final pattern in _merchantPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        merchant = match.group(1)?.trim();
        // Clean up merchant name
        if (merchant != null) {
          merchant = _cleanMerchantName(merchant);
        }
        break;
      }
    }

    // Extract balance (optional)
    double? balance;
    final balanceMatch = _balanceRegex.firstMatch(body);
    if (balanceMatch != null) {
      final balanceStr = balanceMatch.group(1)!.replaceAll(',', '');
      balance = double.tryParse(balanceStr);
    }

    // Calculate confidence based on what we could extract
    double confidence = 0.5; // Base confidence
    if (accountNumber != null) confidence += 0.2;
    if (merchant != null) confidence += 0.2;
    if (balance != null) confidence += 0.1;

    return ParsedTransaction(
      type: type,
      amount: amount,
      merchant: merchant,
      accountNumber: accountNumber,
      balance: balance,
      date: date,
      rawMessage: body,
      senderId: senderId,
      smsId: smsId,
      confidence: confidence.clamp(0.0, 1.0),
    );
  }

  /// Clean up extracted merchant name
  String _cleanMerchantName(String name) {
    // Remove common suffixes
    name = name
        .replaceAll(RegExp(r'\s+ON\s*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+VIA\s*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+REF\s*$', caseSensitive: false), '')
        .trim();

    // Title case for readability
    if (name.toUpperCase() == name) {
      name = name.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }

    return name;
  }
}
