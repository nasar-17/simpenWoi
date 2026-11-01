import 'package:flutter_test/flutter_test.dart';
import 'package:simpen_woi/core/database/app_database.dart';
import 'package:simpen_woi/features/capture/data/capture_transfer_importer.dart';
import 'package:simpen_woi/features/capture/data/native_capture_models.dart';

Wallet wallet(int id, String name, {bool isDefault = false}) => Wallet(
  id: id,
  name: name,
  balance: 0,
  isDefault: isDefault,
  createdAt: DateTime(2026),
);

NativeCapture capture({String? destination = 'id.co.bankbkemobile.digitalbank'}) =>
    NativeCapture(
      id: 3,
      amount: 10000,
      merchant: null,
      sourcePackage: 'id.dana',
      postedAt: DateTime(2026),
      direction: 'OUT',
      categoryId: null,
      note: null,
      isTransfer: true,
      transferSourcePackage: 'id.dana',
      transferDestinationPackage: destination,
    );

void main() {
  test('resolves both explicit transfer wallets instead of default', () {
    final List<Wallet> wallets = <Wallet>[
      wallet(1, 'Tunai', isDefault: true),
      wallet(2, ' DANA '),
      wallet(3, 'seabank'),
    ];
    final ({Wallet source, Wallet destination}) result =
        resolveCapturedTransferWallets(capture(), wallets);
    expect(result.source.id, 2);
    expect(result.destination.id, 3);
  });

  test('missing destination never falls back to unrelated wallet', () {
    expect(
      () => resolveCapturedTransferWallets(capture(), <Wallet>[
        wallet(1, 'Tunai', isDefault: true),
        wallet(2, 'DANA'),
      ]),
      throwsStateError,
    );
  });

  test('unknown package is preserved for review instead of inferred', () {
    expect(
      () => resolveCapturedTransferWallets(
        capture(destination: 'unknown.bank'),
        <Wallet>[wallet(2, 'DANA'), wallet(3, 'SeaBank')],
      ),
      throwsStateError,
    );
  });

  test('same source and destination is not imported as a transfer', () {
    expect(
      () => resolveCapturedTransferWallets(
        capture(destination: 'id.dana'),
        <Wallet>[wallet(2, 'DANA'), wallet(3, 'SeaBank')],
      ),
      throwsStateError,
    );
  });
}
