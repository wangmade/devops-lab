#!/bin/bash
set_menu(){
echo "1.设置静态IP："
echo "2.设置yum源："
echo "3.设置防火墙和selinux(关闭)："
echo "4.设置主机名："
echo "5.安装常用软件："
echo "6.创建用户："
echo "7.sudo授权："
echo "8.清理桌面："
echo "9.磁盘状态："
}


set_static(){
	read -p "请输入您要设置的网卡名：" wkm
	read -p "请输入您要的IP地址：" dz
	read -p "请输入您的子网掩码：" ym
	read -p "请输入您的网关：" wg
	read -p "请输入您的DNS：" dns
	cd /etc/sysconfig/network-scripts 
	[ -z $wkm ] && wkm=ens33
	[ -z $dz ] && dz=192.168.136.100
	[ -z $ym ] && ym=24
	[ -z $wg ] && wg=192.168.136.2
	[ -z $dns ] && dns=114.114.114.114 
	sj=`date +%Y%m%d`
              cp ifcfg-$wkm ${sj}ifcfg_$wkm.bak  #备份
	cp ifcfg-$wkm ifcfg_$wkm.bak  #备份
	cat >ifcfg-$wkm<<EOF
TYPE="Ethernet"
BOOTPROTO="static"
NAME=$wkm
DEVICE=$wkm
IPADDR=$dz
PREFIX=$ym
GATEWAY=$wg
DNS=$dns
ONBOOT="yes"
EOF
	systemctl restart network &>/dev/null
	 ping -c1 www.baidu.com &> /dev/null
        if [ $? -eq 0 ]
        then
                echo "配置成功"
        else
                echo "配置失败，请重新配置"
        fi

}

set_yum(){
	 rpm -qa | grep wget &> /dev/null || yum -y install wget &> /dev/null
    [ -d /etc/yum.repos.d/repo ] || mkdir /etc/yum.repos.d/repo
    mv /etc/yum.repos.d/* repo &>/dev/null
	echo "配置源中请耐心等待"
    wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo &>/dev/null
    wget -O /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo &>/dev/null
    yum clean all &>/dev/null
    yum makecache fast &>/dev/null
    yum repolist &>/dev/null && echo "base源和epl源配置成功" || echo  "配置失败"
    return

}


set_fire_se(){
	systemctl stop firewalld >/dev/null
	systemctl disable firewalld >/dev/null
	systemctl is-active firewalld >/dev/null
	[ $? -ne 0 ] && echo "防火墙永久关闭成功 " || echo "防火墙永久关闭失败"
	setenforce 0  ##临时关闭
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config ##永久关闭重启生效
	echo "已关闭selinux"
}



set_host(){
	read -p "请输入您要设置的主机名：" zjm
	[ -z $zjm ] && zjm="kskbl"
	hostnamectl set-hostname $zjm
	echo "主机名已成功设置为$zjm"
}

set_soft(){
	echo "安装软件中，请稍等哦"
	yum -y install net-tools vim lrzsz wget net-tools zip unzip elinks bash-completion >/dev/null
	echo "软件安装完毕"
	
}


set_user(){
	read -p "请输入您想创建的用户名字：" yhm
	if [ -z "$yhm" ]
	then
		echo "用户名不能为空"
		return
	fi
	  read -s -p "请输入您的密码：" mm
	id $yhm &>/dev/null
	if [ $? -eq 0 ]
	then
		echo "用户已存在"
	else
		useradd $yhm  &>/dev/null
		echo "$yhm:$mm" | chpasswd
		echo "用户成功创建"
	fi
}

set_sudo(){
	read -p "请输入您要提权的用户名：" tqyh
	if [ -z "$tqyh" ]
    then
        echo "用户名不能为空"
        return
    fi
	read -p "请输入您要提权的命令(用,隔开否则无法生效，输入为空则自动给予最大权限)：" ml
#	 if [ -z "$tqyh" ]
#    then
#        echo "用户名不能为空"
#        continue
#    fi
	[ -z "$ml" ] && ml=ALL
cat >> /etc/sudoers <<EOF
$tqyh ALL=(ALL) $ml
EOF

}


set_cp(){
a=`df -h /data | awk 'NR==2{print $5}' | awk -F "%" '{print $1}'`
[ $a -gt 80 ] && echo "磁盘异常" || echo "磁盘正常"
}

while true
do
	set_menu
read -p "请选择您要执行的功能：" opt
	case $opt in
	1)
		set_static
		;;
	2)
		set_yum
		;;
	3)
		set_fire_se
		;;
	4)
		set_host
		;;
	5)
		set_soft
		;;		
	6)
		set_user
		;;
	7)
		set_sudo
		;;
	8)
		clear
		;;
	9)
		set_cp
		;;
	q|Q)
		exit
		;;
	*)
		echo "输入无效"
		;;
	esac
done

