"""
Módulo de validação e normalização de dados.
"""
import re
import csv
from io import StringIO
from datetime import datetime
from typing import List, Optional, Dict, Any
from dateutil import parser as date_parser

from config import (
    DATE_FORMATS,
    SENSITIVE_PATTERNS,
    MAX_DESCRIPTION_LENGTH
)
from models import TransactionInput, BatchInput


class ValidationError(Exception):
    """Exceção customizada para erros de validação."""
    pass


class DataValidator:
    """Classe para validação e normalização de dados de entrada."""

    @staticmethod
    def parse_csv(csv_string: str) -> List[Dict[str, Any]]:
        """
        Parse CSV string para lista de dicionários.
        
        Args:
            csv_string: String contendo dados CSV
            
        Returns:
            Lista de dicionários com os dados
            
        Raises:
            ValidationError: Se o CSV for inválido
        """
        try:
            csv_file = StringIO(csv_string.strip())
            reader = csv.DictReader(csv_file)
            
            required_fields = {'id', 'date', 'description', 'amount'}
            if not required_fields.issubset(set(reader.fieldnames or [])):
                raise ValidationError(
                    f"CSV must contain fields: {required_fields}"
                )
            
            transactions = []
            for row in reader:
                # Converter amount para float
                try:
                    row['amount'] = float(row['amount'])
                except (ValueError, KeyError):
                    raise ValidationError(f"Invalid amount in row: {row}")
                
                # Adicionar campos opcionais se não existirem
                row.setdefault('currency', 'BRL')
                row.setdefault('raw', None)
                
                transactions.append(row)
            
            if not transactions:
                raise ValidationError("CSV contains no data rows")
            
            return transactions
            
        except csv.Error as e:
            raise ValidationError(f"CSV parsing error: {str(e)}")

    @staticmethod
    def normalize_date(date_str: str, raw: Optional[str] = None) -> Optional[str]:
        """
        Normaliza data para formato ISO8601 (YYYY-MM-DD).
        
        Args:
            date_str: String com a data
            raw: Campo raw para tentar extrair data alternativa
            
        Returns:
            Data em formato ISO8601 ou None se não conseguir parsear
        """
        # Tentar formatos específicos primeiro
        for fmt in DATE_FORMATS:
            try:
                dt = datetime.strptime(date_str.strip(), fmt)
                return dt.date().isoformat()
            except ValueError:
                continue
        
        # Tentar parser inteligente
        try:
            dt = date_parser.parse(date_str, dayfirst=True)
            return dt.date().isoformat()
        except (ValueError, TypeError):
            pass
        
        # Tentar extrair do campo raw
        if raw:
            try:
                # Procurar padrão de data no raw
                date_match = re.search(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}', raw)
                if date_match:
                    return DataValidator.normalize_date(date_match.group(), None)
            except Exception:
                pass
        
        return None

    @staticmethod
    def normalize_description(description: str) -> str:
        """
        Normaliza descrição da transação.
        
        Args:
            description: Descrição original
            
        Returns:
            Descrição normalizada
        """
        # Remover caracteres especiais excessivos
        normalized = re.sub(r'[^\w\s\-.,áàâãéèêíïóôõöúçñÁÀÂÃÉÈÊÍÏÓÔÕÖÚÇÑ]', '', description)
        
        # Remover espaços múltiplos
        normalized = re.sub(r'\s+', ' ', normalized).strip()
        
        # Remover números de referência/códigos longos no final
        normalized = re.sub(r'\s+\d{5,}$', '', normalized)
        
        # Title case
        normalized = normalized.title()
        
        # Truncar se muito longo
        if len(normalized) > MAX_DESCRIPTION_LENGTH:
            normalized = normalized[:MAX_DESCRIPTION_LENGTH].rsplit(' ', 1)[0] + '...'
        
        return normalized or description[:50]

    @staticmethod
    def mask_sensitive_data(text: str) -> tuple[str, bool]:
        """
        Mascara dados sensíveis no texto.
        
        Args:
            text: Texto a ser verificado
            
        Returns:
            Tupla (texto_mascarado, tem_dados_sensiveis)
        """
        has_sensitive = False
        masked = text
        
        for pattern in SENSITIVE_PATTERNS:
            if re.search(pattern, masked):
                has_sensitive = True
                masked = re.sub(pattern, '***', masked)
        
        return masked, has_sensitive

    @staticmethod
    def normalize_amount(amount: float, description: str) -> float:
        """
        Normaliza o valor da transação (gastos negativos, receitas positivas).
        
        Args:
            amount: Valor original
            description: Descrição para inferir contexto
            
        Returns:
            Valor normalizado
        """
        # Keywords que indicam receita
        income_keywords = ['salario', 'deposito', 'credito', 'recebimento', 
                          'rendimento', 'dividendo', 'bonus', 'restituicao']
        
        desc_lower = description.lower()
        is_income = any(keyword in desc_lower for keyword in income_keywords)
        
        # Se parece receita mas está negativo, inverter
        if is_income and amount < 0:
            return abs(amount)
        
        # Se não parece receita mas está positivo, tornar negativo
        if not is_income and amount > 0:
            # Verificar se não é transferência/pix que pode ser positivo
            transfer_keywords = ['pix', 'ted', 'doc', 'transf']
            is_transfer = any(keyword in desc_lower for keyword in transfer_keywords)
            if not is_transfer:
                return -amount
        
        return amount

    @staticmethod
    def validate_and_normalize_batch(data: Any) -> BatchInput:
        """
        Valida e normaliza um lote de transações.
        
        Args:
            data: Dados de entrada (dict, list ou CSV string)
            
        Returns:
            BatchInput validado e normalizado
            
        Raises:
            ValidationError: Se dados inválidos
        """
        # Se for string, tentar parse como CSV
        if isinstance(data, str):
            transactions_list = DataValidator.parse_csv(data)
            data = {"transactions": transactions_list}
        
        # Se for lista direta, envolver em dict
        if isinstance(data, list):
            data = {"transactions": data}
        
        # Validar estrutura básica
        if not isinstance(data, dict) or 'transactions' not in data:
            raise ValidationError(
                "Input must be a dict with 'transactions' key or a CSV string"
            )
        
        # Normalizar cada transação
        normalized_transactions = []
        processing_notes = []
        
        for idx, txn in enumerate(data['transactions']):
            try:
                # Validar campos obrigatórios
                if not all(k in txn for k in ['id', 'date', 'description', 'amount']):
                    raise ValidationError(f"Transaction {idx} missing required fields")
                
                # Normalizar data
                normalized_date = DataValidator.normalize_date(
                    txn['date'], 
                    txn.get('raw')
                )
                
                if not normalized_date:
                    processing_notes.append(
                        f"Could not parse date for transaction {txn['id']}"
                    )
                    normalized_date = datetime.now().date().isoformat()
                
                # Normalizar descrição
                description = str(txn['description'])
                normalized_desc = DataValidator.normalize_description(description)
                
                # Mascarar dados sensíveis
                masked_desc, has_sensitive = DataValidator.mask_sensitive_data(normalized_desc)
                if has_sensitive:
                    processing_notes.append(
                        f"Masked sensitive data in transaction {txn['id']}"
                    )
                    normalized_desc = masked_desc
                
                # Normalizar valor
                amount = float(txn['amount'])
                normalized_amount = DataValidator.normalize_amount(amount, description)
                
                # Criar objeto validado
                normalized_txn = TransactionInput(
                    id=str(txn['id']),
                    date=normalized_date,
                    description=description,
                    amount=normalized_amount,
                    currency=txn.get('currency', 'BRL'),
                    raw=txn.get('raw')
                )
                
                normalized_transactions.append(normalized_txn)
                
            except Exception as e:
                raise ValidationError(
                    f"Error processing transaction {idx}: {str(e)}"
                )
        
        # Criar BatchInput
        batch = BatchInput(
            user_id=data.get('user_id'),
            transactions=normalized_transactions,
            historical_data=data.get('historical_data')
        )
        
        return batch

    @staticmethod
    def detect_duplicates(transactions: List[TransactionInput]) -> List[tuple[int, int]]:
        """
        Detecta possíveis transações duplicadas.
        
        Args:
            transactions: Lista de transações
            
        Returns:
            Lista de pares de índices de possíveis duplicatas
        """
        duplicates = []
        
        for i, txn1 in enumerate(transactions):
            for j, txn2 in enumerate(transactions[i+1:], start=i+1):
                # Considerar duplicata se mesmo valor, data próxima e descrição similar
                if (abs(txn1.amount - txn2.amount) < 0.01 and
                    txn1.date == txn2.date and
                    txn1.description[:20] == txn2.description[:20]):
                    duplicates.append((i, j))
        
        return duplicates
