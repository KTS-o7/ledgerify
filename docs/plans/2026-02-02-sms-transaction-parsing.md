# SMS Transaction Parsing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Automatically detect and parse bank transaction SMS messages to populate income and expenses in Ledgerify.

**Architecture:** Regex-based parsing with a strategy pattern for bank-specific parsers. SMS transactions are stored separately and require user confirmation before becoming expenses/incomes. The feature is opt-in via Settings.

**Tech Stack:** `flutter_sms_inbox` for SMS reading, `permission_handler` for permissions, Hive for storage, existing ExpenseService/IncomeService for final storage.

---

## Phase 1: Core Infrastructure

### Task 1: Add Required Dependencies

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add SMS and permission packages**

Add to `dependencies` section in `pubspec.yaml`:

```yaml
  # SMS Reading
  flutter_sms_inbox: ^1.0.4
  
  # Permissions
  permission_handler: ^11.3.1
```

**Step 2: Run pub get**

Run: `flutter pub get`
Expected: Dependencies resolve successfully

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: add SMS reading and permission dependencies"
```

---

### Task 2: Configure Android Permissions

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

**Step 1: Add SMS permissions**

Add inside `<manifest>` tag, before `<application>`:

```xml
    <!-- SMS Reading for transaction parsing -->
    <uses-permission android:name="android.permission.READ_SMS"/>
    <uses-permission android:name="android.permission.RECEIVE_SMS"/>
```

**Step 2: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "feat: add SMS read permissions to Android manifest"
```

---

### Task 3: Create ParsedTransaction Model

**Files:**
- Create: `lib/models/parsed_transaction.dart`

**Step 1: Create the model file**

```dart
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
  debit,  // Expense
  credit, // Income
}
```

**Step 2: Commit**

```bash
git add lib/models/parsed_transaction.dart
git commit -m "feat: add ParsedTransaction model for SMS parsing"
```

---

### Task 4: Create SmsTransaction Hive Model

**Files:**
- Create: `lib/models/sms_transaction.dart`

**Step 1: Create the Hive model**

```dart
import 'package:hive/hive.dart';

part 'sms_transaction.g.dart';

/// Status of an SMS transaction
@HiveType(typeId: 16)
enum SmsTransactionStatus {
  @HiveField(0)
  pending,    // Awaiting user review
  
  @HiveField(1)
  confirmed,  // User confirmed, linked to expense/income
  
  @HiveField(2)
  skipped,    // User chose to skip this transaction
  
  @HiveField(3)
  deleted,    // User deleted this transaction
}

/// Represents a transaction parsed from SMS, stored in Hive.
/// 
/// This is persisted to track which SMS have been processed and
/// to allow users to review pending transactions.
@HiveType(typeId: 15)
class SmsTransaction extends HiveObject {
  /// Unique SMS ID from the system (prevents duplicates)
  @HiveField(0)
  final String smsId;
  
  /// Original SMS body
  @HiveField(1)
  final String rawMessage;
  
  /// SMS sender ID (e.g., "HDFCBK")
  @HiveField(2)
  final String senderId;
  
  /// When the SMS was received
  @HiveField(3)
  final DateTime smsDate;
  
  /// Parsed amount
  @HiveField(4)
  final double amount;
  
  /// Transaction type: 'debit' or 'credit'
  @HiveField(5)
  final String transactionType;
  
  /// Parsed merchant name (if any)
  @HiveField(6)
  final String? merchant;
  
  /// Last 4 digits of account/card
  @HiveField(7)
  final String? accountNumber;
  
  /// Current status of this transaction
  @HiveField(8)
  SmsTransactionStatus status;
  
  /// Linked expense ID (if confirmed as expense)
  @HiveField(9)
  String? linkedExpenseId;
  
  /// Linked income ID (if confirmed as income)
  @HiveField(10)
  String? linkedIncomeId;
  
  /// When this record was created
  @HiveField(11)
  final DateTime createdAt;
  
  /// Parsing confidence score (0.0 - 1.0)
  @HiveField(12)
  final double confidence;
  
  SmsTransaction({
    required this.smsId,
    required this.rawMessage,
    required this.senderId,
    required this.smsDate,
    required this.amount,
    required this.transactionType,
    this.merchant,
    this.accountNumber,
    this.status = SmsTransactionStatus.pending,
    this.linkedExpenseId,
    this.linkedIncomeId,
    DateTime? createdAt,
    this.confidence = 1.0,
  }) : createdAt = createdAt ?? DateTime.now();
  
  /// Whether this is a debit (expense) transaction
  bool get isDebit => transactionType == 'debit';
  
  /// Whether this is a credit (income) transaction
  bool get isCredit => transactionType == 'credit';
  
  /// Whether this transaction is pending review
  bool get isPending => status == SmsTransactionStatus.pending;
  
  /// Whether this transaction has been processed (confirmed/skipped/deleted)
  bool get isProcessed => status != SmsTransactionStatus.pending;
}
```

