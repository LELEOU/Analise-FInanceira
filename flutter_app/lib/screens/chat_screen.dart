import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/transaction_models.dart';

class ChatScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final Summary? summary;
  final Insights? insights;

  const ChatScreen({
    Key? key,
    required this.transactions,
    this.summary,
    this.insights,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final TransactionApiService _apiService = TransactionApiService();
  bool _isLoading = false;
  List<String> _quickSuggestions = [
    "Como posso economizar mais?",
    "Qual categoria gasta mais?",
    "Dicas para reduzir gastos",
    "Análise do meu orçamento",
  ];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: "👋 Olá! Sou seu assistente financeiro pessoal.\n\n"
            "Posso te ajudar a:\n"
            "💰 Analisar seus gastos\n"
            "📊 Identificar oportunidades de economia\n"
            "💡 Dar dicas de planejamento financeiro\n\n"
            "Como posso te ajudar hoje?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      final response = await _apiService.sendChatMessage(
        message: text,
        transactions: widget.transactions,
        summary: widget.summary,
        insights: widget.insights,
      );

      final aiMessage = ChatMessage(
        text: response['message'] ??
            'Desculpe, não consegui processar sua mensagem.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestions: (response['suggestions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
      );

      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Erro ao enviar mensagem. Tente novamente.',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 Chat Financeiro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick insights banner
          _buildQuickInsightsBanner(),

          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: const [
                  SizedBox(width: 16),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Pensando...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

          // Quick suggestions
          if (_quickSuggestions.isNotEmpty) _buildQuickSuggestions(),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildQuickInsightsBanner() {
    if (widget.summary == null) return const SizedBox.shrink();

    final balance = widget.summary!.balance;
    final isPositive = balance >= 0;
    final theme = Theme.of(context);
    final positiveColor = const Color(0xFF10B981); // accentColor from theme
    final negativeColor = const Color(0xFFEF4444); // errorColor from theme

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPositive
            ? positiveColor.withValues(alpha: 0.1)
            : negativeColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: isPositive
                ? positiveColor.withValues(alpha: 0.3)
                : negativeColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? positiveColor : negativeColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo: ${_formatCurrency(balance)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPositive ? positiveColor : negativeColor,
                  ),
                ),
                Text(
                  '${widget.transactions.length} transações analisadas',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color ?? Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _showDetailedInsights,
            icon: const Icon(Icons.analytics, size: 16),
            label: const Text('Ver mais', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Nenhuma mensagem ainda',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comece uma conversa sobre suas finanças!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final errorColor = const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor.withValues(alpha: 0.2),
              child: Icon(Icons.smart_toy, size: 18, color: primaryColor),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? primaryColor
                        : message.isError
                            ? errorColor.withValues(alpha: 0.1)
                            : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                if (message.suggestions != null &&
                    message.suggestions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: message.suggestions!.map((suggestion) {
                        return ActionChip(
                          label: Text(suggestion,
                              style: const TextStyle(fontSize: 12)),
                          onPressed: () => _sendMessage(suggestion),
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                          side: BorderSide(
                              color: primaryColor.withValues(alpha: 0.3)),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sugestões rápidas:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickSuggestions.map((suggestion) {
              return ActionChip(
                label: Text(suggestion, style: const TextStyle(fontSize: 13)),
                onPressed: () => _sendMessage(suggestion),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                side: BorderSide(color: theme.dividerColor),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Digite sua mensagem...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () => _sendMessage(_messageController.text),
            mini: true,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💡 Sobre o Chat Financeiro'),
        content: const Text(
          'Este assistente usa IA para analisar suas transações e '
          'fornecer insights personalizados sobre:\n\n'
          '• Oportunidades de economia\n'
          '• Otimização de gastos\n'
          '• Planejamento financeiro\n'
          '• Análise de padrões\n\n'
          'Suas conversas são processadas com segurança e privacidade.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar conversa?'),
        content: const Text('Todas as mensagens serão removidas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
              Navigator.pop(context);
            },
            child: const Text('Limpar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetailedInsights() async {
    // TODO: Mostrar insights detalhados
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Insights Detalhados'),
        content: const Text('Em desenvolvimento...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2)}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final List<String>? suggestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.suggestions,
  });
}
