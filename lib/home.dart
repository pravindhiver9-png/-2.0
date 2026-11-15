import 'package:flutter/material.dart';
import 'util.dart';
import 'entries.dart';
import 'settings.dart';
import 'db.dart';
import 'state.dart';
import 'theme.dart';
import 'members.dart';
import 'loans.dart';
import 'loan_screens.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int i = 0;

  void open(String k) {
    final nav = Navigator.of(context);
    switch (k) {
      case 'q_member':
        setState(() => i = 1);
        break;
      case 'q_deposit': nav.push(MaterialPageRoute(builder: (_) => const DepositForm())); break;
      case 'q_loan': nav.push(MaterialPageRoute(builder: (_) => const LoanForm())); break;
      case 'q_repay': nav.push(MaterialPageRoute(builder: (_) => const RepayForm())); break;
      case 'q_expense': addExpense(context); break;
      case 'q_extra': addExtra(context); break;
      default: ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.t('soon'))));
    }
  }

  void gear() => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, __) {
          final pages = <Widget>[
            Dashboard(onQuick: open, onGear: gear),
            Column(children: [AppHeader(onGear: gear), const Expanded(child: MembersScreen())]),
            Column(children: [AppHeader(onGear: gear), const Expanded(child: TxnHub())]),
            Center(child: Text(app.t('soon'))),
          ];
          return Scaffold(
            body: SafeArea(child: pages[i]),
            bottomNavigationBar: SafeArea(
              child: FloatBar(
                index: i,
                onTap: (v) => setState(() => i = v),
                items: [
                  (Icons.home_rounded, app.t('home')),
                  (Icons.groups_rounded, app.t('members')),
                  (Icons.account_balance_wallet_rounded, app.t('txn')),
                  (Icons.description_rounded, app.t('stmt')),
                ],
              ),
            ),
          );
        },
      );
}

class Dashboard extends StatefulWidget {
  final void Function(String) onQuick;
  final VoidCallback onGear;
  const Dashboard({super.key, required this.onQuick, required this.onGear});
  @override
  State<Dashboard> createState() => _DashState();
}

class _DashState extends State<Dashboard> {
  Map<String, double> d = {};
  List<Map<String, Object?>> rec = [];

  @override
  void initState() { super.initState(); load(); DB.tick.addListener(load); }
  @override
  void dispose() { DB.tick.removeListener(load); super.dispose(); }
  Future<void> load() async {
    await Loans.processGrace();
    final a = await DB.dashboard();
    final b = await DB.recent();
    if (mounted) setState(() { d = a; rec = b; });
  }

  Widget stat(IconData ic, String label, num v) => Expanded(
        child: Neo(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(children: [
            Icon(ic, color: green, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(rs(v), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5)),
              ]),
            ),
          ]),
        ),
      );

  Widget quick(IconData ic, String k) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 84,
          child: Neo(
            onTap: () => widget.onQuick(k),
            radius: 20,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(ic, color: green, size: 28),
              const SizedBox(height: 6),
              Text(app.t(k), textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 11.5, height: 1.15)),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    const g = SizedBox(height: 12);
    const w = SizedBox(width: 12);
    IconData icon(String k) => k == 'deposit' ? Icons.savings : k == 'loan' ? Icons.volunteer_activism : k == 'repay' ? Icons.published_with_changes : Icons.receipt_long;
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(padding: const EdgeInsets.only(bottom: 12), children: [
        AppHeader(onGear: widget.onGear),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GreenBanner(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(children: [
              const Icon(Icons.groups, color: Colors.white, size: 40),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${(d['members'] ?? 0).toInt()}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.1)),
                Text(app.t('total_members'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
              Container(width: 1, height: 48, color: Colors.white38, margin: const EdgeInsets.symmetric(horizontal: 10)),
              const Icon(Icons.handshake, color: Colors.white, size: 40),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(rs(d['loan'] ?? 0), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.15))),
                Text(app.t('loan_given'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
            ]),
          ),
        ),
        g,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            Row(children: [stat(Icons.savings, app.t('total_deposit'), d['deposit'] ?? 0), w, stat(Icons.percent, app.t('interest_recv'), d['interest'] ?? 0)]),
            g,
            Row(children: [stat(Icons.schedule, app.t('outstanding'), d['outstanding'] ?? 0), w, stat(Icons.account_balance_wallet, app.t('cash'), d['cash'] ?? 0)]),
            g,
            Row(children: [stat(Icons.receipt_long, app.t('expenses'), d['expenses'] ?? 0), w, stat(Icons.add_card, app.t('additional'), d['extra'] ?? 0)]),
          ]),
        ),
        g,
        if (app.isAdmin)
          SizedBox(
            height: 104,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 4, 14),
              children: [
                quick(Icons.add_circle, 'q_loan'),
                quick(Icons.savings, 'q_deposit'),
                quick(Icons.published_with_changes, 'q_repay'),
                quick(Icons.receipt, 'q_expense'),
                quick(Icons.add_card, 'q_extra'),
                quick(Icons.person_add, 'q_member'),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Neo(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(app.t('recent'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const Divider(height: 18),
              if (rec.isEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(app.t('no_data'))),
              for (final r in rec)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: greenLight, child: Icon(icon('${r['k']}'), color: green)),
                  title: Text('${r['n']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${rs(r['a'] as num)} • ${dmy('${r['dt']}')}'),
                  trailing: Chip(label: Text(app.t('a_${r['k']}'), style: const TextStyle(fontSize: 11, color: green)), backgroundColor: greenLight, side: BorderSide.none),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}
