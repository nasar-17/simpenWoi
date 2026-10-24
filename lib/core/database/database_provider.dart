import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError('databaseProvider harus dioverride di main'),
);
