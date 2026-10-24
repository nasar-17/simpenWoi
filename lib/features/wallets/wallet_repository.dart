import '../../core/database/app_database.dart';

class WalletRepository {
  WalletRepository(this._database);

  final AppDatabase _database;

  Stream<List<Wallet>> watchAll() {
    return _database.select(_database.wallets).watch();
  }
}
