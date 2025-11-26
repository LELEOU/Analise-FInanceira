import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../models/transaction_models.dart';
import '../services/api_service.dart';
import '../widgets/transaction_list.dart';
import '../widgets/summary_cards.dart';
import '../widgets/category_chart.dart';
import '../widgets/insights_section.dart';
import 'manual_input_screen.dart';
import 'chat_screen.dart';
import '../widgets/google_sheets_import.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TransactionApiService _apiService =
      MockTransactionApiService(); // Mudar para TransactionApiService() em produção

  AnalysisResult? _analysisResult;
  bool _isLoading = false;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _importCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        _showError('Erro ao ler arquivo');
        return;
      }

      final csvContent = utf8.decode(file.bytes!);
      await _processTransactions(csvContent: csvContent);
    } catch (e) {
      _showError('Erro ao importar CSV: $e');
    }
  }

  Future<void> _importJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        _showError('Erro ao ler arquivo');
        return;
      }

      final jsonContent = utf8.decode(file.bytes!);
      final data = jsonDecode(jsonContent);

      final transactions = (data['transactions'] as List)
          .map((t) => TransactionInput(
                id: t['id'],
                date: t['date'],
                description: t['description'],
                amount: (t['amount'] as num).toDouble(),
                currency: t['currency'] ?? 'BRL',
                raw: t['raw'],
              ))
          .toList();

      await _processTransactions(
        transactions: transactions,
        userId: data['user_id'],
      );
    } catch (e) {
      _showError('Erro ao importar JSON: $e');
    }
  }

  Future<void> _processTransactions({
    List<TransactionInput>? transactions,
    String? csvContent,
    String? userId,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final AnalysisResult result;

      if (csvContent != null) {
        result = await _apiService.analyzeFromCsv(csvContent);
      } else if (transactions != null) {
        result = await _apiService.analyzeTransactions(
          transactions: transactions,
          userId: userId,
        );
      } else {
        throw Exception('Nenhum dado para processar');
      }

      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      _showError(e.toString());
    } catch (e) {
      _showError('Erro ao processar: $e');
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToManualInput() async {
    final transactions = await Navigator.push<List<TransactionInput>>(
      context,
      MaterialPageRoute(builder: (context) => const ManualInputScreen()),
    );

    if (transactions != null && transactions.isNotEmpty) {
      await _processTransactions(transactions: transactions);
    }
  }

  Future<void> _showGoogleSheetsImport() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => GoogleSheetsImportDialog(
        onImport: (url) async {
          try {
            // Baixar CSV do Google Sheets
            final response = await http.get(Uri.parse(url));

            if (response.statusCode == 200) {
              final csvContent = utf8.decode(response.bodyBytes);
              await _processTransactions(csvContent: csvContent);
            } else {
              _showError('Erro ao baixar planilha: ${response.statusCode}');
            }
          } catch (e) {
            _showError('Erro ao importar do Google Sheets: $e');
          }
        },
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Planilha importada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _useSampleData() async {
    final sampleTransactions = [
      TransactionInput(
        id: 'txn_001',
        date: '2025-11-10',
        description: 'PADARIA PAO DOCE',
        amount: -25.90,
      ),
      TransactionInput(
        id: 'txn_002',
        date: '2025-11-09',
        description: 'POSTO SHELL GASOLINA',
        amount: -200.00,
      ),
      TransactionInput(
        id: 'txn_003',
        date: '2025-11-09',
        description: 'SALARIO NOVEMBRO',
        amount: 3500.00,
      ),
      TransactionInput(
        id: 'txn_004',
        date: '2025-11-08',
        description: 'SUPERMERCADO EXTRA',
        amount: -245.80,
      ),
      TransactionInput(
        id: 'txn_005',
        date: '2025-11-07',
        description: 'UBER VIAGEM',
        amount: -32.50,
      ),
      TransactionInput(
        id: 'txn_006',
        date: '2025-11-06',
        description: 'RESTAURANTE PIZZA',
        amount: -89.90,
      ),
      TransactionInput(
        id: 'txn_007',
        date: '2025-11-05',
        description: 'FARMACIA DROGASIL',
        amount: -67.40,
      ),
    ];

    await _processTransactions(
      transactions: sampleTransactions,
      userId: 'demo_user',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Análise Financeira com IA',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_analysisResult != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _analysisResult = null;
                });
              },
              tooltip: 'Nova análise',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processando transações...'),
                  SizedBox(height: 8),
                  Text(
                    'Aguarde enquanto a IA analisa seus dados',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : _analysisResult == null
              ? _buildEmptyState()
              : _buildAnalysisView(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Bem-vindo ao Analisador Financeiro',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Importe suas transações bancárias para receber análises e insights inteligentes sobre seus gastos',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _importCsv,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Importar CSV'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _importJson,
                  icon: const Icon(Icons.code),
                  label: const Text('Importar JSON'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showGoogleSheetsImport,
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Google Sheets'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    backgroundColor: const Color(0xFF10B981), // accentColor
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _navigateToManualInput,
                  icon: const Icon(Icons.edit),
                  label: const Text('Entrada Manual'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _useSampleData,
              icon: const Icon(Icons.science_outlined),
              label: const Text('Usar dados de exemplo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisView() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Resumo'),
            Tab(icon: Icon(Icons.list), text: 'Transações'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Insights'),
            Tab(icon: Icon(Icons.chat), text: 'Chat IA'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSummaryTab(),
              _buildTransactionsTab(),
              _buildInsightsTab(),
              _buildChatTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SummaryCards(summary: _analysisResult!.summary),
          const SizedBox(height: 24),
          CategoryChart(summary: _analysisResult!.summary),
          const SizedBox(height: 16),
          _buildMetadata(),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return TransactionList(transactions: _analysisResult!.transactions);
  }

  Widget _buildInsightsTab() {
    return InsightsSection(summary: _analysisResult!.summary);
  }

  Widget _buildChatTab() {
    // Criar objeto Insights a partir do Summary
    final insights = Insights(
      alerts: _analysisResult!.summary.alerts,
      recommendations: _analysisResult!.summary.recommendations,
      trends: null,
    );

    return ChatScreen(
      transactions: _analysisResult!.transactions,
      summary: _analysisResult!.summary,
      insights: insights,
    );
  }

  Widget _buildMetadata() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações do Processamento',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Modelo', _analysisResult!.modelVersion),
            _buildInfoRow(
              'Processado em',
              _formatDateTime(_analysisResult!.processedAt),
            ),
            _buildInfoRow(
              'Período',
              '${_formatDate(_analysisResult!.summary.periodStart)} - ${_formatDate(_analysisResult!.summary.periodEnd)}',
            ),
            _buildInfoRow(
              'Total de transações',
              '${_analysisResult!.transactions.length}',
            ),
            if (_analysisResult!.processingNotes != null) ...[
              const Divider(height: 24),
              Text(
                'Notas:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _analysisResult!.processingNotes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
