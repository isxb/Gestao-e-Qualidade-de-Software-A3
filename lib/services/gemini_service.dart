import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'storage_service.dart';

class GeminiServiceException implements Exception {
  GeminiServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Serviço de integração com a Google Gemini 2.5 Flash API.
class GeminiService {
  GeminiService({this.modelName = 'gemini-2.5-flash'});

  final String modelName;

  /// Retorna a API key disponível na ordem: override runtime → .env.
  String? _resolveApiKey() {
    final String? override = StorageService.instance.loadApiKey();
    if (override != null && override.isNotEmpty) return override;
    final String fromEnv = dotenv.maybeGet('GEMINI_API_KEY') ?? '';
    return fromEnv.isEmpty ? null : fromEnv;
  }

  bool get hasApiKey => _resolveApiKey() != null;

  Future<String> generate(String prompt) async {
    final String? apiKey = _resolveApiKey();
    if (apiKey == null) {
      throw GeminiServiceException(
        'API key do Gemini não configurada. Vá em Ajustes e informe sua chave.',
      );
    }

    try {
      final GenerativeModel model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.6,
          maxOutputTokens: 2048,
        ),
      );
      final GenerateContentResponse response =
          await model.generateContent(<Content>[Content.text(prompt)]);
      final String text = response.text?.trim() ?? '';
      if (text.isEmpty) {
        throw GeminiServiceException(
          'A IA retornou uma resposta vazia. Tente novamente.',
        );
      }
      return text;
    } on GeminiServiceException {
      rethrow;
    } catch (e) {
      throw GeminiServiceException(
        'Erro ao conectar com a IA: ${e.toString()}',
      );
    }
  }
}
