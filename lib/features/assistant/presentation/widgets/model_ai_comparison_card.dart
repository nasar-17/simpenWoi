import 'package:flutter/material.dart';

class ModelAiComparisonCard extends StatelessWidget {
  const ModelAiComparisonCard({
    super.key,
    required this.input,
    required this.result,
    required this.milliseconds,
  });

  final String input;
  final String result;
  final int milliseconds;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(input, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(result.isEmpty ? 'Tidak ada usulan.' : result),
          Text('${(milliseconds / 1000).toStringAsFixed(1)} detik'),
        ],
      ),
    ),
  );
}
