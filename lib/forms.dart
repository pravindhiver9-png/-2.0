import 'package:flutter/material.dart';
import 'state.dart';
import 'theme.dart';
import 'util.dart';

class F {
  final String k, label, init, type; // type: text | num | date
  final IconData icon;
  final bool req;
  F(this.k, this.label, this.init, {this.type = 'text', this.icon = Icons.edit_note, this.req = true});
}

Future<Map<String, String>?> askFields(BuildContext c, String title, List<F> fs,
        {IconData icon = Icons.savings, VoidCallback? onList}) =>
    Navigator.of(c).push<Map<String, String>>(MaterialPageRoute(builder: (_) => FormPage(title: title, fs: fs, icon: icon, onList: onList)));

class FormPage extends StatefulWidget {
  final String title;
  final List<F> fs;
  final IconData icon;
  final VoidCallback? onList;
  const FormPage({super.key, required this.title, required this.fs, required this.icon, this.onList});
  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  late final Map<String, TextEditingController> ctr = {for (final f in widget.fs) f.k: TextEditingController(text: f.init)};
  String? err;

  void save() {
    final out = <String, String>{};
    for (final f in widget.fs) {
      final v = ctr[f.k]!.text.trim();
      if (v.isEmpty) {
        if (f.req) { setState(() => err = app.t('required')); return; }
        out[f.k] = '';
        continue;
      }
      if (f.type == 'num') {
        final n = double.tryParse(v);
        if (n == null || n <= 0) { setState(() => err = app.t('bad_amt')); return; }
      }
      if (f.type == 'date' && parseDmy(v) == null) { setState(() => err = app.t('required')); return; }
      out[f.k] = v;
    }
    Navigator.pop(context, out);
  }

  Widget field(F f) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 13, backgroundColor: green, child: Icon(f.icon, size: 14, color: Colors.white)),
          const SizedBox(width: 6),
          Expanded(child: Text(f.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
          if (f.req) const Text(' *', style: TextStyle(color: Colors.red)),
        ]),
        const SizedBox(height: 6),
        TextField(
          controller: ctr[f.k],
          readOnly: f.type == 'date',
          keyboardType: f.type == 'num' ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          decoration: InputDecoration(suffixIcon: f.type == 'date' ? const Icon(Icons.calendar_today, size: 18, color: green) : null),
          onTap: f.type != 'date'
              ? null
              : () async {
                  final d = await showDatePicker(
                      context: context, initialDate: parseDmy(ctr[f.k]!.text) ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (d != null) setState(() => ctr[f.k]!.text = dmyDate(d));
                },
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    final fs = widget.fs;
    for (var i = 0; i < fs.length; i += 2) {
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: field(fs[i])),
          const SizedBox(width: 12),
          Expanded(child: i + 1 < fs.length ? field(fs[i + 1]) : const SizedBox()),
        ]),
      ));
    }
    return Scaffold(
      body: SafeArea(
        child: ListView(children: [
          AppHeader(onGear: () => Navigator.maybePop(context)),
          TitleBanner(icon: widget.icon, title: widget.title, sub: app.t('fill_info')),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Neo(padding: const EdgeInsets.all(16), radius: 26, child: Column(children: [
              ...rows,
              if (err != null) Text(err!, style: const TextStyle(color: Colors.red)),
            ])),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 54,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: greenDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                onPressed: save,
                icon: const Icon(Icons.save),
                label: Text(app.t('save'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: Neo(
                  radius: 18,
                  onTap: () => setState(() { for (final f in widget.fs) { ctr[f.k]!.text = f.init; } err = null; }),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.refresh, color: green),
                    const SizedBox(width: 8),
                    Text(app.t('reset'), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
              if (widget.onList != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Neo(
                    radius: 18,
                    onTap: widget.onList,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.description, color: green),
                      const SizedBox(width: 8),
                      Flexible(child: Text(app.t('all_details'), style: const TextStyle(fontWeight: FontWeight.w700))),
                    ]),
                  ),
                ),
              ],
            ]),
          ),
          const FooterNote(),
        ]),
      ),
    );
  }
}
