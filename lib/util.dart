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

const _cons = {'क':'k','ख':'kh','ग':'g','घ':'gh','ङ':'n','च':'ch','छ':'chh','ज':'j','झ':'jh','ञ':'n','ट':'t','ठ':'th','ड':'d','ढ':'dh','ण':'n','त':'t','थ':'th','द':'d','ध':'dh','न':'n','प':'p','फ':'f','ब':'b','भ':'bh','म':'m','य':'y','र':'r','ल':'l','व':'v','श':'sh','ष':'sh','स':'s','ह':'h'};
const _vow = {'अ':'a','आ':'a','इ':'i','ई':'i','उ':'u','ऊ':'u','ए':'e','ऐ':'ai','ओ':'o','औ':'au','ऋ':'ri'};
const _sign = {'ा':'a','ि':'i','ी':'i','ु':'u','ू':'u','े':'e','ै':'ai','ो':'o','ौ':'au','ं':'n','ँ':'n','ः':'h'};

/// rough Devanagari -> Latin, used only for search matching
String roman(String s) {
  final b = StringBuffer();
  final r = s.runes.map(String.fromCharCode).toList();
  for (var i = 0; i < r.length; i++) {
    final c = r[i];
    if (_cons.containsKey(c)) {
      b.write(_cons[c]);
      final nx = i + 1 < r.length ? r[i + 1] : '';
      if (nx == '़') { i++; continue; }
      if (_sign.containsKey(nx)) continue;
      if (nx == '्') { i++; continue; }
      b.write('a');
    } else if (_sign.containsKey(c)) {
      b.write(_sign[c]);
    } else if (_vow.containsKey(c)) {
      b.write(_vow[c]);
    } else if (c != '़' && c != '्') {
      b.write(c.toLowerCase());
    }
  }
  return b.toString();
}

String _skel(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '').replaceAll(RegExp(r'[aeiou]'), '');

/// case-insensitive contains; also lets English letters match Hindi names (e.g. "shiv" -> शिव)
bool smartMatch(String hay, String q) {
  q = q.trim();
  if (q.isEmpty) return true;
  if (hay.toLowerCase().contains(q.toLowerCase())) return true;
  if (RegExp(r'^[A-Za-z ]+$').hasMatch(q)) {
    final rh = roman(hay);
    if (rh.contains(q.toLowerCase())) return true;
    final sq = _skel(q);
    return sq.isNotEmpty && _skel(rh).contains(sq);
  }
  return false;
}
