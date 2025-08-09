#!/bin/bash

if ! command -v wgcf &> /dev/null; then
    echo "Установка wgcf..."
    curl -fsSL https://raw.githubusercontent.com/ViRb3/wgcf/master/wgcf_install.sh | sudo bash
fi

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
Address = 10.0.0.2/24
DNS = 1.1.1.1
Obfuscation = true
MTU = 1400

[Peer]
PublicKey = $PUBLIC_KEY
Endpoint = engage.cloudflareclient.com:2408
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

echo "\n" 
echo "$cloudflareAmnesiaConf"
echo "\n"
echo "PublicKey сервера WARP: $PUBLIC_KEY"
echo "PrivateKey клиента: $PRIVATE_KEY"
