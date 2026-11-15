import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'strings.dart';

class AppState extends ChangeNotifier {
  late SharedPreferences p;
  String lang = 'hi';
  bool dark = false;
  String? role; // admin1, admin2, member
  int _fails = 0;

  bool get isAdmin => role == 'admin1' || role == 'admin2';
  bool get setupDone => p.getString('h_admin1') != null;
  String get groupId => p.getString('group_id') ?? 'HCFF2022025';
  String t(String k) => tr(lang, k);

  Future<void> init() async {
    p = await SharedPreferences.getInstance();
    lang = p.getString('lang') ?? 'hi';
    dark = p.getBool('dark') ?? false;
  }

  double get rateMember => p.getDouble('rate_member') ?? 2;
  double get rateNon => p.getDouble('rate_non') ?? 5;
  double get depAmount => p.getDouble('dep_amount') ?? 200;
  Future<void> setNum(String k, double v) async { await p.setDouble(k, v); notifyListeners(); }

  void setLang(String l) { lang = l; p.setString('lang', l); notifyListeners(); }
  void setDark(bool v) { dark = v; p.setBool('dark', v); notifyListeners(); }

  String _salt() {
    var s = p.getString('salt');
    if (s == null) {
      final r = Random.secure();
      s = List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      p.setString('salt', s);
    }
    return s;
  }

  String _hash(String pin) => sha256.convert(utf8.encode('${_salt()}:$pin')).toString();

  Future<void> setPin(String key, String pin) => p.setString('h_$key', _hash(pin));

  /// returns role or null; sets lockout after 5 wrong tries
  String? login(String pin) {
    final until = p.getInt('lock_until') ?? 0;
    if (DateTime.now().millisecondsSinceEpoch < until) return 'LOCKED';
    for (final k in ['admin1', 'admin2', 'member']) {
      if (p.getString('h_$k') == _hash(pin)) {
        _fails = 0;
        role = k;
        notifyListeners();
        return k;
      }
    }
    _fails++;
    if (_fails >= 5) {
      _fails = 0;
      p.setInt('lock_until', DateTime.now().add(const Duration(seconds: 60)).millisecondsSinceEpoch);
      return 'LOCKED';
    }
    return null;
  }

  void lock() { role = null; notifyListeners(); }
}

final app = AppState();
