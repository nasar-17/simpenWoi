import 'assistant_action.dart';

enum ActionSource { rules, ai }

class CategoryOption {
  const CategoryOption({required this.id, required this.name});

  final int id;
  final String name;
}

class ProposedAction {
  const ProposedAction({
    required this.action,
    required this.confidence,
    required this.source,
    required this.summary,
    this.details = const <String>[],
    this.options = const <CategoryOption>[],
    this.suggestedCategoryName,
  });

  final AssistantAction action;
  final double confidence;
  final ActionSource source;
  final String summary;
  final List<String> details;
  final List<CategoryOption> options;
  final String? suggestedCategoryName;

  ProposedAction copyWith({
    AssistantAction? action,
    double? confidence,
    ActionSource? source,
    String? summary,
    List<String>? details,
    List<CategoryOption>? options,
    String? suggestedCategoryName,
  }) {
    return ProposedAction(
      action: action ?? this.action,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      summary: summary ?? this.summary,
      details: details ?? this.details,
      options: options ?? this.options,
      suggestedCategoryName:
          suggestedCategoryName ?? this.suggestedCategoryName,
    );
  }
}
