import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/function_gemma_model_status.dart';
import '../providers/assistant_providers.dart';

class ModelReadinessBanner extends ConsumerStatefulWidget {
  const ModelReadinessBanner({super.key});

  @override
  ConsumerState<ModelReadinessBanner> createState() => _ModelReadinessBannerState();
}

class _ModelReadinessBannerState extends ConsumerState<ModelReadinessBanner>
    with WidgetsBindingObserver {
  late Future<FunctionGemmaModelStatus> _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  void _refresh() {
    _status = ref.read(functionGemmaModelManagerProvider).status();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(_refresh);
  }

  Future<void> _openModel() async {
    await context.push<void>('/settings/model-ai');
    if (mounted) setState(_refresh);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FunctionGemmaModelStatus>(
      future: _status,
      builder: (BuildContext context, AsyncSnapshot<FunctionGemmaModelStatus> snapshot) {
        final FunctionGemmaModelStatus? status = snapshot.data;
        final bool ready = status?.installed == true && status?.enabled == true;
        final String text = status == null
            ? 'Memeriksa AI lokal…'
            : ready
            ? 'AI lokal aktif. Periksa usulan sebelum menyimpan.'
            : 'Impor dan aktifkan model AI untuk memahami teks. '
                'Anda tetap dapat mencatat melalui Input formulir.';
        return ListTile(
          dense: true,
          leading: Icon(ready ? Icons.smart_toy_outlined : Icons.info_outline),
          title: Text(text),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openModel,
        );
      },
    );
  }
}