**Step 2: Commit**

```bash
git add lib/models/sms_transaction.dart
git commit -m "feat: add SmsTransaction Hive model"
```

---

### Task 5: Generate Hive Adapters

**Files:**
- Generate: `lib/models/sms_transaction.g.dart`

**Step 1: Run build_runner**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: Successfully generates `sms_transaction.g.dart`

**Step 2: Verify generated file exists**

Run: `ls lib/models/sms_transaction.g.dart`
Expected: File exists

**Step 3: Commit**

```bash
git add lib/models/sms_transaction.g.dart
git commit -m "chore: generate Hive adapters for SmsTransaction"
```

---

### Task 6: Create SmsPermissionService

**Files:**
- Create: `lib/services/sms_permission_service.dart`

**Step 1: Create the permission service**

```dart
import 'package:permission_handler/permission_handler.dart';

/// Service for handling SMS permission requests.
/// 
/// Encapsulates permission logic and provides clear status reporting.
class SmsPermissionService {
  /// Check if SMS permission is currently granted
  Future<bool> isGranted() async {
    final status = await Permission.sms.status;
    return status.isGranted;
  }
  
  /// Check if SMS permission is permanently denied
  Future<bool> isPermanentlyDenied() async {
    final status = await Permission.sms.status;
    return status.isPermanentlyDenied;
  }
  
  /// Request SMS permission from user
  /// 
  /// Returns true if permission was granted, false otherwise.
  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }
  
  /// Open app settings (for when permission is permanently denied)
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
  
  /// Get detailed permission status
  Future<SmsPermissionStatus> getStatus() async {
    final status = await Permission.sms.status;
    
    if (status.isGranted) {
      return SmsPermissionStatus.granted;
    } else if (status.isPermanentlyDenied) {
      return SmsPermissionStatus.permanentlyDenied;
    } else if (status.isDenied) {
      return SmsPermissionStatus.denied;
    } else if (status.isRestricted) {
      return SmsPermissionStatus.restricted;
    }
    
    return SmsPermissionStatus.denied;
  }
}

/// SMS permission status enum for UI consumption
enum SmsPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}
```

**Step 2: Commit**

```bash
git add lib/services/sms_permission_service.dart
git commit -m "feat: add SmsPermissionService for handling SMS permissions"
```

---

## Phase 2: Parsing Engine

### Task 7: Create TransactionParser Interface

**Files:**
- Create: `lib/parsers/transaction_parser.dart`

**Step 1: Create the parser interface**

```dart
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
```

**Step 2: Commit**

```bash
git add lib/parsers/transaction_parser.dart
git commit -m "feat: add TransactionParser interface"
```

---

### Task 8: Create GenericIndianBankParser

**Files:**
- Create: `lib/parsers/generic_indian_bank_parser.dart`

**Step 1: Create the generic parser**

```dart
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
  static const _bankSenderPatterns = [
    'HDFC', 'ICICI', 'SBI', 'AXIS', 'KOTAK', 'IDFC', 'INDUS',
    'YES', 'PNB', 'BOB', 'CANARA', 'UNION', 'FEDERAL', 'RBL',
    'AMEX', 'CITI', 'HSBC', 'SCB', 'DBS', 'ONECARD',
    'PAYTM', 'GPAY', 'PHONEPE', 'AMAZONPAY', 'MOBIKWIK',
  ];
  
  /// Keywords indicating a debit transaction
  static const _debitKeywords = [
    'debited', 'debit', 'spent', 'paid', 'payment',
    'deducted', 'withdrawn', 'purchase', 'txn',
    'amt sent', 'transferred', 'bill payment',
  ];
  
  /// Keywords indicating a credit transaction
  static const _creditKeywords = [
    'credited', 'credit', 'received', 'deposited',
    'refund', 'cashback', 'reversed', 'amt received',
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
    RegExp(r'\bat\s+([A-Z][A-Z0-9\s\-\.]+?)(?:\s+on|\s+via|\s*$)', caseSensitive: false),
    // "to VPA merchant@upi"
    RegExp(r'to\s+(?:VPA\s+)?([a-zA-Z0-9\.\-]+@[a-zA-Z]+)', caseSensitive: false),
    // "to MERCHANT NAME"
    RegExp(r'\bto\s+([A-Z][A-Z0-9\s\-\.]+?)(?:\s+on|\s+ref|\s*$)', caseSensitive: false),
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
    final isDebit = _debitKeywords.any((kw) => upperBody.contains(kw.toUpperCase()));
    final isCredit = _creditKeywords.any((kw) => upperBody.contains(kw.toUpperCase()));
    
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
      type = debitIndex < creditIndex ? TransactionType.debit : TransactionType.credit;
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
```

