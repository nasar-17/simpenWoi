part of 'function_gemma_model_manager.dart';

extension FunctionGemmaModelOperations on FunctionGemmaModelManager {
  Future<void> importFromPath(String sourcePath) {
    return exclusive(() => _importFromPath(sourcePath));
  }

  Future<void> _register(File file) async {
    await FlutterGemma.installModel(
      modelType: ModelType.functionGemma,
      fileType: ModelFileType.litertlm,
    ).fromFile(file.path).install();
  }

  Future<void> _unregister() async {
    if (await FlutterGemma.isModelInstalled(
      FunctionGemmaModelStorage.modelId,
    )) {
      await FlutterGemma.uninstallModel(FunctionGemmaModelStorage.modelId);
    }
    await FlutterGemma.clearActiveInferenceIdentity();
  }

  Future<void> _importFromPath(String sourcePath) async {
    if (!sourcePath.toLowerCase().endsWith('.litertlm')) {
      throw const FormatException('Pilih file model .litertlm.');
    }
    final File source = File(sourcePath);
    if (!await source.exists()) {
      throw const FileSystemException('File model tidak ditemukan.');
    }
    if (await source.length() < 1024 * 1024) {
      throw const FormatException('File terlalu kecil untuk model FunctionGemma.');
    }
    await _readStatus();
    final bool previouslyEnabled = _enabled;
    final File target = await _storage.targetFile();
    final File temporary = await _storage.temporaryFile();
    final File backup = File('${target.path}.previous');
    bool replaced = false;
    try {
      // Copy first: a failed or interrupted picker copy leaves the old model.
      await _storage.copyToTemporary(sourcePath);
      await _unload();
      await _unregister();
      if (await target.exists()) {
        if (await backup.exists()) await backup.delete();
        await target.rename(backup.path);
      }
      await temporary.rename(target.path);
      replaced = true;
      await _register(target);
      // Opening the native model validates more than a filename extension.
      _model = await _loadModel();
      await _storage.setEnabledMarker(true);
      _installed = true;
      _enabled = true;
      if (await backup.exists()) await backup.delete();
      _scheduleUnload();
    } catch (_) {
      await _storage.deleteTemporary();
      if (replaced) {
        await _unload();
        await _unregister();
        await _storage.deleteTarget();
      }
      if (await backup.exists()) await backup.rename(target.path);
      if (await target.exists()) {
        await _register(target);
        await _storage.setEnabledMarker(previouslyEnabled);
      } else {
        await _storage.setEnabledMarker(false);
      }
      await _readStatus();
      throw StateError(
        'Model tidak dapat diimpor atau dijalankan. Gunakan file FunctionGemma '
        '270M .litertlm yang kompatibel; model sebelumnya dipertahankan.',
      );
    }
  }

  Future<void> deleteModel() => exclusive(_deleteModel);

  Future<void> _deleteModel() async {
    await _ensureInitialized();
    await _unload();
    await _unregister();
    await _storage.deleteTarget();
    await _storage.setEnabledMarker(false);
    _installed = false;
    _enabled = false;
  }

  Future<void> setEnabled(bool enabled) {
    return exclusive(() => _setEnabled(enabled));
  }

  Future<void> _setEnabled(bool enabled) async {
    await _ensureInitialized();
    if (enabled) {
      await _readStatus();
      if (!_installed) throw StateError('Model AI belum diimpor.');
      _model ??= await _loadModel();
    } else {
      await _unload();
    }
    await _storage.setEnabledMarker(enabled);
    _enabled = enabled;
    if (enabled) _scheduleUnload();
  }
}
