abstract final class TransactionType {
  static const String expense = 'expense';
  static const String income = 'income';
}

abstract final class TransactionSource {
  static const String manual = 'manual';
  static const String notification = 'notification';
  static const String receipt = 'receipt';
  static const String voice = 'voice';
}