**Step 2: Commit**

```bash
git add lib/parsers/generic_indian_bank_parser.dart
git commit -m "feat: add GenericIndianBankParser for SMS parsing"
```

---

### Task 9: Create CategoryClassifier

**Files:**
- Create: `lib/parsers/category_classifier.dart`

**Step 1: Create the classifier**

```dart
import '../models/expense.dart';

/// Classifies merchants into expense categories.
/// 
/// Uses keyword matching to suggest appropriate categories
/// based on merchant names extracted from SMS.
class CategoryClassifier {
  /// Map of keywords to categories
  static const _merchantKeywords = <ExpenseCategory, List<String>>{
    ExpenseCategory.food: [
      'swiggy', 'zomato', 'dominos', 'pizza', 'mcdonalds', 'kfc',
      'burger', 'restaurant', 'cafe', 'coffee', 'starbucks', 'dunkin',
      'food', 'kitchen', 'biryani', 'dine', 'eat', 'meal',
      'subway', 'wendys', 'taco', 'noodles', 'sushi',
    ],
    ExpenseCategory.transport: [
      'uber', 'ola', 'rapido', 'metro', 'irctc', 'railway',
      'petrol', 'fuel', 'diesel', 'parking', 'toll',
      'redbus', 'bus', 'cab', 'taxi', 'auto',
      'makemytrip', 'goibibo', 'cleartrip', 'yatra',
    ],
    ExpenseCategory.shopping: [
      'amazon', 'flipkart', 'myntra', 'ajio', 'nykaa',
      'meesho', 'snapdeal', 'shopclues', 'tatacliq',
      'bigbasket', 'grofers', 'blinkit', 'zepto', 'instamart',
      'dmart', 'reliance', 'mall', 'store', 'mart', 'bazaar',
    ],
    ExpenseCategory.entertainment: [
      'netflix', 'spotify', 'amazon prime', 'hotstar', 'disney',
      'bookmyshow', 'pvr', 'inox', 'cinema', 'movie', 'theatre',
      'game', 'play', 'xbox', 'playstation', 'steam',
      'youtube', 'zee5', 'sonyliv', 'jiocinema',
    ],
    ExpenseCategory.bills: [
      'airtel', 'jio', 'vodafone', 'vi', 'bsnl',
      'electricity', 'power', 'tata power', 'adani',
      'gas', 'water', 'broadband', 'internet', 'wifi',
      'insurance', 'lic', 'hdfc life', 'icici prudential',
      'rent', 'maintenance', 'society',
    ],
    ExpenseCategory.health: [
      'pharmacy', 'medical', 'medicine', 'apollo', 'medplus',
      'netmeds', 'pharmeasy', '1mg', 'tata 1mg',
      'hospital', 'clinic', 'doctor', 'diagnostic', 'lab',
      'gym', 'fitness', 'cult', 'healthify',
    ],
    ExpenseCategory.education: [
      'school', 'college', 'university', 'tuition',
      'udemy', 'coursera', 'unacademy', 'byju',
      'book', 'stationery', 'exam', 'test',
      'linkedin learning', 'skillshare',
    ],
  };
  
  /// Classify a merchant name into a category.
  /// 
  /// Returns the best matching category, or [ExpenseCategory.other]
  /// if no match is found.
  static ExpenseCategory classify(String? merchant) {
    if (merchant == null || merchant.isEmpty) {
      return ExpenseCategory.other;
    }
    
    final lowerMerchant = merchant.toLowerCase();
    
    // Check each category's keywords
    for (final entry in _merchantKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerMerchant.contains(keyword)) {
          return entry.key;
        }
      }
    }
    
    return ExpenseCategory.other;
  }
  
  /// Get confidence score for a classification.
  /// 
  /// Returns 1.0 for exact matches, lower for partial matches.
  static double getConfidence(String? merchant, ExpenseCategory category) {
    if (merchant == null || merchant.isEmpty) return 0.0;
    if (category == ExpenseCategory.other) return 0.3;
    
    final lowerMerchant = merchant.toLowerCase();
    final keywords = _merchantKeywords[category] ?? [];
    
    // Check for exact match (keyword is the full merchant name)
    for (final keyword in keywords) {
      if (lowerMerchant == keyword) return 1.0;
    }
    
    // Check for keyword at start of merchant name
    for (final keyword in keywords) {
      if (lowerMerchant.startsWith(keyword)) return 0.9;
    }
    
    // Check for keyword anywhere in merchant name
    for (final keyword in keywords) {
      if (lowerMerchant.contains(keyword)) return 0.7;
    }
    
    return 0.3;
  }
}
```

