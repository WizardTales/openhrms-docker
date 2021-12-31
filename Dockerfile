FROM ubuntu:20.04

ENV OE_VERSION="14.0"
ENV WKHTMLTOX_X64=https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.trusty_amd64.deb
ENV WKHTMLTOX_X32=https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.trusty_i386.deb
ENV DEBIAN_FRONTEND=noninteractive

ADD openhrms_install.sh /
RUN apt-get update && apt-get install sudo software-properties-common -y \
      && add-apt-repository universe \
      && add-apt-repository ppa:linuxuprising/libpng12 \
      && apt-get install git python3 python3-pip build-essential wget python3-dev python3-venv python3-wheel libxslt-dev libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libpng12-0 libjpeg-dev gdebi nodejs npm libpq-dev wkhtmltopdf -y \
      && pip3 install -r https://github.com/odoo/odoo/raw/${OE_VERSION}/requirements.txt && pip3 install pandas \
      && pip3 install gevent \
      && npm install -g rtlcss && rm -rf /var/lib/apt/lists/*



ENV OE_USER="openhrms"
ENV OE_HOME="/opt/$OE_USER"
ENV OE_HOME_EXT="/$OE_USER/${OE_USER}-server"
ENV OE_CONFIG="${OE_USER}-server"
ENV LONGPOLLING_PORT="8072"
ENV OE_SUPERADMIN="admin"
ENV OE_PORT="8080"

RUN echo -e "\n---- Create ODOO system user ----" \
      && sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER \
      && sudo adduser $OE_USER sudo \
      && echo -e "\n---- Create Log directory ----" \
      && sudo mkdir /var/log/$OE_USER \
      && sudo chown $OE_USER:$OE_USER /var/log/$OE_USER \
      && echo -e "\n==== Installing ODOO Server ====" \
      && sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT/ \
      && sudo git clone --depth 1 --branch $OE_VERSION https://github.com/CybroOdoo/OpenHRMS $OE_HOME_EXT/OpenHRMS \
      && echo -e "\n---- Create custom module directory ----" \
      && sudo su $OE_USER -c "mkdir $OE_HOME/custom" \
      && sudo su $OE_USER -c "mkdir $OE_HOME/custom/addons" \
      && echo -e "\n---- Setting permissions on home folder ----" \
      && sudo chown -R $OE_USER:$OE_USER $OE_HOME/* \
      && echo -e "* Create server config file" \
      && sudo touch /etc/${OE_CONFIG}.conf \
      && echo -e "* Creating server config file" \
      && sudo su root -c "printf '[options] \n; This is the password that allows database operations:\n' >> /etc/${OE_CONFIG}.conf" \
      && echo -e "* Generating random admin password" \
      && OE_SUPERADMIN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1) \
      && sudo su root -c "printf 'admin_passwd = ${OE_SUPERADMIN}\n' >> /etc/${OE_CONFIG}.conf" \
      && sudo su root -c "printf 'http_port = ${OE_PORT}\n' >> /etc/${OE_CONFIG}.conf" \
      && sudo su root -c "printf 'logfile = /var/log/${OE_USER}/${OE_CONFIG}.log\n' >> /etc/${OE_CONFIG}.conf" \
      && sudo chown $OE_USER:$OE_USER /etc/${OE_CONFIG}.conf \
      && sudo chmod 640 /etc/${OE_CONFIG}.conf \
      && sudo su root -c "printf 'addons_path=${OE_HOME_EXT}/addons,${OE_HOME_EXT}/OpenHRMS\n' >> /etc/${OE_CONFIG}.conf" \
      && echo -e "* Create startup file" \
      && sudo su root -c "echo '#!/bin/sh' >> $OE_HOME_EXT/start.sh" \
      && sudo su root -c "echo 'sudo -u $OE_USER $OE_HOME_EXT/odoo-bin --config=/etc/${OE_CONFIG}.conf' >> $OE_HOME_EXT/start.sh" \
      && sudo chmod 755 $OE_HOME_EXT/start.sh 
