import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart';

import '../../../core/assistant/assistant_context.dart';
import '../../../core/assistant/proposed_action.dart';
import '../../../core/database/app_database.dart';
import '../../learning/data/learning_repository.dart';
import '../domain/ai_provider.dart';
import 'function_gemma_action_mapper.dart';
import 'function_gemma_model_manager.dart';
import 'function_gemma_prompt.dart';
import 'function_gemma_tools.dart';

class FunctionGemmaProvider implements AiProvider {
  FunctionGemmaProvider({
    required this.modelManager,
    required this.learningRepository,
    FunctionGemmaPrompt? promptBuilder,
    FunctionGemmaActionMapper? actionMapper,
  }) : _promptBuilder = promptBuilder ?? FunctionGemmaPrompt(),
       _actionMapper = actionMapper ?? const FunctionGemmaActionMapper() {
    unawaited(modelManager.refreshStatus());
  }

  final FunctionGemmaModelManager modelManager;
  final LearningRepository learningRepository;
  final FunctionGemmaPrompt _promptBuilder;
  final FunctionGemmaActionMapper _actionMapper;

  @override
  bool get isAvailable => modelManager.isInstalled && modelManager.isEnabled;

  @override
  Future<List<ProposedAction>?> propose(
    String input,
    AssistantContext context,
  ) async {
    if (!modelManager.isInstalled) {
      await modelManager.refreshStatus();
    }
    if (!isAvailable) {
      return null;
    }
    InferenceModel? model;
    InferenceChat? chat;
    try {
      model = await modelManager.acquire();
      final List<LearningLogEntry> examples = await learningRepository
          .recentExamples(limit: 3);
      final String prompt = await _promptBuilder.build(
        context: context,
        examples: examples,
      );
      chat = await model.createChat(
        temperature: 0.1,
        topK: 1,
        maxOutputTokens: 256,
        systemInstruction: prompt,
        tools: functionGemmaTools,
        supportsFunctionCalls: true,
        modelType: ModelType.functionGemma,
      );
      await chat.addQueryChunk(Message.text(text: input, isUser: true));
      final ModelResponse response = await chat.generateChatResponse().timeout(
        FunctionGemmaModelManager.timeout,
      );
      final List<FunctionCallResponse> calls = _functionCalls(response);
      if (calls.isEmpty) {
        return null;
      }
      final List<ProposedAction> proposals = <ProposedAction>[];
      for (final FunctionCallResponse call in calls) {
        final ProposedAction? proposal = _actionMapper.map(call, context);
        if (proposal == null) {
          return null;
        }
        proposals.add(proposal);
      }
      return proposals;
    } catch (_) {
      return null;
    } finally {
      if (chat != null) {
        try {
          await chat.close();
        } catch (_) {}
      }
      if (model != null) {
        modelManager.release();
      }
    }
  }

  List<FunctionCallResponse> _functionCalls(ModelResponse response) {
    return switch (response) {
      FunctionCallResponse() => <FunctionCallResponse>[response],
      ParallelFunctionCallResponse(:final calls) => calls,
      TextResponse() || ThinkingResponse() => const <FunctionCallResponse>[],
    };
  }
}
