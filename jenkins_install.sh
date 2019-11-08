#!/bin/bash

function jenkins_cli_setup {
    echo -e "\e[92mDownloading jenkins-cli jar from jenkins server\e[0m"
    sleep 5
    curl localhost:8080/jnlpJars/jenkins-cli.jar -o jenkins-cli.jar
}

function generate_service_file() {
    # generates systemd service file for jenkins
cat << EOF > /etc/systemd/system/jenkins.service
[Unit]
Description=Jenkins

[Service]
User=jenkins
WorkingDirectory=$JENKINS_WAR_DIR
ExecStart=$JAVA_HOME -Djenkins.install.runSetupWizard=false -DJENKINS_HOME=$JENKINS_HOME -jar $JENKINS_WAR --httpPort=$HTTP_PORT --logfile=$JENKINS_LOG

[Install]
WantedBy=multi.user.target
EOF

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

if [ "$EUID" -ne 0 ]
    then echo "Please run script as root"
    exit
fi

if [ ! -d '/var/lib/jenkins' ]; then
    install_dependencies
    #if [ $DISTRO == "ubuntu" ] || [ $DISTRO == "debian" ] || [ $DISTRO == "raspbian" ]; then
    #    echo "Installing Jenkins"
    #    wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key |  apt-key add -
    #     sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    #     apt-get update
    #     apt-get install -y jenkins
    #fi
    
    source files/setenv.sh
    echo "Creating jenkins user"
    useradd jenkins && usermod --shell /bin/bash jenkins
    usermod -a -G jenkins jenkins
    mkdir -p $JENKINS_WAR_DIR
    chmod 755 $JENKINS_WAR_DIR
    chown jenkins:jenkins $JENKINS_WAR_DIR
    mkdir -p $JENKINS_LOG_DIR
    touch $JENKINS_LOG_DIR/jenkins.log
    chown -R jenkins:jenkins $JENKINS_LOG_DIR

    echo "Downloading latest jenkins.war"
    curl -L http://updates.jenkins-ci.org/latest/jenkins.war -o $JENKINS_WAR
    #wget -O $JENKINS_WAR http://updates.jenkins-ci.org/latest/jenkins.war
    mkdir -p $JENKINS_HOME
    
    echo "Creating systemd service"
    # mv $(pwd)/files/jenkins.service /etc/systemd/system
    generate_service_file
    systemctl daemon-reload
    
    systemctl start jenkins
    jenkins_cli_setup
fi

install_plugins "$1"
