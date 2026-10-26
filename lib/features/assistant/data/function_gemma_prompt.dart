import 'package:flutter/services.dart';

import '../../../core/assistant/assistant_context.dart';
import '../../../core/database/app_database.dart';

class FunctionGemmaPrompt {
  String? _basePrompt;

  Future<String> build({
    required AssistantContext context,
    required List<LearningLogEntry> examples,
  }) async {
    final String base = _basePrompt ??= await rootBundle.loadString(
      'assets/ai/skill_keuangan.md',
    );
    final StringBuffer buffer = StringBuffer(base.trim())..writeln();
    buffer.writeln('Tanggal: ${_date(DateTime.now())}');
    buffer.writeln('Dompet:');
    for (final Wallet wallet in context.wallets.take(15)) {
      buffer.writeln(
        '- ${wallet.id} | ${wallet.name}'
        '${wallet.isDefault ? ' | utama' : ''}',
      );
    }
    buffer.writeln('Kategori:');
    for (final Category category in context.categories.take(15)) {
      buffer.writeln('- ${category.id} | ${category.name} | ${category.type}');
    }
    if (examples.isNotEmpty) {
      buffer.writeln('Contoh keputusan sebelumnya:');
      for (final LearningLogEntry example in examples.take(3)) {
        buffer.writeln(
          '- "${_singleLine(example.inputText)}" -> '
          '${_singleLine(example.actionJson, max: 160)}',
        );
      }
    }
    return buffer.toString();
  }

  String _date(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _singleLine(String value, {int max = 120}) {
    final String text = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.length <= max ? text : '${text.substring(0, max)}...';
  }
}
