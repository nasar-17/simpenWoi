import 'dart:async';
import 'dart:io';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';

import 'function_gemma_model_status.dart';
import 'function_gemma_model_storage.dart';

part 'function_gemma_model_manager_ops.dart';

/// Owns the model and serializes inference, replacement and teardown.
class FunctionGemmaModelManager {
  FunctionGemmaModelManager({FunctionGemmaModelStorage? storage})
    : _storage = storage ?? FunctionGemmaModelStorage();

  static const int contextTokens = 4096;
  static const Duration idleUnload = Duration(minutes: 3);

  final FunctionGemmaModelStorage _storage;
  Future<void> _tail = Future<void>.value();
  Future<void>? _initialization;
  InferenceModel? _model;
  Timer? _idleTimer;
  bool _installed = false;
  bool _enabled = false;
  bool _disposed = false;
  int _completedInferences = 0;
  Duration? _lastInferenceDuration;

  bool get isInstalled => _installed;
  bool get isEnabled => _enabled;

  /// A failed task must not poison the queue for later requests.
  Future<T> exclusive<T>(Future<T> Function() operation) {
    final Future<T> result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  /// The chat, generation and chat.close must all live inside this callback.
  /// Never time out generation by abandoning its Future: that does not cancel
  /// native inference and would allow close/replacement while it is running.
  Future<T?> withModel<T>(Future<T> Function(InferenceModel model) operation) {
    return exclusive(() async {
      if (_disposed) throw StateError('Pengelola model sudah ditutup.');
      await _readStatus();
      if (!_installed || !_enabled) return null;
      _idleTimer?.cancel();
      try {
        final InferenceModel model = _model ??= await _loadModel();
        final Stopwatch stopwatch = Stopwatch()..start();
        final T result = await operation(model);
        _completedInferences++;
        _lastInferenceDuration = stopwatch.elapsed;
        return result;
      } catch (_) {
        // A failed native chat must not be reused by the next request.
        await _unload();
        rethrow;
      } finally {
        _scheduleUnload();
      }
    });
  }

  Future<void> _ensureInitialized() async {
    final Future<void> future = _initialization ??= _initialize();
    try {
      await future;
    } catch (_) {
      if (identical(_initialization, future)) _initialization = null;
      rethrow;
    }
  }

  Future<void> _initialize() async {
    FlutterGemma.logLevel = GemmaLogLevel.none;
    await FlutterGemma.initialize(
      inferenceEngines: const <LiteRtLmEngine>[LiteRtLmEngine()],
    );
  }

  Future<FunctionGemmaModelStatus> status() => exclusive(_readStatus);

  Future<FunctionGemmaModelStatus> _readStatus() async {
    try {
      await _ensureInitialized();
      final File file = await _storage.targetFile();
      final bool fileExists = await file.exists();
      // The SDK repository is keyed by the full filename, including extension.
      _installed = fileExists && await FlutterGemma.isModelInstalled(
        FunctionGemmaModelStorage.modelId,
      );
      _enabled = _installed && await _storage.markerExists();
      return FunctionGemmaModelStatus(
        installed: _installed,
        enabled: _enabled,
        loaded: _model != null,
        sizeBytes: fileExists ? await file.length() : 0,
        completedInferences: _completedInferences,
        lastInferenceDuration: _lastInferenceDuration,
      );
    } catch (_) {
      _installed = false;
      _enabled = false;
      return FunctionGemmaModelStatus(
        installed: false,
        enabled: false,
        loaded: _model != null,
        sizeBytes: 0,
        error: 'Model AI belum dapat diperiksa. Coba impor ulang model.',
        completedInferences: _completedInferences,
        lastInferenceDuration: _lastInferenceDuration,
      );
    }
  }

  Future<void> refreshStatus() async {
    await status();
  }

  Future<InferenceModel> _loadModel() {
    return FlutterGemma.getActiveModel(
      maxTokens: contextTokens,
      preferredBackend: PreferredBackend.cpu,
    );
  }

  void _scheduleUnload() {
    _idleTimer?.cancel();
    if (_model == null || _disposed) return;
    _idleTimer = Timer(idleUnload, () {
      // Use the same queue as generation: a fired timer can never close a
      // model during a later chat that has already started.
      unawaited(exclusive(() async {
        if (_idleTimer?.isActive ?? false) return;
        await _unload();
      }).catchError((Object _) {}));
    });
  }

  Future<void> unload() => exclusive(_unload);

  Future<void> _unload() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    final InferenceModel? model = _model;
    _model = null;
    if (model != null) await model.close();
  }

  Future<void> dispose() {
    _disposed = true;
    _idleTimer?.cancel();
    return unload().catchError((Object _) {});
  }
}
