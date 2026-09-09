extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String titleCase() {
    if (isEmpty) return this;
    return split(RegExp(r'[\s_]+'))
        .map((str) => str.capitalize())
        .join(' ');
  }
}
