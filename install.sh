#!/bin/bash

export OS=$(uname -s)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function jenkins_cli_setup {
    echo -e "\e[92mDownloading jenkins-cli jar from jenkins server\e[0m"
    sleep 5
    curl localhost:8080/jnlpJars/jenkins-cli.jar -o jenkins-cli.jar
}

function casc_setup () {
    echo "Creating jenkins casc file and directory"
    mkdir $JENKINS_HOME/casc_configs
    CASC_F=$DIR/files/casc.yaml
    sed -e "s/JENKINS_HOST/$JENKINS_HOST/" -e "s/JENKINS_PORT/$JENKINS_PORT/" -e "s|JENKINS_HOME|$JENKINS_HOME|" <$CASC_F > $JENKINS_HOME/casc_configs/casc.yaml 
    chown -R jenkins:jenkins $JENKINS_HOME/casc_configs
    export CASC_JENKINS_CONFIG=$JENKINS_HOME/casc_configs/casc.yaml
}

function seed_job () {
    echo "Creating initial seed job interface"
    mkdir -p $JENKINS_HOME/dslScripts/
    cp $DIR/files/initSeedJob.groovy $JENKINS_HOME/dslScripts/
}

function generate_service_file() {
    # generates systemd service file for jenkins
cat << EOF > /etc/systemd/system/jenkins.service
[Unit]
Description=Jenkins

[Service]
User=jenkins
WorkingDirectory=$JENKINS_WAR_DIR
Environment=JENKINS_HOME=$JENKINS_HOME
Environment=CASC_JENKINS_CONFIG=$CASC_JENKINS_CONFIG
ExecStart=$JAVA_HOME -Djenkins.install.runSetupWizard=false -DJENKINS_HOME=$JENKINS_HOME -jar $JENKINS_WAR --httpPort=$JENKINS_PORT --logfile=$JENKINS_LOG

[Install]
WantedBy=multi.user.target
EOF

}

function generate_ssh_keys() {
    echo "Creating ssh keys"
    mkdir -p $JENKINS_HOME/.ssh
    chmod 700 $JENKINS_HOME/.ssh
    ssh-keygen -N "" -f $JENKINS_HOME/.ssh/id_rsa
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
    
    generate_ssh_keys
    #copy init script directory to JENKINS_HOME
    cp -R $DIR/files/init.groovy.d $JENKINS_HOME
    seed_job
    casc_setup

    echo "Creating systemd service"
    generate_service_file
    systemctl daemon-reload
    
fi

install_plugins 
chown -R jenkins:jenkins $JENKINS_HOME
systemctl start jenkins
