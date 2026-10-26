part of 'function_gemma_model_manager.dart';

extension FunctionGemmaModelOperations on FunctionGemmaModelManager {
  Future<void> importFromPath(String sourcePath) async {
    if (!sourcePath.toLowerCase().endsWith('.litertlm')) {
      throw const FormatException('Pilih file model .litertlm.');
    }
    if (!await File(sourcePath).exists()) {
      throw const FileSystemException('File model tidak ditemukan.');
    }
    await _ensureInitialized();
    final File target = await _storage.targetFile();
    final File temporary = await _storage.temporaryFile();
    await _storage.copyToTemporary(sourcePath);
    try {
      await unload();
      if (await FlutterGemma.isModelInstalled(
        FunctionGemmaModelStorage.modelId,
      )) {
        await FlutterGemma.uninstallModel(FunctionGemmaModelStorage.modelId);
        await FlutterGemma.clearActiveInferenceIdentity();
      }
      await _storage.deleteTarget();
      await temporary.rename(target.path);
      await FlutterGemma.installModel(
        modelType: ModelType.functionGemma,
        fileType: ModelFileType.litertlm,
      ).fromFile(target.path).install();
      await _storage.setEnabledMarker(false);
      _installed = true;
      _enabled = false;
    } catch (_) {
      await _storage.deleteTemporary();
      if (!await FlutterGemma.isModelInstalled(
            FunctionGemmaModelStorage.modelId,
          ) &&
          await target.exists()) {
        await target.delete();
      }
      rethrow;
    }
  }

  Future<void> deleteModel() async {
    await _ensureInitialized();
    await unload();
    try {
      if (await FlutterGemma.isModelInstalled(
        FunctionGemmaModelStorage.modelId,
      )) {
        await FlutterGemma.uninstallModel(FunctionGemmaModelStorage.modelId);
        await FlutterGemma.clearActiveInferenceIdentity();
      }
    } finally {
      await _storage.deleteTarget();
      await _storage.setEnabledMarker(false);
      _installed = false;
      _enabled = false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    await _ensureInitialized();
    if (enabled) {
      await refreshStatus();
      if (!_installed) {
        throw StateError('Model AI belum diimpor.');
      }
    }
    await _storage.setEnabledMarker(enabled);
    _enabled = enabled;
    if (!enabled) {
      if (_activeUsers == 0) {
        await unload();
      } else {
        _scheduleUnload();
      }
    }
  }
}
