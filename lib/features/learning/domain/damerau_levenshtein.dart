int damerauLevenshtein(String left, String right) {
  final int leftLength = left.length;
  final int rightLength = right.length;
  if (leftLength == 0) {
    return rightLength;
  }
  if (rightLength == 0) {
    return leftLength;
  }
  final List<List<int>> distance = List<List<int>>.generate(
    leftLength + 1,
    (int row) => List<int>.filled(rightLength + 1, 0),
  );
  for (int i = 0; i <= leftLength; i++) {
    distance[i][0] = i;
  }
  for (int j = 0; j <= rightLength; j++) {
    distance[0][j] = j;
  }
  for (int i = 1; i <= leftLength; i++) {
    for (int j = 1; j <= rightLength; j++) {
      final int cost = left.codeUnitAt(i - 1) == right.codeUnitAt(j - 1)
          ? 0
          : 1;
      int best = _min(
        distance[i - 1][j] + 1,
        distance[i][j - 1] + 1,
        distance[i - 1][j - 1] + cost,
      );
      if (i > 1 &&
          j > 1 &&
          left.codeUnitAt(i - 1) == right.codeUnitAt(j - 2) &&
          left.codeUnitAt(i - 2) == right.codeUnitAt(j - 1)) {
        best = _min(best, distance[i - 2][j - 2] + 1, best);
      }
      distance[i][j] = best;
    }
  }
  return distance[leftLength][rightLength];
}

int _min(int a, int b, int c) {
  if (a < b) {
    return a < c ? a : c;
  }
  return b < c ? b : c;
}
