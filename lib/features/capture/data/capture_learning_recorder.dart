import 'dart:convert';

import '../../learning/data/learning_repository.dart';

class CaptureLearningRecorder {
  const CaptureLearningRecorder({required this.learningRepository});

  final LearningRepository learningRepository;

  Future<void> record({
    required String inputText,
    required String? merchant,
    required int newCategoryId,
    int? oldCategoryId,
  }) async {
    if (oldCategoryId == newCategoryId) {
      return;
    }
    final String outcome = oldCategoryId == null ? 'accepted' : 'corrected';
    await learningRepository.record(
      inputText: inputText,
      actionJson: jsonEncode(<String, Object?>{
        'source': 'capture',
        'categoryId': newCategoryId,
      }),
      outcome: outcome,
    );
    await learningRepository.applyFeedback(
      inputText: inputText,
      outcome: outcome,
      oldCategoryId: oldCategoryId,
      newCategoryId: newCategoryId,
      merchant: merchant,
    );
  }
}
