# Guia de Deploy - ShardCloud

## 🚀 Deploy Completo

### 1️⃣ Fazer push do código
```bash
git push origin main
```

### 2️⃣ No console da ShardCloud

#### A. Atualizar código:
```bash
cd /app
git pull origin main
```

#### B. Buildar Flutter para Web:
```bash
cd /app/flutter_app
flutter build web --release
```

#### C. Reiniciar servidor:
```bash
cd /app
python apiserver.py
```

---

## 📁 Estrutura no Servidor

Após o build, a estrutura será:
```
/app/
├── apiserver.py              # Servidor Flask
├── src/                      # Backend Python
├── flutter_app/
│   ├── lib/                  # Código fonte Flutter
│   ├── build/web/            # Build compilado ← Gerado no servidor
│   └── web/                  # Template base
└── requirements.txt
```

---

## ⚙️ Configuração da API Key

No console ShardCloud, adicione a variável de ambiente:
```bash
export GEMINI_API_KEY="sua_chave_aqui"
```

Ou edite `/app/src/config.py`:
```bash
nano /app/src/config.py
```

---

## 🔍 Testar Deploy

### Acessar frontend:
```
http://seu-dominio.com
```

### Testar API:
```bash
curl http://seu-dominio.com/api/health
```

---

## ❓ Por que buildar no servidor?

- ✅ OneDrive bloqueia escrita de arquivos durante sync
- ✅ Build no Linux é mais rápido e estável  
- ✅ Evita conflitos de permissão
- ✅ Build otimizado para produção

---

## 🔄 Para atualizações futuras

```bash
cd /app
git pull origin main
cd flutter_app
flutter build web --release
cd ..
# Reinicie o servidor (Ctrl+C e python apiserver.py)
```

---

## ✅ Checklist

- [ ] Código no GitHub atualizado
- [ ] `git pull` no servidor
- [ ] `flutter build web` executado
- [ ] `GEMINI_API_KEY` configurada
- [ ] Servidor rodando na porta 80
- [ ] Frontend acessível em http://seu-dominio.com
