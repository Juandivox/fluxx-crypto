#!/bin/bash
set -e

# Configuración
CHAIN_ID="fluxxchain-devnet"
NODE_MONIKER="node2"
GENESIS_URL="https://raw.githubusercontent.com/Juandivox/fluxx-crypto/main/genesis.json"
PEER_ID="35ef7809585ac724ecce5f72ba4b2ecff8ce5b84"
PEER_IP="172.17.0.2"
DOCKER_IMAGE="fluxxchain:v0.1"
NODE_HOME="/root/.simapp"
NODE_DIR="$HOME/fluxxchain/node2"

# Validar dependencias
for cmd in git docker curl; do
  if ! command -v $cmd &>/dev/null; then
    echo "❌ Error: '$cmd' no está instalado. Abortando."
    exit 1
  fi
done
# Construir imagen Docker si no existe
BUILD_DIR="$HOME/fluxxchain"
SDK_DIR="$BUILD_DIR/cosmos-sdk"
if ! docker image inspect "$DOCKER_IMAGE" >/dev/null 2>&1; then
  echo "📦 Construyendo imagen Docker $DOCKER_IMAGE..."
  mkdir -p "$BUILD_DIR"
  if [ ! -d "$SDK_DIR" ]; then
    git clone https://github.com/cosmos/cosmos-sdk "$SDK_DIR"
  fi
  cd "$SDK_DIR"
  git fetch
  git checkout v0.45.4
  docker build . -t "$DOCKER_IMAGE"
  cd - >/dev/null
fi


echo "📦 Preparando entorno de nodo 2..."
mkdir -p "$NODE_DIR"

if [ ! -d "$NODE_DIR/config" ]; then
  echo "🗂️ Inicializando nodo local..."
  docker run --rm -v "$NODE_DIR":$NODE_HOME "$DOCKER_IMAGE" simd init "$NODE_MONIKER" --chain-id "$CHAIN_ID" --home "$NODE_HOME"
  mkdir -p "$NODE_DIR/config"
else
  echo "ℹ️ Nodo ya inicializado. Usando datos existentes."
fi

if [ ! -f "$NODE_DIR/config/genesis.json" ]; then
  echo "🌐 Descargando genesis.json..."
  curl -sSfL "$GENESIS_URL" -o "$NODE_DIR/config/genesis.json"
else
  echo "ℹ️ genesis.json ya existe."
fi

if [ "$(id -u)" -eq 0 ]; then
  echo "🧼 Ajustando permisos..."
  chown -R "${SUDO_USER:-root}:${SUDO_USER:-root}" "$NODE_DIR"
elif command -v sudo >/dev/null && sudo -n true 2>/dev/null; then
  echo "🧼 Ajustando permisos..."
  sudo chown -R "$USER":"$USER" "$NODE_DIR"
else
  echo "⚠️  No se pudieron ajustar permisos automáticamente." >&2
fi

echo "🚀 Iniciando nodo 2 conectado al nodo principal..."
docker rm -f fluxxchain-node2 >/dev/null 2>&1 || true
docker run -it \
  --name fluxxchain-node2 \
  -v "$NODE_DIR":/root/.simapp \
  -p 26660:26657 \
  "$DOCKER_IMAGE" \
  simd start \
  --home "$NODE_HOME" \
  --p2p.persistent_peers="${PEER_ID}@${PEER_IP}:26656" \
  --rpc.laddr tcp://0.0.0.0:26657 \
  --grpc.address 0.0.0.0:9090 \
  --address tcp://0.0.0.0:26658
