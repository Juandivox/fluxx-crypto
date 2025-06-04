#!/bin/bash
set -e

echo "🚀 Iniciando configuración del nodo génesis de FluxxChain..."

# 🔍 Verificación de dependencias
for cmd in git docker; do
  if ! command -v $cmd &>/dev/null; then
    echo "❌ Error: '$cmd' no está instalado. Abortando."
    exit 1
  fi
done

# 📁 Variables de ruta
BASE_DIR="$(pwd)/fluxxchain"
PRIVATE_DIR="$BASE_DIR/private"
SDK_REPO=https://github.com/cosmos/cosmos-sdk
SDK_VERSION=v0.45.4
DOCKER_IMAGE=fluxxchain:v0.1
CONTAINER_NAME=fluxxchain-node

# 🚫 Verificación de nodo ya inicializado
if [ -d "$PRIVATE_DIR/config" ]; then
  echo "⚠️  El nodo ya fue inicializado. Ejecutando contenedor existente..."
  
  if docker ps -a --format '{{.Names}}' | grep -Eq "^$CONTAINER_NAME$"; then
    docker start -ai "$CONTAINER_NAME"
  else
    echo "❗ El contenedor '$CONTAINER_NAME' no existe, pero la carpeta sí. Usa:"
    echo "   docker run -it -v $PRIVATE_DIR:/root/.simapp --name $CONTAINER_NAME $DOCKER_IMAGE simd start"
  fi

  exit 0
fi

# 📦 Clonar Cosmos SDK y construir imagen
echo "📦 Clonando Cosmos SDK y construyendo imagen Docker..."
mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

if [ ! -d "cosmos-sdk" ]; then
  git clone "$SDK_REPO"
fi

cd cosmos-sdk
git fetch
git checkout "$SDK_VERSION"
docker build . -t "$DOCKER_IMAGE"

# 🔧 Inicializar nodo génesis
echo "🔧 Inicializando nodo simapp y creando cuenta génesis..."

mkdir -p "$PRIVATE_DIR"

docker run --rm -v "$PRIVATE_DIR":/root/.simapp "$DOCKER_IMAGE" sh -c "
  simd init fluxxnode --chain-id fluxxchain-devnet && \
  simd keys add validator --keyring-backend=test && \
  simd add-genesis-account \$(simd keys show validator -a --keyring-backend=test) 100000000stake --keyring-backend=test && \
  simd gentx validator 70000000stake --chain-id fluxxchain-devnet --keyring-backend=test && \
  simd collect-gentxs
"

# 🚀 Arrancar el nodo en contenedor persistente
echo "🚀 Iniciando nodo FluxxChain en contenedor Docker..."
docker run -it \
  -v "$PRIVATE_DIR":/root/.simapp \
  --name "$CONTAINER_NAME" \
  "$DOCKER_IMAGE" \
  simd start
