import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return newValue;
    }

    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      final int index = digitsOnly.length - 1 - i;
      if (i > 0 && i % 3 == 0) {
        formatted = '.$formatted';
      }
      formatted = digitsOnly[index] + formatted;
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

int parseCurrencyInput(String value) {
  return int.tryParse(value.replaceAll('.', '').trim()) ?? 0;
}
