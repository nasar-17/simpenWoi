import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../features/capture/presentation/providers/capture_providers.dart';
import 'router.dart';
import 'theme.dart';

final GoRouter _appRouter = createAppRouter();

class SimpenWoiApp extends ConsumerStatefulWidget {
  const SimpenWoiApp({super.key});

  @override
  ConsumerState<SimpenWoiApp> createState() => _SimpenWoiAppState();
}

class _SimpenWoiAppState extends ConsumerState<SimpenWoiApp>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _captureEvents;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _captureEvents = ref.read(nativeCaptureBridgeProvider).captureEvents.listen(
      (void _) {
        _syncCaptures();
      },
      onError: (Object _) {},
    );
    WidgetsBinding.instance.addPostFrameCallback((Duration timeStamp) {
      _syncCaptures();
    });
  }

  @override
  void dispose() {
    _captureEvents?.cancel();
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
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _appRouter,
      locale: const Locale('id', 'ID'),
      supportedLocales: const <Locale>[Locale('id', 'ID')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
