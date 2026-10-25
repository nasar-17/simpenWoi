import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../wallets/presentation/providers/wallet_providers.dart';
import '../../data/capture_context_pusher.dart';
import '../../data/capture_importer.dart';
import '../../data/capture_sync_service.dart';
import '../../data/merchant_rule_repository.dart';
import '../../data/native_capture_bridge.dart';

final Provider<NativeCaptureBridge> nativeCaptureBridgeProvider =
    Provider<NativeCaptureBridge>((ref) => const NativeCaptureBridge());

final Provider<MerchantRuleRepository> merchantRuleRepositoryProvider =
    Provider<MerchantRuleRepository>(
      (ref) => MerchantRuleRepository(ref.watch(databaseProvider)),
    );

final Provider<CaptureSyncService> captureSyncServiceProvider =
    Provider<CaptureSyncService>((ref) {
      final TransactionRepository transactionRepository = ref.watch(
        transactionRepositoryProvider,
      );
      final MerchantRuleRepository merchantRuleRepository = ref.watch(
        merchantRuleRepositoryProvider,
      );
      final CaptureContextPusher contextPusher = CaptureContextPusher(
        bridge: ref.watch(nativeCaptureBridgeProvider),
        transactionRepository: transactionRepository,
        merchantRuleRepository: merchantRuleRepository,
      );
      final CaptureImporter importer = CaptureImporter(
        bridge: ref.watch(nativeCaptureBridgeProvider),
        transactionRepository: transactionRepository,
        walletRepository: ref.watch(walletRepositoryProvider),
        contextPusher: contextPusher,
      );
      return CaptureSyncService(
        transactionRepository: transactionRepository,
        merchantRuleRepository: merchantRuleRepository,
        contextPusher: contextPusher,
        importer: importer,
      );
    });
