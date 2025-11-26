"""
Script de teste para verificar conexão com a API Gemini.
"""
import sys
import os

# Adicionar diretório src ao path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from gemini_client import GeminiClient
from config import GEMINI_API_KEY, GEMINI_MODEL

def test_gemini_connection():
    """Testa a conexão básica com a API Gemini."""
    print("=" * 60)
    print("TESTE DE CONEXÃO COM API GEMINI")
    print("=" * 60)
    print(f"\nAPI Key: {GEMINI_API_KEY[:20]}...")
    print(f"Modelo: {GEMINI_MODEL}")
    print("\n" + "-" * 60)
    
    try:
        # Criar cliente
        print("\n1. Inicializando cliente Gemini...")
        client = GeminiClient()
        print("   ✓ Cliente inicializado com sucesso")
        
        # Teste simples de geração
        print("\n2. Testando geração de conteúdo...")
        prompt = "Responda com apenas uma palavra: teste funcionando?"
        response = client.generate_content(prompt, temperature=0.1)
        
        if response:
            print(f"   ✓ Resposta recebida: {response[:100]}")
            print("\n" + "=" * 60)
            print("✓ TESTE CONCLUÍDO COM SUCESSO!")
            print("=" * 60)
            return True
        else:
            print("   ✗ Nenhuma resposta recebida")
            print("\n" + "=" * 60)
            print("✗ TESTE FALHOU - API não respondeu")
            print("=" * 60)
            return False
            
    except Exception as e:
        print(f"\n   ✗ Erro: {str(e)}")
        print("\n" + "=" * 60)
        print("✗ TESTE FALHOU")
        print("=" * 60)
        print("\nPossíveis problemas:")
        print("1. Chave da API inválida ou expirada")
        print("2. Modelo não disponível (gemini-2.0-flash-exp pode estar indisponível)")
        print("3. Problema de conexão com a internet")
        print("4. Quota da API excedida")
        print("\nSugestões:")
        print("- Verifique se a chave da API está correta em src/config.py")
        print("- Tente usar 'gemini-1.5-flash' se gemini-2.0-flash-exp não funcionar")
        print("- Verifique sua conexão com a internet")
        return False

if __name__ == "__main__":
    success = test_gemini_connection()
    sys.exit(0 if success else 1)
