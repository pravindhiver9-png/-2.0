import 'package:flutter/material.dart';
import 'db.dart';
import 'state.dart';
import 'theme.dart';
import 'auth.dart';
import 'loans.dart';

final navKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.init();
  await DB.init();
  await Loans.processGrace();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // lock when app goes to background; PIN asked on reopen
    if (s == AppLifecycleState.paused && app.role != null) {
      app.lock();
      navKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, __) => MaterialApp(
          navigatorKey: navKey,
          debugShowCheckedModeBanner: false,
          title: app.t('app'),
          theme: buildTheme(false),
          darkTheme: buildTheme(true),
          themeMode: app.dark ? ThemeMode.dark : ThemeMode.light,
          home: app.setupDone ? const LoginScreen() : const SetupScreen(),
        ),
      );
}
