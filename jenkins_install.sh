#!/bin/bash

export DISTRO=$(sed -n '/\bID\b/p' /etc/os-release | awk -F= '/^ID/{print $2}' | tr -d '"')

function jenkins_cli_setup {
    curl localhost:8080/jnlpJars/jenkins-cli.jar -o jenkins-cli.jar
}

function install_plugins () {
    filepath=$1
    absolute_file="$( cd "${filepath%/*}" && pwd )"/"${filepath##*/}"

    if [ ! -d '/usr/local/bin' ]; then
        mkdir -p /usr/local/bin
    fi
    if [ ! -f /usr/local/bin/jenkins-support ] && [ ! -f /usr/local/bin/install-plugins.sh ]
        curl -L https://raw.githubusercontent.com/jenkinsci/docker/master/install-plugins.sh -o /usr/local/bin/install-plugins.sh
        curl -L https://raw.githubusercontent.com/jenkinsci/docker/master/jenkins-support -o /usr/local/bin/jenkins-support
        chmod 700 /usr/local/bin/install-plugins.sh
        chmod 700 /usr/local/bin/jenkins-support
    fi
    
    /usr/local/bin/install-plugins.sh $absolute_file
    
}

if [ "$EUID" -ne 0 ]
    then echo "Please run script as root"
    exit
fi

if [ ! -d '/var/lib/jenkins' ]; then
    if [ ! -x "$(command -v java)" ]; then
        apt-get update
        apt-get install -y openjdk-8-jre
    fi
    if [ $DISTRO == "ubuntu" ] || [ $DISTRO == "debian" ] || [ $DISTRO == "raspbian" ]; then
        wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
        sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
        sudo apt-get update
        sudo apt-get install -y jenkins
    fi

    systemctl start jenkins
    jenkins_cli_setup
fi


