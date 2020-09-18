#!/bin/bash

export OS=$(uname -s)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/jenkins-setup"
NEW_INSTALL=true

function jenkins_cli_setup {
    echo -e "\e[92mDownloading jenkins-cli jar from jenkins server\e[0m"
    sleep 5
    curl localhost:8080/jnlpJars/jenkins-cli.jar -o jenkins-cli.jar
}

function casc_setup () {
    echo "Creating jenkins casc file and directory"
    sudo mkdir $JENKINS_HOME/casc_configs
    CASC_F=$DIR/files/casc.yaml
    sudo sed -e "s/JENKINS_HOST/$JENKINS_HOST/" -e "s/JENKINS_PORT/$JENKINS_PORT/" -e "s|JENKINS_HOME|$JENKINS_HOME|" <$CASC_F > /tmp/casc.yaml 
    sudo mv /tmp/casc.yaml $JENKINS_HOME/casc_configs/casc.yaml
    sudo chown -R jenkins:jenkins $JENKINS_HOME/casc_configs
    export CASC_JENKINS_CONFIG=$JENKINS_HOME/casc_configs/casc.yaml
}

function seed_job () {
    echo "Creating initial seed job interface"
    sudo mkdir -p $JENKINS_HOME/dslScripts/
    sudo cp $DIR/files/initSeedJob.groovy $JENKINS_HOME/dslScripts/
}

function generate_service_file() {
    # generates systemd service file for jenkins
sudo su -c "cat << EOF > /etc/systemd/system/jenkins.service
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
EOF"

}

function generate_ssh_keys() {
    echo "Creating ssh keys"
    sudo mkdir -p $JENKINS_HOME/.ssh
    sudo chmod 700 $JENKINS_HOME/.ssh
    sudo chown -R jenkins:jenkins $JENKINS_HOME/.ssh
    sudo su - jenkins -c "ssh-keygen -N \"\" -f $JENKINS_HOME/.ssh/id_rsa"
}

function install_plugins () {
    pluginfile="$DIR/plugins.txt"

    if [ ! -d '/usr/local/bin' ]; then
        sudo mkdir -p /usr/local/bin
    fi
    if [ ! -f /usr/local/bin/jenkins-support ] && [ ! -f /usr/local/bin/install-plugins.sh ]; then
        # TODO: switch to jenkins-plugin-cli as install-plugins is deprecated
        sudo mv $DIR/files/install-plugins.sh /usr/local/bin/install-plugins.sh
        sudo mv $DIR/files/jenkins-support /usr/local/bin/jenkins-support
        # sudo curl -L https://raw.githubusercontent.com/jenkinsci/docker/master/jenkins-support -o /usr/local/bin/jenkins-support
        sudo chmod 700 /usr/local/bin/install-plugins.sh
        sudo chmod 700 /usr/local/bin/jenkins-support
    fi
    
    echo -e "\e[92mInstalling plugins\e[0m"
    sudo /usr/local/bin/install-plugins.sh < $pluginfile
    
}

function install_dependencies () {
    dependencies=(java wget unzip)
    sudo apt update
    for dep in ${dependencies[@]}; do 
        if [ ! -x "$(command -v $dep)" ]; then
            echo "Installing pre-requisite: $dep"
            if [ $dep == 'java' ]; then
                sudo apt install -y openjdk-8-jdk
            fi
            sudo apt install -y $dep
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
    
    source $DIR/files/setenv.sh
    echo "Creating jenkins user"
    sudo useradd -m -d $JENKINS_HOME jenkins && usermod --shell /bin/bash jenkins
    sudo usermod -a -G jenkins jenkins
    sudo mkdir -p $JENKINS_WAR_DIR
    sudo chmod 755 $JENKINS_WAR_DIR
    sudo mkdir -p $JENKINS_LOG_DIR
    sudo touch $JENKINS_LOG_DIR/jenkins.log
    sudo chown -R jenkins:jenkins $JENKINS_LOG_DIR

    echo "Downloading latest jenkins.war"
    sudo curl -L http://updates.jenkins-ci.org/latest/jenkins.war -o $JENKINS_WAR
    sudo chown -R jenkins:jenkins $JENKINS_WAR_DIR
    sudo mkdir -p $JENKINS_HOME
    

    generate_ssh_keys
    #copy init script directory to JENKINS_HOME
    sudo cp -R $DIR/files/init.groovy.d $JENKINS_HOME
    seed_job
    casc_setup

    echo "Creating systemd service"
    generate_service_file
    sudo systemctl daemon-reload
else
    NEW_INSTALL=false
    source $DIR/files/setenv.sh
fi

install_plugins 
# Moving plugins from REF directory
sudo mv /usr/share/jenkins/ref/plugins/*.jpi $JENKINS_HOME/plugins
sudo chown -R jenkins:jenkins $JENKINS_HOME

if [[ "$NEW_INSTALL" = true ]]; then
    echo -e "\e[92mJenkins ssh public key:\e[0m"
    sudo cat $JENKINS_HOME/.ssh/id_rsa.pub
fi

sudo systemctl enable jenkins
sudo systemctl start jenkins

sleep 40

