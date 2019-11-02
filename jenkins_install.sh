#!/bin/bash

export DISTRO=$(sed -n '/\bID\b/p' /etc/os-release | awk -F= '/^ID/{print $2}' | tr -d '"')

function jenkins_cli_setup {
    curl localhost:8080/jnlpJars/jenkins-cli.jar -o jenkins-cli.jar
}

if [ "$EUID" -ne 0 ]
    then echo "Please run script as root"
    exit
fi

if [ ! -d '/var/lib/jenkins' ]; then
    if [ $DISTRO == "ubuntu" || $DISTRO == "debian" || $DISTRO == "raspbian" ]; then
        wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
        sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
        sudo apt-get update
        sudo apt-get install jenkins
    fi

    systemctl start jenkins
    jenkins_cli_setup
fi


