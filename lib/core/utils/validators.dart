class Validators {
  static String? required(String? value, [String message = 'This field is required']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (cleanPhone.length < 10) {
      return 'Please enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? number(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (num.tryParse(value.replaceAll(',', '')) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }
}
