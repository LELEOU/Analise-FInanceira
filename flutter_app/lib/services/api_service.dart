// Serviço para comunicação com a API de análise de transações

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction_models.dart';

class ApiException implements Exception {
  final String message;
  final int? code;
  final String? hint;

  ApiException(this.message, {this.code, this.hint});

  @override
  String toString() => hint != null ? '$message\n$hint' : message;
}

class TransactionApiService {
  // Configure seu endpoint aqui
  static const String baseUrl = 'http://localhost:5000/api';

  // Para testes locais Python
  static const String localPythonUrl = 'http://localhost:8000';

  final String apiUrl;
  final Duration timeout;

  TransactionApiService({
    this.apiUrl = baseUrl,
    this.timeout = const Duration(seconds: 30),
  });

  /// Analisa transações enviando JSON
  Future<AnalysisResult> analyzeTransactions({
    required List<TransactionInput> transactions,
    String? userId,
    List<Map<String, dynamic>>? historicalData,
  }) async {
    try {
      final requestBody = {
        if (userId != null) 'user_id': userId,
        'transactions': transactions.map((t) => t.toJson()).toList(),
        if (historicalData != null) 'historical_data': historicalData,
      };

      final response = await http
          .post(
            Uri.parse('$apiUrl/analyze'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro ao conectar com o servidor: ${e.toString()}');
    }
  }

  /// Analisa transações a partir de CSV
  Future<AnalysisResult> analyzeFromCsv(String csvContent) async {
    try {
      final response = await http
          .post(
            Uri.parse('$apiUrl/analyze'),
            headers: {
              'Content-Type': 'text/csv',
              'Accept': 'application/json',
            },
            body: csvContent,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro ao processar CSV: ${e.toString()}');
    }
  }

  /// Processa resposta da API
  AnalysisResult _handleResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    final data = jsonDecode(body) as Map<String, dynamic>;

    // Verificar se há erro
    if (data.containsKey('error')) {
      final error = data['error'] as Map<String, dynamic>;
      throw ApiException(
        error['message'] as String,
        code: error['code'] as int?,
        hint: error['hint'] as String?,
      );
    }

    // Verificar status HTTP
    if (response.statusCode != 200) {
      throw ApiException(
        'Erro na requisição (${response.statusCode})',
        code: response.statusCode,
      );
    }

    // Parse resultado
    try {
      return AnalysisResult.fromJson(data);
    } catch (e) {
      throw ApiException('Erro ao processar resposta: ${e.toString()}');
    }
  }

  /// Testa conexão com a API
  Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Envia mensagem para o chat com IA
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    List<Transaction>? transactions,
    Summary? summary,
    Insights? insights,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'message': message,
      };

      // Adicionar contexto se disponível
      if (transactions != null || summary != null || insights != insights) {
        body['context'] = {};

        if (transactions != null && transactions.isNotEmpty) {
          body['context']['transactions'] = transactions
              .map((t) => {
                    'date': t.date.toIso8601String(),
                    'description': t.description,
                    'amount': t.amount,
                    'category': t.category,
                    'subcategory': t.subcategory,
                  })
              .toList();
        }

        if (summary != null) {
          body['context']['summary'] = {
            'balance': summary.totalIncome - summary.totalExpenses,
            'total_income': summary.totalIncome,
            'total_expense': summary.totalExpenses,
            'transaction_count': transactions?.length ?? 0,
            'category_totals': summary.byCategory,
          };
        }

        if (insights != null) {
          body['context']['insights'] = {
            'alerts': insights.alerts
                .map((a) => {
                      'type': a.type,
                      'message': a.message,
                    })
                .toList(),
            'recommendations': insights.recommendations
                .map((r) => {
                      'id': r.id,
                      'text': r.text,
                    })
                .toList(),
          };
        }
      }

      final response = await http
          .post(
            Uri.parse('$apiUrl/chat'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);

      final responseBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw ApiException(
          data['message'] ?? 'Erro ao enviar mensagem',
          code: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro ao comunicar com chat: ${e.toString()}');
    }
  }

  /// Obtém insights rápidos do chat
  Future<Map<String, dynamic>> getChatInsights() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/chat/insights'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(timeout);

      final responseBody = utf8.decode(response.bodyBytes);
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Erro ao obter insights: ${e.toString()}');
    }
  }

  /// Obtém sugestões de otimização de orçamento
  Future<Map<String, dynamic>> getBudgetOptimization() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/chat/optimize'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(timeout);

      final responseBody = utf8.decode(response.bodyBytes);
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Erro ao obter otimizações: ${e.toString()}');
    }
  }
}

/// Mock service para testes sem backend
class MockTransactionApiService extends TransactionApiService {
  @override
  Future<AnalysisResult> analyzeTransactions({
    required List<TransactionInput> transactions,
    String? userId,
    List<Map<String, dynamic>>? historicalData,
  }) async {
    // Simular delay da rede
    await Future.delayed(const Duration(seconds: 2));

    // Retornar dados mockados
    return AnalysisResult.fromJson(_getMockResponse(transactions));
  }