**Step 2: Commit**

```bash
git add lib/parsers/category_classifier.dart
git commit -m "feat: add CategoryClassifier for merchant categorization"
```

---

### Task 10: Create TransactionParsingService

**Files:**
- Create: `lib/services/transaction_parsing_service.dart`

**Step 1: Create the parsing service**

```dart
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
    return senderId
        .replaceAll(RegExp(r'^[A-Z]{2}-'), '')
        .toUpperCase();
  }
  
  /// Get list of registered parser names (for debugging/UI)
  List<String> get registeredParsers => _parsers.map((p) => p.name).toList();
}
```

**Step 2: Commit**

```bash
git add lib/services/transaction_parsing_service.dart
git commit -m "feat: add TransactionParsingService for orchestrating SMS parsing"
```

---

## Phase 3: SMS Service & Storage

### Task 11: Create SmsService

**Files:**
- Create: `lib/services/sms_service.dart`

**Step 1: Create the SMS reading service**

```dart
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
```

**Step 2: Commit**

```bash
git add lib/services/sms_service.dart
git commit -m "feat: add SmsService for reading and parsing SMS"
```

---

### Task 12: Create SmsTransactionService

**Files:**
- Create: `lib/services/sms_transaction_service.dart`

**Step 1: Create the service**

```dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/parsed_transaction.dart';
import '../models/sms_transaction.dart';
import '../parsers/category_classifier.dart';
import 'expense_service.dart';
import 'income_service.dart';
import 'sms_service.dart';

/// Service for managing SMS transactions.
/// 
/// Handles importing SMS, storing parsed transactions,
/// and converting confirmed transactions to expenses/incomes.
class SmsTransactionService {
  static const String _boxName = 'sms_transactions';
  
  late Box<SmsTransaction> _box;
  final SmsService _smsService;
  final ExpenseService _expenseService;
  final IncomeService _incomeService;
  
  SmsTransactionService({
    required SmsService smsService,
    required ExpenseService expenseService,
    required IncomeService incomeService,
  })  : _smsService = smsService,
        _expenseService = expenseService,
        _incomeService = incomeService;
  
  /// Initialize the service and open Hive box
  Future<void> init() async {
    _box = await Hive.openBox<SmsTransaction>(
      _boxName,
      compactionStrategy: (entries, deletedEntries) =>
          deletedEntries > entries * 0.2,
    );
  }
  
  /// Import new SMS transactions from inbox.
  /// 
  /// [since] - Only import messages after this date
  /// [limit] - Maximum number of messages to scan
  /// 
  /// Returns list of newly imported transactions.
  Future<List<SmsTransaction>> importFromInbox({
    DateTime? since,
    int limit = 500,
  }) async {
    // Get parsed transactions from SMS
    final parsed = await _smsService.readAndParseBankSms(
      count: limit,
      since: since,
    );
    
    final imported = <SmsTransaction>[];
    
    for (final transaction in parsed) {
      // Skip if already processed
      if (_isAlreadyProcessed(transaction.smsId)) continue;
      
      // Create SmsTransaction record
      final smsTransaction = SmsTransaction(
        smsId: transaction.smsId,
        rawMessage: transaction.rawMessage,
        senderId: transaction.senderId,
        smsDate: transaction.date,
        amount: transaction.amount,
        transactionType: transaction.type == TransactionType.debit ? 'debit' : 'credit',
        merchant: transaction.merchant,
        accountNumber: transaction.accountNumber,
        confidence: transaction.confidence,
      );
      
      // Save to box
      await _box.put(smsTransaction.smsId, smsTransaction);
      imported.add(smsTransaction);
    }
    
    return imported;
  }
  
  /// Check if an SMS has already been processed
  bool _isAlreadyProcessed(String smsId) {
    return _box.containsKey(smsId);
  }
  
  /// Get all pending transactions (awaiting user review)
  List<SmsTransaction> getPendingTransactions() {
    return _box.values
        .where((t) => t.status == SmsTransactionStatus.pending)
        .toList()
      ..sort((a, b) => b.smsDate.compareTo(a.smsDate));
  }
  
  /// Get pending debit transactions (expenses)
  List<SmsTransaction> getPendingExpenses() {
    return getPendingTransactions().where((t) => t.isDebit).toList();
  }
  
  /// Get pending credit transactions (incomes)
  List<SmsTransaction> getPendingIncomes() {
    return getPendingTransactions().where((t) => t.isCredit).toList();
  }
  
  /// Get count of pending transactions
  int get pendingCount => getPendingTransactions().length;
  
  /// Confirm a transaction as an expense.
  /// 
  /// [transaction] - The SMS transaction to confirm
  /// [category] - Category to assign (auto-classified if null)
  /// [note] - Optional note to add
  /// 
  /// Returns the created Expense.
  Future<Expense> confirmAsExpense(
    SmsTransaction transaction, {
    ExpenseCategory? category,
    String? note,
  }) async {
    // Auto-classify if category not provided
    final finalCategory = category ?? CategoryClassifier.classify(transaction.merchant);
    
    // Create expense
    final expense = await _expenseService.addExpense(
      amount: transaction.amount,
      category: finalCategory,
      date: transaction.smsDate,
      note: note ?? transaction.merchant,
      source: ExpenseSource.sms,
      merchant: transaction.merchant,
    );
    
    // Update transaction status
    transaction.status = SmsTransactionStatus.confirmed;
    transaction.linkedExpenseId = expense.id;
    await transaction.save();
    
    return expense;
  }
  
  /// Confirm a transaction as income.
  /// 
  /// [transaction] - The SMS transaction to confirm
  /// [source] - Income source to assign
  /// [note] - Optional note to add
  /// 
  /// Returns the created Income.
  Future<Income> confirmAsIncome(
    SmsTransaction transaction, {
    IncomeSource source = IncomeSource.other,
    String? note,
  }) async {
    // Create income
    final income = await _incomeService.addIncome(
      amount: transaction.amount,
      source: source,
      date: transaction.smsDate,
      note: note ?? transaction.merchant ?? 'SMS Import',
    );
    
    // Update transaction status
    transaction.status = SmsTransactionStatus.confirmed;
    transaction.linkedIncomeId = income.id;
    await transaction.save();
    
    return income;
  }
  
  /// Skip a transaction (mark as skipped, won't show in pending)
  Future<void> skipTransaction(SmsTransaction transaction) async {
    transaction.status = SmsTransactionStatus.skipped;
    await transaction.save();
  }
  
  /// Delete a transaction record
  Future<void> deleteTransaction(SmsTransaction transaction) async {
    transaction.status = SmsTransactionStatus.deleted;
    await transaction.save();
  }
  
  /// Confirm multiple transactions as expenses (batch operation)
  Future<List<Expense>> confirmMultipleAsExpenses(
    List<SmsTransaction> transactions,
  ) async {
    final expenses = <Expense>[];
    
    for (final transaction in transactions) {
      if (transaction.isDebit && transaction.isPending) {
        final expense = await confirmAsExpense(transaction);
        expenses.add(expense);
      }
    }
    
    return expenses;
  }
  
  /// Skip multiple transactions (batch operation)
  Future<void> skipMultiple(List<SmsTransaction> transactions) async {
    for (final transaction in transactions) {
      if (transaction.isPending) {
        await skipTransaction(transaction);
      }
    }
  }
  
  /// Get the date of the last imported SMS
  DateTime? getLastImportDate() {
    if (_box.isEmpty) return null;
    
    DateTime? latest;
    for (final transaction in _box.values) {
      if (latest == null || transaction.smsDate.isAfter(latest)) {
        latest = transaction.smsDate;
      }
    }
    return latest;
  }
  
  /// Get the Hive box for UI listening
  Box<SmsTransaction> get box => _box;
  
  /// Get total count of all transactions
  int get totalCount => _box.length;
  
  /// Get count of confirmed transactions
  int get confirmedCount => _box.values
      .where((t) => t.status == SmsTransactionStatus.confirmed)
      .length;
}
```

