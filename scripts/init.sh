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

checkVar() 
{
  for e in $1; do 
    echo "[C-INFO] $e : ${!e}"
    if [ "${!e}" == "" ]; then
      echo "[C-ERROR] $e not set"
      exit 1
    fi
  done
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

checkVar "condarc_file art_user art_apikey repo_name"

echo "[C-INFO] Removing default Channels from Conda config ... "
conda config --remove channels defaults

echo "[C-INFO] Printing CondaInfo BEFORE changes to CondaRC file ... "
conda info 

echo "[C-INFO] Making changes to CondaRC file ... "
cat <<EOF > $condarc_file
auto_activate_base: false
default_channels:
  - ${protocol}://${art_user}:${art_apikey}@${art_host}/api/conda/${repo_name}
EOF

echo "[C-INFO] Printing CondaRC file ... "
cat $condarc_file

echo "[C-INFO] Printing CondaInfo AFTER changes to CondaRC file ... "
conda info
