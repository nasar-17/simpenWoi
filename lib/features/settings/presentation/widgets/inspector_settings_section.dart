import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../capture/data/native_capture_models.dart';
import '../../../capture/presentation/providers/capture_providers.dart';
import '../../../capture/presentation/providers/inspector_providers.dart';
import 'inspector_controls.dart';
import 'inspector_entry_tile.dart';
import 'inspector_log_list.dart';
import 'settings_section.dart';

class InspectorSettingsSection extends ConsumerStatefulWidget {
  const InspectorSettingsSection({super.key});

  @override
  ConsumerState<InspectorSettingsSection> createState() =>
      _InspectorSettingsSectionState();
}

class _InspectorSettingsSectionState
    extends ConsumerState<InspectorSettingsSection> {
  final TextEditingController _filterController = TextEditingController();
  bool? _enabledOverride;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _filterController.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _filterController
      ..removeListener(_onFilterChanged)
      ..dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _setEnabled(bool value) async {
    setState(() {
      _busy = true;
      _enabledOverride = value;
    });
    try {
      await ref.read(nativeCaptureBridgeProvider).setInspectorEnabled(value);
      ref.invalidate(inspectorStatusProvider);
      ref.invalidate(inspectorLogProvider);
    } catch (_) {
      if (mounted) {
        setState(() {
          _enabledOverride = !value;
        });
        _showMessage('Gagal mengubah inspektor.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _clearLog() async {
    try {
      await ref.read(nativeCaptureBridgeProvider).clearInspectorLog();
      ref.invalidate(inspectorLogProvider);
      _showMessage('Log inspektor dihapus.');
    } catch (_) {
      _showMessage('Gagal menghapus log inspektor.');
    }
  }

  void _refresh() {
    ref.invalidate(inspectorStatusProvider);
    ref.invalidate(inspectorLogProvider);
  }

  Future<void> _copyEntry(InspectorEntry entry) async {
    await Clipboard.setData(ClipboardData(text: formatInspectorEntry(entry)));
    _showMessage('Entri disalin.');
  }

  Future<void> _copyAll(List<InspectorEntry> entries) async {
    if (entries.isEmpty) {
      return;
    }
    await Clipboard.setData(
      ClipboardData(text: entries.map(formatInspectorEntry).join('\n\n')),
    );
    _showMessage('Semua entri disalin.');
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
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final AsyncValue<InspectorListenerStatus> statusAsync = ref.watch(
      inspectorStatusProvider,
    );
    final AsyncValue<List<InspectorEntry>> logAsync = ref.watch(
      inspectorLogProvider,
    );
    final bool enabled =
        _enabledOverride ?? statusAsync.value?.inspectorEnabled ?? false;
    final String query = _filterController.text.trim().toLowerCase();
    final List<InspectorEntry> entries =
        logAsync.value ?? const <InspectorEntry>[];
    final List<InspectorEntry> filtered = query.isEmpty
        ? entries
        : entries
              .where(
                (InspectorEntry entry) =>
                    entry.packageName.toLowerCase().contains(query) ||
                    (entry.title ?? '').toLowerCase().contains(query),
              )
              .toList(growable: false);

    return SettingsSection(
      title: 'Inspektor Notifikasi',
      children: <Widget>[
        InspectorControls(
          enabled: enabled,
          busy: _busy,
          status: statusAsync.value,
          filterController: _filterController,
          canCopyAll: filtered.isNotEmpty,
          canClearAll: entries.isNotEmpty,
          onEnabledChanged: _busy ? null : _setEnabled,
          onRefresh: _refresh,
          onCopyAll: () => _copyAll(filtered),
          onClearAll: _clearLog,
        ),
        const Divider(height: 1),
        InspectorLogList(
          entries: filtered,
          loading: logAsync.isLoading,
          error: logAsync.error,
          onCopy: _copyEntry,
        ),
      ],
    );
  }
}
