#!/usr/bin/env bash

#author: Karan Luciano
#describle: Configuracao REDE, Servidor DHCP e DNS
#version: 0.1
#license: GNU GENERAL PUBLIC LICENSE

clear
_ip4=$(ip a |grep "inet "|awk '{print $2}'|tail -n 1|sed 's/\/.*//g')
_ip6=$(ip a |grep "inet6 "|awk '{print $2}'|tail -n 2|head -n 1|sed 's/\/.*//g')
auxip4=$(ip a |grep "inet "|awk '{print $2}'|tail -n 1|sed 's/\/.*//g'|sed 's/192.168.0.//g')
auxip6=$(ip a |grep "inet6 "|awk '{print $2}'|tail -n 2|head -n 1|sed 's/\/.*//g'|sed 's/.*:://g')
endip4=$(echo $ip4 |sed 's/192.168.0.//g')
endip6=$(echo $ip6 |sed 's/.*:://g')

Menu(){
	 
	echo -e '\033[07;32mCONFIGURACOES\033[00;37m##########' 
	echo "[ 1 ] INSTALR ISC-DHCP-SERVER"
	echo "[ 2 ] INSTALR BIND9"
	echo "[ 3 ] CONFIGURAR A REDE"
	echo "[ 4 ] COLOCAR HOSTNAME NO /ETC/HOSTS"
	echo -e '\033[07;32mDHCP\033[00;37m##########' 
	echo "[ 5 ] LIMPA SCOPO/RESERVAS E COMECAR UM NOVO"
	echo "[ 6 ] ADCIONAR RESERVA"
	echo -e '\033[07;32mDNS\033[00;37m##########' 
	echo "[ 7 ] LIMPAR TODAS AS ZONAS E COMECAR UMA NOVA"
	echo "[ 8 ] ADICIONAR A UM ZONA JA EXISTENTE"
	echo "[ 0 ] SAIR"
	echo -e '\033[07;31mQUAL A OPCAO DESEJADA?\033[00;37m' 
	read opcao

	case $opcao in
		1) Isc ;;
		2) Bind ;;
		3) Rede ;;
		4) Hostname ;;
		5) Scopo ;;
		6) Reserva ;;
		7) Novo ;;
		8) Adicionar ;;
		0) exit ;;
	esac
}

Rede(){
	DIR=/etc/netplan/

	ls $DIR 2> /dev/null

		echo -e "\033[07;31mCONFIGURA APENAS OS DISPOSITIVOS 'ENP'\033[00;37m" 	
			
		if [ $? -ne 0 ]; then
		clear
		dispo=$(ip a |grep enp |awk '{print $2}' |head -n 1| sed 's/://g')			
		echo "Qual o IPv4 desejado?"
		read ifip
		echo "Qual a mascara? (EX 255.255.0.0)"
		read ifmask
		echo "Qual o gateway? "
		read ifroute
		echo "Qual o IPv6 desejado?"
		read ifip6
		echo "Qual a mascara em prefixo? (EX 64)"
		read ifmask6		
		ifconfig $dispo $ifip netmask $ifmask up
		route add default gw $ifroute
		ifconfig $dispo inet6 add $ifip6/$ifmask6
		clear		
	else
		clear
		echo -e "\033[07;31mCONFIGURA APENAS OS DISPOSITIVOS 'ENP'\033[00;37m" 
		echo "Qual o IPv4: "
		read ip4
		echo "Qual a mascara? "
		read mask
		source aux.sh
		wait
		echo "$mask"
		echo "Qual o Gateway4: "
		read gate4
		echo "Qual o IPv6? "
		read ip6
		echo "Qual a mascara em prefixo? "
		read mask6
		echo "Qual o Gateway6: "
		read gate6
		dispo=$(ip a |grep enp |awk '{print $2}' |head -n 1)
		aux=$(ls /etc/netplan/)
		echo -e "network:\n   ethernets:\n      $dispo\n         dhcp4: false\n         dhcp6: false\n         addresses: [$ip4/$mask, \"$ip6/$mask6\"]\n         gateway4: $gate4\n         gateway6: $gate6\n   version: 2" > /etc/netplan/$aux	
		clear
		netplan apply
	fi
	Menu
}

Hostname(){
	hostname=$(cat /etc/hostname)
	aux6=$(echo $_ip6    $hostname.ubuntu.local    $hostname)
	sed -i "1s/^/$aux6\n/" /etc/hosts
	aux4=$(echo $_ip4    $hostname.ubuntu.local    $hostname)
	sed -i "1s/^/$aux4\n/" /etc/hosts
	clear
	echo -e '\033[07;31mADICIONADO, REINICIE O SEU COMPUTADOR PARA QUE A MUDANCA TENHA EFEITO\033[00;37m' 
	Menu 
}

Scopo(){	
	echo -e "#CRIANDO SCOPO PARA DHCP\n#Subnet adicionado pelo Sript. By: Karan\n#option domain-name 'example.org';\noption domain-name-servers ns1.example.org, ns2.example.org;\ndefault-lease-time 600;\nmax-lease-time 7200;\nddns-update-style none;\nauthoritative;" > /etc/dhcp/dhcpd.conf
	echo "Diga a REDE: "
	read rede
	echo "Diga a MASCARA: "
	read mask
	echo "Diga quando o RANGE comeca: "
	read rangec
	echo "Diga quando o RANGE termina: "
	read ranget
	echo -e "\n#RESERVAS IPV4\nsubnet $rede netmask $mask {\nrange $rangec $ranget;\n}" >> /etc/dhcp/dhcpd.conf
	clear
	/etc/init.d/isc-dhcp-server restart
	clear
	/etc/init.d/isc-dhcp-server status
	Menu
}	

