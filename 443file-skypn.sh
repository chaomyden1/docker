#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Current folder
cur_dir=$(pwd)
# Color
red='\033[0;31m'
green='\033[0;32m'
#yellow='\033[0;33m'
plain='\033[0m'
operation=(Install Update UpdateConfig logs restart delete)
# Make sure only root can run our script
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] Chưa vào root kìa !, vui lòng xin phép ROOT trước!" && exit 1

#Check system
check_sys() {
  local checkType=$1
  local value=$2
  local release=''
  local systemPackage=''

  if [[ -f /etc/redhat-release ]]; then
    release="centos"
    systemPackage="yum"
  elif grep -Eqi "debian|raspbian" /etc/issue; then
    release="debian"
    systemPackage="apt"
  elif grep -Eqi "ubuntu" /etc/issue; then
    release="ubuntu"
    systemPackage="apt"
  elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
    release="centos"
    systemPackage="yum"
  elif grep -Eqi "debian|raspbian" /proc/version; then
    release="debian"
    systemPackage="apt"
  elif grep -Eqi "ubuntu" /proc/version; then
    release="ubuntu"
    systemPackage="apt"
  elif grep -Eqi "centos|red hat|redhat" /proc/version; then
    release="centos"
    systemPackage="yum"
  fi

  if [[ "${checkType}" == "sysRelease" ]]; then
    if [ "${value}" == "${release}" ]; then
      return 0
    else
      return 1
    fi
  elif [[ "${checkType}" == "packageManager" ]]; then
    if [ "${value}" == "${systemPackage}" ]; then
      return 0
    else
      return 1
    fi
  fi
}

# Get version
getversion() {
  if [[ -s /etc/redhat-release ]]; then
    grep -oE "[0-9.]+" /etc/redhat-release
  else
    grep -oE "[0-9.]+" /etc/issue
  fi
}

