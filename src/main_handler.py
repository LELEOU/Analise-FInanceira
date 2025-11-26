"""
Handler principal para processamento de transações bancárias.
"""
import json
from typing import Any, Union
from datetime import datetime

from validator import DataValidator, ValidationError
from classifier import TransactionClassifier
from insights_generator import InsightsGenerator
from models import ProcessedResult, ErrorResponse


def process_transactions(
    data: Union[str, dict, list],
    use_gemini: bool = True,
    show_progress: bool = False
) -> str:
    """
    Handler principal para processar transações.
    
    Args:
        data: Dados de entrada (JSON dict/list ou CSV string)
        use_gemini: Se True, usa Gemini; se False, apenas heurística
        show_progress: Se True, mostra progresso no console
        
    Returns:
        JSON string com resultado ou erro
    """
    try:
        # Validar e normalizar entrada
        if show_progress:
            print("Validando entrada...")
        
        batch = DataValidator.validate_and_normalize_batch(data)
        
        # Verificar duplicatas
        duplicates = DataValidator.detect_duplicates(batch.transactions)
        processing_notes = []
        
        if duplicates:
            processing_notes.append(
                f"Detected {len(duplicates)} possible duplicate transaction(s)"
            )
        
        # Classificar transações
        if show_progress:
            print(f"Classificando {len(batch.transactions)} transações...")
        
        classifier = TransactionClassifier(use_gemini=use_gemini)
        classified_transactions = classifier.classify_batch(
            batch.transactions,
            show_progress=show_progress
        )
        
        # Determinar versão do modelo
        model_version = "gemini-v1.0" if use_gemini else "heuristic-fallback-v1"
        
        # Verificar se alguma usou fallback
        if use_gemini:
            low_conf_count = sum(1 for t in classified_transactions if t.confidence < 0.6)
            if low_conf_count > len(classified_transactions) * 0.3:
                model_version = "gemini-v1.0-with-fallback"
                processing_notes.append(
                    f"{low_conf_count} transactions classified with heuristic fallback"
                )
        
        # Gerar insights e resumo
        if show_progress:
            print("Gerando insights...")
        
        insights_gen = InsightsGenerator(use_gemini=use_gemini)
        summary = insights_gen.generate_summary(
            classified_transactions,
            batch.historical_data
        )
        
        # Montar resultado
        result = ProcessedResult(
            user_id=batch.user_id,
            processed_at=datetime.now().isoformat(),
            transactions=classified_transactions,
            summary=summary,
            model_version=model_version,
            processing_notes="; ".join(processing_notes) if processing_notes else None
        )
        
        # Retornar JSON
        return result.model_dump_json(indent=2, exclude_none=False)
        
    except ValidationError as e:
        error = ErrorResponse(error={
            "code": 400,
            "message": str(e),
            "hint": "Verifique o formato dos dados de entrada. Use JSON array ou CSV válido."
        })
        return error.model_dump_json(indent=2)
        
    except Exception as e:
        error = ErrorResponse(error={
            "code": 500,
            "message": f"Internal processing error: {str(e)}",
            "hint": "Tente novamente ou contate o suporte se o erro persistir."
        })
        return error.model_dump_json(indent=2)


def process_transactions_dict(
    data: Union[str, dict, list],
    use_gemini: bool = True,
    show_progress: bool = False
) -> dict:
    """
    Versão que retorna dict ao invés de JSON string.
    
    Args:
        data: Dados de entrada
        use_gemini: Se True, usa Gemini
        show_progress: Se True, mostra progresso
        
    Returns:
        Dicionário com resultado ou erro
    """
    json_result = process_transactions(data, use_gemini, show_progress)
    return json.loads(json_result)


# Função de conveniência para usar como API
def handle_request(request_body: str) -> str:
    """
    Handler para request HTTP/API.
    
    Args:
        request_body: Body da requisição (JSON ou CSV)
        
    Returns:
        JSON string de resposta
    """
    try:
        # Tentar parse como JSON
        data = json.loads(request_body)
    except json.JSONDecodeError:
        # Se não for JSON, assumir CSV
        data = request_body
    
    return process_transactions(data, use_gemini=True, show_progress=False)


if __name__ == "__main__":
    # Exemplo de uso
    print("=== Sistema de Análise de Transações ===\n")
    
    # Exemplo com dados de teste
    test_data = {
        "user_id": "user_001",
        "transactions": [
            {
                "id": "txn_001",
                "date": "2025-11-10",
                "description": "PADARIA PAO DOCE",
                "amount": -25.90,
                "currency": "BRL",
                "raw": "10/11/2025 PADARIA PAO DOCE 25.90"
            },
            {
                "id": "txn_002",
                "date": "2025-11-09",
                "description": "POSTO SHELL",
                "amount": -150.00,
                "currency": "BRL",
                "raw": "09/11/2025 POSTO SHELL 150.00"
            },
            {
                "id": "txn_003",
                "date": "2025-11-09",
                "description": "SALARIO NOVEMBRO",
                "amount": 3500.00,
                "currency": "BRL",
                "raw": "09/11/2025 DEPOSITO SALARIO 3500.00"
            },
            {
                "id": "txn_004",
                "date": "2025-11-08",
                "description": "SUPERMERCADO EXTRA",
                "amount": -245.80,
                "currency": "BRL",
                "raw": "08/11/2025 SUPERMERCADO EXTRA 245.80"
            },
            {
                "id": "txn_005",
                "date": "2025-11-07",
                "description": "UBER VIAGEM",
                "amount": -32.50,
                "currency": "BRL",
                "raw": "07/11/2025 UBER 32.50"
            }
        ]
    }
    
    print("Processando transações de exemplo...\n")
    result_json = process_transactions(test_data, use_gemini=False, show_progress=True)
    
    print("\n=== RESULTADO ===")
    print(result_json)
