# Solución para el Error de tokenizers (puccinialin)

El error `ERROR: Could not find a version that satisfies the requirement puccinialin` ocurre porque `tokenizers` necesita compilarse y requiere Rust.

## Solución Rápida (Recomendada)

Instalar Rust y luego las dependencias:

```bash
cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

# Instalar Rust (necesario para compilar tokenizers)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Actualizar pip
pip install --upgrade pip setuptools wheel

# Instalar herramientas de compilación
apt-get update -qq
apt-get install -y -qq build-essential python3-dev

# Instalar tokenizers (ahora debería compilar correctamente)
pip install "tokenizers>=0.13.2"

# Instalar resto de dependencias
pip install -r requirements.txt
```

## Solución con Script Automático

```bash
cd /opt/osac-knowledge-bot
git pull  # Actualizar para obtener los scripts

cd backend
source venv/bin/activate
chmod +x ../SOLUCION_FINAL_DEPENDENCIAS.sh
../SOLUCION_FINAL_DEPENDENCIAS.sh
```

## Solución Alternativa: Instalar dependencias sin compilar

Si no quieres instalar Rust, puedes intentar instalar tokenizers desde una wheel precompilada:

```bash
cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

# Actualizar pip
pip install --upgrade pip setuptools wheel

# Intentar instalar tokenizers desde wheel precompilado
pip install --only-binary :all: tokenizers 2>/dev/null || pip install tokenizers

# Instalar resto de dependencias
pip install -r requirements.txt
```

## Verificación

Después de instalar, verifica:

```bash
python -c "import tokenizers; print('✅ tokenizers OK')"
python -c "import chromadb; print('✅ chromadb OK')"
```

