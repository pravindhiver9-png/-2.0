import 'package:flutter/material.dart';
import 'util.dart';
import 'entries.dart';
import 'settings.dart';
import 'db.dart';
import 'state.dart';
import 'theme.dart';
import 'members.dart';

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
      case 'q_member': nav.push(MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: Text(app.t('members'))), body: const MembersScreen()))); break;
      case 'q_deposit': nav.push(MaterialPageRoute(builder: (_) => const DepositForm())); break;
      case 'q_expense': addExpense(context); break;
      case 'q_extra': addExtra(context); break;
      default: ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.t('soon'))));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, __) {
          final pages = [
            Dashboard(onQuick: open, onSettings: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
            const MembersScreen(),
            const TxnHub(),
            Center(child: Text(app.t('soon'))),
          ];
          return Scaffold(
            body: SafeArea(child: pages[i]),
            bottomNavigationBar: NavigationBar(
              selectedIndex: i,
              onDestinationSelected: (v) => setState(() => i = v),
              destinations: [
                NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: app.t('home')),
                NavigationDestination(icon: const Icon(Icons.groups_outlined), selectedIcon: const Icon(Icons.groups), label: app.t('members')),
                NavigationDestination(icon: const Icon(Icons.account_balance_wallet_outlined), selectedIcon: const Icon(Icons.account_balance_wallet), label: app.t('txn')),
                NavigationDestination(icon: const Icon(Icons.description_outlined), selectedIcon: const Icon(Icons.description), label: app.t('stmt')),
              ],
            ),
          );
        },
      );
}

class Dashboard extends StatefulWidget {
  final void Function(String) onQuick;
  final VoidCallback onSettings;
  const Dashboard({super.key, required this.onQuick, required this.onSettings});
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
    final a = await DB.dashboard();
    final b = await DB.recent();
    if (mounted) setState(() { d = a; rec = b; });
  }

  Widget stat(IconData ic, String label, num v, {bool count = false}) => Expanded(
        child: Neo(
          child: Row(children: [
            Icon(ic, color: green, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FittedBox(child: Text(count ? '${v.toInt()}' : rs(v), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Text(label, style: const TextStyle(fontSize: 12)),
              ]),
            ),
          ]),
        ),
      );

  Widget quick(IconData ic, String k) => Expanded(
        child: Neo(
          onTap: () => widget.onQuick(k),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(children: [
            Icon(ic, color: green, size: 28),
            const SizedBox(height: 6),
            Text(app.t(k), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    const g = SizedBox(height: 12);
    const w = SizedBox(width: 12);
    IconData icon(String k) => k == 'deposit' ? Icons.savings : k == 'loan' ? Icons.volunteer_activism : Icons.receipt_long;
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Neo(padding: const EdgeInsets.all(4), radius: 40, child: Image.asset('assets/logo.png', width: 52, height: 52)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(app.t('app'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Text(app.t('est'), style: const TextStyle(fontSize: 11)),
            ]),
          ),
          Neo(padding: const EdgeInsets.all(8), radius: 14, onTap: widget.onSettings, child: const Icon(Icons.settings, color: green)),
        ]),
        g,
        // banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(4, 6))]),
          child: Row(children: [
            const Icon(Icons.groups, color: Colors.white, size: 36),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${(d['members'] ?? 0).toInt()}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              Text(app.t('total_members'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(child: Text(rs(d['loan'] ?? 0), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
              Text(app.t('loan_given'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          ]),
        ),
        g,
        Row(children: [stat(Icons.savings, app.t('total_deposit'), d['deposit'] ?? 0), w, stat(Icons.percent, app.t('interest_recv'), d['interest'] ?? 0)]),
        g,
        Row(children: [stat(Icons.schedule, app.t('outstanding'), d['outstanding'] ?? 0), w, stat(Icons.account_balance_wallet, app.t('cash'), d['cash'] ?? 0)]),
        g,
        Row(children: [stat(Icons.receipt_long, app.t('expenses'), d['expenses'] ?? 0), w, stat(Icons.add_card, app.t('additional'), d['extra'] ?? 0)]),
        g,
        if (app.isAdmin) ...[
          Row(children: [quick(Icons.person_add, 'q_member'), w, quick(Icons.savings, 'q_deposit'), w, quick(Icons.add_circle, 'q_loan')]),
          g,
          Row(children: [quick(Icons.published_with_changes, 'q_repay'), w, quick(Icons.receipt, 'q_expense'), w, quick(Icons.add_card, 'q_extra')]),
          g,
        ],
        Neo(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(app.t('recent'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (rec.isEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(app.t('no_data'))),
            for (final r in rec)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundColor: greenLight, child: Icon(icon('${r['k']}'), color: green)),
                title: Text('${r['n']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${rs(r['a'] as num)} • ${dmy('${r['dt']}')}'),
                trailing: Chip(label: Text(app.t('a_${r['k']}'), style: const TextStyle(fontSize: 11, color: green)), backgroundColor: greenLight, side: BorderSide.none),
              ),
          ]),
        ),
      ]),
    );
  }
}

