import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:simpen_woi/app/capture_runtime.dart';
import 'package:simpen_woi/features/capture/data/native_capture_bridge.dart';

class FakeCaptureBridge extends NativeCaptureBridge {
  final StreamController<void> events = StreamController<void>.broadcast(
    sync: true,
  );

  @override
  Stream<void> get captureEvents => events.stream;
}

void main() {
  test('starts sync without a widget or UI frame and subscribes only once', () async {
    final FakeCaptureBridge bridge = FakeCaptureBridge();
    int calls = 0;
    final CaptureRuntime runtime = CaptureRuntime(
      bridge: bridge,
      synchronize: () async { calls++; },
      reportError: (_) {},
    );
    runtime.start();
    runtime.start();
    expect(calls, 1);
    bridge.events.add(null);
    expect(calls, 2);
    runtime.dispose();
    await bridge.events.close();
  });

  test('reports a safe error and clears it after a successful retry', () async {
    final FakeCaptureBridge bridge = FakeCaptureBridge();
    bool fail = true;
    String? error;
    final CaptureRuntime runtime = CaptureRuntime(
      bridge: bridge,
      synchronize: () async {
        if (fail) throw StateError('private notification content');
      },
      reportError: (String? value) { error = value; },
    );
    await runtime.sync();
    expect(error, isNotNull);
    expect(error, isNot(contains('private notification content')));
    fail = false;
    await runtime.sync();
    expect(error, isNull);
    runtime.dispose();
    await bridge.events.close();
  });

  test('disposed runtime does not process more notifications', () async {
    final FakeCaptureBridge bridge = FakeCaptureBridge();
    int calls = 0;
    final CaptureRuntime runtime = CaptureRuntime(
      bridge: bridge,
      synchronize: () async { calls++; },
      reportError: (_) {},
    );
    runtime.dispose();
    runtime.start();
    await runtime.sync();
    expect(calls, 0);
    await bridge.events.close();
  });
}
