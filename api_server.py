"""
Servidor Flask para API REST de análise de transações.
Para uso em desenvolvimento e produção.
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
import sys
import os

# Adicionar diretório src ao path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from main_handler import process_transactions_dict
from financial_chat import FinancialChatAssistant

app = Flask(__name__)

# Instância global do chat assistant (em produção, usar sessões/banco de dados)
chat_assistant = FinancialChatAssistant()

# Configurar CORS
# Em produção, substitua * pelos domínios específicos
CORS(app, resources={
    r"/api/*": {
        "origins": "*",
        "methods": ["GET", "POST", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})


@app.route('/', methods=['GET'])
def index():
    """Rota raiz com informações da API."""
    return jsonify({
        'name': 'Financial Analyzer API',
        'version': '1.0.0',
        'endpoints': {
            '/api/analyze': 'POST - Analisar transações',
            '/api/health': 'GET - Verificar saúde da API'
        }
    }), 200


@app.route('/api/health', methods=['GET'])
def health():
    """Endpoint de health check."""
    return jsonify({
        'status': 'ok',
        'service': 'financial-analyzer-api'
    }), 200


@app.route('/api/analyze', methods=['POST', 'OPTIONS'])
def analyze():
    """
    Endpoint principal para análise de transações.
    
    Aceita:
    - JSON: {"transactions": [...]}
    - CSV: string com formato id,date,description,amount,currency
    
    Retorna:
    - JSON com análise completa
    """
    # Tratar preflight CORS
    if request.method == 'OPTIONS':
        return '', 204
    
    try:
        # Obter dados do request
        content_type = request.headers.get('Content-Type', '')
        
        if 'application/json' in content_type:
            data = request.get_json()
        else:
            # Assumir CSV ou JSON como texto
            data = request.get_data(as_text=True)
            
            # Tentar parse como JSON se não for CSV claro
            if not data.startswith('id,'):
                try:
                    import json
                    data = json.loads(data)
                except:
                    pass
        
        # Processar transações
        # use_gemini=True para usar IA, False para heurística
        use_gemini = request.args.get('use_gemini', 'true').lower() == 'true'
        
        result = process_transactions_dict(
            data, 
            use_gemini=use_gemini,
            show_progress=False
        )
        
        # Retornar resultado
        return jsonify(result), 200
        
    except Exception as e:
        # Log do erro (em produção, usar logging adequado)
        print(f"Error processing request: {str(e)}")
        
        return jsonify({
            'error': {
                'code': 500,
                'message': f'Erro ao processar: {str(e)}',
                'hint': 'Verifique o formato dos dados enviados'
            }
        }), 500


@app.errorhandler(404)
def not_found(error):
    """Handler para rotas não encontradas."""
    return jsonify({
        'error': {
            'code': 404,
            'message': 'Endpoint não encontrado',
            'hint': 'Verifique a URL. Use /api/analyze para análise'
        }
    }), 404


@app.errorhandler(500)
def internal_error(error):
    """Handler para erros internos."""
    return jsonify({
        'error': {
            'code': 500,
            'message': 'Erro interno do servidor',
            'hint': 'Tente novamente em alguns instantes'
        }
    }), 500


@app.route('/api/chat', methods=['POST'])
def chat():
    """
    Endpoint de chat com IA financeira.
    
    Body JSON:
    {
        "message": "Como posso economizar mais?",
        "context": {  // Opcional
            "transactions": [...],
            "summary": {...},
            "insights": {...}
        }
    }
    """
    try:
        data = request.get_json()
        
        if not data or 'message' not in data:
            return jsonify({
                "success": False,
                "error": "Message is required",
                "message": "Por favor, envie uma mensagem."
            }), 400
        
        user_message = data.get('message', '').strip()
        
        if not user_message:
            return jsonify({
                "success": False,
                "error": "Empty message",
                "message": "A mensagem não pode estar vazia."
            }), 400
        
        # Atualizar contexto se fornecido
        context = data.get('context')
        if context:
            transactions = context.get('transactions', [])
            summary = context.get('summary', {})
            insights = context.get('insights', {})
            chat_assistant.set_financial_context(transactions, summary, insights)
        
        # Processar mensagem
        response = chat_assistant.chat(user_message)
        
        return jsonify(response), 200 if response.get('success') else 500
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e),
            "message": "Erro ao processar mensagem do chat."
        }), 500


@app.route('/api/chat/insights', methods=['GET'])
def get_chat_insights():
    """Retorna insights rápidos sobre as finanças do usuário."""
    try:
        insights = chat_assistant.get_quick_insights()
        return jsonify(insights), 200
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e),
            "message": "Erro ao obter insights."
        }), 500


@app.route('/api/chat/optimize', methods=['GET'])
def get_budget_optimization():
    """Retorna sugestões de otimização de orçamento."""
    try:
        optimizations = chat_assistant.suggest_budget_optimization()
        return jsonify(optimizations), 200
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e),
            "message": "Erro ao gerar otimizações."
        }), 500


@app.route('/api/chat/history', methods=['GET'])
def get_chat_history():
    """Retorna histórico de conversação."""
    try:
        history = chat_assistant.get_conversation_history()
        return jsonify({
            "success": True,
            "history": history
        }), 200
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e),
            "message": "Erro ao obter histórico."
        }), 500


@app.route('/api/chat/clear', methods=['POST'])
def clear_chat_history():
    """Limpa o histórico de conversação."""
    try:
        chat_assistant.clear_history()
        return jsonify({
            "success": True,
            "message": "Histórico limpo com sucesso."
        }), 200
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e),
            "message": "Erro ao limpar histórico."
        }), 500


if __name__ == '__main__':
    # Configurações
    host = os.getenv('HOST', '0.0.0.0')
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('DEBUG', 'True').lower() == 'true'
    
    banner = f"""
+========================================================+
|   Financial Analyzer API                               |
|   Servidor rodando em http://{host}:{port}             |
|                                                        |
|   Endpoints:                                           |
|   - GET  /                     -> Info da API          |
|   - GET  /api/health           -> Health check         |
|   - POST /api/analyze          -> Analisar transacoes  |
|   - POST /api/chat             -> Chat com IA          |
|   - GET  /api/chat/insights    -> Insights rapidos     |
|   - GET  /api/chat/optimize    -> Otimizar orcamento   |
|   - GET  /api/chat/history     -> Historico do chat    |
|   - POST /api/chat/clear       -> Limpar historico     |
|                                                        |
|   Pressione Ctrl+C para parar                         |
+========================================================+
    """
    print(banner)
    
    app.run(host=host, port=port, debug=debug)
