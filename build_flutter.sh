#!/bin/bash
# Script para buildar o Flutter para Web antes do deploy

echo "🔨 Building Flutter Web App..."

cd flutter_app

# Verificar se Flutter está instalado
if ! command -v flutter &> /dev/null
then
    echo "❌ Flutter não encontrado! Instale o Flutter primeiro."
    exit 1
fi

# Limpar build anterior
echo "🧹 Limpando build anterior..."
flutter clean

# Build para web
echo "🚀 Buildando para web..."
flutter build web --release --web-renderer html

# Verificar se build foi bem-sucedido
if [ -d "build/web" ]; then
    echo "✅ Build concluído com sucesso!"
    echo "📁 Arquivos em: flutter_app/build/web/"
    
    # Copiar para a pasta web que o servidor usa
    rm -rf web/*
    cp -r build/web/* web/
    
    echo "✅ Arquivos copiados para flutter_app/web/"
else
    echo "❌ Erro no build!"
    exit 1
fi

cd ..
echo "🎉 Pronto para deploy!"
