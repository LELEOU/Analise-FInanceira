"""
Assistente de Chat com IA para consultoria financeira.
"""
from typing import List, Dict, Any, Optional
from datetime import datetime
from gemini_client import GeminiClient
from models import TransactionOutput


class FinancialChatAssistant:
    """Assistente de chat com IA especializado em finanças pessoais."""
    
    def __init__(self):
        self.gemini = GeminiClient()
        self.conversation_history = []
        self.context = {}
    
    def set_financial_context(
        self,
        transactions: List[TransactionOutput],
        summary: Dict[str, Any],
        insights: Dict[str, Any]
    ):
        """Define o contexto financeiro do usuário para melhorar as respostas."""
        self.context = {
            "transactions": transactions,
            "summary": summary,
            "insights": insights,
            "updated_at": datetime.now().isoformat()
        }
    
    def _build_system_prompt(self) -> str:
        """Constrói o prompt do sistema com contexto financeiro."""
        base_prompt = """Você é um assistente financeiro especializado em finanças pessoais.
Seu objetivo é ajudar o usuário a:
- Analisar seus gastos e receitas
- Identificar oportunidades de economia
- Sugerir otimizações no orçamento
- Dar dicas de planejamento financeiro
- Responder perguntas sobre suas transações

Seja objetivo, amigável e use exemplos práticos.
Use emojis quando apropriado para tornar a conversa mais leve.
"""
        
        if self.context:
            summary = self.context.get("summary", {})
            insights = self.context.get("insights", {})
            
            context_info = f"""
CONTEXTO FINANCEIRO DO USUÁRIO:

💰 Resumo Financeiro:
- Saldo Total: R$ {summary.get('balance', 0):.2f}
- Total de Receitas: R$ {summary.get('total_income', 0):.2f}
- Total de Despesas: R$ {summary.get('total_expense', 0):.2f}
- Número de Transações: {summary.get('transaction_count', 0)}

📊 Gastos por Categoria:
"""
            category_totals = summary.get('category_totals', {})
            for category, amount in sorted(category_totals.items(), key=lambda x: x[1], reverse=True):
                context_info += f"- {category}: R$ {amount:.2f}\n"
            
            # Adicionar alertas
            alerts = insights.get('alerts', [])
            if alerts:
                context_info += "\n⚠️ Alertas Importantes:\n"
                for alert in alerts[:3]:  # Top 3 alertas
                    context_info += f"- {alert.get('message', '')}\n"
            
            # Adicionar recomendações
            recommendations = insights.get('recommendations', [])
            if recommendations:
                context_info += "\n💡 Recomendações Ativas:\n"
                for rec in recommendations[:3]:  # Top 3 recomendações
                    context_info += f"- {rec.get('message', '')}\n"
            
            base_prompt += context_info
        
        return base_prompt
    
    def chat(self, user_message: str) -> Dict[str, Any]:
        """
        Processa uma mensagem do usuário e retorna resposta da IA.
        
        Args:
            user_message: Mensagem do usuário
            
        Returns:
            Dict com resposta da IA e metadados
        """
        try:
            # Adicionar mensagem ao histórico
            self.conversation_history.append({
                "role": "user",
                "content": user_message,
                "timestamp": datetime.now().isoformat()
            })
            
            # Construir prompt completo
            system_prompt = self._build_system_prompt()
            
            # Construir histórico de conversa para contexto
            conversation_context = "\n\n".join([
                f"{'Usuário' if msg['role'] == 'user' else 'Assistente'}: {msg['content']}"
                for msg in self.conversation_history[-6:]  # Últimas 6 mensagens
            ])
            
            full_prompt = f"{system_prompt}\n\nCONVERSA ATUAL:\n{conversation_context}"
            
            # Obter resposta do Gemini
            response = self.gemini.chat(full_prompt)
            
            if response and response.get("success"):
                ai_response = response.get("content", "Desculpe, não consegui processar sua mensagem.")
                
                # Adicionar resposta ao histórico
                self.conversation_history.append({
                    "role": "assistant",
                    "content": ai_response,
                    "timestamp": datetime.now().isoformat()
                })
                
                return {
                    "success": True,
                    "message": ai_response,
                    "suggestions": self._extract_suggestions(ai_response),
                    "timestamp": datetime.now().isoformat()
                }
            else:
                return {
                    "success": False,
                    "message": "Desculpe, tive um problema ao processar sua mensagem. Tente novamente.",
                    "error": response.get("error", "Unknown error")
                }
                
        except Exception as e:
            return {
                "success": False,
                "message": "Ocorreu um erro ao processar sua mensagem.",
                "error": str(e)
            }
    
    def _extract_suggestions(self, response: str) -> List[str]:
        """Extrai sugestões rápidas da resposta para botões de ação."""
        suggestions = []
        
        # Sugestões baseadas em palavras-chave
        keywords = {
            "gastar": "Quanto posso gastar este mês?",
            "economizar": "Como posso economizar mais?",
            "categoria": "Qual categoria gasta mais?",
            "orçamento": "Como criar um orçamento?",
            "dívida": "Como sair das dívidas?"
        }
        
        for keyword, suggestion in keywords.items():
            if keyword.lower() in response.lower() and len(suggestions) < 3:
                suggestions.append(suggestion)
        
        return suggestions
    
    def get_quick_insights(self) -> Dict[str, Any]:
        """Gera insights rápidos sobre as finanças do usuário."""
        if not self.context:
            return {
                "success": False,
                "message": "Nenhum dado financeiro disponível. Importe suas transações primeiro."
            }
        
        summary = self.context.get("summary", {})
        insights = self.context.get("insights", {})
        
        # Calcular métricas importantes
        balance = summary.get("balance", 0)
        total_income = summary.get("total_income", 0)
        total_expense = summary.get("total_expense", 0)
        savings_rate = (balance / total_income * 100) if total_income > 0 else 0
        
        # Identificar maior gasto
        category_totals = summary.get("category_totals", {})
        top_expense = max(category_totals.items(), key=lambda x: x[1]) if category_totals else ("", 0)
        
        quick_insights = {
            "success": True,
            "balance_status": "positivo" if balance > 0 else "negativo",
            "balance": balance,
            "savings_rate": savings_rate,
            "top_expense_category": top_expense[0],
            "top_expense_amount": top_expense[1],
            "alert_count": len(insights.get("alerts", [])),
            "recommendation_count": len(insights.get("recommendations", []))
        }
        
        return quick_insights
    
    def suggest_budget_optimization(self) -> Dict[str, Any]:
        """Sugere otimizações de orçamento baseadas nos dados."""
        if not self.context:
            return {
                "success": False,
                "message": "Importe suas transações para receber sugestões."
            }
        
        summary = self.context.get("summary", {})
        category_totals = summary.get("category_totals", {})
        total_expense = summary.get("total_expense", 0)
        
        optimizations = []
        
        # Analisar cada categoria
        for category, amount in category_totals.items():
            if amount <= 0:
                continue
                
            percentage = (amount / total_expense * 100) if total_expense > 0 else 0
            
            # Sugestões baseadas em porcentagens
            if category == "alimentacao" and percentage > 30:
                optimizations.append({
                    "category": category,
                    "current_amount": amount,
                    "current_percentage": percentage,
                    "suggested_percentage": 25,
                    "potential_savings": amount - (total_expense * 0.25),
                    "tip": "🍽️ Considere cozinhar mais em casa e reduzir pedidos de delivery."
                })
            
            elif category == "lazer" and percentage > 15:
                optimizations.append({
                    "category": category,
                    "current_amount": amount,
                    "current_percentage": percentage,
                    "suggested_percentage": 10,
                    "potential_savings": amount - (total_expense * 0.10),
                    "tip": "🎮 Busque opções de lazer gratuitas ou mais econômicas."
                })
            
            elif category == "transporte" and percentage > 20:
                optimizations.append({
                    "category": category,
                    "current_amount": amount,
                    "current_percentage": percentage,
                    "suggested_percentage": 15,
                    "potential_savings": amount - (total_expense * 0.15),
                    "tip": "🚗 Considere usar transporte público ou compartilhar caronas."
                })
        
        total_potential_savings = sum(opt["potential_savings"] for opt in optimizations)
        
        return {
            "success": True,
            "optimizations": optimizations,
            "total_potential_savings": total_potential_savings,
            "message": f"💰 Você pode economizar até R$ {total_potential_savings:.2f} por mês!"
        }
    
    def clear_history(self):
        """Limpa o histórico de conversação."""
        self.conversation_history = []
    
    def get_conversation_history(self) -> List[Dict[str, Any]]:
        """Retorna o histórico de conversação."""
        return self.conversation_history
