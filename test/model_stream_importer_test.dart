import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:simpen_woi/features/assistant/data/model_stream_importer.dart';

void main() {
  test('streams picked content to a real temporary file and cleans up', () async {
    String? importedPath;
    await importModelStream(
      name: 'model.litertlm',
      bytes: Stream<List<int>>.fromIterable(<List<int>>[<int>[1, 2], <int>[3, 4]]),
      install: (String path) async {
        importedPath = path;
        expect(await File(path).readAsBytes(), <int>[1, 2, 3, 4]);
      },
    );
    expect(importedPath, endsWith('.litertlm'));
    expect(await File(importedPath!).exists(), false);
  });

  test('failed native installation still removes temporary model bytes', () async {
    String? importedPath;
    await expectLater(importModelStream(
      name: 'model.litertlm', bytes: Stream<List<int>>.value(<int>[1]),
      install: (String path) async {
        importedPath = path;
        throw StateError('invalid model');
      },
    ), throwsStateError);
    expect(await File(importedPath!).exists(), false);
  });

  test('wrong model extension is rejected before installation', () async {
    bool installed = false;
    await expectLater(importModelStream(
      name: 'model.gguf', bytes: const Stream<List<int>>.empty(),
      install: (String path) async { installed = true; },
    ), throwsFormatException);
    expect(installed, false);
  });
}
