import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'db.dart';
import 'interest.dart';
import 'state.dart';
import 'util.dart';

class Loans {
  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  /// member if name or mobile matches the member list
  static Rec? matchMember(List<Rec> members, String name, String mobile) {
    final n = _norm(name);
    for (final m in members) {
      final full = _norm('${m['name']} ${m['surname']}');
      if (n.isNotEmpty && full == n) return m;
      final mm = '${m['mobile'] ?? ''}'.trim();
      if (mobile.trim().isNotEmpty && mm.isNotEmpty && mm == mobile.trim()) return m;
    }
    return null;
  }

  static Future<void> addLoan(String name, String mobile, DateTime date, double principal) async {
    final members = await DB.d.query('members');
    final isM = matchMember(members, name, mobile) != null;
    final rate = isM ? app.rateMember : app.rateNon;
    final id = DB.newId();
    await DB.tx((t) async {
      await t.insert('loans', {
        'id': id, 'borrower': name.trim(), 'mobile': mobile.trim(), 'date': isoOf(date), 'principal': principal,
        'rate': rate, 'is_member': isM ? 1 : 0, 'auto': 0, 'status': 'active', 'rem_principal': 0, 'unpaid_int': 0,
      });
      await DB.log(t, 'add', 'loans', id, '${name.trim()} ${amt(principal)} @$rate%');
    });
  }

  static Future<void> _carry(Transaction t, Rec loan, DateTime date, double amount, String why) async {
    final id = DB.newId();
    await t.insert('loans', {
      'id': id, 'borrower': loan['borrower'], 'mobile': loan['mobile'], 'date': isoOf(date), 'principal': amount,
      'rate': loan['rate'], 'is_member': loan['is_member'], 'parent_id': loan['id'], 'auto': 1, 'status': 'active',
      'rem_principal': 0, 'unpaid_int': 0,
    });
    await DB.log(t, 'auto', 'loans', id, '$why from ${loan['id']} amount ${amt(amount)} date ${isoOf(date)}');
  }

  static Future<void> repay(Rec loan, DateTime pay, double expected, double fin, double ip, double pp) async {
    final id = loan['id'] as String;
    final grace = loan['status'] == 'grace';
    final p = ((grace ? loan['rem_principal'] : loan['principal']) as num).toDouble();
    final plan = planRepayment(
      grace: grace, principal: p, rate: (loan['rate'] as num).toDouble(), loanDate: DateTime.parse('${loan['date']}'),
      pay: pay, finalInt: fin, ip: ip, pp: pp, graceUnpaid: ((loan['unpaid_int'] ?? 0) as num).toDouble(),
    );
    final snap = jsonEncode({
      'status': loan['status'], 'rem_principal': loan['rem_principal'], 'unpaid_int': loan['unpaid_int'], 'grace_end': loan['grace_end'],
    });
    await DB.tx((t) async {
      final rid = DB.newId();
      await t.insert('repayments', {
        'id': rid, 'loan_id': id, 'pay_date': isoOf(pay), 'expected_interest': expected, 'final_interest': fin,
        'interest_paid': ip, 'principal_paid': pp, 'auto': 0, 'prev_state': snap,
      });
      await DB.log(t, 'add', 'repayments', rid, '${loan['borrower']} int ${amt(ip)} prin ${amt(pp)} plan ${plan.kind}');
      switch (plan.kind) {
        case 'paid':
          await t.update('loans', {'status': 'paid', 'rem_principal': 0, 'unpaid_int': 0}, where: 'id=?', whereArgs: [id]);
          break;
        case 'carry':
          await _carry(t, loan, plan.date!, plan.amt, 'carry-forward');
          await t.update('loans', {'status': 'rolled', 'rem_principal': 0, 'unpaid_int': 0}, where: 'id=?', whereArgs: [id]);
          break;
        default:
          await t.update('loans', {
            'status': 'grace', 'rem_principal': plan.amt, 'unpaid_int': plan.unpaid,
            if (plan.date != null) 'grace_end': isoOf(plan.date!),
          }, where: 'id=?', whereArgs: [id]);
      }
    });
  }

  /// After the 15-day grace ends, unpaid interest (and remaining principal) becomes a new loan entry.
  static Future<void> processGrace() async {
    final today = isoOf(DateTime.now());
    final rows = await DB.d.query('loans', where: "status='grace' AND grace_end IS NOT NULL AND grace_end < ?", whereArgs: [today]);
    if (rows.isEmpty) return;
    await DB.tx((t) async {
      for (final l in rows) {
        final total = ((l['rem_principal'] ?? 0) as num).toDouble() + ((l['unpaid_int'] ?? 0) as num).toDouble();
        if (total > 0.5) {
          final d = DateTime.parse('${l['grace_end']}').add(const Duration(days: 1));
          await _carry(t, l, d, total, 'grace-ended');
          await t.update('loans', {'status': 'rolled', 'rem_principal': 0, 'unpaid_int': 0}, where: 'id=?', whereArgs: [l['id']]);
        } else {
          await t.update('loans', {'status': 'paid'}, where: 'id=?', whereArgs: [l['id']]);
        }
      }
    });
  }

  /// returns an error string key, or null on success
  static Future<String?> deleteRepayment(Rec r) async {
    final loanId = r['loan_id'] as String;
    final kids = await DB.d.query('loans', where: 'parent_id=?', whereArgs: [loanId]);
    if (kids.isNotEmpty) return 'has_children';
    final latest = await DB.d.rawQuery('SELECT id FROM repayments WHERE loan_id=? ORDER BY rowid DESC LIMIT 1', [loanId]);
    if (latest.isEmpty || latest.first['id'] != r['id']) return 'not_latest';
    Map<String, dynamic> snap = {'status': 'active', 'rem_principal': 0, 'unpaid_int': 0, 'grace_end': null};
    if (r['prev_state'] != null) snap = jsonDecode('${r['prev_state']}') as Map<String, dynamic>;
    await DB.tx((t) async {
      await t.delete('repayments', where: 'id=?', whereArgs: [r['id']]);
      await t.update('loans', {
        'status': snap['status'] ?? 'active', 'rem_principal': snap['rem_principal'] ?? 0,
        'unpaid_int': snap['unpaid_int'] ?? 0, 'grace_end': snap['grace_end'],
      }, where: 'id=?', whereArgs: [loanId]);
      await DB.log(t, 'delete', 'repayments', '${r['id']}', jsonEncode(r));
    });
    return null;
  }

  static Future<String?> deleteLoan(Rec l) async {
    final id = l['id'] as String;
    final reps = await DB.d.query('repayments', where: 'loan_id=?', whereArgs: [id]);
    if (reps.isNotEmpty) return 'has_repay';
    final kids = await DB.d.query('loans', where: 'parent_id=?', whereArgs: [id]);
    if (kids.isNotEmpty) return 'has_children';
    await DB.tx((t) async {
      await t.delete('loans', where: 'id=?', whereArgs: [id]);
      if (l['parent_id'] != null) {
        await t.update('loans', {'status': 'paid'}, where: "id=? AND status='rolled'", whereArgs: [l['parent_id']]);
      }
      await DB.log(t, 'delete', 'loans', id, jsonEncode(l));
    });
    return null;
  }

  static Future<bool> editable(Rec l) async {
    final id = l['id'] as String;
    final a = await DB.d.query('repayments', where: 'loan_id=?', whereArgs: [id]);
    final b = await DB.d.query('loans', where: 'parent_id=?', whereArgs: [id]);
    return a.isEmpty && b.isEmpty;
  }
}
