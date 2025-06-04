#!/bin/bash

set -e

CHAIN_ID="fluxxchain-devnet"
NODE_MONIKER="node2"
GENESIS_URL="https://github.com/Juandivox/fluxx-crypto/blob/main/genesis.json"
PEER_ID="01ef28c410ac3d7070b9f871700c018207966ec2"
PEER_IP="172.17.0.2"
DOCKER_IMAGE="fluxxchain:v0.1"
NODE_HOME="/root/.simapp"

echo "📦 Clonando Cosmos SDK y compilando imagen Docker..."

mkdir -p ~/fluxxchain
cd ~/fluxxchain

if [ ! -d cosmos-sdk ]; then
  git clone https://github.com/cosmos/cosmos-sdk
  cd cosmos-sdk
  git checkout v0.45.4
  docker build . -t $DOCKER_IMAGE
else
  echo "✔️ Repositorio cosmos-sdk ya existe"
fi

echo "🗂️ Inicializando nodo local..."
mkdir -p ~/fluxxchain/node2
docker run --rm -v ~/fluxxchain/node2:$NODE_HOME $DOCKER_IMAGE simd init $NODE_MONIKER --chain-id $CHAIN_ID --home $NODE_HOME

echo "🌐 Descargando genesis.json desde nodo principal..."
curl -o ~/fluxxchain/node2/config/genesis.json $GENESIS_URL

echo "🧼 Asegurando permisos..."
sudo chown -R $USER:$USER ~/fluxxchain/node2

echo "🚀 Iniciando nodo conectado al nodo principal..."

docker run -it \
  --name fluxxchain-node2 \
  -v ~/fluxxchain/node2:/root/.simapp \
  -p 26660:26657 \
  $DOCKER_IMAGE \
  simd start \
  --home $NODE_HOME \
  --p2p.persistent_peers=${PEER_ID}@${PEER_IP}:26656 \
  --rpc.laddr tcp://0.0.0.0:26657 \
  --grpc.address 0.0.0.0:9090 \
  --address tcp://0.0.0.0:26658