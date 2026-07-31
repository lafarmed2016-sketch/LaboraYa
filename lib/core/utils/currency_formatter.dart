/// Formateador de moneda centralizado para PEN (Soles)
class CurrencyFormatter {
  static const String symbol = 'S/';
  static const String code = 'PEN';

  static String format(double? amount) {
    if (amount == null) return 'A convenir';
    if (amount == amount.roundToDouble()) {
      return '$symbol ${amount.toInt()}';
    }
    return '$symbol ${amount.toStringAsFixed(2)}';
  }

  static String formatRange(double? min, double? max) {
    if (min != null && max != null && min != max) {
      return '$symbol ${min.toInt()} - ${max.toInt()}';
    }
    if (min != null) return format(min);
    if (max != null) return format(max);
    return 'A convenir';
  }
}
