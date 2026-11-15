import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'state.dart';

const green = Color(0xFF2F5D4A);
const greenDark = Color(0xFF1F4535);
const greenLight = Color(0xFFD9EBDF);

ThemeData buildTheme(bool dark) {
  final bg = dark ? const Color(0xFF121212) : const Color(0xFFEEF4F0);
  final base = ThemeData(brightness: dark ? Brightness.dark : Brightness.light);
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: bg,
    textTheme: GoogleFonts.hindTextTheme(base.textTheme),
    colorScheme: ColorScheme.fromSeed(seedColor: green, brightness: dark ? Brightness.dark : Brightness.light, surface: bg),
    appBarTheme: AppBarTheme(backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF1A1A1A) : const Color(0xFFF8FBF9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: dark ? Colors.white12 : const Color(0xFFD5E0D9))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: dark ? Colors.white12 : const Color(0xFFD5E0D9))),
    ),
  );
}

class Neo extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  const Neo({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap, this.color, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = color ?? (dark ? const Color(0xFF1C1C1C) : const Color(0xFFF8FBF9));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(color: dark ? Colors.black87 : const Color(0xFFA9BDB1), offset: const Offset(6, 6), blurRadius: 14),
            BoxShadow(color: dark ? const Color(0xFF2A2A2A) : Colors.white, offset: const Offset(-6, -6), blurRadius: 14),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _Wave extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = Colors.white.withOpacity(0.07);
    final a = Path()
      ..moveTo(0, s.height * .65)
      ..quadraticBezierTo(s.width * .25, s.height * .35, s.width * .5, s.height * .65)
      ..quadraticBezierTo(s.width * .75, s.height * .95, s.width, s.height * .6)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(a, p);
  }
  @override
  bool shouldRepaint(_) => false;
}

/// Green banner with soft wave texture.
class GreenBanner extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const GreenBanner({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: const BoxDecoration(color: green, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(4, 6))]),
          child: CustomPaint(painter: _Wave(), child: Padding(padding: padding, child: child)),
        ),
      );
}

Widget logo(double s) => Image.asset('assets/logo.png', width: s, height: s);

class AppHeader extends StatelessWidget {
  final VoidCallback? onGear;
  const AppHeader({super.key, this.onGear});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(children: [
          Expanded(
            child: Neo(
              radius: 40,
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(children: [
                logo(46),
                Container(width: 1, height: 36, margin: const EdgeInsets.symmetric(horizontal: 10), color: Colors.black26),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(app.t('app'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: green)),
                  Text(app.t('tagline'), style: const TextStyle(fontSize: 11, color: green)),
                ])),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          Neo(padding: const EdgeInsets.all(12), radius: 16, onTap: onGear, child: const Icon(Icons.settings, color: green)),
        ]),
      );
}

class TitleBanner extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  const TitleBanner({super.key, required this.icon, required this.title, required this.sub});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GreenBanner(
          child: Row(children: [
            Icon(icon, color: Colors.white, size: 44),
            Container(width: 1, height: 44, margin: const EdgeInsets.symmetric(horizontal: 14), color: Colors.white38),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          ]),
        ),
      );
}

class FooterNote extends StatelessWidget {
  const FooterNote({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          const Icon(Icons.groups, color: green, size: 20),
          Text('—  ${app.t('footer')}  —', style: const TextStyle(fontSize: 12, color: green, fontWeight: FontWeight.w600)),
        ]),
      );
}

class FloatBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<(IconData, String)> items;
  const FloatBar({super.key, required this.index, required this.onTap, required this.items});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Neo(
          radius: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                      decoration: BoxDecoration(color: i == index ? green : Colors.transparent, borderRadius: BorderRadius.circular(22)),
                      child: Icon(items[i].$1, color: i == index ? Colors.white : green, size: 24),
                    ),
                    const SizedBox(height: 2),
                    Text(items[i].$2, style: TextStyle(fontSize: 11, fontWeight: i == index ? FontWeight.bold : FontWeight.normal, color: green)),
                  ]),
                ),
              ),
          ]),
        ),
      );
}
