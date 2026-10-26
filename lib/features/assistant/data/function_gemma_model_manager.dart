import 'dart:async';
import 'dart:io';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';

import 'function_gemma_model_status.dart';
import 'function_gemma_model_storage.dart';

part 'function_gemma_model_manager_ops.dart';

class FunctionGemmaModelManager {
  FunctionGemmaModelManager({FunctionGemmaModelStorage? storage})
    : _storage = storage ?? FunctionGemmaModelStorage();

  static const int contextTokens = 1024;
  static const Duration idleUnload = Duration(minutes: 3);
  static const Duration timeout = Duration(seconds: 25);

  final FunctionGemmaModelStorage _storage;
  Future<void>? _initialization;
  Future<InferenceModel>? _loading;
  InferenceModel? _model;
  Timer? _idleTimer;
  int _activeUsers = 0;
  bool _installed = false;
  bool _enabled = false;

  bool get isInstalled => _installed;
  bool get isEnabled => _enabled;

  Future<void> _ensureInitialized() async {
    final Future<void> future = _initialization ??= _initialize();
    try {
      await future;
    } catch (_) {
      if (identical(_initialization, future)) {
        _initialization = null;
      }
      rethrow;
    }
  }

  Future<void> _initialize() async {
    FlutterGemma.logLevel = GemmaLogLevel.none;
    await FlutterGemma.initialize(
      inferenceEngines: const <LiteRtLmEngine>[LiteRtLmEngine()],
    );
  }

  Future<FunctionGemmaModelStatus> status() async {
    try {
      await _ensureInitialized();
      final File file = await _storage.targetFile();
      final bool fileExists = await file.exists();
      final bool installed =
          fileExists &&
          await FlutterGemma.isModelInstalled(
            FunctionGemmaModelStorage.modelId,
          );
      final bool enabled = installed && await _storage.markerExists();
      _installed = installed;
      _enabled = enabled;
      return FunctionGemmaModelStatus(
        installed: installed,
        enabled: enabled,
        loaded: _model != null,
        sizeBytes: fileExists ? await file.length() : 0,
      );
    } catch (error) {
      _installed = false;
      _enabled = false;
      return FunctionGemmaModelStatus(
        installed: false,
        enabled: false,
        loaded: false,
        sizeBytes: 0,
        error: '$error',
      );
    }
  }

  Future<void> refreshStatus() async {
    await status();
  }

  Future<InferenceModel> acquire() async {
    await _ensureInitialized();
    if (!_installed) {
      await refreshStatus();
    }
    if (!_installed || !_enabled) {
      throw StateError('Asisten on-device belum aktif.');
    }
    _activeUsers++;
    _idleTimer?.cancel();
    try {
      final InferenceModel? existing = _model;
      if (existing != null) {
        return existing;
      }
      return await (_loading ??= _loadModel());
    } catch (_) {
      _activeUsers--;
      rethrow;
    } finally {
      _loading = null;
    }
  }

  Future<InferenceModel> _loadModel() async {
    final InferenceModel model = await FlutterGemma.getActiveModel(
      maxTokens: contextTokens,
      preferredBackend: PreferredBackend.cpu,
    );
    _model = model;
    return model;
  }

  void release() {
    if (_activeUsers > 0) {
      _activeUsers--;
    }
    _scheduleUnload();
  }

  void _scheduleUnload() {
    _idleTimer?.cancel();
    if (_activeUsers > 0 || _model == null) {
      return;
    }
    _idleTimer = Timer(idleUnload, () {
      unawaited(unload());
    });
  }

  Future<void> unload() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    final InferenceModel? model = _model;
    _model = null;
    if (model != null) {
      try {
        await model.close();
      } catch (_) {}
    }
  }

  Future<void> dispose() => unload();
}
