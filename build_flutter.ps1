# Script PowerShell para buildar o Flutter para Web

Write-Host "🔨 Building Flutter Web App..." -ForegroundColor Cyan

Set-Location "flutter_app"

# Verificar se Flutter está instalado
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter não encontrado! Instale o Flutter primeiro." -ForegroundColor Red
    exit 1
}

# Limpar build anterior
Write-Host "🧹 Limpando build anterior..." -ForegroundColor Yellow
flutter clean

# Build para web
Write-Host "🚀 Buildando para web..." -ForegroundColor Green
flutter build web --release --web-renderer html

# Verificar se build foi bem-sucedido
if (Test-Path "build/web") {
    Write-Host "✅ Build concluído com sucesso!" -ForegroundColor Green
    Write-Host "📁 Arquivos em: flutter_app/build/web/" -ForegroundColor Cyan
    
    # Copiar para a pasta web que o servidor usa
    Remove-Item -Path "web\*" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "build\web\*" -Destination "web\" -Recurse -Force
    
    Write-Host "✅ Arquivos copiados para flutter_app/web/" -ForegroundColor Green
} else {
    Write-Host "❌ Erro no build!" -ForegroundColor Red
    exit 1
}

Set-Location ".."
Write-Host "🎉 Pronto para deploy!" -ForegroundColor Green
