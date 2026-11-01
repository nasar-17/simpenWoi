import 'package:flutter_test/flutter_test.dart';
import 'package:simpen_woi/core/assistant/assistant_action.dart';
import 'package:simpen_woi/core/assistant/assistant_context.dart';
import 'package:simpen_woi/core/assistant/proposed_action.dart';
import 'package:simpen_woi/core/database/app_database.dart';
import 'package:simpen_woi/features/assistant/domain/ai_provider.dart';
import 'package:simpen_woi/features/capture/data/capture_ai_transfer_processor.dart';
import 'package:simpen_woi/features/capture/data/native_capture_bridge.dart';
import 'package:simpen_woi/features/capture/data/native_capture_models.dart';

final DateTime _now = DateTime(2026, 11, 1, 12);
final List<Wallet> _wallets = <Wallet>[
  Wallet(id: 1, name: 'DANA', balance: 0, isDefault: true, createdAt: _now),
  Wallet(id: 2, name: 'SeaBank', balance: 0, isDefault: false, createdAt: _now),
];

NativeCapture _capture(int id, String package, {String direction = 'raw',
  int amount = 0}) => NativeCapture(
    id: id, amount: amount, merchant: null, sourcePackage: package,
    postedAt: _now, direction: direction, categoryId: null,
    note: 'Complete unparsed notification $id',
  );

ProposedAction _transfer({int from = 1, int to = 2, int amount = 10000}) =>
    ProposedAction(
      action: TransferAction(amount: amount, fromWalletId: from, toWalletId: to),
      confidence: 0, source: ActionSource.ai, summary: 'Transfer',
    );

class _Ai implements AiProvider {
  _Ai(this.actions);
  final List<ProposedAction>? actions;
  final List<String> prompts = <String>[];
  @override
  bool get isAvailable => false;
  @override
  Future<List<ProposedAction>?> propose(String input, AssistantContext context) async {
    prompts.add(input);
    return actions;
  }
}

class _Bridge extends NativeCaptureBridge {
  _Bridge(this.recent);
  final List<NativeCapture> recent;
  final List<({int primaryId, int secondaryId, String direction})> confirmed = [];
  @override
  Future<List<NativeCapture>> getRecentCaptures() async => recent;
  @override
  Future<bool> confirmAiTransfer({
    required int primaryId, required int secondaryId, required int amount,
    required int fromWalletId, required int toWalletId,
    required String primaryDirection, required String secondaryDirection,
  }) async {
    confirmed.add((primaryId: primaryId, secondaryId: secondaryId,
        direction: primaryDirection));
    return true;
  }
}

Future<Set<int>> _resolve(_Ai ai, _Bridge bridge, List<NativeCapture> pending) =>
    CaptureAiTransferProcessor(ai: ai, bridge: bridge).resolvePending(
      captures: pending, wallets: _wallets, categories: const <Category>[],
    );

void main() {
  test('only validated model transfer pairs captures without amount prefilter', () async {
    final _Ai ai = _Ai(<ProposedAction>[_transfer()]);
    final _Bridge bridge = _Bridge(<NativeCapture>[
      _capture(2, 'id.co.bankbkemobile.digitalbank'),
    ]);
    expect(await _resolve(ai, bridge, <NativeCapture>[_capture(1, 'id.dana')]),
        <int>{1, 2});
    expect(ai.prompts.single, contains('Complete unparsed notification 1'));
    expect(ai.prompts.single, contains('Complete unparsed notification 2'));
    expect(bridge.confirmed.single.direction, 'OUT');
  });

  test('incoming primary preserves its direction for undo', () async {
    final _Bridge bridge = _Bridge(<NativeCapture>[
      _capture(2, 'id.dana', direction: 'OUT', amount: 10000),
    ]);
    await _resolve(_Ai(<ProposedAction>[_transfer()]), bridge, <NativeCapture>[
      _capture(1, 'id.co.bankbkemobile.digitalbank'),
    ]);
    expect(bridge.confirmed.single.direction, 'IN');
  });

  test('same amounts alone and model clarification never pair captures', () async {
    final _Bridge bridge = _Bridge(<NativeCapture>[
      _capture(2, 'id.co.bankbkemobile.digitalbank', direction: 'IN', amount: 10000),
    ]);
    final _Ai ai = _Ai(const <ProposedAction>[
      ProposedAction(action: AskClarificationAction(question: 'Tidak terkait'),
          confidence: 0, source: ActionSource.ai, summary: 'Tidak terkait'),
    ]);
    expect(await _resolve(ai, bridge, <NativeCapture>[_capture(1, 'id.dana')]), isEmpty);
    expect(bridge.confirmed, isEmpty);
  });

  test('unknown wallet and multiple action responses are rejected', () async {
    for (final List<ProposedAction> actions in <List<ProposedAction>>[
      <ProposedAction>[_transfer(to: 99)],
      <ProposedAction>[_transfer(), _transfer()],
    ]) {
      final _Bridge bridge = _Bridge(<NativeCapture>[
        _capture(2, 'id.co.bankbkemobile.digitalbank'),
      ]);
      expect(await _resolve(_Ai(actions), bridge,
          <NativeCapture>[_capture(1, 'id.dana')]), isEmpty);
      expect(bridge.confirmed, isEmpty);
    }
  });

  test('known historical transaction cannot change amount or direction', () async {
    for (final NativeCapture other in <NativeCapture>[
      _capture(2, 'id.co.bankbkemobile.digitalbank', direction: 'IN', amount: 9000),
      _capture(3, 'id.co.bankbkemobile.digitalbank', direction: 'OUT', amount: 10000),
    ]) {
      final _Bridge bridge = _Bridge(<NativeCapture>[other]);
      expect(await _resolve(_Ai(<ProposedAction>[_transfer()]), bridge,
          <NativeCapture>[_capture(1, 'id.dana')]), isEmpty);
      expect(bridge.confirmed, isEmpty);
    }
  });

  test('unknown source package never uses default wallet for a transfer', () async {
    final _Ai ai = _Ai(<ProposedAction>[_transfer()]);
    final _Bridge bridge = _Bridge(<NativeCapture>[_capture(2, 'id.dana')]);
    expect(await _resolve(ai, bridge,
        <NativeCapture>[_capture(1, 'unknown.bank')]), isEmpty);
    expect(ai.prompts, isEmpty);
  });

  test('pair inference is bounded to four attempts per sync', () async {
    final _Ai ai = _Ai(null);
    final _Bridge bridge = _Bridge(<NativeCapture>[
      for (int id = 2; id < 12; id++)
        _capture(id, 'id.co.bankbkemobile.digitalbank'),
    ]);
    await _resolve(ai, bridge, <NativeCapture>[_capture(1, 'id.dana')]);
    expect(ai.prompts.length, CaptureAiTransferProcessor.maxAttempts);
  });
}
