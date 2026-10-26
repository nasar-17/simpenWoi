import '../../../core/assistant/assistant_action.dart';
import '../../../core/assistant/assistant_context.dart';
import '../../../core/assistant/assistant_data_repository.dart';
import '../../../core/assistant/proposed_action.dart';
import '../../../core/constants/transaction_values.dart';
import '../../../core/database/app_database.dart';
import '../../../core/parser/parsed_entry.dart';
import '../../../core/parser/transaction_parser.dart';
import '../../../core/utils/currency.dart';
import '../../categories/domain/category_rules.dart';
import 'ai_provider.dart';
import 'category_scorer.dart';
import 'input_patterns.dart';

part 'input_engine_helpers.dart';

class InputEngine {
  const InputEngine({
    required this.dataRepository,
    required this.categoryScorer,
    required this.aiProvider,
  });

  final AssistantDataRepository dataRepository;
  final CategoryScorer categoryScorer;
  final AiProvider aiProvider;

  Future<List<ProposedAction>> process(String raw) async {
    final String input = raw.trim();
    if (input.isEmpty) {
      return const <ProposedAction>[];
    }
    if (isCancellation(input)) {
      return <ProposedAction>[
        _clarify('Baik, tidak ada yang disimpan. Ada yang ingin dicatat?'),
      ];
    }
    final AssistantContext context = await dataRepository.loadContext();
    if (context.wallets.isEmpty) {
      return <ProposedAction>[
        _clarify('Dompet belum tersedia. Buat dompet terlebih dahulu.'),
      ];
    }
    final ProposedAction? fixed = matchFixedPattern(input, context);
    if (fixed != null) {
      return <ProposedAction>[fixed];
    }

    final List<ProposedAction> proposals = <ProposedAction>[];
    for (final String item in splitItems(input)) {
      final ParsedEntry parsed = const TransactionParser().parse(
        item,
        categories: categoryRulesFrom(context.categories),
      );
      if (parsed.amount <= 0) {
        continue;
      }
      if (parsed.type != TransactionType.expense &&
          parsed.type != TransactionType.income) {
        proposals.add(
          _clarify('Sebutkan dompet asal dan tujuan untuk transfer.'),
        );
        continue;
      }
      final Wallet? mentionedWallet = walletFromText(item, context);
      final Wallet wallet = mentionedWallet ?? context.defaultWallet;
      final List<CategoryScore> scores = parsed.categoryId == null
          ? await categoryScorer.score(
              text: item,
              type: parsed.type,
              categories: context.categories,
            )
          : const <CategoryScore>[];
      final CategoryScore? best = scores.isEmpty ? null : scores.first;
      final bool confidentCategory =
          parsed.categoryId != null || (best?.score ?? 0) >= 0.75;
      final int? categoryId =
          parsed.categoryId ?? (confidentCategory ? best?.categoryId : null);
      final Category? category = context.categoryById(categoryId);
      final List<CategoryOption> options = _options(scores, context, best);
      final String categoryLabel = category?.name ?? 'kategori belum dipilih';
      final double confidence = parsed.categoryId != null
          ? 0.9
          : best?.score ?? 0.55;
      final String typeLabel = parsed.type == TransactionType.income
          ? 'Tambah pemasukan'
          : 'Tambah pengeluaran';
      proposals.add(
        ProposedAction(
          action: AddTransactionAction(
            amount: parsed.amount,
            type: parsed.type,
            walletId: wallet.id,
            categoryId: categoryId,
            note: parsed.note,
            merchant: parsed.merchant,
          ),
          confidence: confidence,
          source: ActionSource.rules,
          summary:
              '$typeLabel ${formatRupiah(parsed.amount)} \u2014 '
              '$categoryLabel',
          details: <String>[wallet.name],
          options: options,
          suggestedCategoryName: confidentCategory
              ? null
              : mainNoun(parsed.note ?? item),
        ),
      );
    }

    if (proposals.isEmpty ||
        (proposals.every((ProposedAction item) => item.confidence < 0.75) &&
            aiProvider.isAvailable)) {
      final List<ProposedAction>? aiResult = await aiProvider.propose(
        input,
        context,
      );
      if (aiResult != null && aiResult.isNotEmpty) {
        return aiResult;
      }
    }
    if (proposals.isNotEmpty) {
      return proposals;
    }
    return <ProposedAction>[
      _clarify(
        'Saya belum yakin maksudnya. Coba tulis nominal dan keterangannya, '
        'misalnya "bakso 15rb" atau "total makan bulan ini".',
      ),
    ];
  }

  List<CategoryOption> _options(
    List<CategoryScore> scores,
    AssistantContext context,
    CategoryScore? best,
  ) {
    if (best == null || best.score < 0.4 || best.score >= 0.75) {
      return const <CategoryOption>[];
    }
    return scores
        .take(3)
        .map((CategoryScore score) {
          final Category? category = context.categoryById(score.categoryId);
          return category == null
              ? null
              : CategoryOption(id: category.id, name: category.name);
        })
        .whereType<CategoryOption>()
        .toList(growable: false);
  }

  ProposedAction _clarify(String question) {
    return ProposedAction(
      action: AskClarificationAction(question: question),
      confidence: 0,
      source: ActionSource.rules,
      summary: question,
    );
  }
}
