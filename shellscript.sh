#!/bin/bash

echo "Установка зависимостей и wgcf..."
sudo apt update
sudo apt-get update -y --fix-missing && sudo apt-get install wireguard-tools curl jq wget -y --fix-missing

WGCF_VERSION="2.2.17"
wget "https://github.com/ViRb3/wgcf/releases/download/v${WGCF_VERSION}/wgcf_${WGCF_VERSION}_linux_amd64" -O wgcf
chmod +x wgcf
sudo mv wgcf /usr/local/bin/

echo "Создание профиля WARP..."
wgcf register --accept-tos
wgcf generate
warpCfg="wgcf-profile.conf"
if [ ! -f "$warpCfg" ]; then
    echo "Ошибка: файл $warpCfg не найден!"
    exit 1
fi

privateKey=$(grep -Po "PrivateKey\s*=\s*\K[^\s]+" "$warpCfg")
publicKey=$(grep -Po "PublicKey\s*=\s*\K[^\s]+" "$warpCfg")

if [ -z "$privateKey" ] || [ -z "$publicKey" ]; then
    echo "Ошибка: не удалось извлечь ключи из $warpCfg!"
    exit 1
fi

cloudflareAmnesiaConf="cloudflareWARP.conf"
cat > "$cloudflareAmnesiaConf" <<EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Jc = 120
Jmin = 23
Jmax = 911
H1 = 1
H2 = 2
H3 = 3
H4 = 4
MTU = 1280
Address = 172.16.0.2/32
DNS = 1.1.1.1
Obfuscation = true

[Peer]
PublicKey = $PUBLIC_KEY
AllowedIPs = 0.0.0.0/0
Endpoint = engage.cloudflareclient.com:2408
PersistentKeepalive = 10   
EOF

echo "\n" 
echo "-# Начало"
cat cloudflareWARP.conf
echo "-# Конец"
echo "\n"
echo "PublicKey сервера WARP: $PUBLIC_KEY"
echo "PrivateKey клиента: $PRIVATE_KEY"
