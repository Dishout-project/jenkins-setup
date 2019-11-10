#!/bin/bash

#set -x
function usage () {
    echo "$(basename "$0") [-h] [-i] [-u] -- a script to install jenkins locally using the latest war file

where:
    -h  show this help text
    -i  install jenkins
    -u  uninstall jenkins installed using this script"
}

if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root"
    exit 1
fi

while getopts ':iuh' option; do
  case "$option" in
    h) usage
       exit
       ;;
    i) source install.sh;;
    u) source uninstall.sh;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2
       usage >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       usage >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))

if [[ $OPTIND -eq 1 ]]; then
    usage
    exit 2
fi


