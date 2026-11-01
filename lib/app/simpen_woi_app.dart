import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import 'capture_runtime.dart';
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncCaptures());
    }
  }

  Future<void> _syncCaptures() {
    return ref.read(captureRuntimeProvider).sync();
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
      builder: (BuildContext context, Widget? child) {
        final String? error = ref.watch(captureRuntimeErrorProvider);
        return Column(
          children: <Widget>[
            if (error != null)
              SafeArea(
                bottom: false,
                child: Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    child: Row(
                      children: <Widget>[
                        Expanded(child: Text(error)),
                        TextButton(
                          onPressed: () => unawaited(_syncCaptures()),
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
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

