import 'package:intl/intl.dart';

class Formatters {
  static String currency(num amount, {String symbol = '\$'}) {
    final format = NumberFormat.currency(symbol: symbol, decimalDigits: 0);
    return format.format(amount);
  }

  static String date(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(dateTime);
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
      return DateFormat('MMM d').format(dateTime);
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
}
