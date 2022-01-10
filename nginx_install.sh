#!/bin/bash

#exit option
set -e



#check if su

if [[ $EUID -ne 0 ]]; then
   echo -e "\033[1;91mPlease use the script with superuser\033[0m"
   exit 
fi

#gets the OS information as variable
source /etc/os-release
DISTRO_NAME_HUMAN="$(gawk -F'"' '{print $2}' /etc/os-release | head -1)"



#Version check for ubuntu and centos
    function if_ubuntu () {
        WHICH_OS=ubuntuu
        if [[ "$VERSION_ID" != "18.04" ]]; then
            echo -e "\033[0;31mVersion of the $DISTRO_NAME_HUMAN should be 18.04!\033[0m"
             exit 1
        else 
            echo -e "\033[0;32mStarting installation for $PRETTY_NAME!\033[0m"
        fi
        }
#Check version of the CentOS
    function if_centos () {
        WHICH_OS=centoss
        if [ "$VERSION_ID" != "7"]; then
            echo -e "\033[0;31mVersion of the $DISTRO_NAME_HUMAN should be 7!\033[0m"
            exit 1
        else
            echo -e "\033[0;32mStarting installation for $PRETTY_NAME!\033[0m"
        fi
}
#UBUNTU Cheks is nginx installed
    function install_nginx_u () {

        if [ ! -w /etc/nginx/sites-available/default ]; then
            echo -e "\033[0;32mInstalling Nginx\033[0m"
            apt install nginx -y
        fi
#UBUNTU if nginx is already installed changes listen port to 80 at default .conf
        if [ -w /etc/nginx/sites-available/default ]; then
            echo -e "\033[0;32mNginx is installed."
           sed -i 's/listen 80 d/listen 8000 d/' /etc/nginx/sites-available/default
           sed -i 's/:]:80 /:]:8000 /' /etc/nginx/sites-available/default
           ufw allow 8000/tcp
            echo -e "\033[0;32mChanging listening port from 80 to 8000\033[0m"
            echo -e "\033[0;32mAdding Firewall permissions.\033[0m"
        fi
}
#CENTOS if nginx is already installed changes listen port to 80 at default .conf
    function install_nginx_c () {
        if [ ! -w /etc/nginx/nginx.conf ]; then
            echo -e "\033[0;32mInstalling Nginx\033[0m"
            yum -y install epel-release
            yum -y install nginx
        fi

        if [ -w /etc/nginx/nginx.conf ]; then
        echo -e "\033[0;32mNginx is installed, continuing.\033[0m"
           sed -i 's/80;/8000;/' /etc/nginx/nginx.conf
           sed -i 's/[::]:80;/[::]:8000;/' /etc/nginx/nginx.conf
         echo -e "\033[0;32mChanging listening port from 80 to 8000\033[0m"
         echo -e "\033[0;32mAdding firewall permissions\033[0m"
         firewall-cmd --zone=public --permanent --add-port=8000/tcp

        fi
}
#UBUNTU Ask for system update
function ubuntu_sysupdate(){
    while true; do
    echo -e -n "\033[0;32mDo you wish to update your Os?: \033[0m"
    read -p "" yn
    case $yn in
        [Yy]* ) apt-get update; break;;
        [Nn]* ) break;;
        * ) echo -e "\033[0;31mPlease answer yes or no.\033[0m";;
    esac
done
}
function centos_sysupdate(){
        while true; do
    echo -e -n "\033[0;32mDo you wish to update your Os?: \033[0m"
    read -p "" yn
    case $yn in
        [Yy]* ) yum update; break;;
        [Nn]* ) break;;
        * ) echo -e "\033[0;31mPlease answer yes or no.\033[0m";;
    esac
done
}

#gets the default directory for the index.html file
#UBUNTU Cleans and creates example html file at main folder
function default_html_u(){
     ROOT_DIR=$(grep root -m1 /etc/nginx/sites-available/default | cut -d " " -f2 | sed 's/;$//')
   find $ROOT_DIR -type f -delete
   cat > $ROOT_DIR/index.html << EOF
<!DOCTYPE html>
<html>
    <title>
    is workin
    </title>
    <body style="background-color:black;text-align:center;font-family:'Courier New';">
    
        <h1 style="color:cyan;">testing one two tree</h1>
            <img src="https://c.tenor.com/zBc1XhcbTSoAAAAC/nyan-cat-rainbow.gif" alt="kurcalamaaa">
    </body>
</html>"
EOF
}
#CENTOS looks and changes default html folder
function default_html_c(){
     ROOT_DIR=$(grep root -m1 /etc/nginx/nginx.conf | awk '{print $2}' | sed 's/;$//')
   find $ROOT_DIR -type f -delete
   cat > $ROOT_DIR/index.html << EOF
<!DOCTYPE html>
<html>
    <title>
    is workin
    </title>
    <body style="background-color:black;text-align:center;font-family:'Courier New';">
    
        <h1 style="color:cyan;">testing one two tree</h1>
            <img src="https://c.tenor.com/zBc1XhcbTSoAAAAC/nyan-cat-rainbow.gif" alt="kurcalamaaa">
    </body>
</html>"
EOF
}
#UBUNTUChecks which OS is running
if [ "$ID" == "ubuntu" ]; then
        ubuntu_sysupdate
        if_ubuntu
    elif [ "$ID" == "centos" ]; then
         centos_sysupdate
         if_centos
else
    echo -e "\033[0;31mOperating system should be Ubuntu 18.04 or CentOs 7 $PRETTY_NAME is not supported.\033[0m"
    exit 1
fi
if [ "$WHICH_OS" == "ubuntuu" ]; then
        install_nginx_u
    elif [ "$WHICH_OS" == "centoss" ]; then
        install_nginx_c
    else
        echo -e "\033[0;31mAn error occured cannot verify the type of the Operating system.\033[0m"
            exit 1
fi

if [ "$WHICH_OS" == "ubuntuu" ]; then
        default_html_u
    elif [ "$WHICH_OS" == "centoss" ]; then
        default_html_c
    else
    echo -e "\033[0;31mAn error occured cannot verify the type of the Operating system.\033[0m"
fi
    
    echo -e "\033[0;32mInstallation successfull. Creating default page.\033[0m"


systemctl start nginx.service
systemctl status nginx
