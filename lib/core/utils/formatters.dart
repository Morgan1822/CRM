import 'package:intl/intl.dart';

class Formatters {
  static String currency(num amount, {String symbol = '₹'}) {
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: symbol,
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  static String date(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  static String time(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('h:mm a').format(dateTime);
  }

  static String relativeDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes <= 1) return 'Just now';
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('dd MMM').format(dateTime);
    }
  }

  static String initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Format Indian phone number for display (e.g., +91 98765 43210)
  static String formatIndianPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+91 ${digits.substring(2, 7)} ${digits.substring(7)}';
    }
    return phone;
  }

  /// Get standard dialable URI string for phone call / SMS (+91...)
  static String dialablePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '';
    var clean = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!clean.startsWith('+')) {
      if (clean.length == 10) {
        clean = '+91$clean';
      } else if (clean.length == 12 && clean.startsWith('91')) {
        clean = '+$clean';
      }
    }
    return clean;
  }
}
