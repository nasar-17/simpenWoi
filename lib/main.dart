import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app/capture_runtime.dart';
import 'app/simpen_woi_app.dart';
import 'core/database/app_database.dart';
import 'core/database/database_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  Intl.defaultLocale = 'id_ID';

  final AppDatabase database = AppDatabase();
  await database.seedDefaults();
  final ProviderContainer container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(database)],
  );
  // The Activity and notification listener share one engine and this container.
  // Subscribe before rendering: a cold background start has no surface/frame.
  container.read(captureRuntimeProvider).start();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SimpenWoiApp(),
    ),
  );
}
