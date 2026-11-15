import 'package:flutter/material.dart';
import 'db.dart';
import 'state.dart';
import 'theme.dart';
import 'dart:convert';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});
  @override
  State<MembersScreen> createState() => _MembersState();
}

class _MembersState extends State<MembersScreen> {
  List<Map<String, Object?>> rows = [];
  String q = '';

  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    final r = await DB.d.query('members', orderBy: 'created_at');
    if (mounted) setState(() => rows = r);
  }

  Future<void> form([Map<String, Object?>? m]) async {
    final n = TextEditingController(text: '${m?['name'] ?? ''}');
    final s = TextEditingController(text: '${m?['surname'] ?? ''}');
    final p = TextEditingController(text: '${m?['mobile'] ?? ''}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(app.t('add_member')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: n, decoration: InputDecoration(labelText: app.t('name'))),
          const SizedBox(height: 8),
          TextField(controller: s, decoration: InputDecoration(labelText: app.t('surname'))),
          const SizedBox(height: 8),
          TextField(controller: p, keyboardType: TextInputType.phone, maxLength: 10, decoration: InputDecoration(labelText: app.t('mobile'), counterText: '')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(app.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(app.t('save'))),
        ],
      ),
    );
    if (ok != true) return;
    void msg(String k) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.t(k)))); }
    if (n.text.trim().isEmpty || s.text.trim().isEmpty) { msg('name_req'); return; }
    final dup = await DB.d.rawQuery(
        'SELECT id FROM members WHERE lower(name)=? AND lower(surname)=? AND id<>?',
        [n.text.trim().toLowerCase(), s.text.trim().toLowerCase(), '${m?['id'] ?? ''}']);
    if (dup.isNotEmpty) { msg('dup_member'); return; }
    final v = {'name': n.text.trim(), 'surname': s.text.trim(), 'mobile': p.text.trim()};
    await DB.tx((t) async {
      if (m == null) {
        final id = DB.newId();
        await t.insert('members', {'id': id, ...v, 'created_at': DateTime.now().toIso8601String()});
        await DB.log(t, 'add', 'members', id, '${v['name']} ${v['surname']}');
      } else {
        await t.update('members', v, where: 'id=?', whereArgs: [m['id']]);
        await DB.log(t, 'edit', 'members', '${m['id']}', '${v['name']} ${v['surname']}');
      }
    });
    load();
  }

  Future<void> remove(Map<String, Object?> m) async {
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
      await t.delete('members', where: 'id=?', whereArgs: [m['id']]);
      await DB.log(t, 'delete', 'members', '${m['id']}', jsonEncode(m));
    });
    load();
  }

  @override
  Widget build(BuildContext context) {
    final list = rows.where((r) => ('${r['name']} ${r['surname']} ${r['mobile']}').toLowerCase().contains(q.toLowerCase())).toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: app.isAdmin ? FloatingActionButton(backgroundColor: green, onPressed: () => form(), child: const Icon(Icons.add, color: Colors.white)) : null,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(onChanged: (v) => setState(() => q = v), decoration: InputDecoration(hintText: app.t('search'), prefixIcon: const Icon(Icons.search))),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final m = list[i];
              return Neo(
                child: Row(children: [
                  CircleAvatar(backgroundColor: greenLight, child: Text('${i + 1}', style: const TextStyle(color: green))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${m['name']} ${m['surname']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    if ('${m['mobile']}'.isNotEmpty) Text('${m['mobile']}', style: const TextStyle(fontSize: 12)),
                  ])),
                  if (app.isAdmin) ...[
                    IconButton(icon: const Icon(Icons.edit, color: green), onPressed: () => form(m)),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => remove(m)),
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
