import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

typedef Rec = Map<String, Object?>;

class DB {
  static late Database d;
  static final _r = Random();
  static final tick = ValueNotifier<int>(0);
  static Future<void> tx(Future<void> Function(Transaction t) f) async {
    await d.transaction(f);
    tick.value++;
  }
  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch}${_r.nextInt(1 << 32).toRadixString(16)}';

  static Future<void> init() async {
    d = await openDatabase(join(await getDatabasesPath(), 'hcff.db'), version: 2,
        onUpgrade: (db, o, n) async {
      if (o < 2) {
        for (final q in [
          "ALTER TABLE loans ADD COLUMN status TEXT DEFAULT 'active'",
          'ALTER TABLE loans ADD COLUMN grace_end TEXT',
          'ALTER TABLE loans ADD COLUMN rem_principal REAL DEFAULT 0',
          'ALTER TABLE loans ADD COLUMN unpaid_int REAL DEFAULT 0',
          'ALTER TABLE repayments ADD COLUMN expected_interest REAL DEFAULT 0',
          'ALTER TABLE repayments ADD COLUMN prev_state TEXT',
        ]) { await db.execute(q); }
      }
    },
        onCreate: (db, v) async {
      await db.execute('CREATE TABLE members(id TEXT PRIMARY KEY,name TEXT,surname TEXT,mobile TEXT,created_at TEXT)');
      await db.execute('CREATE TABLE deposits(id TEXT PRIMARY KEY,member_id TEXT,amount REAL,date TEXT,for_month TEXT,note TEXT)');
      await db.execute('CREATE TABLE loans(id TEXT PRIMARY KEY,borrower TEXT,mobile TEXT,date TEXT,principal REAL,rate REAL,is_member INTEGER,parent_id TEXT,auto INTEGER DEFAULT 0,status TEXT DEFAULT \'active\',grace_end TEXT,rem_principal REAL DEFAULT 0,unpaid_int REAL DEFAULT 0)');
      await db.execute('CREATE TABLE repayments(id TEXT PRIMARY KEY,loan_id TEXT,pay_date TEXT,final_interest REAL,interest_paid REAL,principal_paid REAL,auto INTEGER DEFAULT 0,expected_interest REAL DEFAULT 0,prev_state TEXT)');
      await db.execute('CREATE TABLE expenses(id TEXT PRIMARY KEY,name TEXT,amount REAL,date TEXT)');
      await db.execute('CREATE TABLE extras(id TEXT PRIMARY KEY,amount REAL,date TEXT)');
      await db.execute('CREATE TABLE audit(id INTEGER PRIMARY KEY AUTOINCREMENT,ts TEXT,action TEXT,tbl TEXT,rec_id TEXT,detail TEXT)');
    });
  }

  static Future<void> log(DatabaseExecutor x, String action, String tbl, String id, String detail) =>
      x.insert('audit', {'ts': DateTime.now().toIso8601String(), 'action': action, 'tbl': tbl, 'rec_id': id, 'detail': detail});

  static Future<double> sum(String sql) async {
    final r = await d.rawQuery(sql);
    final v = r.first.values.first;
    return v == null ? 0 : (v as num).toDouble();
  }

  static Future<Map<String, double>> dashboard() async {
    final members = await sum('SELECT COUNT(*) FROM members');
    final dep = await sum('SELECT SUM(amount) FROM deposits');
    final loan = await sum('SELECT SUM(principal) FROM loans WHERE auto=0');
    final intr = await sum('SELECT SUM(interest_paid) FROM repayments');
    final pp = await sum('SELECT SUM(principal_paid) FROM repayments');
    final exp = await sum('SELECT SUM(amount) FROM expenses');
    final extra = await sum('SELECT SUM(amount) FROM extras');
    final outA = await sum("SELECT SUM(principal) FROM loans WHERE status='active'");
    final outG = await sum("SELECT SUM(rem_principal+unpaid_int) FROM loans WHERE status='grace'");
    return {
      'members': members, 'deposit': dep, 'loan': loan, 'interest': intr,
      'outstanding': outA + outG, 'expenses': exp, 'extra': extra,
      'cash': dep + intr + pp + extra - loan - exp,
    };
  }

  static Future<List<Rec>> recent() => d.rawQuery('''
    SELECT 'deposit' k, x.amount a, x.date dt, m.name||' '||m.surname n FROM deposits x JOIN members m ON m.id=x.member_id
    UNION ALL SELECT 'loan', principal, date, borrower FROM loans WHERE auto=0
    UNION ALL SELECT 'repay', r.interest_paid+r.principal_paid, r.pay_date, l.borrower FROM repayments r JOIN loans l ON l.id=r.loan_id
    UNION ALL SELECT 'expense', amount, date, name FROM expenses
    ORDER BY dt DESC LIMIT 5''');
}
