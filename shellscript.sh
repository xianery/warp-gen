#!/bin/bash

exec 3>&1
exec >/dev/null 2>&1

echo "Установка зависимостей и wgcf..." >&3
sudo apt update
sudo apt-get update -y --fix-missing && sudo apt-get install wireguard-tools curl jq wget -y --fix-missing

WGCF_VERSION="2.2.17"
wget "https://github.com/ViRb3/wgcf/releases/download/v${WGCF_VERSION}/wgcf_${WGCF_VERSION}_linux_amd64" -O wgcf
chmod +x wgcf
sudo mv wgcf /usr/local/bin/

echo "Создание профиля WARP..." >&3
wgcf register --accept-tos
wgcf generate
warpCfg="wgcf-profile.conf"
privateKey=$(grep -E "^PrivateKey[[:space:]]*=" "$warpCfg" | cut -d '=' -f 2 | tr -d '[:space:]')
publicKey=$(grep -A1 -E "^\[Peer\]" "$warpCfg" | grep -E "^PublicKey[[:space:]]*=" | cut -d '=' -f 2 | tr -d '[:space:]')

echo "-# Ключи" >&3
echo "----------------------------------------" >&3
echo "PrivateKey (ваш ключ): $privateKey=" >&3
echo "PublicKey (сервера):   $publicKey=" >&3
echo "----------------------------------------" >&3

cloudflareAmnesiaConf="cloudflareWARP.conf"
cat > "$cloudflareAmnesiaConf" <<EOF
[Interface]
PrivateKey = $privateKey=
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

[Peer]
PublicKey = $publicKey=
AllowedIPs = 0.0.0.0/0
Endpoint = engage.cloudflareclient.com:2408 
EOF

echo " " >&3
echo "-# Конфиг" >&3
echo "----------------------------------------" >&3
cat cloudflareWARP.conf >&3
echo "----------------------------------------" >&3
echo " " >&3

exec 1>&3 3>&-
