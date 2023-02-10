#/bin/bash

sudo apt update

if ! command -v curl &> /dev/null || ! command -v git &> /dev/null || ! command -v jq &> /dev/null; then
  sudo apt install -y curl git jq
fi

if [ ! ${MASSA_PASS} ]; then
	read -p 'Enter your massa password: ' MASSA_PASS
fi
echo "export MASSA_PASS=$MASSA_PASS" >> $HOME/.profile
source $HOME/.profile

sudo systemctl stop massa
rm -rf $HOME/massa

RELEASE_INFO=$(curl --silent https://api.github.com/repos/massalabs/massa/releases/latest)
TAG_NAME=$(echo $RELEASE_INFO | jq -r '.tag_name')

wget https://github.com/massalabs/massa/releases/download/${TAG_NAME}/massa_${TAG_NAME}_release_linux.tar.gz
tar zxvf massa_${TAG_NAME}_release_linux.tar.gz -C $HOME/

sudo tee <<EOF >/dev/null /etc/systemd/system/massa.service
[Unit]
Description=Massa Node
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/massa/massa-node
ExecStart=$HOME/massa/massa-node/massa-node -p "$MASSA_PASS"
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable massa
sudo systemctl restart massa

echo "alias client='cd $HOME/massa/massa-client/ && $HOME/massa/massa-client/massa-client --pwd $MASSA_PASS && cd'" >> ~/.profile
echo "alias clientw='cd $HOME/massa/massa-client/ && $HOME/massa/massa-client/massa-client --pwd $MASSA_PASS && cd'" >> ~/.profile

if [ "$language" = "uk" ]; then
    echo -e "\n\e[93mMassa $TAG_NAME \e[0m\n"
    echo -e "Подивитись логи ноди \e[92mjournalctl -u massa -f -o cat\e[0m"
    echo -e "\e[92mCTRL + C\e[0m щоб вийти з логів\n"
    echo -e "Зайти в меню ноди \e[92msource .profile && clientw\e[0m"
else
    echo -e "\n\e[93mMassa $TAG_NAME \e[0m\n"
    echo -e "Check node logs \e[92mjournalctl -u massa -f -o cat\e[0m"
    echo -e "\e[92mCTRL + C\e[0m to exit logs\n"
    echo -e "Open node menu \e[92msource .profile && clientw\e[0m"
fi