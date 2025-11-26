"""
Modelos de dados usando Pydantic para validação e serialização.
"""
from typing import Optional, List, Dict, Any, Literal
from datetime import datetime, date
from pydantic import BaseModel, Field, validator


class TransactionInput(BaseModel):
    """Modelo de entrada de uma transação."""
    id: str
    date: str
    description: str
    amount: float
    currency: str = "BRL"
    raw: Optional[str] = None

    class Config:
        json_schema_extra = {
            "example": {
                "id": "txn_001",
                "date": "2025-11-10",
                "description": "PADARIA PAO DOCE",
                "amount": -25.90,
                "currency": "BRL",
                "raw": "10/11/2025 PADARIA PAO DOCE 25.90"
            }
        }


class TransactionOutput(BaseModel):
    """Modelo de saída de uma transação processada."""
    id: str
    date: str  # ISO8601 format
    description: str
    amount: float
    currency: str
    category: str
    subcategory: Optional[str] = None
    confidence: float = Field(ge=0.0, le=1.0)
    normalized_description: str
    explanation: Optional[str] = None

    @validator('category')
    def validate_category(cls, v):
        from .config import VALID_CATEGORIES
        if v not in VALID_CATEGORIES:
            raise ValueError(f"Category must be one of {VALID_CATEGORIES}")
        return v


class TrendInfo(BaseModel):
    """Informações de tendência de uma categoria."""
    change_pct: float
    direction: Literal["up", "down", "stable"]


class Alert(BaseModel):
    """Modelo de alerta."""
    type: Literal["high_spend", "low_balance", "unusual_category", "possible_duplicate"]
    message: str
    related_category: Optional[str] = None


class Recommendation(BaseModel):
    """Modelo de recomendação."""
    id: str
    text: str = Field(max_length=250)
    impact_estimate_pct: Optional[float] = None


class Summary(BaseModel):
    """Resumo financeiro do período."""
    period_start: str  # ISO8601 date
    period_end: str  # ISO8601 date
    total_income: float
    total_expenses: float
    by_category: Dict[str, float]
    top_3_expense_categories: List[str]
    trend: Dict[str, Dict[str, TrendInfo]] = Field(default_factory=lambda: {"category_trends": {}})
    alerts: List[Alert] = Field(default_factory=list)
    recommendations: List[Recommendation] = Field(default_factory=list)


class ProcessedResult(BaseModel):
    """Resultado completo do processamento."""
    user_id: Optional[str] = None
    processed_at: str  # ISO8601 timestamp
    transactions: List[TransactionOutput]
    summary: Summary
    model_version: str
    processing_notes: Optional[str] = None


class ErrorResponse(BaseModel):
    """Resposta de erro padronizada."""
    error: Dict[str, Any]

    class Config:
        json_schema_extra = {
            "example": {
                "error": {
                    "code": 400,
                    "message": "Invalid input format",
                    "hint": "Please provide transactions as JSON array or CSV string"
                }
            }
        }


class BatchInput(BaseModel):
    """Modelo de entrada em lote."""
    user_id: Optional[str] = None
    transactions: List[TransactionInput]
    historical_data: Optional[List[Dict[str, Any]]] = None  # Para cálculo de tendências

    @validator('transactions')
    def validate_batch_size(cls, v):
        from .config import MAX_TRANSACTIONS_PER_BATCH
        if len(v) > MAX_TRANSACTIONS_PER_BATCH:
            raise ValueError(
                f"Batch size exceeds maximum of {MAX_TRANSACTIONS_PER_BATCH} transactions. "
                f"Please split into smaller batches."
            )
        return v
