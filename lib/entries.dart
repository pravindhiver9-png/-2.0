import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'db.dart';
import 'state.dart';
import 'theme.dart';
import 'util.dart';

typedef Rec = Map<String, Object?>;

// ---------- generic helpers ----------
class F {
  final String k, label, init, type; // type: text | num | date
  F(this.k, this.label, this.init, {this.type = 'text'});
}

Future<Map<String, String>?> askFields(BuildContext c, String title, List<F> fs) {
  final ctr = {for (final f in fs) f.k: TextEditingController(text: f.init)};
  String? err;
  return showDialog<Map<String, String>>(
    context: c,
    builder: (dc) => StatefulBuilder(
      builder: (dc, set) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final f in fs)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: ctr[f.k],
                  readOnly: f.type == 'date',
                  keyboardType: f.type == 'num' ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                  decoration: InputDecoration(labelText: f.label, suffixIcon: f.type == 'date' ? const Icon(Icons.calendar_today, size: 18) : null),
                  onTap: f.type != 'date'
                      ? null
                      : () async {
                          final d = await showDatePicker(
                              context: dc,
                              initialDate: parseDmy(ctr[f.k]!.text) ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100));
                          if (d != null) ctr[f.k]!.text = dmyDate(d);
                        },
                ),
              ),
            if (err != null) Text(err!, style: const TextStyle(color: Colors.red)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dc), child: Text(app.t('cancel'))),
          FilledButton(
            onPressed: () {
              final out = <String, String>{};
              for (final f in fs) {
                final v = ctr[f.k]!.text.trim();
                if (v.isEmpty) { set(() => err = app.t('required')); return; }
                if (f.type == 'num') {
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) { set(() => err = app.t('bad_amt')); return; }
                }
                if (f.type == 'date' && parseDmy(v) == null) { set(() => err = app.t('required')); return; }
                out[f.k] = v;
              }
              Navigator.pop(dc, out);
            },
            child: Text(app.t('save')),
          ),
        ],
      ),
    ),
  );
}

/// Editable preview. returns null = cancel, (text, share?)
Future<(String, bool)?> previewDialog(BuildContext c, String msg) {
  final t = TextEditingController(text: msg);
  return showDialog<(String, bool)>(
    context: c,
    builder: (dc) => AlertDialog(
      title: Text(app.t('preview')),
      content: TextField(controller: t, maxLines: 10, minLines: 4),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dc), child: Text(app.t('cancel'))),
        OutlinedButton(onPressed: () => Navigator.pop(dc, (t.text, false)), child: Text(app.t('save_only'))),
        FilledButton(onPressed: () => Navigator.pop(dc, (t.text, true)), child: Text(app.t('save_wa'))),
      ],
    ),
  );
}

void toast(BuildContext c, String k) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(app.t(k))));

String dotDate(String dmySlash) => dmySlash.replaceAll('/', '.');

// ---------- generic list ----------
class RecordList extends StatefulWidget {
  final String title, table;
  final Future<List<Rec>> Function() load;
  final String Function(Rec) head, sub, searchText;
  final num Function(Rec) amount;
  final Future<void> Function()? onAdd;
  final Future<void> Function(Rec)? onEdit;
  const RecordList({super.key, required this.title, required this.table, required this.load, required this.head,
      required this.sub, required this.searchText, required this.amount, this.onAdd, this.onEdit});
  @override
  State<RecordList> createState() => _RecordListState();
}

class _RecordListState extends State<RecordList> {
  List<Rec> rows = [];
  String q = '';
  @override
  void initState() { super.initState(); go(); DB.tick.addListener(go); }
  @override
  void dispose() { DB.tick.removeListener(go); super.dispose(); }
  Future<void> go() async {
    final r = await widget.load();
    if (mounted) setState(() => rows = r);
  }