  Map<String, dynamic> _getMockResponse(List<TransactionInput> transactions) {
    final now = DateTime.now();

    return {
      'user_id': 'mock_user',
      'processed_at': now.toIso8601String(),
      'transactions': transactions.map((t) {
        final category = _mockClassify(t.description);
        return {
          'id': t.id,
          'date': t.date,
          'description': t.description,
          'amount': t.amount,
          'currency': t.currency,
          'category': category['category'],
          'subcategory': category['subcategory'],
          'confidence': category['confidence'],
          'normalized_description': t.description,
          'explanation': category['explanation'],
        };
      }).toList(),
      'summary': {
        'period_start': transactions.first.date,
        'period_end': transactions.last.date,
        'total_income': transactions
            .where((t) => t.amount > 0)
            .fold(0.0, (sum, t) => sum + t.amount),
        'total_expenses': transactions
            .where((t) => t.amount < 0)
            .fold(0.0, (sum, t) => sum + t.amount.abs()),
        'by_category': {
          'alimentacao': -300.0,
          'transporte': -150.0,
          'renda': 3500.0,
        },
        'top_3_expense_categories': ['alimentacao', 'transporte', 'compras'],
        'trend': {
          'category_trends': {
            'alimentacao': {'change_pct': 5.2, 'direction': 'up'},
            'transporte': {'change_pct': -2.1, 'direction': 'down'},
          }
        },
        'alerts': [
          {
            'type': 'high_spend',
            'message': 'Gastos em alimentação acima da média',
            'related_category': 'alimentacao'
          }
        ],
        'recommendations': [
          {
            'id': 'rec_1',
            'text':
                'Considere reduzir gastos com delivery para economizar cerca de 15%',
            'impact_estimate_pct': 15.0
          }
        ]
      },
      'model_version': 'mock-v1.0',
      'processing_notes': 'Dados mockados para teste'
    };
  }

  Map<String, dynamic> _mockClassify(String description) {
    final desc = description.toLowerCase();

    if (desc.contains('padaria') ||
        desc.contains('supermercado') ||
        desc.contains('restaurante')) {
      return {
        'category': 'alimentacao',
        'subcategory': 'restaurante',
        'confidence': 0.92,
        'explanation': 'Identificado como alimentação baseado na descrição'
      };
    } else if (desc.contains('uber') ||
        desc.contains('posto') ||
        desc.contains('gasolina')) {
      return {
        'category': 'transporte',
        'subcategory': 'combustivel',
        'confidence': 0.88,
        'explanation': 'Classificado como transporte'
      };
    } else if (desc.contains('salario') || desc.contains('deposito')) {
      return {
        'category': 'renda',
        'subcategory': 'salario',
        'confidence': 0.98,
        'explanation': 'Receita identificada como salário'
      };
    }

    return {
      'category': 'outros',
      'subcategory': null,
      'confidence': 0.5,
      'explanation': 'Categoria não identificada com certeza'
    };
  }

  /// Envia mensagem para o chat com IA
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    List<Transaction>? transactions,
    Summary? summary,
    Insights? insights,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'message': message,
      };

      // Adicionar contexto se disponível
      if (transactions != null || summary != null || insights != null) {
        body['context'] = {};

        if (transactions != null && transactions.isNotEmpty) {
          body['context']['transactions'] = transactions
              .map((t) => {
                    'date': t.date.toIso8601String(),
                    'description': t.description,
                    'amount': t.amount,
                    'category': t.category,
                    'subcategory': t.subcategory,
                  })
              .toList();
        }

        if (summary != null) {
          body['context']['summary'] = {
            'balance': summary.totalIncome - summary.totalExpenses,
            'total_income': summary.totalIncome,
            'total_expense': summary.totalExpenses,
            'transaction_count': transactions?.length ?? 0,
            'category_totals': summary.byCategory,
          };
        }

        if (insights != null) {
          body['context']['insights'] = {
            'alerts': insights.alerts
                .map((a) => {
                      'type': a.type,
                      'message': a.message,
                    })
                .toList(),
            'recommendations': insights.recommendations
                .map((r) => {
                      'id': r.id,
                      'text': r.text,
                    })
                .toList(),
          };
        }
      }

      final response = await http
          .post(
            Uri.parse('$apiUrl/chat'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);

      final responseBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw ApiException(
          data['message'] ?? 'Erro ao enviar mensagem',
          code: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro ao comunicar com chat: ${e.toString()}');
    }
  }

  /// Obtém insights rápidos do chat
  Future<Map<String, dynamic>> getChatInsights() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/chat/insights'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(timeout);

      final responseBody = utf8.decode(response.bodyBytes);
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Erro ao obter insights: ${e.toString()}');
    }
  }

  /// Obtém sugestões de otimização de orçamento
  Future<Map<String, dynamic>> getBudgetOptimization() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/chat/optimize'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(timeout);

      final responseBody = utf8.decode(response.bodyBytes);
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Erro ao obter otimizações: ${e.toString()}');
    }
  }
}