Reserva(){
	echo -e '\033[07;31mCRIANDO RESERVAS\033[00;37m'   
	echo "Diga o MAC: "
	read mac
	if [[ $mac =~ ^[0-9A-Fa-f]{12}$ ]]
	then
		echo -e "MAC Valido"
	else
		clear
		echo -e "MAC Invalido"
		Reserva
	fi
	mac=$(echo $mac | sed -e 's!\.!!g;s!\(..\)!\1:!g;s!:$!!' -e 'y/abcdef/ABCDEF/')
	echo  "Diga o nome do HOST: "
	read host
	echo "Diga o IP: "
	read ip
	echo -e "\nhost $host {\nhardware ethernet $mac;\nfixed-address $ip;\n}" >> /etc/dhcp/dhcpd.conf
	/etc/init.d/isc-dhcp-server restart
	clear
	/etc/init.d/isc-dhcp-server status
	Menu
}

Novo(){
	hostname=$(cat /etc/hostname)

	cp /etc/bind/db.local /etc/bind/db.local_old
	cp /etc/bind/db.127 /etc/bind/db.127_old
	
	echo    "zone \"ubuntu.local\" {
	type master;
	file \"/etc/bind/db.local\";
	};

	zone \"0.168.192.in-addr.arpa\" {
	type master;
	file \"/etc/bind/db.127\";
	};
	
	zone \"0.0.0.0.0.0.0.0.e.f.a.c.ip6.arpa\" {
	type master;
	file \"/etc/bind/db.127\";
	};" > /etc/bind/named.conf.local
	
	echo -e "\n;\n; BIND data file for local loopback interface\n;\n\$TTL    604800\n@	IN	SOA	$hostname.ubuntu.local. root.$hostname.ubuntu.local. (\n			      2		; Serial\n			 604800		; Refresh\n			  86400		; Retry\n			2419200		; Expire\n			 604800 )	; Negative Cache TTL\n;" > /etc/bind/db.local

	echo -e "\n;\n; BIND data file for local loopback interface\n;\n\$TTL   604800\n@	IN	SOA	$hostname.ubuntu.local. root.$hostname.ubuntu.local. (\n			      2		; Serial\n			 604800		; Refresh\n			  86400		; Retry\n			2419200		; Expire\n			 604800 )	; Negative Cache TTL\n;" > /etc/bind/db.127

	echo -e "\nubuntu.local.	IN	NS	$hostname.ubuntu.local.\nubuntu.local.	IN	A	$_ip4\nubuntu.local.	IN	AAAA	$_ip6\n" >>  /etc/bind/db.local
	echo -e "\n$hostname	IN	A	$_ip4\n$hostname	IN	AAAA	$_ip6\nservidor	IN	CNAME	$hostname" >> /etc/bind/db.local

	echo -e '\033[07;31mADICIONANDO  NOVAS MAQUINAS AO DNS\033[00;37m'   
	echo "Diga o NOME da maquina: "
	read nome
	echo "Diga o IPv4 da maquina: "
	read ip4
	echo "Diga o IPv6 da maquina: "
	read ip6
	echo "Diga um apelido: "
	read apelido

	endip4=$(echo $ip4 |sed 's/192.168.0.//g')
	endip6=$(echo $ip6 |sed 's/.*:://g')

	echo -e "\n	IN	NS	$hostname.\n$auxip4	IN	PTR	$hostname.ubuntu.local.\n$auxip6.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0	IN	PTR	$hostname.ubuntu.local.\n\n$endip4	IN	PTR	$nome.ubuntu.local.\n$endip6.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0	IN	PTR	$nome.ubuntu.local." >>  /etc/bind/db.127

	echo -e "\n$nome	IN	A	$ip4\n$nome	IN	AAAA	$ip6\n$apelido	IN	CNAME	$nome" >> /etc/bind/db.local
	/etc/init.d/bind9 restart
	clear
	/etc/init.d/bind9 status
	Menu
}

Adicionar(){	
	hostname=$(cat /etc/hostname)

	echo -e '\033[07;31mADICIONANDO  NOVAS MAQUINAS AO DNS\033[00;37m'   
	echo "Diga o NOME da maquina: "
	read nome
	echo "Diga o IPv4 da maquina: "
	read ip4
	echo "Diga o IPv6 da maquina: "
	read ip6
	echo "Diga um apelido: "
	read apelido

	endip4=$(echo $ip4 |sed 's/192.168.0.//g')
	endip6=$(echo $ip6 |sed 's/.*:://g')

	echo -e "\n$endip4	IN	PTR	$nome.ubuntu.local.\n$endip6.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0	IN	PTR	$nome.ubuntu.local." >>  /etc/bind/db.127
	echo -e "\n$nome	IN	A	$ip4\n$nome	IN	AAAA	$ip6\n$apelido	IN	CNAME	$nome" >> /etc/bind/db.local
	
	/etc/init.d/bind9 restart
	Menu
}

Isc(){
	sudo apt update	
	sudo apt install isc-dhcp-server -y
	clear
	Menu	
}

Bind(){
	sudo apt update	
	sudo apt install bind9 -y
	clear
	Menu
}	
Menu
