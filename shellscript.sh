#!/bin/bash

exec >/dev/null 2>&1

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

privateKey=$(grep -E "^PrivateKey[[:space:]]*=" "$warpCfg" | cut -d '=' -f 2 | tr -d '[:space:]')
publicKey=$(grep -A1 -E "^\[Peer\]" "$warpCfg" | grep -E "^PublicKey[[:space:]]*=" | cut -d '=' -f 2 | tr -d '[:space:]')

if [ -z "$privateKey" ] || [ -z "$publicKey" ]; then
    echo "Ошибка: не удалось извлечь ключи из $warpCfg!"
    echo "Проверьте содержимое файла:"
    cat "$warpCfg"
    exit 1
fi

echo "-# Ключи" >&3
echo "----------------------------------------" >&3
echo "PrivateKey (ваш ключ): $privateKey" >&3
echo "PublicKey (сервера):   $publicKey" >&3
echo "----------------------------------------" >&3

cloudflareAmnesiaConf="cloudflareWARP.conf"
cat > "$cloudflareAmnesiaConf" <<EOF
[Interface]
PrivateKey = $privateKey
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
PublicKey = $publicKey
AllowedIPs = 0.0.0.0/0
Endpoint = engage.cloudflareclient.com:2408
PersistentKeepalive = 10   
EOF

echo "\n" >&3
echo "-# Конфиг" >&3
echo "----------------------------------------" >&3
cat cloudflareWARP.conf >&3
echo "----------------------------------------" >&3
echo "\n" >&3

confBase64=$(cat wgcf-profile.conf | base64 -w 0)
echo "Скачать: https://xianerydev.vercel.app/?filename=cloudflare_warp.conf&data=SGVsbG8=$confBase64" >&3
