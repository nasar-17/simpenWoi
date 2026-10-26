String normalizeAssistantName(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp('\\s+'), ' ');
}

bool areSimilarNames(String left, String right) {
  if (left.isEmpty || right.isEmpty) {
    return false;
  }
  if (left == right) {
    return true;
  }
  if (left.length >= 4 &&
      right.length >= 4 &&
      (left.contains(right) || right.contains(left))) {
    return true;
  }
  final int tolerance = left.length >= 8 && right.length >= 8 ? 2 : 1;
  if (left.length < 5 || right.length < 5) {
    return false;
  }
  return editDistance(left, right) <= tolerance;
}

int editDistance(String left, String right) {
  final List<int> previous = List<int>.generate(right.length + 1, (int i) => i);
  final List<int> current = List<int>.filled(right.length + 1, 0);
  for (int i = 0; i < left.length; i++) {
    current[0] = i + 1;
    for (int j = 0; j < right.length; j++) {
      final int cost = left.codeUnitAt(i) == right.codeUnitAt(j) ? 0 : 1;
      current[j + 1] = _min(
        current[j] + 1,
        previous[j + 1] + 1,
        previous[j] + cost,
      );
    }
    previous.setAll(0, current);
  }
  return previous[right.length];
}

int _min(int a, int b, int c) {
  if (a < b) {
    return a < c ? a : c;
  }
  return b < c ? b : c;
}
