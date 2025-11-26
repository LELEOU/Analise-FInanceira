"""
Classificador de transações usando Gemini com fallback heurístico.
"""
from typing import Dict, Any, List
from gemini_client import GeminiClient
from heuristic_fallback import HeuristicClassifier
from models import TransactionInput, TransactionOutput
from validator import DataValidator
from config import VALID_CATEGORIES


class TransactionClassifier:
    """Classificador inteligente de transações."""
    
    def __init__(self, use_gemini: bool = True):
        """
        Inicializa o classificador.
        
        Args:
            use_gemini: Se True, tenta usar Gemini; se False, usa apenas heurística
        """
        self.use_gemini = use_gemini
        self.gemini_client = None
        
        if use_gemini:
            try:
                self.gemini_client = GeminiClient()
            except ValueError as e:
                print(f"Gemini not available: {e}. Using heuristic fallback.")
                self.use_gemini = False
    
    def classify_transaction(self, transaction: TransactionInput) -> TransactionOutput:
        """
        Classifica uma única transação.
        
        Args:
            transaction: Transação de entrada
            
        Returns:
            Transação classificada
        """
        txn_dict = {
            'description': transaction.description,
            'amount': transaction.amount,
            'currency': transaction.currency,
            'raw': transaction.raw
        }
        
        classification = None
        model_version = "heuristic-fallback-v1"
        
        # Tentar Gemini primeiro
        if self.use_gemini and self.gemini_client:
            try:
                classification = self.gemini_client.classify_transaction(txn_dict)
                if classification:
                    model_version = "gemini-v1.0"
            except Exception as e:
                print(f"Gemini classification failed: {e}")
        
        # Fallback heurístico
        if not classification:
            classification = HeuristicClassifier.classify(txn_dict)
        
        # Validar categoria
        if classification['category'] not in VALID_CATEGORIES:
            classification['category'] = 'outros'
            classification['confidence'] = min(classification['confidence'], 0.3)
        
        # Normalizar descrição
        normalized_desc = DataValidator.normalize_description(transaction.description)
        
        # Criar output
        return TransactionOutput(
            id=transaction.id,
            date=transaction.date,
            description=transaction.description,
            amount=transaction.amount,
            currency=transaction.currency,
            category=classification['category'],
            subcategory=classification.get('subcategory'),
            confidence=classification['confidence'],
            normalized_description=normalized_desc,
            explanation=classification.get('explanation')
        )
    
    def classify_batch(
        self, 
        transactions: List[TransactionInput],
        show_progress: bool = False
    ) -> List[TransactionOutput]:
        """
        Classifica um lote de transações.
        
        Args:
            transactions: Lista de transações
            show_progress: Se True, mostra progresso
            
        Returns:
            Lista de transações classificadas
        """
        classified = []
        total = len(transactions)
        
        for idx, txn in enumerate(transactions):
            if show_progress and (idx % 10 == 0 or idx == total - 1):
                print(f"Classificando: {idx + 1}/{total}")
            
            classified.append(self.classify_transaction(txn))
        
        return classified
