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

echo "📦 Preparando entorno de nodo 2..."
mkdir -p "$NODE_DIR"

echo "🗂️ Inicializando nodo local..."
docker run --rm -v "$NODE_DIR":$NODE_HOME "$DOCKER_IMAGE" simd init "$NODE_MONIKER" --chain-id "$CHAIN_ID" --home "$NODE_HOME"

echo "🌐 Descargando genesis.json..."
curl -s -L -o "$NODE_DIR/config/genesis.json" "$GENESIS_URL"

echo "🧼 Ajustando permisos..."
sudo chown -R $USER:$USER "$NODE_DIR"

echo "🚀 Iniciando nodo 2 conectado al nodo principal..."
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
