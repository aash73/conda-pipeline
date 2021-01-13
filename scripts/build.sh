#!/bin/bash

usage()
{
  echo -e "==============================================================\n"
  echo -e "Usage:\n\t $0 -i build_id -n build_number -c pkg_cache -r target_repo -a arty_id -o output_fldr [-v]"
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

while getopts 'ha:c:i:n:r:o:t:' opt 
do
  case $opt in
    a) arty_id=$OPTARG ;;
    i) build_id=$OPTARG ;;
    n) build_number=$OPTARG ;;
    c) pkg_cache=$OPTARG ;;
    r) target_repo=$OPTARG ;;
    o) output_fldr=$OPTARG ;;
    h) usage ;;
  esac
done

checkVar "build_id build_number target_repo arty_id output_fldr"

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

export BUILD_NUMBER=build_number

mkdir $output-fldr

#echo "[C-INFO] installing dependencies ..."
#while read requirement; do conda install --yes $requirement; done < requirements.txt

#jfrog rt bad $build_id $build_number "$pkg_cache/*.tar.bz2"

#echo "[C-INFO] dependencies installed !"

echo "[C-INFO] Building Spaghetti-feedstock pkg......"

conda build --no-anaconda-upload --no-test --output-folder $output-fldr spaghetti-feedstock/recipe/

echo "[C-INFO] uploading conda package to Artifactory ... "
jfrog rt u $output-fldr/noarch/spaghetti-1.5.6-py_0.tar.bz2 $target_repo/ --build-name=$build_id --build-number=$build_number
echo "[C-INFO] conda package uploaded !"

jfrog rt bce $build_id $build_number
jfrog rt bp $build_id $build_number

