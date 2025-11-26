"""
Cliente para comunicação com a API Google Gemini.
"""
import json
import time
from typing import Optional, Dict, Any
import google.generativeai as genai

from config import GEMINI_API_KEY, GEMINI_MODEL, GEMINI_TIMEOUT


class GeminiClient:
    """Cliente para interação com a API Gemini."""
    
    def __init__(self, api_key: Optional[str] = None, model: str = GEMINI_MODEL):
        """
        Inicializa o cliente Gemini.
        
        Args:
            api_key: Chave da API (usa variável de ambiente se None)
            model: Nome do modelo a usar
        """
        self.api_key = api_key or GEMINI_API_KEY
        if not self.api_key:
            raise ValueError("GEMINI_API_KEY not configured")
        
        genai.configure(api_key=self.api_key)
        self.model = genai.GenerativeModel(model)
        self.timeout = GEMINI_TIMEOUT
        
    def generate_content(
        self, 
        prompt: str,
        temperature: float = 0.3,
        max_output_tokens: int = 2048
    ) -> Optional[str]:
        """
        Gera conteúdo usando a API Gemini.
        
        Args:
            prompt: Prompt para o modelo
            temperature: Temperatura de geração (0.0 - 1.0)
            max_output_tokens: Máximo de tokens na resposta
            
        Returns:
            Resposta do modelo ou None em caso de erro
        """
        try:
            start_time = time.time()
            
            generation_config = genai.types.GenerationConfig(
                temperature=temperature,
                max_output_tokens=max_output_tokens,
            )
            
            response = self.model.generate_content(
                prompt,
                generation_config=generation_config,
            )
            
            elapsed = time.time() - start_time
            
            # Verificar timeout
            if elapsed > self.timeout:
                print(f"Warning: Gemini call took {elapsed:.2f}s (timeout: {self.timeout}s)")
                return None
            
            if not response or not response.text:
                return None
            
            return response.text.strip()
            
        except Exception as e:
            print(f"Gemini API error: {str(e)}")
            return None
    
    def classify_transaction(self, transaction: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Classifica uma transação usando Gemini.
        
        Args:
            transaction: Dicionário com dados da transação
            
        Returns:
            Dicionário com classificação ou None em caso de erro
        """
        prompt = f"""Você é um classificador de transações bancárias. Analise a transação abaixo e retorne APENAS um JSON válido (sem markdown, sem texto explicativo).

Transação:
- Descrição: {transaction['description']}
- Valor: {transaction['amount']}
- Moeda: {transaction.get('currency', 'BRL')}
- Raw: {transaction.get('raw', 'N/A')}

Categorias válidas: alimentacao, transporte, moradia, lazer, saude, compras, contas, transferencia, renda, educacao, outros

Responda SOMENTE com JSON neste formato exato:
{{
  "category": "categoria_escolhida",
  "subcategory": "subcategoria_ou_null",
  "confidence": 0.0_a_1.0,
  "explanation": "Breve justificativa em 15-30 palavras"
}}"""

        response = self.generate_content(prompt, temperature=0.2, max_output_tokens=256)
        
        if not response:
            return None
        
        try:
            # Tentar extrair JSON da resposta
            # Remover markdown se presente
            json_text = response
            if "```json" in json_text:
                json_text = json_text.split("```json")[1].split("```")[0]
            elif "```" in json_text:
                json_text = json_text.split("```")[1].split("```")[0]
            
            result = json.loads(json_text.strip())
            
            # Validar estrutura
            if not all(k in result for k in ['category', 'confidence']):
                return None
            
            return result
            
        except (json.JSONDecodeError, IndexError):
            print(f"Failed to parse Gemini response: {response}")
            return None
    
    def generate_insights(
        self, 
        transactions_summary: Dict[str, Any],
        historical_context: Optional[Dict[str, Any]] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Gera insights e recomendações baseados nas transações.
        
        Args:
            transactions_summary: Resumo das transações classificadas
            historical_context: Dados históricos para análise de tendências
            
        Returns:
            Dicionário com insights ou None em caso de erro
        """
        hist_text = ""
        if historical_context:
            hist_text = f"\n\nDados históricos (últimos meses):\n{json.dumps(historical_context, indent=2)}"
        
        prompt = f"""Você é um analista financeiro. Analise o resumo de transações e gere insights. Responda APENAS com JSON válido (sem markdown).

Resumo atual:
{json.dumps(transactions_summary, indent=2, ensure_ascii=False)}
{hist_text}

Gere:
1. Alertas sobre gastos elevados (se alguma categoria está 20%+ acima da média esperada)
2. Recomendações práticas de economia (máx 3)

Responda SOMENTE com JSON neste formato:
{{
  "alerts": [
    {{"type": "high_spend", "message": "mensagem curta", "related_category": "categoria"}}
  ],
  "recommendations": [
    {{"id": "rec_1", "text": "recomendação objetiva em 30-50 palavras", "impact_estimate_pct": 5}}
  ]
}}"""

        response = self.generate_content(prompt, temperature=0.4, max_output_tokens=800)
        
        if not response:
            return None
        
        try:
            # Extrair JSON
            json_text = response
            if "```json" in json_text:
                json_text = json_text.split("```json")[1].split("```")[0]
            elif "```" in json_text:
                json_text = json_text.split("```")[1].split("```")[0]
            
            result = json.loads(json_text.strip())
            
            # Validar estrutura básica
            if 'alerts' not in result:
                result['alerts'] = []
            if 'recommendations' not in result:
                result['recommendations'] = []
            
            return result
            
        except (json.JSONDecodeError, IndexError):
            print(f"Failed to parse insights response: {response}")
            return None
    
    def chat(self, prompt: str, temperature: float = 0.7) -> Dict[str, Any]:
        """
        Método de chat genérico para conversação.
        
        Args:
            prompt: Prompt/mensagem do usuário
            temperature: Criatividade da resposta (0.0-1.0)
            
        Returns:
            Dict com success, content e possível erro
        """
        try:
            response = self.generate_content(prompt, temperature=temperature, max_output_tokens=1024)
            
            if response:
                return {
                    "success": True,
                    "content": response
                }
            else:
                return {
                    "success": False,
                    "error": "No response from Gemini",
                    "content": "Desculpe, não consegui processar sua mensagem no momento."
                }
                
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "content": "Ocorreu um erro ao processar sua mensagem."
            }