**Step 2: Commit**

```bash
git add lib/services/sms_transaction_service.dart
git commit -m "feat: add SmsTransactionService for managing SMS transactions"
```

---

## Phase 4: Register Services in main.dart

### Task 13: Register Hive Adapters

**Files:**
- Modify: `lib/main.dart`

**Step 1: Add imports at top of file**

After the existing imports around line 10, add:

```dart
import 'models/sms_transaction.dart';
```

**Step 2: Register Hive adapters**

After line 71 (after `MerchantHistoryAdapter` registration), add:

```dart
  if (!Hive.isAdapterRegistered(15)) {
    Hive.registerAdapter(SmsTransactionAdapter());
  }
  if (!Hive.isAdapterRegistered(16)) {
    Hive.registerAdapter(SmsTransactionStatusAdapter());
  }
```

**Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: register SmsTransaction Hive adapters in main.dart"
```

---

### Task 14: Initialize SMS Services

**Files:**
- Modify: `lib/main.dart`

**Step 1: Add service imports**

Add these imports after the existing service imports (around line 20):

```dart
import 'services/sms_permission_service.dart';
import 'services/sms_service.dart';
import 'services/sms_transaction_service.dart';
import 'services/transaction_parsing_service.dart';
```

**Step 2: Create service instances**

After line 79 (after `merchantHistoryService` creation), add:

```dart
  final smsPermissionService = SmsPermissionService();
  final transactionParsingService = TransactionParsingService();
  final smsService = SmsService(
    permissionService: smsPermissionService,
    parsingService: transactionParsingService,
  );
