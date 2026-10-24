import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/database/app_database.dart';
import 'core/database/database_provider.dart';
import 'features/capture/capture_sync_service.dart';

final GoRouter _appRouter = createAppRouter();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  Intl.defaultLocale = 'id_ID';

  final AppDatabase database = AppDatabase();
  await database.seedDefaults();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const SimpenWoiApp(),
    ),
  );
}

class SimpenWoiApp extends ConsumerStatefulWidget {
  const SimpenWoiApp({super.key});

  @override
  ConsumerState<SimpenWoiApp> createState() => _SimpenWoiAppState();
}

class _SimpenWoiAppState extends ConsumerState<SimpenWoiApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((Duration timeStamp) {
      _syncCaptures();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncCaptures();
    }
  }

  Future<void> _syncCaptures() async {
    try {
      await ref.read(captureSyncServiceProvider).sync();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'simpenWoi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _appRouter,
      locale: const Locale('id', 'ID'),
      supportedLocales: const <Locale>[
        Locale('id', 'ID'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
