import 'package:flutter/material.dart';

class ModelAiComparisonCard extends StatelessWidget {
  const ModelAiComparisonCard({
    super.key,
    required this.input,
    required this.rules,
    required this.ai,
  });

  final String input;
  final String rules;
  final String ai;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(input, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text('Rules: $rules'),
            Text('AI: $ai'),
          ],
        ),
      ),
    );
  }
}
