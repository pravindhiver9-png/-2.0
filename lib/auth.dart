import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'state.dart';
import 'theme.dart';
import 'home.dart';

Widget pinField(TextEditingController c, String label) => TextField(
      controller: c,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, counterText: ''),
    );

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupState();
}

class _SetupState extends State<SetupScreen> {
  final a = TextEditingController(), m = TextEditingController();
  String? err;

  Future<void> go() async {
    if (a.text.length != 6 || m.text.length != 6) { setState(() => err = app.t('pin_6')); return; }
    await app.setPin('admin1', a.text);
    await app.setPin('member', m.text);
    app.login(a.text);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const SizedBox(height: 24),
            Center(child: Image.asset('assets/logo.png', width: 100, height: 100)),
            const SizedBox(height: 12),
            Center(child: Text(app.t('app'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: green))),
            const SizedBox(height: 8),
            Center(child: Text('${app.t('group_id')}: ${app.groupId}')),
            const SizedBox(height: 24),
            Text(app.t('setup_title'), style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            pinField(a, app.t('admin_pin')),
            const SizedBox(height: 12),
            pinField(m, app.t('member_pin')),
            if (err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(err!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 20),
            FilledButton(onPressed: go, child: Text(app.t('create'))),
          ]),
        ),
      );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final c = TextEditingController();
  String? err;

  void go() {
    final r = app.login(c.text);
    if (r == null) { setState(() => err = app.t('wrong_pin')); c.clear(); return; }
    if (r == 'LOCKED') { setState(() => err = app.t('locked')); c.clear(); return; }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset('assets/logo.png', width: 110, height: 110),
              const SizedBox(height: 12),
              Text(app.t('app'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: green)),
              const SizedBox(height: 4),
              Text(app.groupId, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 28),
              pinField(c, app.t('pin')),
              if (err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(err!, style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: go, child: Text(app.t('login')))),
            ]),
          ),
        ),
      );
}
