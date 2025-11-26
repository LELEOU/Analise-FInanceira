"""
Classificador heurístico de fallback para transações.
"""
from typing import Dict, Any, Optional
from config import HEURISTIC_KEYWORDS, SUBCATEGORIES, HEURISTIC_CONFIDENCE_RANGE


class HeuristicClassifier:
    """Classificador baseado em palavras-chave para fallback."""
    
    @staticmethod
    def classify(transaction: Dict[str, Any]) -> Dict[str, Any]:
        """
        Classifica transação usando regras heurísticas.
        
        Args:
            transaction: Dicionário com dados da transação
            
        Returns:
            Dicionário com classificação
        """
        description = transaction['description'].lower()
        amount = transaction['amount']
        
        # Detectar categoria
        category = "outros"
        subcategory = None
        confidence = HEURISTIC_CONFIDENCE_RANGE[0]
        matches = []
        
        # Verificar keywords
        for cat, keywords in HEURISTIC_KEYWORDS.items():
            for keyword in keywords:
                if keyword in description:
                    matches.append((cat, keyword))
        
        # Se houver matches, usar a categoria mais provável
        if matches:
            # Pegar categoria mais frequente
            category_counts = {}
            for cat, keyword in matches:
                category_counts[cat] = category_counts.get(cat, 0) + 1
            
            category = max(category_counts, key=category_counts.get)
            
            # Aumentar confidence se múltiplos matches
            match_count = category_counts[category]
            confidence = min(
                HEURISTIC_CONFIDENCE_RANGE[1], 
                HEURISTIC_CONFIDENCE_RANGE[0] + (match_count * 0.1)
            )
            
            # Tentar inferir subcategoria
            subcategory = HeuristicClassifier._infer_subcategory(
                category, description, matches
            )
        
        # Regra especial para receitas (valores positivos altos)
        if amount > 500 and category == "outros":
            category = "renda"
            subcategory = "outros"
            confidence = 0.4
        
        # Regra especial para transferências
        if any(word in description for word in ['pix', 'ted', 'doc', 'transf']):
            category = "transferencia"
            subcategory = "pix" if "pix" in description else "ted"
            confidence = min(0.6, confidence + 0.1)
        
        explanation = HeuristicClassifier._generate_explanation(
            category, subcategory, matches
        )
        
        return {
            "category": category,
            "subcategory": subcategory,
            "confidence": round(confidence, 2),
            "explanation": explanation
        }
    
    @staticmethod
    def _infer_subcategory(
        category: str, 
        description: str, 
        matches: list
    ) -> Optional[str]:
        """Infere subcategoria baseada nos matches."""
        if category not in SUBCATEGORIES or not SUBCATEGORIES[category]:
            return None
        
        # Procurar subcategoria específica nos matches
        for cat, keyword in matches:
            if cat == category:
                # Tentar mapear keyword para subcategoria
                for subcat in SUBCATEGORIES[category]:
                    if subcat in keyword or keyword in subcat:
                        return subcat
        
        # Mapeamento direto de keywords comuns
        subcat_mapping = {
            "alimentacao": {
                "supermercado": "supermercado",
                "mercado": "supermercado",
                "padaria": "padaria",
                "restaurante": "restaurante",
                "lanchonete": "lanchonete",
                "ifood": "delivery",
                "rappi": "delivery",
            },
            "transporte": {
                "uber": "uber",
                "99": "taxi",
                "gas": "combustivel",
                "gasolina": "combustivel",
                "posto": "combustivel",
            },
            "saude": {
                "farmacia": "farmacia",
                "drogaria": "farmacia",
                "consulta": "consulta",
                "plano": "plano_saude",
            },
            "contas": {
                "luz": "luz",
                "energia": "luz",
                "agua": "agua",
                "internet": "internet",
                "telefone": "telefone",
            },
            "renda": {
                "salario": "salario",
                "freelance": "freelance",
            }
        }
        
        if category in subcat_mapping:
            for keyword, subcat in subcat_mapping[category].items():
                if keyword in description:
                    return subcat
        
        return None
    
    @staticmethod
    def _generate_explanation(
        category: str, 
        subcategory: Optional[str],
        matches: list
    ) -> str:
        """Gera explicação para a classificação."""
        if not matches:
            return "Classificação baseada em análise heurística padrão."
        
        keywords_found = list(set([kw for _, kw in matches if _ == category]))
        
        if subcategory:
            return (
                f"Identificado como {category}/{subcategory} "
                f"baseado em palavras-chave: {', '.join(keywords_found[:2])}."
            )
        else:
            return (
                f"Classificado como {category} "
                f"por correspondência com: {', '.join(keywords_found[:2])}."
            )
