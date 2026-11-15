import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'db.dart';
import 'entries.dart';
import 'forms.dart';
import 'interest.dart';
import 'loans.dart';
import 'state.dart';
import 'theme.dart';
import 'util.dart';

Widget lf(IconData ic, String label, {required Widget child, bool req = false}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(radius: 12, backgroundColor: green, child: Icon(ic, size: 13, color: Colors.white)),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
        if (req) const Text(' *', style: TextStyle(color: Colors.red)),
      ]),
      const SizedBox(height: 6),
      child,
    ]);

Widget ro(TextEditingController c) => TextField(controller: c, readOnly: true, decoration: const InputDecoration(fillColor: Color(0xFFE6ECE8)));

Widget two(Widget a, Widget? b) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b ?? const SizedBox())]),
    );

Widget formChrome(BuildContext c, IconData ic, String title, List<Widget> body, String btn, VoidCallback onSave, {String? err}) => Scaffold(
      body: SafeArea(
        child: ListView(children: [
          AppHeader(onGear: () => Navigator.maybePop(c)),
          TitleBanner(icon: ic, title: title, sub: app.t('fill_info')),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Neo(padding: const EdgeInsets.all(16), radius: 26, child: Column(children: [
              ...body,
              if (err != null) Text(err, style: const TextStyle(color: Colors.red)),
            ])),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 54,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: greenDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                onPressed: onSave,
                icon: const Icon(Icons.visibility),
                label: Text(btn, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const FooterNote(),
        ]),
      ),
    );

Future<bool> confirmDel(BuildContext c) async =>
    await showDialog<bool>(
      context: c,
      builder: (d) => AlertDialog(
        content: Text(app.t('confirm_delete')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(app.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(app.t('delete'))),
        ],
      ),
    ) ??
    false;

// ================= NEW LOAN =================
class LoanForm extends StatefulWidget {
  const LoanForm({super.key});
  @override
  State<LoanForm> createState() => _LoanFormState();
}

class _LoanFormState extends State<LoanForm> {
  List<Rec> members = [];
  final known = <String, String>{};
  String name = '';
  final mobileC = TextEditingController();
  final dateC = TextEditingController(text: dmyDate(DateTime.now()));
  final prinC = TextEditingController();
  String? err;
  Rec? member;

  @override
  void initState() {
    super.initState();
    () async {
      final ls = await DB.d.rawQuery('SELECT borrower, mobile FROM loans ORDER BY date ASC');
      final ms = await DB.d.query('members');
      for (final l in ls) { known['${l['borrower']}'] = '${l['mobile']}'; }
      for (final m in ms) {
        final n = '${m['name']} ${m['surname']}'.trim();
        final mob = '${m['mobile'] ?? ''}';
        if (mob.isNotEmpty || !known.containsKey(n)) known[n] = mob;
      }
      if (mounted) setState(() => members = ms);
    }();
  }

  void detect() => setState(() => member = Loans.matchMember(members, name, mobileC.text));

  Future<void> save() async {
    final n = name.trim(), mob = mobileC.text.trim();
    final date = parseDmy(dateC.text.trim());
    final p = double.tryParse(prinC.text.trim());
    if (n.isEmpty) { setState(() => err = app.t('required')); return; }
    if (!RegExp(r'^\d{10}$').hasMatch(mob)) { setState(() => err = app.t('bad_mobile')); return; }
    if (date == null || p == null || p <= 0) { setState(() => err = app.t('bad_amt')); return; }
    final dup = await DB.d.query('loans', where: 'borrower=? AND date=? AND principal=? AND auto=0', whereArgs: [n, isoOf(date), p]);
    if (dup.isNotEmpty) { setState(() => err = app.t('dup_loan')); return; }
    if (!mounted) return;
    final r = await previewDialog(context, 'दिनाँक ${dotDate(dmyDate(date))}\n\n*$n* को ₹${amt(p)} दिया।');
    if (r == null) return;
    await Loans.addLoan(n, mob, date, p);
    if (!mounted) return;
    Navigator.pop(context);
    if (r.$2) Share.share(r.$1);
  }

  @override
  Widget build(BuildContext context) {
    final isM = member != null;
    final rate = isM ? app.rateMember : app.rateNon;
    return formChrome(
      context, Icons.add_circle, app.t('loan_title'),
      [
        lf(Icons.person, app.t('borrower'), req: true,
            child: Autocomplete<String>(
              optionsBuilder: (v) => v.text.isEmpty ? const Iterable<String>.empty() : known.keys.where((k) => smartMatch(k, v.text)).take(6),
              onSelected: (s) {
                name = s;
                final m = known[s] ?? '';
                if (m.isNotEmpty) mobileC.text = m;
                detect();
              },
              fieldViewBuilder: (c, ctrl, fn, _) => TextField(controller: ctrl, focusNode: fn, onChanged: (v) { name = v; detect(); }),
            )),
        const SizedBox(height: 14),
        two(
          lf(Icons.phone, app.t('mobile_req'), req: true,
              child: TextField(controller: mobileC, keyboardType: TextInputType.phone, maxLength: 10, onChanged: (_) => detect(), decoration: const InputDecoration(counterText: ''))),
          lf(Icons.calendar_month, app.t('loan_date'), req: true,
              child: TextField(
                controller: dateC,
                readOnly: true,
                decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today, size: 18, color: green)),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: parseDmy(dateC.text) ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (d != null) setState(() => dateC.text = dmyDate(d));
                },
              )),
        ),
        two(
          lf(Icons.currency_rupee, app.t('principal'), req: true,
              child: TextField(controller: prinC, keyboardType: TextInputType.number)),
          lf(Icons.percent, app.t('rate'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: greenLight, borderRadius: BorderRadius.circular(16)),
                child: Text('${isM ? app.t('member_tag') : app.t('nonmember_tag')} • ${amt(rate)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: green)),
              )),
        ),
      ],
      app.t('preview'), save, err: err,
    );
  }
}