```

**Step 3: Initialize SmsTransactionService**

The SmsTransactionService needs expenseService and incomeService, so add after incomeService is created (around line 116):

```dart
  final smsTransactionService = SmsTransactionService(
    smsService: smsService,
    expenseService: expenseService,
    incomeService: incomeService,
  );
  await smsTransactionService.init();
```

**Step 4: Pass services to LedgerifyApp**

Add to the LedgerifyApp constructor call (around line 127):

```dart
    smsPermissionService: smsPermissionService,
    smsTransactionService: smsTransactionService,
```

**Step 5: Update LedgerifyApp class**

Add fields and constructor parameters to LedgerifyApp class:

```dart
  final SmsPermissionService smsPermissionService;
  final SmsTransactionService smsTransactionService;
```

**Step 6: Update MainShell call**

Pass the services to MainShell:

```dart
            smsPermissionService: smsPermissionService,
            smsTransactionService: smsTransactionService,
```

**Step 7: Commit**

```bash
git add lib/main.dart
git commit -m "feat: initialize SMS services in main.dart"
```

---

## Phase 5: UI - Settings Toggle

### Task 15: Add SMS Import Toggle to Settings

**Files:**
- Modify: `lib/screens/settings_screen.dart`

**Step 1: Add imports**

Add at top of file:

```dart
import '../services/sms_permission_service.dart';
import '../services/sms_transaction_service.dart';
```

**Step 2: Add service parameters to SettingsScreen**

Add to class fields:

```dart
  final SmsPermissionService smsPermissionService;
  final SmsTransactionService smsTransactionService;
```

Update constructor:

```dart
  const SettingsScreen({
    super.key,
    required this.themeService,
    required this.tagService,
    required this.customCategoryService,
    required this.notificationService,
    required this.notificationPrefsService,
    required this.smsPermissionService,
    required this.smsTransactionService,
  });
```

**Step 3: Add SMS Import tile to Data section**

After the Tags tile (around line 103), add:

```dart
                Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 16,
                  color: colors.surfaceHighlight,
                ),
                _SmsImportTile(
                  colors: colors,
                  smsPermissionService: smsPermissionService,
                  smsTransactionService: smsTransactionService,
                ),
```

**Step 4: Create _SmsImportTile widget**

Add after _TagsTile class (around line 450):

```dart
/// SMS Import tile
class _SmsImportTile extends StatelessWidget {
  final LedgerifyColorScheme colors;
  final SmsPermissionService smsPermissionService;
  final SmsTransactionService smsTransactionService;

  const _SmsImportTile({
    required this.colors,
    required this.smsPermissionService,
    required this.smsTransactionService,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: LedgerifySpacing.lg,
        vertical: LedgerifySpacing.xs,
      ),
      leading: Icon(
        Icons.sms_rounded,
        color: colors.textSecondary,
      ),
      title: Text(
        'SMS Import',
        style: LedgerifyTypography.bodyLarge.copyWith(
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        'Import transactions from bank SMS',
        style: LedgerifyTypography.bodySmall.copyWith(
          color: colors.textTertiary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colors.textTertiary,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SmsImportScreen(
              smsPermissionService: smsPermissionService,
              smsTransactionService: smsTransactionService,
            ),
          ),
        );
      },
    );
  }
}
```

**Step 5: Commit (will fail until SmsImportScreen exists)**

```bash
git add lib/screens/settings_screen.dart
git commit -m "feat: add SMS Import tile to Settings screen"
```

---

## Phase 6: UI - Import Screen

### Task 16: Create SmsImportScreen

**Files:**
- Create: `lib/screens/sms_import_screen.dart`

**Step 1: Create the screen**

```dart
import 'package:flutter/material.dart';
import '../models/sms_transaction.dart';
import '../services/sms_permission_service.dart';
import '../services/sms_transaction_service.dart';
import '../theme/ledgerify_theme.dart';
import '../utils/currency_formatter.dart';

/// Screen for importing transactions from SMS.
/// 
/// Handles permission requests and displays import progress.
class SmsImportScreen extends StatefulWidget {
  final SmsPermissionService smsPermissionService;
  final SmsTransactionService smsTransactionService;

