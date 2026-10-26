import 'package:flutter/material.dart';

class AssistantEmptyState extends StatelessWidget {
  const AssistantEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.chat_bubble_outline, size: 48, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'Tulis transaksi dengan bahasa sehari-hari.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Contoh: "bakso 15rb", "gajian 2jt", '
              '"total makan bulan ini", atau "pindah 50rb dari DANA ke SeaBank".',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class AssistantComposer extends StatelessWidget {
  const AssistantComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.busy,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool busy;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            const IconButton(
              onPressed: null,
              tooltip: 'Scan struk segera hadir',
              icon: Icon(Icons.document_scanner_outlined),
            ),
            const IconButton(
              onPressed: null,
              tooltip: 'Input suara segera hadir',
              icon: Icon(Icons.mic_none),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (String _) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Tulis transaksi...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: busy ? null : onSend,
              tooltip: 'Kirim',
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
