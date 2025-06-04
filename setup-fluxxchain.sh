#!/bin/bash

set -e

echo "🚀 Iniciando configuración del nodo genesis de FluxxChain..."

# Variables
BASE_DIR=~/fluxxchain
PRIVATE_DIR=$BASE_DIR/private
SDK_REPO=https://github.com/cosmos/cosmos-sdk
SDK_VERSION=v0.45.4
DOCKER_IMAGE=fluxxchain:v0.1

# Paso 1: Clonar SDK y compilar imagen Docker
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

# Paso 2: Inicializar simapp y crear cuenta genesis
echo "🔧 Inicializando nodo simapp y creando cuenta genesis..."

mkdir -p "$PRIVATE_DIR"

docker run --rm -v "$PRIVATE_DIR":/root/.simapp "$DOCKER_IMAGE" sh -c "
  simd init fluxxnode --chain-id fluxxchain-devnet && \
  simd keys add validator --keyring-backend=test && \
  simd add-genesis-account \$(simd keys show validator -a --keyring-backend=test) 100000000stake --keyring-backend=test && \
  simd gentx validator 70000000stake --chain-id fluxxchain-devnet --keyring-backend=test && \
  simd collect-gentxs
"

# Paso 3: Iniciar nodo
echo "🚀 Iniciando nodo FluxxChain en contenedor Docker..."
docker run -it \
  -v "$PRIVATE_DIR":/root/.simapp \
  --name fluxxchain-node \
  "$DOCKER_IMAGE" \
  simd start
