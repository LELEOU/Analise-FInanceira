// Modelos de dados para transações e resumo financeiro

class Transaction {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final String currency;
  final String category;
  final String? subcategory;
  final double confidence;
  final String normalizedDescription;
  final String? explanation;

  Transaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.currency,
    required this.category,
    this.subcategory,
    required this.confidence,
    required this.normalizedDescription,
    this.explanation,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      confidence: (json['confidence'] as num).toDouble(),
      normalizedDescription: json['normalized_description'] as String,
      explanation: json['explanation'] as String?,
    );
  }

  bool get isExpense => amount < 0;
  bool get isIncome => amount > 0;

  String get categoryDisplay {
    final Map<String, String> categoryNames = {
      'alimentacao': 'Alimentação',
      'transporte': 'Transporte',
      'moradia': 'Moradia',
      'lazer': 'Lazer',
      'saude': 'Saúde',
      'compras': 'Compras',
      'contas': 'Contas',
      'transferencia': 'Transferência',
      'renda': 'Renda',
      'educacao': 'Educação',
      'outros': 'Outros',
    };
    return categoryNames[category] ?? category;
  }
}

class TrendInfo {
  final double changePct;
  final String direction;

  TrendInfo({
    required this.changePct,
    required this.direction,
  });

  factory TrendInfo.fromJson(Map<String, dynamic> json) {
    return TrendInfo(
      changePct: (json['change_pct'] as num).toDouble(),
      direction: json['direction'] as String,
    );
  }
}

class Alert {
  final String type;
  final String message;
  final String? relatedCategory;

  Alert({
    required this.type,
    required this.message,
    this.relatedCategory,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      type: json['type'] as String,
      message: json['message'] as String,
      relatedCategory: json['related_category'] as String?,
    );
  }
}

class Recommendation {
  final String id;
  final String text;
  final double? impactEstimatePct;

  Recommendation({
    required this.id,
    required this.text,
    this.impactEstimatePct,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'] as String,
      text: json['text'] as String,
      impactEstimatePct: json['impact_estimate_pct'] != null
          ? (json['impact_estimate_pct'] as num).toDouble()
          : null,
    );
  }
}

class Summary {
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalIncome;
  final double totalExpenses;
  final Map<String, double> byCategory;
  final List<String> top3ExpenseCategories;
  final Map<String, TrendInfo> categoryTrends;
  final List<Alert> alerts;
  final List<Recommendation> recommendations;

  Summary({
    required this.periodStart,
    required this.periodEnd,
    required this.totalIncome,
    required this.totalExpenses,
    required this.byCategory,
    required this.top3ExpenseCategories,
    required this.categoryTrends,
    required this.alerts,
    required this.recommendations,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    final trendData = json['trend']['category_trends'] as Map<String, dynamic>;
    final categoryTrends = trendData.map(
      (key, value) =>
          MapEntry(key, TrendInfo.fromJson(value as Map<String, dynamic>)),
    );

    return Summary(
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpenses: (json['total_expenses'] as num).toDouble(),
      byCategory: (json['by_category'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      top3ExpenseCategories: (json['top_3_expense_categories'] as List)
          .map((e) => e as String)
          .toList(),
      categoryTrends: categoryTrends,
      alerts: (json['alerts'] as List)
          .map((e) => Alert.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendations: (json['recommendations'] as List)
          .map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  double get balance => totalIncome - totalExpenses;
  double get savingsRate => totalIncome > 0 ? (balance / totalIncome) * 100 : 0;
}

class AnalysisResult {
  final String? userId;
  final DateTime processedAt;
  final List<Transaction> transactions;
  final Summary summary;
  final String modelVersion;
  final String? processingNotes;

  AnalysisResult({
    this.userId,
    required this.processedAt,
    required this.transactions,
    required this.summary,
    required this.modelVersion,
    this.processingNotes,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      userId: json['user_id'] as String?,
      processedAt: DateTime.parse(json['processed_at'] as String),
      transactions: (json['transactions'] as List)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: Summary.fromJson(json['summary'] as Map<String, dynamic>),
      modelVersion: json['model_version'] as String,
      processingNotes: json['processing_notes'] as String?,
    );
  }
}

class TransactionInput {
  final String id;
  final String date;
  final String description;
  final double amount;
  final String currency;
  final String? raw;

  TransactionInput({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    this.currency = 'BRL',
    this.raw,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'description': description,
      'amount': amount,
      'currency': currency,
      if (raw != null) 'raw': raw,
    };
  }
}

class Insights {
  final List<Alert> alerts;
  final List<Recommendation> recommendations;
  final List<TrendInfo>? trends;

  Insights({
    required this.alerts,
    required this.recommendations,
    this.trends,
  });

  factory Insights.fromJson(Map<String, dynamic> json) {
    return Insights(
      alerts: (json['alerts'] as List<dynamic>?)
              ?.map((e) => Alert.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      trends: (json['trends'] as List<dynamic>?)
          ?.map((e) => TrendInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
