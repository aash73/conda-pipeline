#!/bin/bash

usage()
{
  echo "=============================================================="
  echo -e "Usage:\n\t $0 -u user -k apikey -l host -r repo -c condarc_file"
  echo "=============================================================="
  echo -e "\t - user : Artifactory user"
  echo -e "\t - apikey : User's apikey"
  echo -e "\t - host : Artifactory DNS (http://192.168.41.41:8081/artifactory)"
  echo -e "\t - repo : Artifactory repo"

  exit 2
}

condarc_file=/root/.condarc

while getopts 'hc:k:l:r:u:' opt 
do
  case $opt in
    c) condarc_file=$OPTARG;;
    k) art_apikey=$OPTARG;;
    l) 
       art_host=`echo $OPTARG | cut -d"/" -f 3,4` 
       protocol=`echo $OPTARG | cut -d":" -f 1`;;
    r) repo_name=$OPTARG ;;
    u) art_user=$OPTARG ;;
    h) usage ;;
  esac
done

conda config --remove channels defaults

conda info 

cat <<EOF > $condarc_file
auto_activate_base: false
default_channels:
  - ${protocol}://${art_user}:${art_apikey}@${art_host}/api/conda/${repo_name}
EOF

cat $condarc_file

conda info
