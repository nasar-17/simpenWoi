bool containsKeyword(String input, String keyword) {
  final String pattern = r'(^|[^a-z])' + RegExp.escape(keyword) + r'([^a-z]|$)';
  return RegExp(pattern).hasMatch(input);
}
