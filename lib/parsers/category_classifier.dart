import '../models/expense.dart';

/// Classifies merchants into expense categories.
///
/// Uses keyword matching to suggest appropriate categories
/// based on merchant names extracted from SMS.
class CategoryClassifier {
  /// Map of keywords to categories
  static const _merchantKeywords = <ExpenseCategory, List<String>>{
    ExpenseCategory.food: [
      'swiggy',
      'zomato',
      'dominos',
      'pizza',
      'mcdonalds',
      'kfc',
      'burger',
      'restaurant',
      'cafe',
      'coffee',
      'starbucks',
      'dunkin',
      'food',
      'kitchen',
      'biryani',
      'dine',
      'eat',
      'meal',
      'subway',
      'wendys',
      'taco',
      'noodles',
      'sushi',
    ],
    ExpenseCategory.transport: [
      'uber',
      'ola',
      'rapido',
      'metro',
      'irctc',
      'railway',
      'petrol',
      'fuel',
      'diesel',
      'parking',
      'toll',
      'redbus',
      'bus',
      'cab',
      'taxi',
      'auto',
      'makemytrip',
      'goibibo',
      'cleartrip',
      'yatra',
    ],
    ExpenseCategory.shopping: [
      'amazon',
      'flipkart',
      'myntra',
      'ajio',
      'nykaa',
      'meesho',
      'snapdeal',
      'shopclues',
      'tatacliq',
      'bigbasket',
      'grofers',
      'blinkit',
      'zepto',
      'instamart',
      'dmart',
      'reliance',
      'mall',
      'store',
      'mart',
      'bazaar',
    ],
    ExpenseCategory.entertainment: [
      'netflix',
      'spotify',
      'amazon prime',
      'hotstar',
      'disney',
      'bookmyshow',
      'pvr',
      'inox',
      'cinema',
      'movie',
      'theatre',
      'game',
      'play',
      'xbox',
      'playstation',
      'steam',
      'youtube',
      'zee5',
      'sonyliv',
      'jiocinema',
    ],
    ExpenseCategory.bills: [
      'airtel',
      'jio',
      'vodafone',
      'vi',
      'bsnl',
      'electricity',
      'power',
      'tata power',
      'adani',
      'gas',
      'water',
      'broadband',
      'internet',
      'wifi',
      'insurance',
      'lic',
      'hdfc life',
      'icici prudential',
      'rent',
      'maintenance',
      'society',
    ],
    ExpenseCategory.health: [
      'pharmacy',
      'medical',
      'medicine',
      'apollo',
      'medplus',
      'netmeds',
      'pharmeasy',
      '1mg',
      'tata 1mg',
      'hospital',
      'clinic',
      'doctor',
      'diagnostic',
      'lab',
      'gym',
      'fitness',
      'cult',
      'healthify',
    ],
    ExpenseCategory.education: [
      'school',
      'college',
      'university',
      'tuition',
      'udemy',
      'coursera',
      'unacademy',
      'byju',
      'book',
      'stationery',
      'exam',
      'test',
      'linkedin learning',
      'skillshare',
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