// ================= REPAYMENT =================
class RepayForm extends StatefulWidget {
  final String? loanId;
  const RepayForm({super.key, this.loanId});
  @override
  State<RepayForm> createState() => _RepayFormState();
}

class _RepayFormState extends State<RepayForm> {
  List<Rec> open = [];
  String? borrower;
  Rec? loan;
  final mobileC = TextEditingController(), prinC = TextEditingController(), rateC = TextEditingController(), expC = TextEditingController();
  final finC = TextEditingController(), ipC = TextEditingController(), ppC = TextEditingController(text: '0'), totalC = TextEditingController();
  final dateC = TextEditingController(text: dmyDate(DateTime.now()));
  Plan? plan;
  String? err;
  double expected = 0;

  @override
  void initState() {
    super.initState();
    DB.d.query('loans', where: "status IN ('active','grace')", orderBy: 'date ASC').then((r) {
      if (!mounted) return;
      setState(() => open = r);
      if (widget.loanId != null) {
        final l = r.where((x) => x['id'] == widget.loanId).toList();
        if (l.isNotEmpty) { borrower = '${l.first['borrower']}'; pick(l.first); }
      }
    });
  }

  bool get grace => loan?['status'] == 'grace';
  double get P => loan == null ? 0 : ((grace ? loan!['rem_principal'] : loan!['principal']) as num).toDouble();
  double num_(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;
  DateTime get payDate => parseDmy(dateC.text) ?? DateTime.now();

  void pick(Rec l) {
    loan = l;
    mobileC.text = '${l['mobile']}';
    prinC.text = amt(P);
    rateC.text = '${amt((l['rate'] as num).toDouble())}%';
    recompute();
  }

  void recompute() {
    if (loan == null) return;
    final rate = (loan!['rate'] as num).toDouble();
    expected = grace ? ((loan!['unpaid_int'] ?? 0) as num).toDouble() : expectedInterest(P, rate, DateTime.parse('${loan!['date']}'), payDate);
    expC.text = amt(expected);
    finC.text = amt(expected);
    ipC.text = amt(expected);
    ppC.text = '0';
    calc();
  }

  void calc() {
    if (loan == null) return;
    final ip = num_(ipC), pp = num_(ppC);
    totalC.text = amt(ip + pp);
    setState(() {
      plan = planRepayment(
        grace: grace, principal: P, rate: (loan!['rate'] as num).toDouble(), loanDate: DateTime.parse('${loan!['date']}'),
        pay: payDate, finalInt: num_(finC), ip: ip, pp: pp, graceUnpaid: ((loan!['unpaid_int'] ?? 0) as num).toDouble(),
      );
    });
  }

  String outcome() {
    final p = plan;
    if (p == null) return '';
    if (p.kind == 'paid') return app.t('out_paid');
    if (p.kind == 'carry') return '${app.t('out_carry')}: ${dmyDate(p.date!)} • ${rs(p.amt)}';
    return p.date == null ? app.t('out_grace_stay') : app.t('out_grace');
  }

  Future<void> save() async {
    if (loan == null) { setState(() => err = app.t('pick_loan')); return; }
    final fin = num_(finC), ip = num_(ipC), pp = num_(ppC);
    if (fin < 0 || ip < 0 || pp < 0 || ip + pp <= 0 || pp > P + 0.5) { setState(() => err = app.t('bad_pay')); return; }
    final pay = parseDmy(dateC.text.trim());
    if (pay == null) { setState(() => err = app.t('required')); return; }
    final ld = DateTime.parse('${loan!['date']}');
    final msg = 'दिनाँक ${dotDate(dmyDate(pay))}\n\n*${loan!['borrower']}*\n'
        '• ऋण दिनांक: ${dotDate(dmyDate(ld))} (अवधि: ${periodText(ld, pay)}, ब्याज दर: ${amt((loan!['rate'] as num).toDouble())}%)\n'
        '• मूलधन जमा: ₹${amt(pp)}\n• ब्याज जमा: ₹${amt(ip)}\n• कुल जमा राशि: ₹${amt(ip + pp)}';
    final r = await previewDialog(context, msg);
    if (r == null) return;
    await Loans.repay(loan!, pay, expected, fin, ip, pp);
    if (!mounted) return;
    Navigator.pop(context);
    if (r.$2) Share.share(r.$1);
  }

  @override
  Widget build(BuildContext context) {
    final borrowers = open.map((l) => '${l['borrower']}').toSet().toList();
    final loans = open.where((l) => '${l['borrower']}' == borrower).toList();
    return formChrome(
      context, Icons.published_with_changes, app.t('repay_title'),
      [
        if (open.isEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(app.t('no_loans'))),
        two(
          lf(Icons.person, app.t('borrower'), req: true,
              child: DropdownButtonFormField<String>(
                value: borrower,
                isExpanded: true,
                hint: Text(app.t('pick_borrower')),
                items: [for (final b in borrowers) DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis))],
                onChanged: (v) {
                  setState(() { borrower = v; loan = null; plan = null; });
                  final ls = open.where((l) => '${l['borrower']}' == v).toList();
                  if (ls.length == 1) { setState(() => pick(ls.first)); }
                },
              )),
          lf(Icons.phone, app.t('mobile_req'), child: ro(mobileC)),
        ),
        two(
          lf(Icons.calendar_month, app.t('loan_date'), req: true,
              child: DropdownButtonFormField<String>(
                value: loan?['id'] as String?,
                isExpanded: true,
                hint: Text(app.t('pick_loan')),
                items: [
                  for (final l in loans)
                    DropdownMenuItem(
                      value: l['id'] as String,
                      child: Text('${dmy('${l['date']}')} • ${rs(((l['status'] == 'grace' ? l['rem_principal'] : l['principal']) as num))}', overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => pick(loans.firstWhere((l) => l['id'] == v))),
              )),
          lf(Icons.currency_rupee, app.t('principal'), child: ro(prinC)),
        ),
        two(
          lf(Icons.percent, app.t('rate'), child: ro(rateC)),
          lf(Icons.calendar_today, app.t('pay_date'), req: true,
              child: TextField(
                controller: dateC,
                readOnly: true,
                decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today, size: 18, color: green)),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: payDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (d != null) { dateC.text = dmyDate(d); recompute(); }
                },
              )),
        ),
        two(
          lf(Icons.calculate, app.t('expected_int'), child: ro(expC)),
          lf(Icons.edit, app.t('final_int'), req: true, child: TextField(controller: finC, keyboardType: TextInputType.number, onChanged: (_) => calc())),
        ),
        two(
          lf(Icons.volunteer_activism, app.t('int_paid'), req: true, child: TextField(controller: ipC, keyboardType: TextInputType.number, onChanged: (_) => calc())),
          lf(Icons.savings, app.t('prin_paid'), req: true, child: TextField(controller: ppC, keyboardType: TextInputType.number, onChanged: (_) => calc())),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: greenLight, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(app.t('total_paid'), style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(rs(num_(ipC) + num_(ppC)), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            if (plan != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('${app.t('status')}: ${outcome()}', style: const TextStyle(fontSize: 12.5, color: green))),
          ]),
        ),
        const SizedBox(height: 8),
      ],
      app.t('preview'), save, err: err,
    );
  }
}

