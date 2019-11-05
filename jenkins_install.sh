#!/bin/bash
source files/setenv.sh
export DISTRO=$(sed -n '/\bID\b/p' /etc/os-release | awk -F= '/^ID/{print $2}' | tr -d '"')

function jenkins_cli_setup {
    echo -e "\e[92mDownloading jenkins-cli jar from jenkins server\e[0m"
    sleep 5
    curl localhost:8080/jnlpJars/jenkins-cli.jar -o jenkins-cli.jar
}

function install_plugins () {
    pluginfile=$(pwd)/$1

    if [ ! -d '/usr/local/bin' ]; then
        mkdir -p /usr/local/bin
    fi
    if [ ! -f /usr/local/bin/jenkins-support ] && [ ! -f /usr/local/bin/install-plugins.sh ]; then
        curl -L https://raw.githubusercontent.com/jenkinsci/docker/master/install-plugins.sh -o /usr/local/bin/install-plugins.sh
        curl -L https://raw.githubusercontent.com/jenkinsci/docker/master/jenkins-support -o /usr/local/bin/jenkins-support
        chmod 700 /usr/local/bin/install-plugins.sh
        chmod 700 /usr/local/bin/jenkins-support
    fi
    
    echo -e "\e[92mInstalling plugins\e[0m"
    /usr/local/bin/install-plugins.sh < $pluginfile
    
}

if [ "$EUID" -ne 0 ]
    then echo "Please run script as root"
    exit
fi

if [ ! -d '/var/lib/jenkins' ]; then
    if [ ! -x "$(command -v java)" ]; then
        echo "Installing pre-requisite: Java"
        apt-get update
        apt-get install -y openjdk-8-jdk
    fi
    #if [ $DISTRO == "ubuntu" ] || [ $DISTRO == "debian" ] || [ $DISTRO == "raspbian" ]; then
    #    echo "Installing Jenkins"
    #    wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key |  apt-key add -
    #     sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    #     apt-get update
    #     apt-get install -y jenkins
    #fi
    echo "Creating jenkins user"
    useradd jenkins && usermod --shell /bin/bash jenkins 
    mkdir -p $JENKINS_WAR
    chmod 755 $JENKINS_WAR

    echo "Downloading latest jenkins.war"
    curl -L http://updates.jenkins-ci.org/latest/jenkins.war -o $JENKINS_WAR/jenkins.war
    mkdir -p $JENKINS_HOME
    
    echo "Creating systemd service"
    mv $(pwd)/files/jenkins.service /etc/systemd/system
    systemctl daemon-reload
    
    systemctl start jenkins
    jenkins_cli_setup
fi

install_plugins "$1"
