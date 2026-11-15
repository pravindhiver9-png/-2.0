import 'package:intl/intl.dart';
import 'state.dart';

String rs(num v) => NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(v);
String dmy(String iso) {
  final p = iso.split('-');
  return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
}
String dmyDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
String isoOf(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
DateTime? parseDmy(String s) {
  try { return DateFormat('dd/MM/yyyy').parseStrict(s); } catch (_) { return null; }
}
String monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);
String prevMonthKey(DateTime d) => monthKey(DateTime(d.year, d.month - 1, 1));
String monthLabel(String key) {
  final p = key.split('-');
  if (p.length != 2) return key;
  final names = app.t('months').split(',');
  return '${names[int.parse(p[1]) - 1]} ${p[0]}';
}
String amt(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
