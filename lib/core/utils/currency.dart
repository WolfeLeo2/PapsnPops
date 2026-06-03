import 'package:intl/intl.dart';

class CurrencyHelper {
  static final _formatter = NumberFormat.currency(
    locale: 'en_KE',
    symbol: 'KES ',
    decimalDigits: 0,
  );

  static String format(int amountInCents) {
    return _formatter.format(amountInCents / 100.0);
  }
}
