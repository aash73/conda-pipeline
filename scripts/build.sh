#!/bin/bash

usage()
{
  echo -e "==============================================================\n"
  echo -e "Usage:\n\t $0 -i build_id -n build_number -c pkg_cache -r target_repo -a arty_id [-v]"
  echo -e "==============================================================\n"
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

#####################################
#### MAIN 		
#####################################

while getopts 'ha:c:i:n:r:t:' opt 
do
  case $opt in
    a) arty_id=$OPTARG ;;
    i) build_id=$OPTARG ;;
    n) build_number=$OPTARG ;;
    c) pkg_cache=$OPTARG ;;
    r) target_repo=$OPTARG ;;
    h) usage ;;
  esac
done

checkVar "build_id build_number target_repo arty_id"

echo "[C-INFO] pinging Artifactory ..."
jfrog rt c show
jfrog rt use $arty_id
jfrog rt curl api/system/ping

if [ $? -eq 0 ]; then 
  echo -e "\n[C-INFO] ping OK !"
else
  echo -e "\n[C-ERROR] ping KO !!"
  exit 1
fi

echo "[C-INFO] installing dependencies ..."
while read requirement; do conda install --yes $requirement; done < requirements.txt

jfrog rt bad $build_id $build_number "$pkg_cache/*.tar.bz2"

echo "[C-INFO] dependencies installed !"

echo "[C-INFO] uploading conda package to Artifactory ... "
jfrog rt u whitebox-0.5.1-py37_0.tar.bz2 $target_repo/ --build-name=$build_id --build-number=$build_number
echo "[C-INFO] conda package uploaded !"

jfrog rt bce $build_id $build_number
jfrog rt bp $build_id $build_number

