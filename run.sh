#!/bin/bash
# Script para iniciar Backend e Frontend simultaneamente (Linux/Mac)
# Uso: ./run.sh

echo ""
echo "╔═══════════════════════════════════════════════════╗"
echo "║   Iniciando Sistema de Análise Financeira        ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""

# Verificar Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python não encontrado! Instale Python 3.8+ primeiro."
    exit 1
fi
echo "✅ Python encontrado"

# Verificar Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter não encontrado! Instale Flutter primeiro."
    echo "   https://flutter.dev/docs/get-started/install"
    exit 1
fi
echo "✅ Flutter encontrado"
echo ""

# Verificar/instalar dependências Python
echo "📦 Verificando dependências Python..."
if [ ! -d "venv" ]; then
    echo "   Criando ambiente virtual Python..."
    python3 -m venv venv
fi

source venv/bin/activate
pip install -q -r requirements.txt
if [ $? -ne 0 ]; then
    echo "❌ Erro ao instalar dependências Python"
    exit 1
fi
echo "✅ Dependências Python OK"
echo ""

# Verificar/instalar dependências Flutter
echo "📦 Verificando dependências Flutter..."
cd flutter_app
flutter pub get > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Erro ao instalar dependências Flutter"
    cd ..
    exit 1
fi
echo "✅ Dependências Flutter OK"
cd ..
echo ""

echo "🚀 Iniciando servidores..."
echo ""
echo "┌─────────────────────────────────────────────────┐"
echo "│ Backend:  http://localhost:5000                 │"
echo "│ Frontend: Abrirá automaticamente no navegador   │"
echo "│                                                 │"
echo "│ Pressione Ctrl+C para parar ambos os servidores│"
echo "└─────────────────────────────────────────────────┘"
echo ""

# Função para cleanup ao sair
cleanup() {
    echo ""
    echo "🛑 Parando servidores..."
    kill $BACKEND_PID 2>/dev/null
    kill $FRONTEND_PID 2>/dev/null
    echo "✅ Servidores parados!"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Iniciar Backend em background
echo "🐍 Iniciando Backend Python..."
source venv/bin/activate
python api_server.py &
BACKEND_PID=$!

# Aguardar backend iniciar
sleep 3

# Iniciar Frontend
echo "📱 Iniciando Frontend Flutter..."
cd flutter_app
flutter run -d chrome &
FRONTEND_PID=$!
cd ..

# Aguardar ambos os processos
wait
