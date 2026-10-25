import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home.dart';
import 'screens/splash.dart';
import 'store.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  store.load();
  runApp(ElagyApp(store: store));
}

class ElagyApp extends StatefulWidget {
  final AppStore store;
  const ElagyApp({super.key, required this.store});

  @override
  State<ElagyApp> createState() => _ElagyAppState();
}

class _ElagyAppState extends State<ElagyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final systemDark = WidgetsBinding
                .instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
        final dark = store.themeMode == 'dark' ||
            (store.themeMode == 'system' && systemDark);
        final arabic = store.lang != 'en';
        final theme = buildTheme(dark: dark, arabic: arabic);
        return StoreScope(
          store: store,
          child: MaterialApp(
            // Rebuild the whole tree when language/theme change so every
            // screen picks up the new strings and colors.
            key: ValueKey('${store.lang}-$dark'),
            title: arabic ? 'علاجي' : 'Elagy',
            debugShowCheckedModeBanner: false,
            theme: theme,
            locale: arabic ? const Locale('ar', 'EG') : const Locale('en'),
            supportedLocales: const [Locale('ar', 'EG'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: store.splashShown
                ? const HomeScreen()
                : const SplashScreen(),
          ),
        );
      },
    );
  }
}
