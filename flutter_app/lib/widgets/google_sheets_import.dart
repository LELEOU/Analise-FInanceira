import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GoogleSheetsImportDialog extends StatefulWidget {
  final Function(String) onImport;

  const GoogleSheetsImportDialog({
    Key? key,
    required this.onImport,
  }) : super(key: key);

  @override
  State<GoogleSheetsImportDialog> createState() =>
      _GoogleSheetsImportDialogState();
}

class _GoogleSheetsImportDialogState extends State<GoogleSheetsImportDialog> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _importFromUrl() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, insira uma URL válida';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Converter URL do Google Sheets para formato CSV export
      String csvUrl = url;

      if (url.contains('docs.google.com/spreadsheets')) {
        // Extrair ID da planilha
        final regex = RegExp(r'/d/([a-zA-Z0-9-_]+)');
        final match = regex.firstMatch(url);

        if (match != null) {
          final spreadsheetId = match.group(1);
          csvUrl =
              'https://docs.google.com/spreadsheets/d/$spreadsheetId/export?format=csv';
        }
      }

      widget.onImport(csvUrl);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao importar: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = const Color(0xFF10B981); // accentColor from theme

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.table_chart, color: accentColor),
          const SizedBox(width: 12),
          const Text('Importar do Google Sheets'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cole o link da sua planilha do Google Sheets:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://docs.google.com/spreadsheets/d/...',
                prefixIcon: const Icon(Icons.link),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data != null && data.text != null) {
                      _urlController.text = data.text!;
                    }
                  },
                  tooltip: 'Colar',
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Como configurar:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Abra sua planilha no Google Sheets\n'
                    '2. Clique em "Arquivo" > "Compartilhar" > "Publicar na Web"\n'
                    '3. Selecione "Toda a planilha" e formato "CSV"\n'
                    '4. Clique em "Publicar"\n'
                    '5. Copie o link e cole aqui',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text(
                'Formato esperado da planilha',
                style: TextStyle(fontSize: 14),
              ),
              children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Sua planilha deve ter as seguintes colunas:\n\n'
                    '• Data (dd/mm/yyyy ou yyyy-mm-dd)\n'
                    '• Descrição\n'
                    '• Valor (use números negativos para despesas)\n'
                    '• Moeda (opcional, padrão: BRL)\n\n'
                    'Exemplo:\n'
                    'Data | Descrição | Valor | Moeda\n'
                    '01/12/2025 | Supermercado | -150.50 | BRL\n'
                    '05/12/2025 | Salário | 3000.00 | BRL',
                    style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _importFromUrl,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download),
          label: Text(_isLoading ? 'Importando...' : 'Importar'),
        ),
      ],
    );
  }
}
