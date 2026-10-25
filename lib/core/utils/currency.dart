import 'package:intl/intl.dart';

final NumberFormat _rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

String formatRupiah(int amount) => _rupiahFormat.format(amount);

String formatRupiahDigits(int amount) {
  return _rupiahFormat.format(amount).replaceFirst('Rp', '').trim();
}
