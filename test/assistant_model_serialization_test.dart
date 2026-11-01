import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:simpen_woi/features/assistant/data/function_gemma_model_manager.dart';

void main() {
  test('teardown waits for the full inference operation', () async {
    final FunctionGemmaModelManager manager = FunctionGemmaModelManager();
    final Completer<void> generating = Completer<void>();
    final List<String> events = <String>[];
    final Future<void> inference = manager.exclusive(() async {
      events.add('generate');
      await generating.future;
      events.add('close chat');
    });
    final Future<void> teardown = manager.exclusive(() async {
      events.add('close model');
    });
    await Future<void>.delayed(Duration.zero);
    expect(events, <String>['generate']);
    generating.complete();
    await Future.wait(<Future<void>>[inference, teardown]);
    expect(events, <String>['generate', 'close chat', 'close model']);
    await manager.dispose();
  });

  test('failed inference does not poison later inference requests', () async {
    final FunctionGemmaModelManager manager = FunctionGemmaModelManager();
    await expectLater(manager.exclusive<void>(() async {
      throw StateError('failed inference');
    }), throwsStateError);
    expect(await manager.exclusive(() async => 42), 42);
    await manager.dispose();
  });
}
