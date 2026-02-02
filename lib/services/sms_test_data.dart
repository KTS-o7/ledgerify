/// Test SMS data for verifying the SMS parsing feature.
///
/// Use this to test parsing logic on emulators or devices without bank SMS.
class SmsTestData {
  /// Sample Indian bank SMS messages for testing
  static const List<Map<String, dynamic>> sampleMessages = [
    // HDFC Bank - Debit
    {
      'id': 'test_001',
      'address': 'HD-HDFCBK',
      'body':
          'Rs.1,250.00 debited from A/c XX4521 on 15-01-24. Info: UPI-SWIGGY-merchant@paytm. Avl Bal: Rs.45,230.50',
      'date': -1, // Will be set to recent date
    },
    // ICICI Bank - Debit
    {
      'id': 'test_002',
      'address': 'VM-ICICIB',
      'body':
          'INR 3,500.00 spent on your ICICI Bank Card XX7834 on 20-Jan-24 at AMAZON INDIA. Avl Bal: INR 1,25,000.00',
      'date': -2,
    },
    // SBI - Credit (Salary)
    {
      'id': 'test_003',
      'address': 'BZ-SBIINB',
      'body':
          'Rs.75,000.00 credited to your A/c XX9876 on 01-Jan-24. Ref: NEFT-SALARY-JAN24. Avl Bal: Rs.1,45,230.00',
      'date': -5,
    },
    // Axis Bank - Debit (UPI)
    {
      'id': 'test_004',
      'address': 'AX-AXISBK',
      'body':
          'Amt Sent Rs.450.00 From Axis Bank A/C *4521 To gpay-zomato@okaxis On 18-01. Ref No 401234567890',
      'date': -3,
    },
    // Kotak - Debit
    {
      'id': 'test_005',
      'address': 'VM-KOTAKB',
      'body':
          'Rs 2,999.00 debited from Kotak Bank A/c XX1234 for purchase at NETFLIX.COM on 10-Jan-24. Balance: Rs 34,567.89',
      'date': -10,
    },
    // HDFC - Credit (Refund)
    {
      'id': 'test_006',
      'address': 'HD-HDFCBK',
      'body':
          'Rs.599.00 credited to A/c XX4521 on 12-01-24. Info: REFUND-AMAZON. Avl Bal: Rs.45,829.50',
      'date': -8,
    },
    // Paytm Wallet
    {
      'id': 'test_007',
      'address': 'VM-PAYTMB',
      'body':
          'Rs.150 paid to UBER INDIA at Delhi on 19-Jan-24. Paytm Wallet Bal: Rs.2,340',
      'date': -1,
    },
    // IDFC First Bank
    {
      'id': 'test_008',
      'address': 'VM-IDFCFB',
      'body':
          'INR 1,750.00 spent on your IDFC FIRST Bank Credit Card ending XX4521 at FLIPKART on 15 Jan 2024 at 02:30 PM',
      'date': -5,
    },
    // Federal Bank - UPI
    {
      'id': 'test_009',
      'address': 'FD-FEDBK',
      'body':
          'Rs 500.00 debited via UPI on 16-01-2024 14:30:45 to VPA bigbasket@upi. Ref No 401234567891',
      'date': -4,
    },
    // Google Pay
    {
      'id': 'test_010',
      'address': 'BT-GPAY',
      'body':
          'Paid Rs.320 to STARBUCKS INDIA using Google Pay. UPI Ref: 401234567892',
      'date': -2,
    },
    // AMEX Credit Card
    {
      'id': 'test_011',
      'address': 'AX-AMEXIN',
      'body':
          'Alert: You\'ve spent INR 5,000.00 on your AMEX card **1234 at MAKEMYTRIP on 15 January 2024 at 02:30 PM',
      'date': -7,
    },
    // PhonePe
    {
      'id': 'test_012',
      'address': 'VM-PHONEPE',
      'body':
          'Rs.89 paid to DOMINOS PIZZA via PhonePe. Txn ID: PPE401234567893',
      'date': -1,
    },
    // Real SMS samples from user (with realistic sender IDs including -S suffix)
    // SBI - Credit (NEFT Salary)
    {
      'id': 'test_013',
      'address': 'AD-SBIPSG-S',
      'body':
          'Dear Customer, INR 25,000.00 credited to your A/c No XX2062 on 02/02/2026 through NEFT with UTR HDFCH00773476458 by LATSPACE TECHNOLOGIES PRIVATE LIMIT, INFO: BATCHID:0025 0001 SALARY JAN 26',
      'date': 0, // Today
    },
    // SBI - Debit (UPI Transfer)
    {
      'id': 'test_014',
      'address': 'AD-SBIINB-S',
      'body':
          'SBI Your A/C XXXXX712062 Debited INR 12,500.00 on 01/02/26 -Transferred to Master KRISHNA TEJAS. Avl Balance INR 19,850.91-SBI',
      'date': -1,
    },
    // Slice Credit Card
    {
      'id': 'test_015',
      'address': 'VM-SLICE-S',
      'body':
          'Your slice credit card transaction of Rs. 110 on Upahara darshini is successful. If not you, call 08048329999 - slice',
      'date': 0, // Today
    },
  ];

  /// Get test messages with proper dates (relative to today)
  static List<Map<String, dynamic>> getTestMessages() {
    final now = DateTime.now();
    return sampleMessages.map((msg) {
      final daysAgo = (msg['date'] as int).abs();
      final date = now.subtract(Duration(days: daysAgo));
      return {
        ...msg,
        'date': date,
      };
    }).toList();
  }

  /// Get a specific number of test messages
  static List<Map<String, dynamic>> getTestMessagesLimited(int count) {
    final messages = getTestMessages();
    return messages.take(count).toList();
  }
}
