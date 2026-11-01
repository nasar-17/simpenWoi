import 'dart:io';

/// Storage providers may return content:// URIs instead of filesystem paths.
/// Stream the model to app-private temporary storage without loading its weights
/// into Dart memory, then let the manager validate/install it atomically.
Future<void> importModelStream({
  required String name,
  required Stream<List<int>> bytes,
  required Future<void> Function(String) install,
}) async {
  if (!name.toLowerCase().endsWith('.litertlm')) {
    throw const FormatException('Pilih model FunctionGemma .litertlm.');
  }
  final Directory directory = await Directory.systemTemp.createTemp('simpenwoi-model-');
  try {
    final File file = File('${directory.path}/function_gemma_270m.litertlm');
    await bytes.pipe(file.openWrite());
    await install(file.path);
  } finally {
    await directory.delete(recursive: true);
  }
}
