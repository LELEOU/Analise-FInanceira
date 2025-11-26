"""
Configurações e constantes do sistema de análise de transações.
"""
import os
from typing import Set

# API Configuration
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")  # Configure via environment variable
GEMINI_MODEL = "gemini-2.5-flash"  # Gemini 2.5 Flash - mais recente e disponível
GEMINI_TIMEOUT = 10  # segundos

# Processing limits
MAX_TRANSACTIONS_PER_BATCH = 200
MAX_DESCRIPTION_LENGTH = 100

# Categories and subcategories
VALID_CATEGORIES = {
    "alimentacao",
    "transporte",
    "moradia",
    "lazer",
    "saude",
    "compras",
    "contas",
    "transferencia",
    "renda",
    "educacao",
    "outros"
}

SUBCATEGORIES = {
    "alimentacao": ["restaurante", "supermercado", "padaria", "lanchonete", "delivery", "bar"],
    "transporte": ["combustivel", "uber", "taxi", "onibus", "metro", "pedagio", "estacionamento"],
    "moradia": ["aluguel", "condominio", "iptu", "manutencao"],
    "lazer": ["cinema", "streaming", "viagem", "evento", "restaurante_lazer"],
    "saude": ["farmacia", "consulta", "plano_saude", "exame", "dentista"],
    "compras": ["roupas", "eletronicos", "casa", "presentes", "diversos"],
    "contas": ["luz", "agua", "internet", "telefone", "gas", "tv"],
    "transferencia": ["pix", "ted", "doc"],
    "renda": ["salario", "freelance", "investimento", "bonus", "restituicao"],
    "educacao": ["curso", "livro", "mensalidade", "material"],
    "outros": []
}

# Heuristic keywords for fallback classification
HEURISTIC_KEYWORDS = {
    "alimentacao": [
        "padaria", "supermercado", "mercado", "restaurante", "lanchonete", "pizzaria",
        "hamburgueria", "ifood", "rappi", "uber eats", "bar", "cafeteria", "acai",
        "sorveteria", "pao", "feira", "hortifruti"
    ],
    "transporte": [
        "uber", "99", "taxi", "gas", "gasolina", "etanol", "combustivel", "posto",
        "shell", "ipiranga", "onibus", "metro", "estacionamento", "pedagio",
        "mecanica", "oficina"
    ],
    "moradia": [
        "aluguel", "condominio", "iptu", "imovel", "casa", "apt", "apartamento"
    ],
    "lazer": [
        "cinema", "spotify", "netflix", "amazon prime", "disney", "hbo", "ingresso",
        "viagem", "hotel", "pousada", "airbnb", "turismo", "parque"
    ],
    "saude": [
        "farmacia", "drogaria", "droga", "consulta", "medic", "hospital", "clinica",
        "plano saude", "unimed", "amil", "bradesco saude", "laboratorio", "exame",
        "dentista", "odonto"
    ],
    "compras": [
        "magazine", "loja", "mercado livre", "amazon", "shopee", "aliexpress",
        "c&a", "renner", "zara", "americanas", "submarino", "casas bahia",
        "extra", "eletro"
    ],
    "contas": [
        "luz", "energia", "cemig", "cpfl", "enel", "agua", "sabesp", "cedae",
        "internet", "vivo", "claro", "tim", "oi", "telefone", "celular", "gas",
        "tv cabo", "net", "sky"
    ],
    "transferencia": [
        "pix", "ted", "doc", "transf", "pagamento", "envio", "transfer"
    ],
    "renda": [
        "salario", "pagamento", "deposito", "credito", "recebimento", "freelance",
        "rendimento", "dividendo", "bonus", "restituicao", "ir"
    ],
    "educacao": [
        "escola", "faculdade", "universidade", "curso", "livraria", "livro",
        "estacio", "anhanguera", "unip", "udemy", "coursera", "alura", "material escolar"
    ]
}

# Confidence thresholds
MIN_CONFIDENCE_THRESHOLD = 0.6
HEURISTIC_CONFIDENCE_RANGE = (0.3, 0.6)

# Trend analysis
TREND_THRESHOLD_UP = 5  # % increase to mark as "up"
TREND_THRESHOLD_DOWN = -5  # % decrease to mark as "down"

# Privacy patterns (for masking)
SENSITIVE_PATTERNS = [
    r"\d{3}\.\d{3}\.\d{3}-\d{2}",  # CPF
    r"\d{5}-\d{1}",  # Conta bancária parcial
    r"\d{4}\s?\d{4}\s?\d{4}\s?\d{4}",  # Cartão de crédito
]

# Date formats to try parsing
DATE_FORMATS = [
    "%Y-%m-%d",
    "%d/%m/%Y",
    "%d-%m-%Y",
    "%Y/%m/%d",
    "%d.%m.%Y",
]
