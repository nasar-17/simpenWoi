import '../../../core/database/app_database.dart';

/// Akses data dompet.
class WalletRepository {
  WalletRepository(this._database);

  final AppDatabase _database;

  Stream<List<Wallet>> watchAll() {
    return _database.select(_database.wallets).watch();
  }

  Future<List<Wallet>> getAll() {
    return _database.select(_database.wallets).get();
  }
}
