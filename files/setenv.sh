#!/bin/bash
export JAVA_HOME=$(which java)
export JENKINS_WAR_DIR=/usr/share/jenkins
export JENKINS_WAR=/usr/share/jenkins/jenkins.war
export JENKINS_UC='https://updates.jenkins.io'
export JENKINS_HOME=/var/lib/jenkins
export REF=$JENKINS_HOME
export JENKINS_HOST=jenkins.local
export JENKINS_PORT=8080
export JENKINS_LOG=/var/log/jenkins/jenkins.log
export JENKINS_LOG_DIR=/var/log/jenkins
# export DISTRO=$(sed -n '/\bID\b/p' /etc/os-release | awk -F= '/^ID/{print $2}' | tr -d '"')
