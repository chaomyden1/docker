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

    echo -e "--- Docker port 443 FAST4G.ME ---"
    echo -e "Vui lòng nhập ID node và Domain"

    read -p "Nhập Node ID port 443: " node_443
    echo -e "Node 443 là: ${node_443}"

    read -p "Nhập subdomain: " CertDomain443
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
  -----BEGIN CERTIFICATE-----
MIIEFTCCAv2gAwIBAgIUYXu2jpmNEGVcctbXjvyUpdNvphgwDQYJKoZIhvcNAQEL
BQAwgagxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRYwFAYDVQQH
Ew1TYW4gRnJhbmNpc2NvMRkwFwYDVQQKExBDbG91ZGZsYXJlLCBJbmMuMRswGQYD
VQQLExJ3d3cuY2xvdWRmbGFyZS5jb20xNDAyBgNVBAMTK01hbmFnZWQgQ0EgOTY3
OTRhODViYTc4ZDg2YWRlOTVhMjk3Y2E3NjIxYmYwHhcNMjIxMTA3MTgyMTAwWhcN
MzIxMTA0MTgyMTAwWjAiMQswCQYDVQQGEwJVUzETMBEGA1UEAxMKQ2xvdWRmbGFy
ZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOkk3FFnedoph+ZBi60J
lzv1tCYJ7+X8aQSjmMKd7BruV/fnZzkb8ljGe7GDK5olg7dV7dzBQb+3SHtH0Fv+
h+z80yIqCvSmOs7uQ9DB7A/Uj6Nbm5fXZoYXuXLoQ27qO9ntwKxswSO/Xnrx2Xg/
wZsn/wcqPkX0y5fOKJzdMrtVcn9uuFidpu5viLu4FTfOjrx6O4MC/F/HydlVftoS
tI2tYe55brFYFepbByqvwptGGIoP5VPivZQB9p559DRV8DrDJXysH/3z4pdXzgqx
te3SqiT+iVQM3RyKCGgYE6Lhu2HqflcsC8klYasBUgqusMAYmUTJYK8skFaPQJGH
2BMCAwEAAaOBuzCBuDATBgNVHSUEDDAKBggrBgEFBQcDAjAMBgNVHRMBAf8EAjAA
MB0GA1UdDgQWBBR6KODaGLR50ubUFwCeb5lp89zxzjAfBgNVHSMEGDAWgBT2V+XX
VnAarstbUHhH5ghkeISzdjBTBgNVHR8ETDBKMEigRqBEhkJodHRwOi8vY3JsLmNs
b3VkZmxhcmUuY29tL2Q4NmUwY2RmLWE1MDctNGFjYi1iNzkwLTE4NjhlN2I4MDc5
ZS5jcmwwDQYJKoZIhvcNAQELBQADggEBAJm7cDv/r0EU7t9VmTcF/5QVrfvth8c6
eWt5GB06A+ncie7v23q4ICwhwWagKrM+/PSyUdDJpne9VHU4XueP6dU0lBQ3WlgG
YelMw3WgGNhhFTdURsF1oKkVM1UdasWXrTLY1kinqCFEd3hx2OmEpMDufoZFYt0s
bP66sMynmyDYPG1svUZM4y4F1e1lSxS4+UgeCDsCgYN2Av51VBkPHudS50Atr98N
7cnvUOWpGW5guC2qC7OHAb1WO+68naMEii/aK4PKhQ8MoGIa8te44zwPU0Y35bMH
+GV3UK+VySIphAySjc5Joco2VWZUONGqMMVgFpbZQJZ1uojNb+fN210=
-----END CERTIFICATE-----
EOF
  cat >crt.crt <<EOF
