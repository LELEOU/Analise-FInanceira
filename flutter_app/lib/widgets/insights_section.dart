import 'package:flutter/material.dart';
import '../models/transaction_models.dart';

class InsightsSection extends StatelessWidget {
  final Summary summary;

  const InsightsSection({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alertas
          if (summary.alerts.isNotEmpty) ...[
            _buildSectionTitle(context, 'Alertas', Icons.warning_amber),
            const SizedBox(height: 12),
            ...summary.alerts.map((alert) => _buildAlertCard(context, alert)),
            const SizedBox(height: 24),
          ],

          // Recomendações
          if (summary.recommendations.isNotEmpty) ...[
            _buildSectionTitle(context, 'Recomendações', Icons.lightbulb),
            const SizedBox(height: 12),
            ...summary.recommendations.map((rec) => _buildRecommendationCard(context, rec)),
            const SizedBox(height: 24),
          ],

          // Tendências
          if (summary.categoryTrends.isNotEmpty) ...[
            _buildSectionTitle(context, 'Tendências', Icons.trending_up),
            const SizedBox(height: 12),
            _buildTrendsCard(context),
          ],

          // Dicas gerais
          const SizedBox(height: 24),
          _buildGeneralTips(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(BuildContext context, Alert alert) {
    Color color;
    IconData icon;

    switch (alert.type) {
      case 'high_spend':
        color = Colors.orange;
        icon = Icons.trending_up;
        break;
      case 'low_balance':
        color = Colors.red;
        icon = Icons.warning;
        break;
      case 'unusual_category':
        color = Colors.blue;
        icon = Icons.help_outline;
        break;
      case 'possible_duplicate':
        color = Colors.purple;
        icon = Icons.content_copy;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getAlertTitle(alert.type),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.message,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (alert.relatedCategory != null) ...[
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        _getCategoryName(alert.relatedCategory!),
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: color.withOpacity(0.2),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, Recommendation rec) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tips_and_updates, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.text,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  if (rec.impactEstimatePct != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.savings,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Potencial economia: ${rec.impactEstimatePct!.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsCard(BuildContext context) {
    final trends = summary.categoryTrends.entries.toList()
      ..sort((a, b) => b.value.changePct.abs().compareTo(a.value.changePct.abs()));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...trends.take(5).map((entry) {
              final category = entry.key;
              final trend = entry.value;
              
              IconData icon;
              Color color;
              
              switch (trend.direction) {
                case 'up':
                  icon = Icons.trending_up;
                  color = Colors.red;
                  break;
                case 'down':
                  icon = Icons.trending_down;
                  color = Colors.green;
                  break;
                default:
                  icon = Icons.trending_flat;
                  color = Colors.grey;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getCategoryName(category),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _getTrendDescription(trend),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${trend.changePct >= 0 ? '+' : ''}${trend.changePct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTips(BuildContext context) {
    final savingsRate = summary.savingsRate;
    
    String tipTitle;
    String tipMessage;
    IconData tipIcon;
    Color tipColor;

    if (savingsRate >= 20) {
      tipTitle = 'Excelente!';
      tipMessage = 'Você está economizando mais de 20% da sua renda. Continue assim!';
      tipIcon = Icons.emoji_events;
      tipColor = Colors.green;
    } else if (savingsRate >= 10) {
      tipTitle = 'Muito Bem!';
      tipMessage = 'Sua taxa de poupança está boa. Tente aumentar gradualmente para 20%.';
      tipIcon = Icons.thumb_up;
      tipColor = Colors.blue;
    } else if (savingsRate > 0) {
      tipTitle = 'Atenção';
      tipMessage = 'Sua taxa de poupança está baixa. Revise seus gastos e tente poupar pelo menos 10%.';
      tipIcon = Icons.info;
      tipColor = Colors.orange;
    } else {
      tipTitle = 'Alerta!';
      tipMessage = 'Você está gastando mais do que ganha. É importante ajustar seu orçamento urgentemente.';
      tipIcon = Icons.warning;
      tipColor = Colors.red;
    }

    return Card(
      color: tipColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(tipIcon, color: tipColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  tipTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: tipColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tipMessage,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTipChip('Taxa de poupança: ${savingsRate.toStringAsFixed(1)}%'),
                _buildTipChip('Meta ideal: 20%'),
                _buildTipChip('Mínimo recomendado: 10%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipChip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  String _getAlertTitle(String type) {
    const titles = {
      'high_spend': 'Gasto Elevado',
      'low_balance': 'Saldo Baixo',
      'unusual_category': 'Categoria Incomum',
      'possible_duplicate': 'Possível Duplicata',
    };
    return titles[type] ?? 'Alerta';
  }

  String _getTrendDescription(TrendInfo trend) {
    switch (trend.direction) {
      case 'up':
        return 'Gastos aumentaram';
      case 'down':
        return 'Gastos diminuíram';
      default:
        return 'Gastos estáveis';
    }
  }

  String _getCategoryName(String category) {
    const names = {
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
    return names[category] ?? category;
  }
}
