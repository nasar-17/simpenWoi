import 'dart:io';

import 'package:path_provider/path_provider.dart';

class FunctionGemmaModelStorage {
  static const String fileName = 'function_gemma_270m.litertlm';
  static const String modelId = 'function_gemma_270m';

  Future<File> targetFile() async => File(await _targetPath());

  Future<File> temporaryFile() async {
    return File('${(await targetFile()).path}.tmp');
  }

  Future<bool> markerExists() async {
    return File(await _markerPath()).exists();
  }

  Future<void> copyToTemporary(String sourcePath) async {
    final File temporary = await temporaryFile();
    await File(sourcePath).openRead().pipe(temporary.openWrite());
  }

  Future<void> deleteTarget() async {
    final File file = await targetFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteTemporary() async {
    final File file = await temporaryFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> setEnabledMarker(bool enabled) async {
    final File marker = File(await _markerPath());
    if (enabled) {
      await marker.writeAsString('1', flush: true);
    } else if (await marker.exists()) {
      await marker.delete();
    }
  }

  Future<String> _targetPath() async {
    final Directory directory = await _modelsDirectory();
    return '${directory.path}${Platform.pathSeparator}$fileName';
  }

  Future<String> _markerPath() async {
    final Directory directory = await _modelsDirectory();
    return '${directory.path}${Platform.pathSeparator}enabled';
  }

  Future<Directory> _modelsDirectory() async {
    final Directory support = await getApplicationSupportDirectory();
    final Directory directory = Directory(
      '${support.path}${Platform.pathSeparator}ai_models',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