// ================= LISTS =================
String stLabel(String s) => app.t(s == 'active' ? 'st_active' : s == 'grace' ? 'st_grace' : s == 'paid' ? 'st_paid' : 'st_rolled');
Color stColor(String s) => s == 'active' ? green : s == 'grace' ? Colors.orange.shade800 : s == 'paid' ? Colors.red.shade700 : Colors.blueGrey;

class LoanList extends StatefulWidget {
  const LoanList({super.key});
  @override
  State<LoanList> createState() => _LoanListState();
}

class _LoanListState extends State<LoanList> {
  List<Rec> rows = [];
  String f = 'all', q = '';
  @override
  void initState() { super.initState(); go(); DB.tick.addListener(go); }
  @override
  void dispose() { DB.tick.removeListener(go); super.dispose(); }
  Future<void> go() async {
    final r = await DB.d.query('loans', orderBy: 'date DESC, rowid DESC');
    if (mounted) setState(() => rows = r);
  }

  double shown(Rec l) => l['status'] == 'grace' ? ((l['rem_principal'] ?? 0) as num).toDouble() + ((l['unpaid_int'] ?? 0) as num).toDouble() : (l['principal'] as num).toDouble();

  Future<void> edit(Rec l) async {
    final free = await Loans.editable(l);
    if (!mounted) return;
    if (!free) toast(context, 'loan_edit_limit');
    final v = await askFields(context, app.t('loan_title'), [
      F('m', app.t('mobile_req'), '${l['mobile']}', icon: Icons.phone),
      if (free) F('d', app.t('loan_date'), dmy('${l['date']}'), type: 'date', icon: Icons.calendar_month),
      if (free) F('p', app.t('principal'), amt(l['principal'] as num), type: 'num', icon: Icons.currency_rupee),
      if (free) F('r', app.t('rate'), amt(l['rate'] as num), type: 'num', icon: Icons.percent),
    ], icon: Icons.add_circle);
    if (v == null) return;
    final row = <String, Object?>{'mobile': v['m']};
    if (free) {
      row['date'] = isoOf(parseDmy(v['d']!)!);
      row['principal'] = double.parse(v['p']!);
      row['rate'] = double.parse(v['r']!);
    }
    await DB.tx((t) async {
      await t.update('loans', row, where: 'id=?', whereArgs: [l['id']]);
      await DB.log(t, 'edit', 'loans', '${l['id']}', 'new=$row');
    });
  }

