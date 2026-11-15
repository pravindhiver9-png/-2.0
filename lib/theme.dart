import 'package:flutter/material.dart';

const green = Color(0xFF2F5D4A);
const greenLight = Color(0xFFD9EBDF);

ThemeData buildTheme(bool dark) {
  final bg = dark ? const Color(0xFF121212) : const Color(0xFFF0F5F2);
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(
        seedColor: green, brightness: dark ? Brightness.dark : Brightness.light, surface: bg),
    appBarTheme: AppBarTheme(backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0),
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF1A1A1A) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
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
    final base = color ?? (dark ? const Color(0xFF1C1C1C) : const Color(0xFFF7FAF8));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(color: dark ? Colors.black87 : const Color(0xFFBFCDC5), offset: const Offset(5, 5), blurRadius: 12),
            BoxShadow(color: dark ? const Color(0xFF2A2A2A) : Colors.white, offset: const Offset(-5, -5), blurRadius: 12),
          ],
        ),
        child: child,
      ),
    );
  }
}