  const SmsImportScreen({
    super.key,
    required this.smsPermissionService,
    required this.smsTransactionService,
  });

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  bool _isLoading = false;
  bool _hasPermission = false;
  String? _errorMessage;
  List<SmsTransaction>? _importedTransactions;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await widget.smsPermissionService.isGranted();
    setState(() {
      _hasPermission = granted;
    });
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final status = await widget.smsPermissionService.getStatus();
    
    if (status == SmsPermissionStatus.permanentlyDenied) {
      // Need to open settings
      final opened = await widget.smsPermissionService.openSettings();
      if (!opened) {
        setState(() {
          _errorMessage = 'Could not open settings';
          _isLoading = false;
        });
      }
      return;
    }

    final granted = await widget.smsPermissionService.requestPermission();
    
    setState(() {
      _hasPermission = granted;
      _isLoading = false;
      if (!granted) {
        _errorMessage = 'SMS permission is required to import transactions';
      }
    });
  }

  Future<void> _startImport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _importedTransactions = null;
    });

    try {
      // Import from last 30 days
      final since = DateTime.now().subtract(const Duration(days: 30));
      final imported = await widget.smsTransactionService.importFromInbox(
        since: since,
        limit: 500,
      );

      setState(() {
        _importedTransactions = imported;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to import: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SMS Import',
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(LedgerifySpacing.lg),
        child: _buildContent(colors),
      ),
    );
  }

  Widget _buildContent(LedgerifyColorScheme colors) {
    if (_isLoading) {
      return _buildLoadingState(colors);
    }

    if (!_hasPermission) {
      return _buildPermissionRequest(colors);
    }

    if (_importedTransactions != null) {
      return _buildImportResults(colors);
    }

    return _buildReadyToImport(colors);
  }

  Widget _buildLoadingState(LedgerifyColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colors.accent,
            strokeWidth: 2,
          ),
          LedgerifySpacing.verticalLg,
          Text(
            'Scanning messages...',
            style: LedgerifyTypography.bodyLarge.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequest(LedgerifyColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: LedgerifySpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sms_rounded,
              size: 64,
              color: colors.textTertiary,
            ),
            LedgerifySpacing.verticalXl,
            Text(
              'SMS Permission Required',
              style: LedgerifyTypography.headlineSmall.copyWith(
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            LedgerifySpacing.verticalMd,
            Text(
              'Ledgerify needs access to your SMS to automatically detect and import bank transactions.',
              style: LedgerifyTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_errorMessage != null) ...[
              LedgerifySpacing.verticalMd,
              Text(
                _errorMessage!,
                style: LedgerifyTypography.bodySmall.copyWith(
                  color: colors.negative,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            LedgerifySpacing.verticalXl,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _requestPermission,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.background,
                  padding: const EdgeInsets.symmetric(vertical: LedgerifySpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: LedgerifyRadius.borderRadiusMd,
                  ),
                ),
                child: Text(
                  'Grant Permission',
                  style: LedgerifyTypography.labelLarge.copyWith(
                    color: colors.background,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyToImport(LedgerifyColorScheme colors) {
    final pendingCount = widget.smsTransactionService.pendingCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(LedgerifySpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: LedgerifyRadius.borderRadiusLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: colors.accent,
                    size: 20,
                  ),
                  LedgerifySpacing.horizontalSm,
                  Text(
                    'Permission Granted',
                    style: LedgerifyTypography.labelMedium.copyWith(
                      color: colors.accent,
                    ),
                  ),
                ],
              ),
              LedgerifySpacing.verticalMd,
              Text(
                'Ready to scan your SMS for bank transactions.',
                style: LedgerifyTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              if (pendingCount > 0) ...[
                LedgerifySpacing.verticalMd,
                Text(
                  '$pendingCount pending transactions to review',
                  style: LedgerifyTypography.bodySmall.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),

        LedgerifySpacing.verticalXl,

        // Import button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _startImport,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Import from SMS'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.background,
              padding: const EdgeInsets.symmetric(vertical: LedgerifySpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: LedgerifyRadius.borderRadiusMd,
              ),
            ),
          ),
        ),

        LedgerifySpacing.verticalMd,

        // Info text
        Text(
          'This will scan the last 30 days of SMS messages for bank transactions.',
          style: LedgerifyTypography.bodySmall.copyWith(
            color: colors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildImportResults(LedgerifyColorScheme colors) {
    final transactions = _importedTransactions!;
    final debitCount = transactions.where((t) => t.isDebit).length;
    final creditCount = transactions.where((t) => t.isCredit).length;
    final totalAmount = transactions
        .where((t) => t.isDebit)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(LedgerifySpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: LedgerifyRadius.borderRadiusLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: colors.accent,
                    size: 24,
                  ),
                  LedgerifySpacing.horizontalSm,
                  Text(
                    'Import Complete',
                    style: LedgerifyTypography.headlineSmall.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              LedgerifySpacing.verticalLg,
              _ResultRow(
                label: 'Transactions found',
                value: '${transactions.length}',
                colors: colors,
              ),
              LedgerifySpacing.verticalSm,
              _ResultRow(
                label: 'Expenses (debits)',
                value: '$debitCount',
                colors: colors,
              ),
              LedgerifySpacing.verticalSm,
              _ResultRow(
                label: 'Income (credits)',
                value: '$creditCount',
                colors: colors,
              ),
              LedgerifySpacing.verticalSm,
              _ResultRow(
                label: 'Total expense amount',
                value: CurrencyFormatter.format(totalAmount),
                colors: colors,
                isHighlighted: true,
              ),
            ],
          ),
        ),

        LedgerifySpacing.verticalXl,

        if (transactions.isNotEmpty) ...[
          Text(
            'Review your imported transactions to confirm or skip them.',
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          LedgerifySpacing.verticalLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                // TODO: Navigate to pending transactions screen
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.background,
                padding: const EdgeInsets.symmetric(vertical: LedgerifySpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                ),
              ),
              child: const Text('Review Transactions'),
            ),
          ),
        ],

        LedgerifySpacing.verticalMd,

        // Import more button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _startImport,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textSecondary,
              side: BorderSide(color: colors.surfaceHighlight),
              padding: const EdgeInsets.symmetric(vertical: LedgerifySpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: LedgerifyRadius.borderRadiusMd,
              ),
            ),
            child: const Text('Scan Again'),
          ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final LedgerifyColorScheme colors;
  final bool isHighlighted;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.colors,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: LedgerifyTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        Text(
          value,
          style: (isHighlighted
                  ? LedgerifyTypography.amountMedium
                  : LedgerifyTypography.bodyMedium)
              .copyWith(
            color: isHighlighted ? colors.textPrimary : colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
```

**Step 2: Add import to settings_screen.dart**

Add at top of `lib/screens/settings_screen.dart`:

```dart
import 'sms_import_screen.dart';
```

**Step 3: Commit**

```bash
git add lib/screens/sms_import_screen.dart lib/screens/settings_screen.dart
git commit -m "feat: add SmsImportScreen for importing SMS transactions"
```

---

## Phase 7: Wire Up MainShell

### Task 17: Update MainShell to Pass SMS Services

**Files:**
- Modify: `lib/screens/main_shell.dart`

**Step 1: Add imports**

Add at top of file:

```dart
import '../services/sms_permission_service.dart';
import '../services/sms_transaction_service.dart';
```

**Step 2: Add service fields to MainShell**

Add to class fields:

```dart
  final SmsPermissionService smsPermissionService;
  final SmsTransactionService smsTransactionService;
```

**Step 3: Update constructor**

Add required parameters:

```dart
  required this.smsPermissionService,
  required this.smsTransactionService,
```

**Step 4: Update SettingsScreen call**

Find where SettingsScreen is created and add:

```dart
            smsPermissionService: widget.smsPermissionService,
            smsTransactionService: widget.smsTransactionService,
```

**Step 5: Commit**

```bash
git add lib/screens/main_shell.dart
git commit -m "feat: pass SMS services through MainShell to Settings"
```

---

## Phase 8: Testing & Verification

### Task 18: Run Flutter Analyze

**Step 1: Run analyzer**

Run: `flutter analyze lib/`
Expected: No errors (warnings are acceptable)

**Step 2: Fix any errors**

If errors exist, fix them before proceeding.

**Step 3: Commit any fixes**

```bash
git add -A
git commit -m "fix: resolve analyzer issues"
```

---

### Task 19: Build Debug APK

**Step 1: Build**

Run: `flutter build apk --debug`
Expected: BUILD SUCCESSFUL

**Step 2: Commit**

```bash
git add -A
git commit -m "chore: verify debug build succeeds with SMS feature"
```

---

## Summary

This plan implements SMS transaction parsing in 19 tasks across 8 phases:

| Phase | Tasks | Description |
|-------|-------|-------------|
| 1 | 1-6 | Core infrastructure (dependencies, permissions, models) |
| 2 | 7-10 | Parsing engine (parser interface, generic parser, classifier) |
| 3 | 11-12 | SMS service & storage |
| 4 | 13-14 | Register services in main.dart |
| 5 | 15 | Settings toggle UI |
| 6 | 16 | Import screen UI |
| 7 | 17 | Wire up MainShell |
| 8 | 18-19 | Testing & verification |

**Future enhancements (not in this plan):**
- Pending transactions review screen
- Bank-specific parsers (HDFC, ICICI, SBI)
- Real-time SMS listener
- Background sync with WorkManager
- Notification for new detected transactions