  Future<void> del(Rec l) async {
    if (!await confirmDel(context)) return;
    final e = await Loans.deleteLoan(l);
    if (e != null && mounted) toast(context, e);
  }

  @override
  Widget build(BuildContext context) {
    final list = rows.where((l) {
      final s = '${l['status']}';
      final okF = f == 'all' || (f == 'active' && (s == 'active' || s == 'grace')) || (f == 'paid' && s == 'paid');
      return okF && smartMatch('${l['borrower']} ${l['mobile']}', q);
    }).toList();
    final total = list.fold<double>(0, (a, l) => a + (l['status'] == 'active' || l['status'] == 'grace' ? shown(l) : 0));
    return Scaffold(
      appBar: AppBar(title: Text(app.t('loan_list'))),
      floatingActionButton: app.isAdmin
          ? FloatingActionButton(backgroundColor: green, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoanForm())), child: const Icon(Icons.add, color: Colors.white))
          : null,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(onChanged: (v) => setState(() => q = v), decoration: InputDecoration(hintText: app.t('search'), prefixIcon: const Icon(Icons.search))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            for (final e in [('all', 'f_all'), ('active', 'st_active'), ('paid', 'st_paid')])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: Text(app.t(e.$2)), selected: f == e.$1, selectedColor: greenLight, onSelected: (_) => setState(() => f = e.$1)),
              ),
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
                    final l = list[i];
                    final s = '${l['status']}';
                    final active = s == 'active';
                    final extra = active
                        ? ' • ${app.t('expected_int')} ${rs(expectedInterest((l['principal'] as num).toDouble(), (l['rate'] as num).toDouble(), DateTime.parse('${l['date']}'), DateTime.now()))}'
                        : '';
                    return Neo(
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${l['borrower']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          Text('${dmy('${l['date']}')} • ${amt((l['rate'] as num).toDouble())}% • ${l['is_member'] == 1 ? app.t('member_tag') : app.t('nonmember_tag')}${l['auto'] == 1 ? ' • AUTO' : ''}', style: const TextStyle(fontSize: 11.5)),
                          if (extra.isNotEmpty) Text(extra.substring(3), style: const TextStyle(fontSize: 11.5, color: green)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(color: stColor(s).withOpacity(0.14), borderRadius: BorderRadius.circular(12)),
                            child: Text(stLabel(s), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: stColor(s))),
                          ),
                        ])),
                        Text(rs(shown(l)), style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (app.isAdmin) ...[
                          IconButton(icon: const Icon(Icons.edit, color: green, size: 20), onPressed: () => edit(l)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => del(l)),
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

class RepayList extends StatelessWidget {
  const RepayList({super.key});
  @override
  Widget build(BuildContext context) => RecordList(
        title: app.t('repay_list'),
        table: 'repayments',
        load: () => DB.d.rawQuery('SELECT r.*, l.borrower, l.date ld, l.rate FROM repayments r JOIN loans l ON l.id=r.loan_id ORDER BY r.pay_date DESC, r.rowid DESC'),
        head: (r) => '${r['borrower']}',
        sub: (r) => '${dmy('${r['pay_date']}')} • ${app.t('int_paid')} ${rs(r['interest_paid'] as num)} • ${app.t('prin_paid')} ${rs(r['principal_paid'] as num)}',
        searchText: (r) => '${r['borrower']} ${dmy('${r['pay_date']}')}',
        amount: (r) => (r['interest_paid'] as num) + (r['principal_paid'] as num),
        onAdd: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RepayForm())),
        onDelete: (r) async {
          if (!await confirmDel(context)) return;
          final e = await Loans.deleteRepayment(r);
          if (e != null && context.mounted) toast(context, e);
        },
        onEdit: (r) async {
          if (!await confirmDel(context)) return;
          final e = await Loans.deleteRepayment(r);
          if (!context.mounted) return;
          if (e != null) { toast(context, e); return; }
          Navigator.push(context, MaterialPageRoute(builder: (_) => RepayForm(loanId: r['loan_id'] as String)));
        },
      );
}
