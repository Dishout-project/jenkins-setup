#!/bin/bash

source files/setenv.sh

echo "Performing uninstall of Jenkins"
sleep 3
echo "Stopping jenkins service"
systemctl stop jenkins
echo "Removing jenkins directories and files"
rm -rf $JENKINS_HOME
rm -rf $JENKINS_LOG_DIR
rm -rf $JENKINS_WAR_DIR
rm /usr/local/bin/jenkins-support
rm /usr/local/bin/install-plugins.sh
echo "Removing systemd service"
rm /etc/systemd/system/jenkins.service
systemctl daemon-reload
echo "Removing jenkins user and group"
userdel jenkins
groupdel jenkins

if [ ! -d $JENKINS_HOME ] && [ ! -d $JENKINS_LOG_DIR ] && [ ! -d $JENKINS_WAR_DIR ] && [ ! -f "/etc/systemd/system/jenkins.service" ]; then
    echo "Jenkins successfully uninstalled"
    exit
else
    echo "Jenkins uninstall unsuccessful!"
fi
