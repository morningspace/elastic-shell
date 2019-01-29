#!/bin/bash

find_home() {
  local script=$0 script_home
  while [ -h "$script" ]; do
    script_home="$( cd -P "$( dirname "$script" )" >/dev/null 2>&1 && pwd )"
    script="$(readlink "$script")"
    [[ $script != /* ]] && script="$script_home/$script"
  done
  script_home="$( cd -P "$( dirname "$script" )" >/dev/null 2>&1 && pwd )"
  echo $script_home
}

app_cmd=$1
app_home=$(find_home)
bin_dir=$app_home/bin
help_dir=$app_home/help
script_name=${0##*/}

[ -f $bin_dir/common/log.sh ] && . $bin_dir/common/log.sh

if [[ -z $1 || $1 == --help ]] ; then
  cat $help_dir/main.txt
  exit 0
fi

if [[ ! -f $bin_dir/$1.sh ]] ; then
  error "command '$1' not found" "See '$script_name --help'"
  exit 1
fi

set -- "${@:2}"

. $bin_dir/$app_cmd.sh
