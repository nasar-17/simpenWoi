import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/wallet_balance.dart';

/// Akses data dompet dan aturan dompet utama.
class WalletRepository {
  WalletRepository(this._database);

  final AppDatabase _database;

  Stream<List<Wallet>> watchAll() {
    return (_database.select(
      _database.wallets,
    )..orderBy([(table) => OrderingTerm.asc(table.id)])).watch();
  }

  Future<List<Wallet>> getAll() {
    return (_database.select(
      _database.wallets,
    )..orderBy([(table) => OrderingTerm.asc(table.id)])).get();
  }

  Future<Wallet?> getById(int id) {
    return (_database.select(
      _database.wallets,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<int> add({required String name, required int initialBalance}) {
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Nama dompet wajib diisi.');
    }
    return _database.transaction(() async {
      final bool hasWallet = await _hasWallet();
      return _database
          .into(_database.wallets)
          .insert(
            WalletsCompanion.insert(
              name: trimmedName,
              balance: Value<int>(initialBalance),
              isDefault: Value<bool>(!hasWallet),
            ),
          );
    });
  }

  Future<void> update({required int id, required String name}) async {
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Nama dompet wajib diisi.');
    }
    await (_database.update(_database.wallets)
          ..where((table) => table.id.equals(id)))
        .write(WalletsCompanion(name: Value<String>(trimmedName)));
  }

  Future<void> setDefault(int id) {
    return _database.transaction(() async {
      final Wallet? wallet = await getById(id);
      if (wallet == null) {
        return;
      }
      await (_database.update(_database.wallets)
            ..where((table) => table.isDefault.equals(true)))
          .write(const WalletsCompanion(isDefault: Value<bool>(false)));
      await (_database.update(_database.wallets)
            ..where((table) => table.id.equals(id)))
          .write(const WalletsCompanion(isDefault: Value<bool>(true)));
    });
  }

  Future<int> countTransactions(int id) async {
    final QueryRow row = await _database
        .customSelect(
          'SELECT COUNT(*) AS total FROM transactions WHERE wallet_id = ?',
          variables: <Variable<Object>>[Variable.withInt(id)],
        )
        .getSingle();
    return row.read<int>('total');
  }

  Future<void> delete(int id, {int? moveToId}) {
    return _database.transaction(() async {
      final Wallet? wallet = await getById(id);
      if (wallet == null) {
        return;
      }
      final int usage = await countTransactions(id);
      Wallet? target;
      if (usage > 0) {
        if (moveToId == null || moveToId == id) {
          throw StateError('Dompet tujuan tidak valid.');
        }
        target = await getById(moveToId);
        if (target == null) {
          throw StateError('Dompet tujuan tidak valid.');
        }
        await (_database.update(_database.transactions)
              ..where((table) => table.walletId.equals(id)))
            .write(TransactionsCompanion(walletId: Value<int>(target.id)));
        await adjustWalletBalance(_database, target.id, wallet.balance);
      }
      final bool wasDefault = wallet.isDefault;
      await (_database.delete(
        _database.wallets,
      )..where((table) => table.id.equals(id))).go();
      if (!wasDefault) {
        return;
      }
      final Wallet? next =
          target ??
          await (_database.select(_database.wallets)
                ..orderBy([(table) => OrderingTerm.asc(table.id)]))
              .getSingleOrNull();
      if (next != null) {
        await (_database.update(_database.wallets)
              ..where((table) => table.id.equals(next.id)))
            .write(const WalletsCompanion(isDefault: Value<bool>(true)));
      }
    });
  }

  Future<bool> _hasWallet() async {
    final Wallet? wallet = await (_database.select(
      _database.wallets,
    )..limit(1)).getSingleOrNull();
    return wallet != null;
  }
}
