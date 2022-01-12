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

          if [ ! -x "$(command -v nginx)" ]; then
            echo -e "\033[0;32mInstalling Nginx\033[0m"
            apt install nginx -y
        fi
#UBUNTU if nginx is already installed changes listen port to 80 at default .conf
        if [ -x "$(command -v nginx)" ]; then
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
        if [ ! -x "$(command -v nginx)" ]; then
            echo -e "\033[0;32mInstalling Nginx\033[0m"
            yum -y install epel-release
            yum -y install nginx
        fi

        if [ -x "$(command -v nginx)" ]; then
        echo -e "\033[0;32mNginx is installed, continuing.\033[0m"
           sed -i 's/80;/8000;/' /etc/nginx/nginx.conf
           sed -i 's/[::]:80;/[::]:8000;/' /etc/nginx/nginx.conf
         yum install policycoreutils-python
         semanage port -m -t http_port_t -p tcp 8000
         firewall-cmd --zone=public --permanent --add-port=8000/tcp
         echo -e "\033[0;32mChanging listening port from 80 to 8000\033[0m"
         echo -e "\033[0;32mAdding firewall permissions\033[0m"

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
<html lang="en">
    <head>
    <title>is workin</title>
    </head>
    <body style="background-color:rgb(255, 255, 255);text-align:center;font-family:'Courier New';">
     <h1 style="color:rgb(77, 177, 11);">there is something wrong with the encoding..</h1>
     <img src=$IMG alt="nyan" width="1200" height="500">
    </body>
</html>
EOF
}
#CENTOS looks and changes default html folder
function default_html_c(){
     ROOT_DIR=$(grep root -m1 /etc/nginx/nginx.conf | awk '{print $2}' | sed 's/;$//')
   find $ROOT_DIR -type f -delete
   cat > $ROOT_DIR/index.html << EOF
<!DOCTYPE html>
<html lang="en">
    <head>
    <title>is workin</title>
    </head>
    <body style="background-color:rgb(255, 255, 255);text-align:center;font-family:'Courier New';">
     <h1 style="color:rgb(77, 177, 11);">there is something wrong with the encoding..</h1>
    <img src=$IMG alt="nyan" width="1200" height="500">
    </body>
</html>
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
systemctl restart nginx.service
systemctl status nginx


IMG="data:image/jpeg;base64,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"
