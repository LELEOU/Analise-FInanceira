"""
Testes unitários para o sistema de análise de transações.
"""
import json
import unittest
from src.main_handler import process_transactions_dict
from src.validator import DataValidator, ValidationError
from src.heuristic_fallback import HeuristicClassifier


class TestTransactionProcessing(unittest.TestCase):
    """Testes para processamento de transações."""
    
    def setUp(self):
        """Setup para cada teste."""
        self.sample_transactions = [
            {
                "id": "txn_001",
                "date": "2025-11-10",
                "description": "PADARIA PAO DOCE",
                "amount": -25.90,
                "currency": "BRL"
            },
            {
                "id": "txn_002",
                "date": "2025-11-09",
                "description": "POSTO IPIRANGA",
                "amount": -200.00,
                "currency": "BRL"
            }
        ]
    
    def test_json_input(self):
        """Testa entrada em formato JSON."""
        data = {"transactions": self.sample_transactions}
        result = process_transactions_dict(data, use_gemini=False)
        
        self.assertIn('transactions', result)
        self.assertIn('summary', result)
        self.assertEqual(len(result['transactions']), 2)
    
    def test_csv_input(self):
        """Testa entrada em formato CSV."""
        csv_data = """id,date,description,amount,currency
txn_001,2025-11-10,PADARIA PAO DOCE,-25.90,BRL
txn_002,2025-11-09,POSTO IPIRANGA,-200.00,BRL"""
        
        result = process_transactions_dict(csv_data, use_gemini=False)
        
        self.assertIn('transactions', result)
        self.assertEqual(len(result['transactions']), 2)
    
    def test_category_classification(self):
        """Testa classificação de categorias."""
        data = {"transactions": self.sample_transactions}
        result = process_transactions_dict(data, use_gemini=False)
        
        # Verificar se categorias foram atribuídas
        for txn in result['transactions']:
            self.assertIn('category', txn)
            self.assertIn('confidence', txn)
            self.assertIsInstance(txn['confidence'], (int, float))
            self.assertGreaterEqual(txn['confidence'], 0.0)
            self.assertLessEqual(txn['confidence'], 1.0)
    
    def test_summary_generation(self):
        """Testa geração de resumo."""
        data = {"transactions": self.sample_transactions}
        result = process_transactions_dict(data, use_gemini=False)
        
        summary = result['summary']
        self.assertIn('total_income', summary)
        self.assertIn('total_expenses', summary)
        self.assertIn('by_category', summary)
        self.assertIn('top_3_expense_categories', summary)
        
        # Verificar cálculos
        self.assertEqual(summary['total_expenses'], 225.90)
        self.assertGreater(len(summary['by_category']), 0)
    
    def test_empty_input(self):
        """Testa entrada vazia."""
        data = {"transactions": []}
        result = process_transactions_dict(data, use_gemini=False)
        
        # Deve ter erro ou summary vazio
        if 'error' not in result:
            self.assertEqual(len(result['transactions']), 0)
    
    def test_invalid_csv(self):
        """Testa CSV inválido."""
        invalid_csv = "invalid,csv,without,proper,headers\n1,2,3"
        result = process_transactions_dict(invalid_csv, use_gemini=False)
        
        self.assertIn('error', result)
    
    def test_date_normalization(self):
        """Testa normalização de datas."""
        # Formato brasileiro
        date1 = DataValidator.normalize_date("10/11/2025")
        self.assertEqual(date1, "2025-11-10")
        
        # Formato ISO
        date2 = DataValidator.normalize_date("2025-11-10")
        self.assertEqual(date2, "2025-11-10")
    
    def test_amount_normalization(self):
        """Testa normalização de valores."""
        # Salário deve ser positivo
        amount1 = DataValidator.normalize_amount(2500, "SALARIO NOVEMBRO")
        self.assertGreater(amount1, 0)
        
        # Compra deve ser negativa
        amount2 = DataValidator.normalize_amount(50, "SUPERMERCADO")
        self.assertLess(amount2, 0)
    
    def test_heuristic_classification(self):
        """Testa classificação heurística."""
        # Alimentação
        txn1 = {"description": "padaria pao doce", "amount": -25}
        result1 = HeuristicClassifier.classify(txn1)
        self.assertEqual(result1['category'], 'alimentacao')
        
        # Transporte
        txn2 = {"description": "uber viagem", "amount": -30}
        result2 = HeuristicClassifier.classify(txn2)
        self.assertEqual(result2['category'], 'transporte')
        
        # Renda
        txn3 = {"description": "salario", "amount": 3000}
        result3 = HeuristicClassifier.classify(txn3)
        self.assertEqual(result3['category'], 'renda')
    
    def test_duplicate_detection(self):
        """Testa detecção de duplicatas."""
        from src.models import TransactionInput
        
        transactions = [
            TransactionInput(
                id="txn_1",
                date="2025-11-10",
                description="PADARIA",
                amount=-25.90,
                currency="BRL"
            ),
            TransactionInput(
                id="txn_2",
                date="2025-11-10",
                description="PADARIA",
                amount=-25.90,
                currency="BRL"
            )
        ]
        
        duplicates = DataValidator.detect_duplicates(transactions)
        self.assertGreater(len(duplicates), 0)
    
    def test_max_batch_size(self):
        """Testa limite de transações por lote."""
        from src.config import MAX_TRANSACTIONS_PER_BATCH
        
        large_batch = [
            {
                "id": f"txn_{i}",
                "date": "2025-11-10",
                "description": "TEST",
                "amount": -10.0,
                "currency": "BRL"
            }
            for i in range(MAX_TRANSACTIONS_PER_BATCH + 1)
        ]
        
        data = {"transactions": large_batch}
        result = process_transactions_dict(data, use_gemini=False)
        
        # Deve retornar erro
        self.assertIn('error', result)
    
    def test_income_expense_separation(self):
        """Testa separação de receitas e despesas."""
        data = {
            "transactions": [
                {
                    "id": "txn_income",
                    "date": "2025-11-01",
                    "description": "SALARIO",
                    "amount": 3000,
                    "currency": "BRL"
                },
                {
                    "id": "txn_expense",
                    "date": "2025-11-02",
                    "description": "SUPERMERCADO",
                    "amount": -200,
                    "currency": "BRL"
                }
            ]
        }
        
        result = process_transactions_dict(data, use_gemini=False)
        summary = result['summary']
        
        self.assertEqual(summary['total_income'], 3000)
        self.assertEqual(summary['total_expenses'], 200)
    
    def test_confidence_scores(self):
        """Testa scores de confiança."""
        data = {"transactions": self.sample_transactions}
        result = process_transactions_dict(data, use_gemini=False)
        
        for txn in result['transactions']:
            confidence = txn['confidence']
            self.assertGreaterEqual(confidence, 0.0)
            self.assertLessEqual(confidence, 1.0)


class TestDataValidator(unittest.TestCase):
    """Testes para o validador de dados."""
    
    def test_csv_parsing(self):
        """Testa parsing de CSV."""
        csv_str = """id,date,description,amount,currency
txn_1,2025-11-10,TEST,-50.00,BRL"""
        
        result = DataValidator.parse_csv(csv_str)
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]['id'], 'txn_1')
    
    def test_description_normalization(self):
        """Testa normalização de descrição."""
        desc1 = DataValidator.normalize_description("PADARIA PAO DOCE #12345")
        self.assertIn("Padaria", desc1)
        
        desc2 = DataValidator.normalize_description("  SUPERMERCADO   EXTRA  ")
        self.assertEqual(desc2.count(' '), 1)
    
    def test_sensitive_data_masking(self):
        """Testa mascaramento de dados sensíveis."""
        text = "Transferencia CPF 123.456.789-00"
        masked, has_sensitive = DataValidator.mask_sensitive_data(text)
        
        self.assertTrue(has_sensitive)
        self.assertNotIn("123.456.789-00", masked)


if __name__ == '__main__':
    print("Executando testes...\n")
    unittest.main(verbosity=2)
