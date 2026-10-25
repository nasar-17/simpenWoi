import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../capture/presentation/providers/capture_providers.dart';
import '../../data/category_repository.dart';
import '../../data/category_service.dart';

final Provider<CategoryRepository> categoryRepositoryProvider =
    Provider<CategoryRepository>(
      (ref) => CategoryRepository(ref.watch(databaseProvider)),
    );

final Provider<CategoryService> categoryServiceProvider =
    Provider<CategoryService>(
      (ref) => CategoryService(
        repository: ref.watch(categoryRepositoryProvider),
        refreshNativeContext: () =>
            ref.read(captureSyncServiceProvider).refreshNativeContext(),
      ),
    );