# CentOS version
centosversion() {
  if check_sys sysRelease centos; then
    local code=$1
    local version="$(getversion)"
    local main_ver=${version%%.*}
    if [ "$main_ver" == "$code" ]; then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

get_char() {
  SAVEDSTTY=$(stty -g)
  stty -echo
  stty cbreak
  dd if=/dev/tty bs=1 count=1 2>/dev/null
  stty -raw
  stty echo
  stty $SAVEDSTTY
}
error_detect_depends() {
  local command=$1
  local depend=$(echo "${command}" | awk '{print $4}')
  echo -e "[${green}Info${plain}] Bắt đầu cài đặt các gói ${depend}"
  ${command} >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo -e "[${red}Error${plain}] Cài đặt gói không thành công ${red}${depend}${plain}"
    exit 1
  fi
}

# Pre-installation settings
pre_install_docker_compose() {
    echo -e "---- SKYPN.FUN DOCKER 443 FILE ---"
    read -p "Nhập Node ID port 443: " node_443
    echo -e "Node 443 là: ${node_443}"

    read -p "Nhập subdomain 443: " CertDomain443
    echo -e "CertDomain port 443 là: ${CertDomain}"
}

# Config docker
config_docker() {
  cd ${cur_dir} || exit
  echo "Bắt đầu cài đặt các gói"
  install_dependencies
  echo "Tải tệp cấu hình DOCKER"
  cat >docker-compose.yml <<EOF
version: '3'
services: 
  xrayr: 
    image: ghcr.io/xrayr-project/xrayr:latest
    volumes:
      - ./config.yml:/etc/XrayR/config.yml
      - ./dns.json:/etc/XrayR/dns.json
      - ./crt.crt:/etc/XrayR/crt.crt
      - ./key.key:/etc/XrayR/key.key
    restart: always
    network_mode: host
    
EOF
  cat >dns.json <<EOF
{
    "servers": [
        "1.1.1.1",
        "8.8.8.8",
        "localhost"
    ],
    "tag": "dns_inbound"
}
EOF
  cat >key.key <<EOF
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC/4dY+jjJ9GcX6
24xwCIU6mKx6geB0OyxLRhWOwaqWzLSKGbGSH1ZE9krDqZM/s3DfzdfPy3hWft8W
55or+IaEjXoiJJIObSaaZyC+yKFdztwBifh76cimVW6BSslyFG/1+I1WdtmHibMf
RSdv752gpDcoYk7AEMwyrGTIzIjkj+HdEYI1BL72EGO9Pe+EhS3FRt4izgyf8S8f
wODN6iMbhBa7uQIAhVBSUcM/KQ96F0QMRCAWJy/+Z56NneswvgcfSmPb2BLnts1g
0wwMvhiU3t8a6u76aIYmk5iCeR41874I9n6dBnLNJqMfJaOfNxOOSfeRsfTw7WJm
SyxUVQaxAgMBAAECggEAXMLuQmaW5OCJU+lAXsbXtYiqVT0lR7t1gdxbPpzEfctv
ehXKwNPSbltMsINxkomKhz9pVeTNA6+o5NdJMnmeekU05n2ceEnvMBSsAV9Xl1SS
ClJrZGgUHslNN0by1OopaBVlKoghSENa60KQuq3xm3/XxHemD3bvaI3r2SD8CtXm
k8swEljtE22kP++yziv9CCEUs3K89lxGzPi35ICMQFlfI9jTfO2OjkvgHxrM7kH9
Z1WsmcYAhJzzwAl+N14oVnErk0dIoKLkMLJHQiRGJHh4JrcDciLmF4iLV7866W5+
AwV8GCf6zhKbkDTK08SGC80RYjo57jXcv5i+haI2IwKBgQD1nXqv5lm1m4abKW79
ZrGOV3P9WEZxEuERzITydLcySu9niu9/aDaW7qa5UZOhACpYTW/1K/0OaMX2PnvG
EgrGmsyIhugXqt01naVlaRK0Q+SLTPo/7mUNzoWEMMNP99juV1FatDTCB/aKEgdn
Hnrvy0Fv3f8TJZ9BNSXZ1MQMOwKBgQDH/sF5SauoyendBgvXC4GsCou6we3KSTMf
5505uPc0urwtH09dEIYgQU/RgBcHdCDrZTYCzRZWIglricoW3As6LYda2GpBXbtp
Jrfby54bE1+sApjpYGA2YtY+CvayOjLg6Js+w0QS3wZiBEWAbJ7b0UL24fkW3oic
N4mKJsaGAwKBgQCdes9DIQq76nAv5C0JxGJrxZ7U/ViM/3HXm65SVotvb6R4Wxic
NBFsTLARekCRpi2AWIZESGQEbSEgdYeew8qs9GvXzcfaBO+4hM+bafdYJX/P4RdD
DnM0mwn4a9uO1nb8unerFIgPMFPeyxh8AYsJXOUj+M6nVCP8Bzuxoz3gKQKBgF8C
eatDAle3RHCJ1MoeX0X55JOeWXcF+1Gm2Jx5cIcORyMwgqV1miJspJykO0yBMLpj
ZJtEDt5wYQVDekwN0Q+cXXcc5K2U99lmWWYDf2Lhe0veGAKWlF6B6cGjt7rHxy/t
kQLqBMbqSL/7w4DVGUrYSPW8OHdS1JdSEvccoKc9AoGAaJrEKJ8PoNlSL+MYQuDM
+f2FkSCBo7keHOUc79Uzinnd1PQ6VK4xw2jucq26XskQKICfm3W+vuji/gJM8S0c
+WUJAGe7Jr7mS3Wz/X3Mciv7ZtMvpNRyIJlrtLLnkYGDtpUI8Vt8BAuy5sqYzEYW
z/xKGbvVBlV8APMQWWepiO4=
-----END PRIVATE KEY-----
EOF
  cat >crt.crt <<EOF
-----BEGIN CERTIFICATE-----
MIIEnjCCA4agAwIBAgIUNRgryfzs2nRAZwT+yqJEYFgr8DkwDQYJKoZIhvcNAQEL
BQAwgYsxCzAJBgNVBAYTAlVTMRkwFwYDVQQKExBDbG91ZEZsYXJlLCBJbmMuMTQw
MgYDVQQLEytDbG91ZEZsYXJlIE9yaWdpbiBTU0wgQ2VydGlmaWNhdGUgQXV0aG9y
aXR5MRYwFAYDVQQHEw1TYW4gRnJhbmNpc2NvMRMwEQYDVQQIEwpDYWxpZm9ybmlh
MB4XDTIzMDMwMjA0NDcwMFoXDTM4MDIyNjA0NDcwMFowYjEZMBcGA1UEChMQQ2xv
dWRGbGFyZSwgSW5jLjEdMBsGA1UECxMUQ2xvdWRGbGFyZSBPcmlnaW4gQ0ExJjAk
BgNVBAMTHUNsb3VkRmxhcmUgT3JpZ2luIENlcnRpZmljYXRlMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv+HWPo4yfRnF+tuMcAiFOpiseoHgdDssS0YV
jsGqlsy0ihmxkh9WRPZKw6mTP7Nw383Xz8t4Vn7fFueaK/iGhI16IiSSDm0mmmcg
vsihXc7cAYn4e+nIplVugUrJchRv9fiNVnbZh4mzH0Unb++doKQ3KGJOwBDMMqxk
yMyI5I/h3RGCNQS+9hBjvT3vhIUtxUbeIs4Mn/EvH8DgzeojG4QWu7kCAIVQUlHD
PykPehdEDEQgFicv/meejZ3rML4HH0pj29gS57bNYNMMDL4YlN7fGuru+miGJpOY
gnkeNfO+CPZ+nQZyzSajHyWjnzcTjkn3kbH08O1iZkssVFUGsQIDAQABo4IBIDCC
ARwwDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMCBggrBgEFBQcD
ATAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBShxnQupzRctMFAl6Js/IFofasxKDAf
BgNVHSMEGDAWgBQk6FNXXXw0QIep65TbuuEWePwppDBABggrBgEFBQcBAQQ0MDIw
MAYIKwYBBQUHMAGGJGh0dHA6Ly9vY3NwLmNsb3VkZmxhcmUuY29tL29yaWdpbl9j
YTAhBgNVHREEGjAYggsqLnNreXBuLmZ1boIJc2t5cG4uZnVuMDgGA1UdHwQxMC8w
LaAroCmGJ2h0dHA6Ly9jcmwuY2xvdWRmbGFyZS5jb20vb3JpZ2luX2NhLmNybDAN
BgkqhkiG9w0BAQsFAAOCAQEAcDif1Y/LMVY9IuDBqCLzpqkLP7Ua/7SoKkocUj7N
xJV5FcDMtyekZy1XmFA6LrLxWuQIQZ4pFqtIoFaPsxuGi5x4BIHea0zqMsFS1pBg
y23xbnky/MOLmCfmnj82GWrl29Z3VvaNmGpRaYLEjLm4fvH0Mq7UCD3/z2ICQjio
dotrnWBASUfNerx55pGpyzA8S/yYPxPDB9VLWnONVBBhwfotRwSjh0WZWQ289n/y
Aku2soaiuUd8TK3r8m/aDyeTOiYgJrbptPMRv3EIi3lkdvqBUnAfbbgkj1rqghYu
JKdjoEI2JuBlMpP4MafPNrWE/fOY1TN0YHu4dlOhDqHYnw==
-----END CERTIFICATE-----
EOF
  cat >config.yml <<EOF
Log:
  Level: none # Log level: none, error, warning, info, debug 
  AccessPath: # ./access.Log
  ErrorPath: # ./error.log
DnsConfigPath: # ./dns.json Path to dns config
ConnetionConfig:
  Handshake: 4 # Handshake time limit, Second
  ConnIdle: 10 # Connection idle time limit, Second
  UplinkOnly: 0 # Time limit when the connection downstream is closed, Second
  DownlinkOnly: 0 # Time limit when the connection is closed after the uplink is closed, Second
  BufferSize: 64 # The internal cache size of each connection, kB
Nodes:
  -
    PanelType: "V2board" # Panel type: SSpanel, V2board, PMpanel
    ApiConfig:
      ApiHost: "https://skypn.fun/"
      ApiKey: "adminskypn9810@skypn.fun"
      NodeID: $node_443
      NodeType: V2ray # Node type: V2ray, Shadowsocks, Trojan
      Timeout: 10 # Timeout for the api request
      EnableVless: false # Enable Vless for V2ray Type
      EnableXTLS: false # Enable XTLS for V2ray and Trojan
      SpeedLimit: 0 # Mbps, Local settings will replace remote settings, 0 means disable
      DeviceLimit: $DeviceLimit # Local settings will replace remote settings, 0 means disable
      RuleListPath: # ./rulelist Path to local arulelist file
    ControllerConfig:
      ListenIP: 0.0.0.0 # IP address you want to listen
      SendIP: 0.0.0.0 # IP address you want to send pacakage
      UpdatePeriodic: 60 # Time to update the nodeinfo, how many sec.
      EnableDNS: false # Use custom DNS config, Please ensure that you set the dns.json well
      DNSType: AsIs # AsIs, UseIP, UseIPv4, UseIPv6, DNS strategy
      DisableUploadTraffic: false # Disable Upload Traffic to the panel
      DisableGetRule: false # Disable Get Rule from the panel
      DisableIVCheck: false # Disable the anti-reply protection for Shadowsocks
      DisableSniffing: true # Disable domain sniffing 
      EnableProxyProtocol: false # Only works for WebSocket and TCP
      EnableFallback: false # Only support for Trojan and Vless
      FallBackConfigs:  # Support multiple fallbacks
        -
          SNI:  # TLS SNI(Server Name Indication), Empty for any
          Path: # HTTP PATH, Empty for any
          Dest: 80
          ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for dsable
      CertConfig:
        CertMode: dns # Option about how to get certificate: none, file, http, dns. Choose "none" will forcedly disable the tls config.
        CertDomain: "$CertDomain443" # Domain to cert
        CertFile: ./crt.crt # Provided if the CertMode is file
        KeyFile: ./key.key
        Provider: cloudflare # DNS cert provider, Get the full support list here: https://go-acme.github.io/lego/dns/
        Email: test@me.com
        DNSEnv: # DNS ENV option used by DNS provider
          CLOUDFLARE_EMAIL: $mailcf
          CLOUDFLARE_API_KEY: $token
EOF

}

# Install docker and docker compose
install_docker() {
  echo -e "Bắt đầu cài đặt DOCKER "
 sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
systemctl start docker
systemctl enable docker
  echo -e "Bắt đầu cài đặt Docker Compose "
curl -fsSL https://get.docker.com | bash -s docker
curl -L "https://github.com/docker/compose/releases/download/1.26.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
  echo "Khởi động Docker "
  service docker start
  echo "Khởi động Docker-Compose "
  docker-compose up -d
  echo
  echo -e "Đã hoàn tất cài đặt phụ trợ ！"
  echo -e "0 0 */3 * *  cd /root/${cur_dir} && /usr/local/bin/docker-compose pull && /usr/local/bin/docker-compose up -d" >>/etc/crontab
  echo -e "Cài đặt cập nhật thời gian kết thúc đã hoàn tất! hệ thống sẽ update sau [${green}24H${plain}] Từ lúc bạn cài đặt"
}

install_check() {
  if check_sys packageManager yum || check_sys packageManager apt; then
    if centosversion 5; then
      return 1
    fi
    return 0
  else
    return 1
  fi
}

install_dependencies() {
  if check_sys packageManager yum; then
    echo -e "[${green}Info${plain}] Kiểm tra kho EPEL ..."
    if [ ! -f /etc/yum.repos.d/epel.repo ]; then
      yum install -y epel-release >/dev/null 2>&1
    fi
    [ ! -f /etc/yum.repos.d/epel.repo ] && echo -e "[${red}Error${plain}] Không cài đặt được kho EPEL, vui lòng kiểm tra." && exit 1
    [ ! "$(command -v yum-config-manager)" ] && yum install -y yum-utils >/dev/null 2>&1
    [ x"$(yum-config-manager epel | grep -w enabled | awk '{print $3}')" != x"True" ] && yum-config-manager --enable epel >/dev/null 2>&1
    echo -e "[${green}Info${plain}] Kiểm tra xem kho lưu trữ EPEL đã hoàn tất chưa ..."

    yum_depends=(
      curl
    )
    for depend in ${yum_depends[@]}; do
      error_detect_depends "yum -y install ${depend}"
    done
  elif check_sys packageManager apt; then
    apt_depends=(
      curl
    )
    apt-get -y update
    for depend in ${apt_depends[@]}; do
      error_detect_depends "apt-get -y install ${depend}"
    done
  fi
  echo -e "[${green}Info${plain}] Đặt múi giờ thành phố Hà Nội GTM+7"
  ln -sf /usr/share/zoneinfo/Asia/Hanoi  /etc/localtime
  date -s "$(curl -sI g.cn | grep Date | cut -d' ' -f3-6)Z"

}

#update_image
Update_xrayr() {
  cd ${cur_dir}
  echo "Tải Plugin DOCKER"
  docker-compose pull
  echo "Bắt đầu chạy dịch vụ DOCKER"
  docker-compose up -d
}

#show last 100 line log

logs_xrayr() {
  echo "Nhật ký chạy sẽ được hiển thị"
  docker-compose logs --tail 100
}

# Update config
UpdateConfig_xrayr() {
  cd ${cur_dir}
  echo "Đóng dịch vụ hiện tại"
  docker-compose down
  pre_install_docker_compose
  config_docker
  echo "Bắt đầu chạy dịch vụ DOKCER"
  docker-compose up -d
}

restart_xrayr() {
  cd ${cur_dir}
  docker-compose down
  docker-compose up -d
  echo "Khởi động lại thành công!"
}
delete_xrayr() {
  cd ${cur_dir}
  docker-compose down
  cd ~
  rm -Rf ${cur_dir}
  echo "Đã xóa thành công!"
}
# Install xrayr
Install_xrayr() {
  pre_install_docker_compose
  config_docker
  install_docker
}

# Initialization step
clear
while true; do
  echo "Vui lòng nhập một số để Thực Hiện Câu Lệnh:"
  for ((i = 1; i <= ${#operation[@]}; i++)); do
    hint="${operation[$i - 1]}"
    echo -e "${green}${i}${plain}) ${hint}"
  done
  read -p "Vui lòng chọn một số và nhấn Enter (Enter theo mặc định ${operation[0]}): " selected
  [ -z "${selected}" ] && selected="1"
  case "${selected}" in
  1 | 2 | 3 | 4 | 5 | 6 | 7)
    echo
    echo "Bắt Đầu : ${operation[${selected} - 1]}"
    echo
    ${operation[${selected} - 1]}_xrayr
    break
    ;;
  *)
    echo -e "[${red}Error${plain}] Vui lòng nhập số chính xác [1-6]"
    ;;
  esac

done
