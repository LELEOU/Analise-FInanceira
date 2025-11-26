import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction_models.dart';
import '../theme/app_theme.dart';

class CategoryChart extends StatelessWidget {
  final Summary summary;

  const CategoryChart({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    // Filtrar apenas despesas
    final expenses = summary.byCategory.entries
        .where((e) => e.value < 0)
        .map((e) => MapEntry(e.key, e.value.abs()))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (expenses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Nenhuma despesa para exibir'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Despesas por Categoria',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            
            // Gráfico de pizza
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        sections: _buildSections(expenses),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildLegend(expenses),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Lista de categorias com barras
            ...expenses.take(5).map((entry) => _buildCategoryBar(
                  context,
                  entry.key,
                  entry.value,
                  summary.totalExpenses,
                )),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(List<MapEntry<String, double>> expenses) {
    final total = expenses.fold<double>(0, (sum, e) => sum + e.value);
    
    return expenses.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value.key;
      final value = entry.value.value;
      final percentage = (value / total) * 100;
      final color = AppTheme.getCategoryColor(category);

      return PieChartSectionData(
        color: color,
        value: value,
        title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(List<MapEntry<String, double>> expenses) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: expenses.take(5).map((entry) {
        final color = AppTheme.getCategoryColor(entry.key);
        final name = _getCategoryName(entry.key);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryBar(
    BuildContext context,
    String category,
    double amount,
    double total,
  ) {
    final percentage = (amount / total) * 100;
    final color = AppTheme.getCategoryColor(category);
    final name = _getCategoryName(category);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'R\$ ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${percentage.toStringAsFixed(1)}% do total',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
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
