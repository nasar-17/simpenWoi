import 'wallet_repository.dart';

/// Menjalankan perubahan dompet lalu menyegarkan konteks native.
class WalletService {
  WalletService({required this.repository, required this.refreshNativeContext});

  final WalletRepository repository;
  final Future<void> Function() refreshNativeContext;

  Future<void> add({required String name, required int initialBalance}) async {
    await repository.add(name: name, initialBalance: initialBalance);
    await refreshNativeContext();
  }

  Future<void> update({required int id, required String name}) async {
    await repository.update(id: id, name: name);
    await refreshNativeContext();
  }

  Future<void> setDefault(int id) async {
    await repository.setDefault(id);
    await refreshNativeContext();
  }

  Future<void> delete(int id, {int? moveToId}) async {
    await repository.delete(id, moveToId: moveToId);
    await refreshNativeContext();
  }
}