-----BEGIN CERTIFICATE-----
MIIEFTCCAv2gAwIBAgIUYXu2jpmNEGVcctbXjvyUpdNvphgwDQYJKoZIhvcNAQEL
BQAwgagxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRYwFAYDVQQH
Ew1TYW4gRnJhbmNpc2NvMRkwFwYDVQQKExBDbG91ZGZsYXJlLCBJbmMuMRswGQYD
VQQLExJ3d3cuY2xvdWRmbGFyZS5jb20xNDAyBgNVBAMTK01hbmFnZWQgQ0EgOTY3
OTRhODViYTc4ZDg2YWRlOTVhMjk3Y2E3NjIxYmYwHhcNMjIxMTA3MTgyMTAwWhcN
MzIxMTA0MTgyMTAwWjAiMQswCQYDVQQGEwJVUzETMBEGA1UEAxMKQ2xvdWRmbGFy
ZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOkk3FFnedoph+ZBi60J
lzv1tCYJ7+X8aQSjmMKd7BruV/fnZzkb8ljGe7GDK5olg7dV7dzBQb+3SHtH0Fv+
h+z80yIqCvSmOs7uQ9DB7A/Uj6Nbm5fXZoYXuXLoQ27qO9ntwKxswSO/Xnrx2Xg/
wZsn/wcqPkX0y5fOKJzdMrtVcn9uuFidpu5viLu4FTfOjrx6O4MC/F/HydlVftoS
tI2tYe55brFYFepbByqvwptGGIoP5VPivZQB9p559DRV8DrDJXysH/3z4pdXzgqx
te3SqiT+iVQM3RyKCGgYE6Lhu2HqflcsC8klYasBUgqusMAYmUTJYK8skFaPQJGH
2BMCAwEAAaOBuzCBuDATBgNVHSUEDDAKBggrBgEFBQcDAjAMBgNVHRMBAf8EAjAA
MB0GA1UdDgQWBBR6KODaGLR50ubUFwCeb5lp89zxzjAfBgNVHSMEGDAWgBT2V+XX
VnAarstbUHhH5ghkeISzdjBTBgNVHR8ETDBKMEigRqBEhkJodHRwOi8vY3JsLmNs
b3VkZmxhcmUuY29tL2Q4NmUwY2RmLWE1MDctNGFjYi1iNzkwLTE4NjhlN2I4MDc5
ZS5jcmwwDQYJKoZIhvcNAQELBQADggEBAJm7cDv/r0EU7t9VmTcF/5QVrfvth8c6
eWt5GB06A+ncie7v23q4ICwhwWagKrM+/PSyUdDJpne9VHU4XueP6dU0lBQ3WlgG
YelMw3WgGNhhFTdURsF1oKkVM1UdasWXrTLY1kinqCFEd3hx2OmEpMDufoZFYt0s
bP66sMynmyDYPG1svUZM4y4F1e1lSxS4+UgeCDsCgYN2Av51VBkPHudS50Atr98N
7cnvUOWpGW5guC2qC7OHAb1WO+68naMEii/aK4PKhQ8MoGIa8te44zwPU0Y35bMH
+GV3UK+VySIphAySjc5Joco2VWZUONGqMMVgFpbZQJZ1uojNb+fN210=
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
      NodeType: V2ray 
      Timeout: 10 
      EnableVless: false 
      EnableXTLS: false 
      SpeedLimit: 0 
      DeviceLimit: 3
      RuleListPath: 
    ControllerConfig:
      ListenIP: 0.0.0.0 
      SendIP: 0.0.0.0 
      UpdatePeriodic: 60 
      EnableDNS: false 
      DNSType: AsIs 
      DisableUploadTraffic: false 
      DisableGetRule: false 
      DisableIVCheck: false 
      DisableSniffing: true 
      EnableProxyProtocol: false 
      EnableFallback: false 
      FallBackConfigs:  
        -
          SNI:  
          Path: 
          Dest: 80
          ProxyProtocolVer: 0 
      CertConfig:
        CertMode: file
        CertDomain: "$CertDomain443" 
        CertFile: ./crt.crt
        KeyFile: ./key.key
        Provider: alidns 
        Email: test@me.com
        DNSEnv: 
          ALICLOUD_ACCESS_KEY: aaa
          ALICLOUD_SECRET_KEY: bbb
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
  echo -e "bắt đầu cài đặt Docker Compose "
curl -fsSL https://get.docker.com | bash -s docker
curl -L "https://github.com/docker/compose/releases/download/1.26.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
  echo "khởi động Docker "
  service docker start
  echo "khởi động Docker-Compose "
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
  echo "nhật ký chạy sẽ được hiển thị"
  docker-compose logs --tail 100
}

# Update config
UpdateConfig_xrayr() {
  cd ${cur_dir}
  echo "đóng dịch vụ hiện tại"
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
  echo "đã xóa thành công!"
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
  echo "--- DOCKER 443 được thực hiện bởi FAST4G ---"
  echo "Vui lòng nhập một số để Thực Hiện Câu Lệnh: "
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