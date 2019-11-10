#!/bin/bash

export OS=$(uname -s)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function jenkins_cli_setup {
    echo -e "\e[92mDownloading jenkins-cli jar from jenkins server\e[0m"
    sleep 5
    curl localhost:8080/jnlpJars/jenkins-cli.jar -o jenkins-cli.jar
}

function casc_setup () {
    CASC_JENKINS_CONFIG=$DIR/files/casc.yaml
    sed -e "s/JENKINS_HOST/$JENKINS_HOST/" -e "s/JENKINS_PORT/$JENKINS_PORT/" <$CASC_JENKINS_CONFIG
    export CASC_JENKINS_CONFIG
}

function generate_service_file() {
    # generates systemd service file for jenkins
cat << EOF > /etc/systemd/system/jenkins.service
[Unit]
Description=Jenkins

[Service]
User=jenkins
WorkingDirectory=$JENKINS_WAR_DIR
ExecStart=$JAVA_HOME -Djenkins.install.runSetupWizard=false -DJENKINS_HOME=$JENKINS_HOME -jar $JENKINS_WAR --httpPort=$JENKINS_PORT --logfile=$JENKINS_LOG

[Install]
WantedBy=multi.user.target
EOF

}

function install_plugins () {
    pluginfile="$DIR/plugins.txt"

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

function install_dependencies () {
    dependencies=(java wget unzip)
    apt-get update
    for dep in ${dependencies[@]}; do 
        if [ ! -x "$(command -v $dep)" ]; then
            echo "Installing pre-requisite: $dep"
            if [ $dep == 'java' ]; then
                apt-get install -y openjdk-8-jdk
            fi
            apt-get install -y $dep
        fi
    done
}

if [ $OS != "Linux" ]; then
    echo "This script currently does not support $OS"
    exit
else
    if [ ! -f "/etc/debian_version" ]; then
        echo "This script currently does not support non-debian distributions"
        exit
    fi
fi

if [ ! -d '/var/lib/jenkins' ]; then
    install_dependencies
    
    source files/setenv.sh
    echo "Creating jenkins user"
    useradd jenkins && usermod --shell /bin/bash jenkins
    usermod -a -G jenkins jenkins
    mkdir -p $JENKINS_WAR_DIR
    chmod 755 $JENKINS_WAR_DIR
    mkdir -p $JENKINS_LOG_DIR
    touch $JENKINS_LOG_DIR/jenkins.log
    chown -R jenkins:jenkins $JENKINS_LOG_DIR

    echo "Downloading latest jenkins.war"
    curl -L http://updates.jenkins-ci.org/latest/jenkins.war -o $JENKINS_WAR
    chown -R jenkins:jenkins $JENKINS_WAR_DIR
    mkdir -p $JENKINS_HOME
    chown -R jenkins:jenkins $JENKINS_HOME
    
    echo "Creating systemd service"
    generate_service_file
    systemctl daemon-reload
    
    systemctl start jenkins
    #jenkins_cli_setup
fi

install_plugins 
casc_setup
systemctl restart jenkins
