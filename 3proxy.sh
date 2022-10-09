#!/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

random() {
    tr </dev/urandom -dc A-Za-z0-9 | head -c5
    echo
}

ip64() {
    local array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
    echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
}

gen64() {
    echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
}

install_bkns() {
}

install_proxy() {
    echo "Installing 3proxy..."
    yum install gcc make epel-release net-tools gcc bsdtar zip -y
    wget -qO- https://github.com/z3APA3A/3proxy/archive/0.9.4.tar.gz | bsdtar -xvf-
    cd 3proxy-*
    make -f Makefile.Linux
    make -f Makefile.Linux install
    mkdir -p /etc/3proxy/logs
    touch /etc/3proxy/{proxy,black,white}.list
    touch ~/{boot_iptables,boot_ifconfig}.sh
    chmod +x ~/boot_*.sh /etc/rc.local /etc/3proxy/*.list
    wget https://raw.githubusercontent.com/beebeo/3proxy/main/3proxy.cfg -O=/etc/3proxy/3proxy.cfg
    wget https://raw.githubusercontent.com/beebeo/3proxy/main/black.list -O=/etc/3proxy/black.list
    wget https://raw.githubusercontent.com/beebeo/3proxy/main/white.list -O=/etc/3proxy/white.list

    echo "* hard nofile 999999" >> /etc/security/limits.conf
    echo "* soft nofile 999999" >> /etc/security/limits.conf
    echo "net.ipv6.conf.eth0.proxy_ndp=1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.proxy_ndp=1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.default.forwarding=1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
    echo "net.ipv6.ip_nonlocal_bind=1" >> /etc/sysctl.conf
    echo "vm.max_map_count=95120" >> /etc/sysctl.conf
    echo "kernel.pid_max=95120" >> /etc/sysctl.conf
    echo "net.ipv4.ip_local_port_range=1024 65000" >> /etc/sysctl.conf
    echo "bash ~/boot_iptables.sh" >> /etc/rc.local
    echo "bash ~/boot_ifconfig.sh" >> /etc/rc.local
    echo "ulimit -n 600000" >> /etc/rc.local
    echo "service 3proxy start" >> /etc/rc.local

    sysctl -p
    chmod -R 777 /etc/3proxy/
    ulimit -n 600000
    service 3proxy start
    cd
    rm -rf 3proxy-*
    echo "Installed 3proxy !"
    bash -i
}

generate_ipv6() {
    [ -z "$USERNAME" ] && { echo "Missing flag -u"; exit; }
    [ -z "$PASSWORD" ] && { echo "Missing flag -p"; exit; }
    [ -z "$PROXY_PORT" ] && { echo "Missing flag -o"; exit; }

    local IPv4=$(curl -4 -s icanhazip.com)
    local IPv6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')
    local PROXY_HOST=$(gen64 $IPv6)

    ifconfig eth0 inet6 add $PROXY_HOST/64
    iptables -I INPUT -p tcp --dport $PROXY_PORT -m state --state NEW -j ACCEPT

    echo "ifconfig eth0 inet6 add $PROXY_HOST/64" >> ~/boot_ifconfig.sh
    echo "iptables -I INPUT -p tcp --dport $PROXY_PORT -m state --state NEW -j ACCEPT" >> ~/boot_iptables.sh

    local APPEND=""
    local APPEND+="#user: $USERNAME\n"
    local APPEND+="auth strong\n"
    local APPEND+="users $USERNAME:CL:$PASSWORD\n"
    local APPEND+="allow $USERNAME * $/etc/3proxy/white.list\n"
    local APPEND+="deny $USERNAME * $/etc/3proxy/black.list\n"
    local APPEND+="proxy -6 -n -a -p$PROXY_PORT -i$IPv4 -e$PROXY_HOST\n"
    local APPEND+="flush\n\n"

    echo -e $APPEND >> /etc/3proxy/proxy.list
    sleep 0.3

    echo "USERNAME: $USERNAME"
    echo "PASSWORD: $PASSWORD"
    echo "PROXY_HOST: $PROXY_HOST"
    echo "PROXY_PORT: $PROXY_PORT"
}

# Enable ipv6 with BKNS
elif [ "$1" == "bkns" ]; then
	install_bkns
fi

# setup 3proxy
elif [ "$1" == "install" ]; then
	install_proxy
fi

# generate ipv6
elif [ "$1" == "setup" ]; then
    shift 1
    while getopts u:p:o: option
    do
        case "${option}" in
            u) USERNAME=${OPTARG};;
            p) PASSWORD=${OPTARG};;
            o) PROXY_PORT=${OPTARG};;
        esac
    done
	generate_ipv6
fi

# no command
else
	clear
	echo "./3proxy.sh <command>"
	echo ""
	echo "Usage:"
    echo "  ./3proxy.sh bkns                                                    enable ipv6 bkns"
	echo "  ./3proxy.sh install                                                 setup 3proxy"
	echo "  ./3proxy.sh setup -u <username> -p <password> -o <port>             setup proxy with <username, password, port>"
fi
