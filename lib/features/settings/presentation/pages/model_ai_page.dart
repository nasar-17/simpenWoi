import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/capture_runtime.dart';
import '../../../assistant/data/function_gemma_model_manager.dart';
import '../../../assistant/data/function_gemma_model_status.dart';
import '../../../assistant/data/model_stream_importer.dart';
import '../../../assistant/presentation/providers/assistant_providers.dart';
import '../widgets/model_ai_status_card.dart';

class ModelAiPage extends ConsumerStatefulWidget {
  const ModelAiPage({super.key});

  @override
  ConsumerState<ModelAiPage> createState() => _ModelAiPageState();
}

class _ModelAiPageState extends ConsumerState<ModelAiPage> {
  Future<FunctionGemmaModelStatus>? _statusFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _statusFuture = ref.read(functionGemmaModelManagerProvider).status();
  }

  Future<void> _importModel() async {
    PlatformFile? result;
    try {
      result = await FilePicker.pickFile(
        dialogTitle: 'Pilih model FunctionGemma',
        type: FileType.custom,
        allowedExtensions: <String>['litertlm'],
      );
    } catch (_) {
      _showMessage('Gagal membuka pemilih file.');
      return;
    }
    if (result == null || !mounted) {
      return;
    }
    final PlatformFile picked = result;
    await _run(() async {
      await importModelStream(
        name: picked.name, bytes: picked.readAsByteStream(),
        install: ref.read(functionGemmaModelManagerProvider).importFromPath,
      );
      if (mounted) {
        unawaited(ref.read(captureRuntimeProvider).sync());
      }
      _showMessage('Model AI diimpor dan diaktifkan. Coba Uji AI lokal.');
    }, 'Gagal mengimpor model. Pastikan file .litertlm valid.');
  }

  Future<void> _openModelDebug() async {
    await context.push<void>('/settings/model-ai-debug');
    if (mounted) {
      setState(_refresh);
    }
  }

  Future<void> _deleteModel() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Hapus model AI'),
        content: const Text(
          'Model dan pengaturan asisten on-device akan dihapus.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await _run(() async {
      await ref.read(functionGemmaModelManagerProvider).deleteModel();
      _showMessage('Model AI dihapus.');
    }, 'Gagal menghapus model.');
  }

  Future<void> _toggleEnabled(bool enabled) async {
    await _run(() async {
      await ref.read(functionGemmaModelManagerProvider).setEnabled(enabled);
      if (enabled && mounted) {
        unawaited(ref.read(captureRuntimeProvider).sync());
      }
    }, 'Gagal mengubah status asisten on-device.');
  }

  Future<void> _run(Future<void> Function() action, String errorMessage) async {
    setState(() {
      _busy = true;
    });
    try {
      await action();
      if (mounted) {
        setState(_refresh);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model AI'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Segarkan status model',
            onPressed: _busy ? null : () => setState(_refresh),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<FunctionGemmaModelStatus>(
        future: _statusFuture,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<FunctionGemmaModelStatus> snapshot,
            ) {
              final FunctionGemmaModelStatus? status = snapshot.data;
              final bool installed = status?.installed ?? false;
              final bool enabled = status?.enabled ?? false;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: <Widget>[
                  ModelAiStatusCard(
                    status: status,
                    busy: _busy,
                    installed: installed,
                    enabled: enabled,
                    onImport: _busy ? null : _importModel,
                    onDelete: _busy ? null : _deleteModel,
                    onToggle: installed && !_busy ? _toggleEnabled : null,
                  ),
                  const SizedBox(height: 16),
                  const ModelAiInfoCard(),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.bug_report_outlined),
                      title: const Text('Uji AI lokal'),
                      subtitle: const Text(
                        'Periksa hasil inferensi dan waktu proses',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: installed && enabled
                          ? _openModelDebug
                          : null,
                    ),
                  ),
                ],
              );
            },
      ),
    );
  }
}
