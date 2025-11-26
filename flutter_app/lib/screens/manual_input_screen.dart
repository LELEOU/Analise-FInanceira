import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_models.dart';
import 'package:uuid/uuid.dart';

class ManualInputScreen extends StatefulWidget {
  const ManualInputScreen({super.key});

  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TransactionInput> _transactions = [];
  
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isExpense = true;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _addTransaction() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final transaction = TransactionInput(
        id: const Uuid().v4(),
        date: _selectedDate.toIso8601String().split('T')[0],
        description: _descriptionController.text,
        amount: _isExpense ? -amount : amount,
        currency: 'BRL',
      );

      setState(() {
        _transactions.add(transaction);
        _descriptionController.clear();
        _amountController.clear();
        _selectedDate = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transação adicionada!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _removeTransaction(int index) {
    setState(() {
      _transactions.removeAt(index);
    });
  }

  void _submit() {
    if (_transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos uma transação'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(context, _transactions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrada Manual'),
        actions: [
          if (_transactions.isNotEmpty)
            TextButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: Text('Analisar (${_transactions.length})'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Formulário
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nova Transação',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Tipo (Despesa/Receita)
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('Despesa'),
                          icon: Icon(Icons.remove_circle_outline),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('Receita'),
                          icon: Icon(Icons.add_circle_outline),
                        ),
                      ],
                      selected: {_isExpense},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          _isExpense = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Descrição
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Ex: Supermercado Extra',
                        prefixIcon: Icon(Icons.description),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite uma descrição';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Valor
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.attach_money),
                        prefixText: 'R\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite um valor';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Valor inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Data
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Botão adicionar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addTransaction,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar Transação'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Lista de transações
          Expanded(
            child: _transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma transação adicionada',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final txn = _transactions[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: txn.amount < 0
                                ? Colors.red.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                            child: Icon(
                              txn.amount < 0
                                  ? Icons.remove
                                  : Icons.add,
                              color: txn.amount < 0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                          title: Text(txn.description),
                          subtitle: Text(txn.date),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'R\$ ${txn.amount.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: txn.amount < 0
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeTransaction(index),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
