"""
Gerador de insights, resumos e recomendações financeiras.
"""
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from collections import defaultdict

from models import TransactionOutput, Summary, Alert, Recommendation, TrendInfo
from gemini_client import GeminiClient
from config import TREND_THRESHOLD_UP, TREND_THRESHOLD_DOWN, VALID_CATEGORIES


class InsightsGenerator:
    """Gerador de insights e análises financeiras."""
    
    def __init__(self, use_gemini: bool = True):
        """
        Inicializa o gerador de insights.
        
        Args:
            use_gemini: Se True, usa Gemini para insights avançados
        """
        self.use_gemini = use_gemini
        self.gemini_client = None
        
        if use_gemini:
            try:
                self.gemini_client = GeminiClient()
            except ValueError:
                self.use_gemini = False
    
    def generate_summary(
        self,
        transactions: List[TransactionOutput],
        historical_data: Optional[List[Dict[str, Any]]] = None
    ) -> Summary:
        """
        Gera resumo completo das transações.
        
        Args:
            transactions: Lista de transações classificadas
            historical_data: Dados históricos para análise de tendências
            
        Returns:
            Objeto Summary com análise completa
        """
        if not transactions:
            return self._empty_summary()
        
        # Calcular totais por categoria
        by_category = self._calculate_by_category(transactions)
        
        # Calcular totais gerais
        total_income = sum(t.amount for t in transactions if t.amount > 0)
        total_expenses = abs(sum(t.amount for t in transactions if t.amount < 0))
        
        # Top 3 categorias de gasto
        expense_categories = {
            cat: abs(val) for cat, val in by_category.items() 
            if val < 0
        }
        top_3 = sorted(
            expense_categories.items(), 
            key=lambda x: x[1], 
            reverse=True
        )[:3]
        top_3_categories = [cat for cat, _ in top_3]
        
        # Período
        dates = [datetime.fromisoformat(t.date) for t in transactions]
        period_start = min(dates).date().isoformat()
        period_end = max(dates).date().isoformat()
        
        # Análise de tendências
        trend = self._calculate_trends(by_category, historical_data)
        
        # Gerar alertas
        alerts = self._generate_alerts(
            by_category, 
            total_expenses, 
            historical_data,
            transactions
        )
        
        # Gerar recomendações
        recommendations = self._generate_recommendations(
            by_category,
            total_income,
            total_expenses,
            trend,
            historical_data
        )
        
        return Summary(
            period_start=period_start,
            period_end=period_end,
            total_income=round(total_income, 2),
            total_expenses=round(total_expenses, 2),
            by_category={k: round(v, 2) for k, v in by_category.items()},
            top_3_expense_categories=top_3_categories,
            trend={"category_trends": trend},
            alerts=alerts,
            recommendations=recommendations
        )
    
    def _calculate_by_category(
        self, 
        transactions: List[TransactionOutput]
    ) -> Dict[str, float]:
        """Calcula totais por categoria."""
        by_category = defaultdict(float)
        
        for txn in transactions:
            by_category[txn.category] += txn.amount
        
        return dict(by_category)
    
    def _calculate_trends(
        self,
        current_by_category: Dict[str, float],
        historical_data: Optional[List[Dict[str, Any]]]
    ) -> Dict[str, TrendInfo]:
        """Calcula tendências por categoria."""
        trends = {}
        
        if not historical_data:
            # Sem dados históricos, marcar tudo como stable
            for category in current_by_category:
                trends[category] = TrendInfo(change_pct=0.0, direction="stable")
            return trends
        
        # Agregar dados históricos por categoria
        historical_by_category = defaultdict(list)
        for hist in historical_data:
            if 'category' in hist and 'amount' in hist:
                historical_by_category[hist['category']].append(abs(hist['amount']))
        
        # Calcular média histórica
        historical_avg = {
            cat: sum(vals) / len(vals) if vals else 0
            for cat, vals in historical_by_category.items()
        }
        
        # Comparar com período atual
        for category, current_total in current_by_category.items():
            current_abs = abs(current_total)
            
            if category in historical_avg and historical_avg[category] > 0:
                avg = historical_avg[category]
                change_pct = ((current_abs - avg) / avg) * 100
                
                if change_pct >= TREND_THRESHOLD_UP:
                    direction = "up"
                elif change_pct <= TREND_THRESHOLD_DOWN:
                    direction = "down"
                else:
                    direction = "stable"
                
                trends[category] = TrendInfo(
                    change_pct=round(change_pct, 1),
                    direction=direction
                )
            else:
                trends[category] = TrendInfo(change_pct=0.0, direction="stable")
        
        return trends
    
    def _generate_alerts(
        self,
        by_category: Dict[str, float],
        total_expenses: float,
        historical_data: Optional[List[Dict[str, Any]]],
        transactions: List[TransactionOutput]
    ) -> List[Alert]:
        """Gera alertas baseados em padrões anormais."""
        alerts = []
        
        # Alerta de gasto elevado por categoria (>30% do total)
        for category, amount in by_category.items():
            if amount < 0:  # Apenas despesas
                pct_of_total = (abs(amount) / total_expenses * 100) if total_expenses > 0 else 0
                if pct_of_total > 30:
                    alerts.append(Alert(
                        type="high_spend",
                        message=f"{category.title()} representa {pct_of_total:.0f}% dos gastos totais",
                        related_category=category
                    ))
        
        # Alerta de categoria incomum (confiança baixa em várias transações)
        low_confidence_by_cat = defaultdict(int)
        for txn in transactions:
            if txn.confidence < 0.5:
                low_confidence_by_cat[txn.category] += 1
        
        for category, count in low_confidence_by_cat.items():
            if count >= 3:
                alerts.append(Alert(
                    type="unusual_category",
                    message=f"{count} transações em {category} com baixa confiança de classificação",
                    related_category=category
                ))
        
        # Se houver dados históricos, comparar gastos
        if historical_data:
            historical_total = sum(abs(h.get('amount', 0)) for h in historical_data)
            if historical_total > 0:
                change_pct = ((total_expenses - historical_total) / historical_total) * 100
                if change_pct > 20:
                    alerts.append(Alert(
                        type="high_spend",
                        message=f"Gastos {change_pct:.0f}% acima da média dos últimos períodos",
                        related_category=None
                    ))
        
        return alerts[:5]  # Limitar a 5 alertas
    
    def _generate_recommendations(
        self,
        by_category: Dict[str, float],
        total_income: float,
        total_expenses: float,
        trend: Dict[str, TrendInfo],
        historical_data: Optional[List[Dict[str, Any]]]
    ) -> List[Recommendation]:
        """Gera recomendações de economia."""
        recommendations = []
        
        # Usar Gemini se disponível
        if self.use_gemini and self.gemini_client:
            try:
                insights = self.gemini_client.generate_insights(
                    {
                        'by_category': by_category,
                        'total_income': total_income,
                        'total_expenses': total_expenses
                    },
                    historical_data
                )
                
                if insights and 'recommendations' in insights:
                    for rec in insights['recommendations'][:3]:
                        recommendations.append(Recommendation(
                            id=rec.get('id', f"rec_{len(recommendations) + 1}"),
                            text=rec.get('text', ''),
                            impact_estimate_pct=rec.get('impact_estimate_pct')
                        ))
                    return recommendations
            except Exception as e:
                print(f"Failed to generate Gemini recommendations: {e}")
        
        # Recomendações heurísticas
        
        # 1. Taxa de poupança
        if total_income > 0:
            savings_rate = ((total_income - total_expenses) / total_income) * 100
            if savings_rate < 10:
                recommendations.append(Recommendation(
                    id="rec_savings",
                    text="Sua taxa de poupança está abaixo de 10%. Tente guardar pelo menos 10-20% da renda mensal para segurança financeira.",
                    impact_estimate_pct=10
                ))
        
        # 2. Categoria com maior gasto
        max_expense_cat = max(
            ((cat, abs(val)) for cat, val in by_category.items() if val < 0),
            key=lambda x: x[1],
            default=(None, 0)
        )
        
        if max_expense_cat[0] and max_expense_cat[1] > 0:
            cat_name = max_expense_cat[0]
            if cat_name in trend and trend[cat_name].direction == "up":
                recommendations.append(Recommendation(
                    id=f"rec_{cat_name}",
                    text=f"Gastos em {cat_name} estão em alta. Avalie possibilidades de redução nesta categoria para economizar.",
                    impact_estimate_pct=abs(int(trend[cat_name].change_pct))
                ))
        
        # 3. Recomendação geral de corte
        if not recommendations and total_expenses > total_income * 0.8:
            recommendations.append(Recommendation(
                id="rec_general",
                text="Considere revisar pequenas despesas recorrentes (assinaturas, delivery) que somadas fazem diferença no orçamento.",
                impact_estimate_pct=5
            ))
        
        return recommendations[:3]  # Máximo 3 recomendações
    
    def _empty_summary(self) -> Summary:
        """Retorna summary vazio para lista vazia de transações."""
        now = datetime.now().date().isoformat()
        return Summary(
            period_start=now,
            period_end=now,
            total_income=0.0,
            total_expenses=0.0,
            by_category={},
            top_3_expense_categories=[],
            trend={"category_trends": {}},
            alerts=[],
            recommendations=[]
        )
