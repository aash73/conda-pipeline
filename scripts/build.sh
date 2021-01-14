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

###########################################################
#This method generates the full path for the conda package given the arguments.
#Conda Package Format: VersionName + - + VersionNumber + - + "py_" + BuildNnumber + ".tar.bz2"
#Full path to package: CondaPackageDir + / + CondaPackageName
#arg1 metafile path
#arg2 build number
#arg3 conda package output dir
generate_conda_package_path() {
  echo "1st Arg =  " $1
  echo "2nd Arg =  " $2
  echo "3rd Arg =  " $3
  v_name=$(awk '/{% set name =/ {print $5}' $1)
  v_number=$(awk '/{% set version =/ {print $5}' $1)
  v_name=$(eval echo $v_name) && v_number=$(eval echo $v_number)
  #echo "Version Name =  " $v_name
  #echo "Version Number =  " $v_number
  package_path="${3}/noarch/${v_name}-${v_number}-py_${2}.tar.bz2"
  #echo "Package Path = " $package_path
  return 0
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

export BUILD_NUMBER=$build_number

mkdir $output_fldr

echo "[C-INFO] Building Spaghetti-feedstock pkg......"

conda build --no-anaconda-upload --no-test --output-folder $output_fldr spaghetti-feedstock/recipe/

if [ $? -ne 0 ]; then 
  echo -e "\n[C-ERROR] Conda Build Failed ..."
  exit 1
fi

#To Test the build
#conda build -t --output-folder /Users/asimp/conda-examples/conda-pipeline/condabuild/ ./spaghetti-feedstock/recipe/
#conda build -t condabuild/noarch/spaghetti-1.5.6-py_0.tar.bz2

echo "[C-INFO] Generating final package path ... "
generate_conda_package_path spaghetti-feedstock/recipe/meta.yaml $BUILD_NUMBER $output_fldr
if [ $? -eq 0 ]; then
  echo "[C-INFO] Package Path = $package_path"
else
  echo "[C-ERROR] generate_conda_package_path() failed "
  exit 1
fi

echo "[C-INFO] uploading conda package to Artifactory ... "
jfrog rt u $package_path $target_repo/ --build-name=$build_id --build-number=$build_number

if [ $? -eq 0 ]; then 
  echo -e "\n[C-INFO] conda package uploaded !"
else
  echo -e "\n[C-ERROR] Conda Package upload failed ... !!"
  exit 1
fi

jfrog rt bce $build_id $build_number
jfrog rt bp $build_id $build_number

