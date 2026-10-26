import '../database/app_database.dart';
import 'assistant_name.dart';

class AssistantContext {
  const AssistantContext({required this.wallets, required this.categories});

  final List<Wallet> wallets;
  final List<Category> categories;

  Wallet? walletById(int? id) {
    if (id == null) {
      return null;
    }
    for (final Wallet wallet in wallets) {
      if (wallet.id == id) {
        return wallet;
      }
    }
    return null;
  }

  Category? categoryById(int? id) {
    if (id == null) {
      return null;
    }
    for (final Category category in categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  Wallet? walletByName(String name) {
    final String wanted = normalizeAssistantName(name);
    for (final Wallet wallet in wallets) {
      if (normalizeAssistantName(wallet.name) == wanted) {
        return wallet;
      }
    }
    for (final Wallet wallet in wallets) {
      if (normalizeAssistantName(wallet.name).contains(wanted) ||
          wanted.contains(normalizeAssistantName(wallet.name))) {
        return wallet;
      }
    }
    return null;
  }

  Category? categoryByName(String name, {String? type}) {
    final String wanted = normalizeAssistantName(name);
    for (final Category category in categories) {
      if (type != null && category.type != type) {
        continue;
      }
      if (normalizeAssistantName(category.name) == wanted) {
        return category;
      }
    }
    return null;
  }

  Category? similarCategory(String name, {String? type}) {
    final String wanted = normalizeAssistantName(name);
    if (wanted.isEmpty) {
      return null;
    }
    for (final Category category in categories) {
      if (type != null && category.type != type) {
        continue;
      }
      if (areSimilarNames(wanted, normalizeAssistantName(category.name))) {
        return category;
      }
    }
    return null;
  }

  Wallet get defaultWallet {
    for (final Wallet wallet in wallets) {
      if (wallet.isDefault) {
        return wallet;
      }
    }
    return wallets.first;
  }
}
