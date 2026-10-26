class LearningStats {
  const LearningStats({
    required this.words,
    required this.corrections7d,
    required this.guesses7d,
    required this.correctFirstGuess7d,
  });

  final int words;
  final int corrections7d;
  final int guesses7d;
  final int correctFirstGuess7d;

  double get accuracy7d {
    if (guesses7d == 0) {
      return 0;
    }
    return correctFirstGuess7d / guesses7d;
  }
}
