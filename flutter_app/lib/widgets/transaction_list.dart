import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_models.dart';
import '../theme/app_theme.dart';

class TransactionList extends StatefulWidget {
  final List<Transaction> transactions;

  const TransactionList({super.key, required this.transactions});

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  String _filterCategory = 'all';
  String _sortBy = 'date';

  List<Transaction> get _filteredTransactions {
    var list = widget.transactions;

    // Filtrar por categoria
    if (_filterCategory != 'all') {
      list = list.where((t) => t.category == _filterCategory).toList();
    }

    // Ordenar
    switch (_sortBy) {
      case 'date':
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'amount':
        list.sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
        break;
      case 'category':
        list.sort((a, b) => a.category.compareTo(b.category));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['all', ...widget.transactions.map((t) => t.category).toSet().toList()];
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Column(
      children: [
        // Filtros e ordenação
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _filterCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(Icons.filter_list),
                    isDense: true,
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat == 'all' ? 'Todas' : _getCategoryName(cat)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterCategory = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Ordenar',
                    prefixIcon: Icon(Icons.sort),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'date', child: Text('Data')),
                    DropdownMenuItem(value: 'amount', child: Text('Valor')),
                    DropdownMenuItem(value: 'category', child: Text('Categoria')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        // Lista de transações
        Expanded(
          child: _filteredTransactions.isEmpty
              ? const Center(
                  child: Text('Nenhuma transação encontrada'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final txn = _filteredTransactions[index];
                    return _buildTransactionCard(txn, currencyFormat);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Transaction txn, NumberFormat currencyFormat) {
    final categoryColor = AppTheme.getCategoryColor(txn.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTransactionDetails(txn),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone da categoria
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(txn.category),
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 16),
              
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txn.normalizedDescription,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            txn.categoryDisplay,
                            style: TextStyle(
                              fontSize: 12,
                              color: categoryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (txn.subcategory != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '• ${txn.subcategory}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(txn.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Valor
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(txn.amount.abs()),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: txn.isExpense ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildConfidenceBadge(txn.confidence),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    Color color;
    String text;

    if (confidence >= 0.8) {
      color = Colors.green;
      text = 'Alta';
    } else if (confidence >= 0.6) {
      color = Colors.orange;
      text = 'Média';
    } else {
      color = Colors.red;
      text = 'Baixa';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showTransactionDetails(Transaction txn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Detalhes da Transação',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow('ID', txn.id),
                  _buildDetailRow('Descrição', txn.description),
                  _buildDetailRow('Descrição Normalizada', txn.normalizedDescription),
                  _buildDetailRow('Categoria', txn.categoryDisplay),
                  if (txn.subcategory != null)
                    _buildDetailRow('Subcategoria', txn.subcategory!),
                  _buildDetailRow('Valor', NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(txn.amount)),
                  _buildDetailRow('Data', DateFormat('dd/MM/yyyy').format(txn.date)),
                  _buildDetailRow('Confiança', '${(txn.confidence * 100).toStringAsFixed(0)}%'),
                  if (txn.explanation != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Explicação da IA:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        txn.explanation!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
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

  IconData _getCategoryIcon(String category) {
    const icons = {
      'alimentacao': Icons.restaurant,
      'transporte': Icons.directions_car,
      'moradia': Icons.home,
      'lazer': Icons.sports_esports,
      'saude': Icons.medical_services,
      'compras': Icons.shopping_bag,
      'contas': Icons.receipt,
      'transferencia': Icons.swap_horiz,
      'renda': Icons.attach_money,
      'educacao': Icons.school,
      'outros': Icons.category,
    };
    return icons[category] ?? Icons.help_outline;
  }
}
