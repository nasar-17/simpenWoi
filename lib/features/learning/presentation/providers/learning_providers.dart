import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/learning_repository.dart';
import '../../data/lexicon_repository.dart';

final Provider<LexiconRepository> lexiconRepositoryProvider =
    Provider<LexiconRepository>((ref) => LexiconRepository());

final Provider<LearningRepository> learningRepositoryProvider =
    Provider<LearningRepository>(
      (ref) => LearningRepository(
        ref.watch(databaseProvider),
        ref.watch(lexiconRepositoryProvider),
      ),
    );
