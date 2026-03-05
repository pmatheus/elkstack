#!/bin/bash

# --- CONFIGURAÇÕES PADRÃO ---
STACK_VERSION=9.3.1
CLUSTER_NAME="mme-forensics"

# --- DESCOBERTA DE IP ---
# Tenta pegar o IP da interface que tem a rota padrão (gateway)
HOST_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+')
if [ -z "$HOST_IP" ]; then
    HOST_IP=$(hostname -I | awk '{print $1}')
fi

echo "---[ ELK Stack Bootstrap ]---"
echo "IP Detectado: $HOST_IP"

# --- GERAÇÃO DE SENHAS ---
generate_password() {
    openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16
}

if [ ! -f .env ]; then
    echo "Criando arquivo .env com configurações seguras..."
    ELASTIC_PASSWORD=$(generate_password)
    KIBANA_PASSWORD=$(generate_password)
    ENCRYPTION_KEY=$(openssl rand -base64 32)
    
    cat <<EOF > .env
STACK_VERSION=$STACK_VERSION
CLUSTER_NAME=$CLUSTER_NAME
LICENSE=basic
ES_PORT=9200
KIBANA_PORT=5601
FLEET_PORT=8220
HOST_IP=$HOST_IP
ELASTIC_PASSWORD=$ELASTIC_PASSWORD
KIBANA_PASSWORD=$KIBANA_PASSWORD
ENCRYPTION_KEY=$ENCRYPTION_KEY
ES_MEM_LIMIT=4g
KB_MEM_LIMIT=2g
EOF
    echo "OK: .env criado."
else
    echo "Aviso: Arquivo .env já existe. Pulando geração de senhas."
    # Atualiza apenas o HOST_IP se necessário
    sed -i "s/^HOST_IP=.*/HOST_IP=$HOST_IP/" .env
fi

# --- LIMPEZA DE ESTADO ANTERIOR ---
if [ "$1" == "--clean" ]; then
    echo "Limpando volumes e certificados anteriores..."
    docker compose down -v
    rm -rf certs/
fi

# --- START ---
echo "Iniciando infraestrutura..."
docker compose up -d

echo "------------------------------------------------"
echo "Aguardando inicialização (pode levar alguns minutos)..."
echo "Acesse o Kibana em: https://$HOST_IP:5601"
echo "Usuário: elastic"
echo "Senha: $(grep ELASTIC_PASSWORD .env | cut -d'=' -f2)"
echo "------------------------------------------------"