  Future<void> del(Rec r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(app.t('confirm_delete')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(app.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(app.t('delete'))),
        ],
      ),
    );
    if (ok != true) return;
    await DB.tx((t) async {
      await t.delete(widget.table, where: 'id=?', whereArgs: [r['id']]);
      await DB.log(t, 'delete', widget.table, '${r['id']}', jsonEncode(r));
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = rows.where((r) => widget.searchText(r).toLowerCase().contains(q.toLowerCase())).toList();
    final total = list.fold<double>(0, (a, r) => a + widget.amount(r));
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: app.isAdmin && widget.onAdd != null
          ? FloatingActionButton(backgroundColor: green, onPressed: widget.onAdd, child: const Icon(Icons.add, color: Colors.white))
          : null,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(onChanged: (v) => setState(() => q = v), decoration: InputDecoration(hintText: app.t('search'), prefixIcon: const Icon(Icons.search))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text('${list.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(rs(total), style: const TextStyle(fontWeight: FontWeight.bold, color: green)),
          ]),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(child: Text(app.t('no_data')))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final r = list[i];
                    return Neo(
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(widget.head(r), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          Text(widget.sub(r), style: const TextStyle(fontSize: 12)),
                        ])),
                        Text(rs(widget.amount(r)), style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (app.isAdmin) ...[
                          if (widget.onEdit != null) IconButton(icon: const Icon(Icons.edit, color: green, size: 20), onPressed: () => widget.onEdit!(r)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => del(r)),
                        ],
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

// ---------- hub ----------
class TxnHub extends StatelessWidget {
  const TxnHub({super.key});
  @override
  Widget build(BuildContext context) {
    Widget tile(IconData ic, String k, Widget? page) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Neo(
            onTap: () => page == null ? toast(context, 'soon') : Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
            child: Row(children: [
              Icon(ic, color: green),
              const SizedBox(width: 14),
              Expanded(child: Text(app.t(k), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
              const Icon(Icons.chevron_right),
            ]),
          ),
        );
    return ListView(padding: const EdgeInsets.all(16), children: [
      tile(Icons.savings, 'deposit_list', const DepositList()),
      tile(Icons.receipt_long, 'expense_list', const ExpenseList()),
      tile(Icons.add_card, 'extra_list', const ExtraList()),
      tile(Icons.volunteer_activism, 'loan_list', null),
      tile(Icons.published_with_changes, 'repay_list', null),
    ]);
  }
}

// ---------- deposits ----------
class DepositList extends StatelessWidget {
  const DepositList({super.key});
  @override
  Widget build(BuildContext context) => RecordList(
        title: app.t('deposit_list'),
        table: 'deposits',
        load: () => DB.d.rawQuery(
            "SELECT x.*, COALESCE(m.name||' '||m.surname,'?') n FROM deposits x LEFT JOIN members m ON m.id=x.member_id ORDER BY x.date DESC, x.rowid DESC"),
        head: (r) => '${r['n']}',
        sub: (r) => '${dmy('${r['date']}')} • ${monthLabel('${r['for_month']}')}',
        searchText: (r) => '${r['n']} ${r['for_month']} ${dmy('${r['date']}')}',
        amount: (r) => r['amount'] as num,
        onAdd: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DepositForm())),
        onEdit: (r) async {
          final v = await askFields(context, '${r['n']}', [
            F('a', app.t('amount'), amt(r['amount'] as num), type: 'num'),
            F('d', app.t('date'), dmy('${r['date']}'), type: 'date'),
          ]);
          if (v == null) return;
          await DB.tx((t) async {
            await t.update('deposits', {'amount': double.parse(v['a']!), 'date': isoOf(parseDmy(v['d']!)!)}, where: 'id=?', whereArgs: [r['id']]);
            await DB.log(t, 'edit', 'deposits', '${r['id']}', 'old=${r['amount']} ${r['date']} new=${v['a']} ${v['d']}');
          });
        },
      );
}

class DepositForm extends StatefulWidget {
  const DepositForm({super.key});
  @override
  State<DepositForm> createState() => _DepositFormState();
}

class _DepositFormState extends State<DepositForm> {
  List<Rec> members = [];
  final cur = <String>{}, prev = <String>{};
  late final TextEditingController amountC = TextEditingController(text: amt(app.depAmount));
  late final TextEditingController dateC = TextEditingController(text: dmyDate(DateTime.now()));

  @override
  void initState() {
    super.initState();
    DB.d.query('members', orderBy: 'created_at').then((r) { if (mounted) setState(() => members = r); });
  }

  String name(Rec m) => '${m['name']} ${m['surname']}'.trim();

  Future<void> save() async {
    final a = double.tryParse(amountC.text.trim());
    final date = parseDmy(dateC.text.trim());
    if (a == null || a <= 0 || date == null) { toast(context, 'bad_amt'); return; }
    final sel = members.where((m) => cur.contains(m['id']) || prev.contains(m['id'])).toList();
    if (sel.isEmpty) { toast(context, 'pick_member'); return; }
    final cm = monthKey(date), pm = prevMonthKey(date);
    // duplicate check
    final dups = <String>[];
    for (final m in sel) {
      for (final k in [if (cur.contains(m['id'])) cm, if (prev.contains(m['id'])) pm]) {
        final e = await DB.d.query('deposits', where: 'member_id=? AND for_month=?', whereArgs: [m['id'], k]);
        if (e.isNotEmpty) dups.add('${name(m)} (${monthLabel(k)})');
      }
    }
    if (dups.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${app.t('dup_deposit')} ${dups.join(', ')}')));
      return;
    }
    final lines = <String>[];
    for (final m in sel) {
      final c = cur.contains(m['id']);
      final p = prev.contains(m['id']);
      final a0 = '₹${amt(a)}';
      lines.add(c && p
          ? '${name(m)} $a0 जमा + पिछले माह का $a0 जमा'
          : c ? '${name(m)} $a0 जमा' : '${name(m)} पिछले माह का $a0 जमा');
    }
    final msg = 'दिनांक ${dmyDate(date)}\n\n${lines.join('\n\n')}';
    final r = await previewDialog(context, msg);
    if (r == null) return;
    await DB.tx((t) async {
      for (final m in sel) {
        for (final k in [if (cur.contains(m['id'])) cm, if (prev.contains(m['id'])) pm]) {
          final id = DB.newId();
          await t.insert('deposits', {'id': id, 'member_id': m['id'], 'amount': a, 'date': isoOf(date), 'for_month': k, 'note': ''});
          await DB.log(t, 'add', 'deposits', id, '${name(m)} ${amt(a)} $k');
        }
      }
    });
    if (!mounted) return;
    Navigator.pop(context);
    if (r.$2) Share.share(r.$1);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(app.t('deposit_title'))),
        body: members.isEmpty
            ? Center(child: Text(app.t('no_members')))
            : Column(children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Expanded(child: TextField(controller: amountC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: app.t('amount')))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: dateC,
                        readOnly: true,
                        decoration: InputDecoration(labelText: app.t('date'), suffixIcon: const Icon(Icons.calendar_today, size: 18)),
                        onTap: () async {
                          final d = await showDatePicker(context: context, initialDate: parseDmy(dateC.text) ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                          if (d != null) setState(() => dateC.text = dmyDate(d));
                        },
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    const Spacer(),
                    SizedBox(width: 78, child: Text(app.t('current_m'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                    SizedBox(width: 78, child: Text(app.t('prev_m'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                  ]),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: members.length,
                    itemBuilder: (_, i) {
                      final m = members[i];
                      final id = m['id'] as String;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Neo(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Row(children: [
                            Expanded(child: Text(name(m), style: const TextStyle(fontWeight: FontWeight.w600))),
                            SizedBox(width: 78, child: Checkbox(value: cur.contains(id), activeColor: green, onChanged: (v) => setState(() => v! ? cur.add(id) : cur.remove(id)))),
                            SizedBox(width: 78, child: Checkbox(value: prev.contains(id), activeColor: green, onChanged: (v) => setState(() => v! ? prev.add(id) : prev.remove(id)))),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(width: double.infinity, child: FilledButton(onPressed: save, child: Text(app.t('preview')))),
                ),
              ]),
      );
}

// ---------- expenses ----------
Future<void> addExpense(BuildContext c, [Rec? r]) async {
  final v = await askFields(c, app.t('expense_title'), [
    F('n', app.t('expense_name'), '${r?['name'] ?? ''}'),
    F('a', app.t('amount'), r == null ? '' : amt(r['amount'] as num), type: 'num'),
    F('d', app.t('date'), r == null ? dmyDate(DateTime.now()) : dmy('${r['date']}'), type: 'date'),
  ]);
  if (v == null || !c.mounted) return;
  final date = parseDmy(v['d']!)!, a = double.parse(v['a']!);
  bool share = false;
  String text = '';
  if (r == null) {
    final p = await previewDialog(c, 'दिनांक ${dotDate(v['d']!)}\n\n*${v['n']}* पर ₹${amt(a)} खर्च।');
    if (p == null) return;
    share = p.$2;
    text = p.$1;
  }
  await DB.tx((t) async {
    final row = {'name': v['n'], 'amount': a, 'date': isoOf(date)};
    if (r == null) {
      final id = DB.newId();
      await t.insert('expenses', {'id': id, ...row});
      await DB.log(t, 'add', 'expenses', id, '${v['n']} ${amt(a)}');
    } else {
      await t.update('expenses', row, where: 'id=?', whereArgs: [r['id']]);
      await DB.log(t, 'edit', 'expenses', '${r['id']}', 'old=${jsonEncode(r)} new=${jsonEncode(row)}');
    }
  });
  if (share) Share.share(text);
}

class ExpenseList extends StatelessWidget {
  const ExpenseList({super.key});
  @override
  Widget build(BuildContext context) => RecordList(
        title: app.t('expense_list'),
        table: 'expenses',
        load: () => DB.d.query('expenses', orderBy: 'date DESC, rowid DESC'),
        head: (r) => '${r['name']}',
        sub: (r) => dmy('${r['date']}'),
        searchText: (r) => '${r['name']} ${dmy('${r['date']}')}',
        amount: (r) => r['amount'] as num,
        onAdd: () => addExpense(context),
        onEdit: (r) => addExpense(context, r),
      );
}

// ---------- additional amount ----------
Future<void> addExtra(BuildContext c, [Rec? r]) async {
  final v = await askFields(c, app.t('extra_title'), [
    F('a', app.t('amount'), r == null ? '' : amt(r['amount'] as num), type: 'num'),
    F('d', app.t('date'), r == null ? dmyDate(DateTime.now()) : dmy('${r['date']}'), type: 'date'),
  ]);
  if (v == null) return;
  final row = {'amount': double.parse(v['a']!), 'date': isoOf(parseDmy(v['d']!)!)};
  await DB.tx((t) async {
    if (r == null) {
      final id = DB.newId();
      await t.insert('extras', {'id': id, ...row});
      await DB.log(t, 'add', 'extras', id, v['a']!);
    } else {
      await t.update('extras', row, where: 'id=?', whereArgs: [r['id']]);
      await DB.log(t, 'edit', 'extras', '${r['id']}', 'old=${jsonEncode(r)} new=${jsonEncode(row)}');
    }
  });
}

class ExtraList extends StatelessWidget {
  const ExtraList({super.key});
  @override
  Widget build(BuildContext context) => RecordList(
        title: app.t('extra_list'),
        table: 'extras',
        load: () => DB.d.query('extras', orderBy: 'date DESC, rowid DESC'),
        head: (r) => app.t('extra_title'),
        sub: (r) => dmy('${r['date']}'),
        searchText: (r) => '${r['amount']} ${dmy('${r['date']}')}',
        amount: (r) => r['amount'] as num,
        onAdd: () => addExtra(context),
        onEdit: (r) => addExtra(context, r),
      );
}
