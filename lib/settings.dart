import 'package:flutter/material.dart';
import 'state.dart';
import 'theme.dart';
import 'util.dart';
import 'entries.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> editNum(BuildContext c, String key, String label, double cur) async {
    final r = await askFields(c, label, [F('v', label, amt(cur), type: 'num')]);
    if (r != null) await app.setNum(key, double.parse(r['v']!));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, __) => Scaffold(
          appBar: AppBar(title: Text(app.t('settings'))),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Neo(child: Column(children: [
              ListTile(
                title: Text(app.t('language')),
                trailing: SegmentedButton<String>(
                  segments: const [ButtonSegment(value: 'hi', label: Text('हिंदी')), ButtonSegment(value: 'en', label: Text('EN'))],
                  selected: {app.lang},
                  onSelectionChanged: (s) => app.setLang(s.first),
                ),
              ),
              SwitchListTile(title: Text(app.t('dark')), value: app.dark, onChanged: app.setDark),
            ])),
            const SizedBox(height: 16),
            Neo(child: Column(children: [
              ListTile(
                title: Text(app.t('rate_member')),
                trailing: Text('${amt(app.rateMember)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: app.isAdmin ? () => editNum(context, 'rate_member', app.t('rate_member'), app.rateMember) : null,
              ),
              ListTile(
                title: Text(app.t('rate_non')),
                trailing: Text('${amt(app.rateNon)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: app.isAdmin ? () => editNum(context, 'rate_non', app.t('rate_non'), app.rateNon) : null,
              ),
              ListTile(
                title: Text(app.t('dep_amount')),
                trailing: Text(rs(app.depAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: app.isAdmin ? () => editNum(context, 'dep_amount', app.t('dep_amount'), app.depAmount) : null,
              ),
              if (!app.isAdmin) Padding(padding: const EdgeInsets.all(8), child: Text(app.t('admin_only'), style: const TextStyle(fontSize: 12))),
            ])),
          ]),
        ),
      );
}
