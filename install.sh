#!/bin/bash

if (( $EUID != 0 )); then
    echo "Run with sudo"
    exit
fi

if [ "$1" == "update" ]; then
echo "Updating"
rm -rf /home/pi/bcmeter/ /home/pi/interface/
git clone https://github.com/bcmeter/bcmeter.git /home/pi/bcmeter


fi

if [ "$1" != "update" ]; then


echo "Installing software packages needed to run bcMeter. This will take a while and is dependent on your internet connection, the amount of updates and the speed of your pi."
apt update && apt upgrade -y && apt install -y i2c-tools zram-tools python3-pip python3-smbus python3-dev python3-rpi.gpio python3-numpy nginx php php-fpm php-pear php-common php-cli php-gd screen git openssl && pip3 install gpiozero adafruit-blinka tabulate && systemctl enable zramswap.service  
git clone https://github.com/bcmeter/bcmeter.git /home/pi/bcmeter
  
fi

#mkdir /etc/nginx/certificate

#read -p "Enableing HTTPS - do you want to use our Key (Y) or create your own (N)" yn
#    case $yn in
#        [Yy]* ) mv /home/pi/nginx.key /etc/nginx/certificate/nginx.key; break;;
#        [Nn]* ) openssl req -new -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes -out nginx-certificate.crt -keyout /etc/nginx/certificate/nginx.key;;
#        * ) echo "Please answer yes or no.";;
#    esac




mv /home/pi/bcmeter/* /home/pi/
rm -rf /home/pi/gerbers/ /home/pi/stl/
if [ "$1" != "update" ]; then
mkdir /home/pi/logs
touch /home/pi/logs/log_current.csv

echo "Installing common Temperature sensors (DHT22/DHT11 and BMP180/280)"
git clone https://github.com/coding-world/Python_BMP.git && cd Python_BMP/ &&  python3 setup.py install 
pip3 install Adafruit_Python_DHT
fi
echo "Configuring"
raspi-config nonint do_onewire 0
sh -c "echo 'dtoverlay=w1-gpio,gpiopin=5' >> /boot/config.txt"
raspi-config nonint do_boot_behaviour B2
echo "enabled autologin - you can disable this with sudo raspi-config anytime"
raspi-config nonint do_i2c 0
echo "enabled i2c"
if [ "$1" != "update" ]; then
mv /home/pi/nginx-bcMeter.conf /etc/nginx/sites-enabled/default

usermod -aG sudo www-data
usermod -aG sudo pi

echo "www-data  ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/www-data
echo "pi  ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/pi

systemctl start nginx

echo "enabled webserver."
echo "\e[104m!if you get a 502 bad gateway error in browser, check PHP-FPM version in /etc/nginx/sites-enabled/default is corresponding to installed php version!"

read -p "which hostname / address should be used for access (user interface in browser, ssh)? (for example: bcmeter01):" hostname  
raspi-config nonint do_hostname $hostname

echo "configuration complete. default timezone is UTC+0 - you can change it with 'sudo raspi-config'. "
fi

if [ "$1" != "update" ]; then
if ! grep -q "bcMeter.py" /home/pi/.bashrc; then
 read -p "Do you wish to autostart the script with every bootup? (y/n)" yn
    case $yn in
        [Yy]* ) echo -e "#autostart bcMeter \n if ! pgrep -f "bcMeter.py" > /dev/null \n then sudo screen python3 /home/pi/bcMeter.py \n else python3 /home/pi/output.py \n fi " >> /home/pi/.bashrc; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
fi

read -p "Do you wish to start the script NOW? You can always stop it by pressing ctrl+c. " yn
    case $yn in
        [Yy]* ) screen python3 /home/pi/bcMeter.py; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
fi
if [ "$1" == "update" ]; then
screen python3 /home/pi/bcMeter.py

fi
rm -rf /home/pi/bcmeter
chmod -R 777 /home/pi/*

read -p "Do you wish to finish configuration by rebooting? " yn
    case $yn in
        [Yy]* ) reboot now; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
fi
