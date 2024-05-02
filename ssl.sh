#!/bin/bash
clear
echo " "
echo -e "\e[35m
____________________________________________________________________________________
        ____                             _     _                                     
    ,   /    )                           /|   /                                  /   
-------/____/---_--_----__---)__--_/_---/-| -/-----__--_/_-----------__---)__---/-__-
  /   /        / /  ) /   ) /   ) /    /  | /    /___) /   | /| /  /   ) /   ) /(    
_/___/________/_/__/_(___(_/_____(_ __/___|/____(___ _(_ __|/_|/__(___/_/_____/___\__
\033[0m"
echo "=== Get Easy SSL Certificate  ==="
echo "***** https://github.com/ipmartnetwork *****"\e[35m
echo
sleep 3

function exit_badly {
  echo "$1"
  exit 1
}

error() {
    echo -e " \n $red Something Bad Happen $none \n "
}

DISTRO="$(awk -F= '/^NAME/{print tolower($2)}' /etc/os-release|awk 'gsub(/[" ]/,x) + 1')"
DISTROVER="$(awk -F= '/^VERSION_ID/{print tolower($2)}' /etc/os-release|awk 'gsub(/[" ]/,x) + 1')"

valid_os()
{
    case "$DISTRO" in
    "debiangnu/linux"|"ubuntu"|"centosstream")
        return 0;;
    *)
        echo "OS $DISTRO is not supported"
        return 1;;
    esac
}
if ! valid_os "$DISTRO"; then
    echo "Bye."
    exit 1
else
[[ $(id -u) -eq 0 ]] || exit_badly "Please re-run as root (e.g. sudo ./path/to/this/script)"
fi

echo
echo "=== Update System ==="
echo
sleep 1

if [[ $DISTRO == "ubuntu" ]] || [[ $DISTRO == "debiangnu/linux" ]]; then
apt-get -o Acquire::ForceIPv4=true update
apt-get -o Acquire::ForceIPv4=true install -y software-properties-common
add-apt-repository --yes universe
add-apt-repository --yes restricted
add-apt-repository --yes multiverse
apt-get -o Acquire::ForceIPv4=true upgrade
apt-get -o Acquire::ForceIPv4=true install -y moreutils dnsutils tmux screen nano wget curl socat
else
dnf -y upgrade --refresh
dnf -y install epel-release
dnf -y install bind-utils tmux screen nano wget curl socat
fi

echo
echo "=== Install acme.sh ==="
echo
sleep 1

curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --upgrade
source ~/.bashrc
source ~/.bashrc


echo
echo "=== Get Certificate ==="
echo
sleep 1

ETH0ORSIMILAR=$(ip route get 1.1.1.1 | grep -oP ' dev \K\S+')
IP=$(dig -4 +short myip.opendns.com @resolver1.opendns.com)

echo "Network interface: ${ETH0ORSIMILAR}"
echo "External IP: ${IP}"
echo
echo "** Note: this hostname must already resolve to this machine, to enable Let's Encrypt certificate setup **"
read -r -p "Hostname for Certificate: " SSLHOST
read -r -p "Email for Certificate: " SSLEMAIL

SSLHOSTIP=$(dig -4 +short "${SSLHOST}")
[[ -n "$SSLHOSTIP" ]] || exit_badly "Cannot resolve SSL hostname: aborting"

if [[ "${IP}" != "${SSLHOSTIP}" ]]; then
  echo "Warning: ${SSLHOST} resolves to ${SSLHOSTIP}, not ${IP}"
  echo "Either you're behind NAT, or something is wrong (e.g. hostname points to wrong IP, CloudFlare proxying shenanigans, ...)"
  read -r -p "Press [Return] to continue anyway, or Ctrl-C to abort"
fi
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh --register-account -m ${SSLEMAIL}
~/.acme.sh/acme.sh --issue -d ${SSLHOST} --standalone
~/.acme.sh/acme.sh --installcert -d ${SSLHOST} --key-file /root/private.key --fullchain-file /root/cert.crt
echo "Certificate Installed at /root/*"

echo
echo "=== Finished ==="
echo
sleep 1
