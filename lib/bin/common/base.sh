#!/bin/bash

trap clean_up exit

bin_dir=$app_home/bin
config_dir=$app_home/config
tmp=/tmp/tmp$$
tmp_res=/tmp/tmp_res$$
tmp_ret=/tmp/tmp_ret$$
tmp_dryrun=/tmp/tmp_dryrun$$

selected_dir=
selected_file=

exists() {
  command -v $1 >/dev/null 2>&1
}

preflight_check() {
  exists "curl" || {
    warn "dependency 'curl' not found, launch in dry run mode"
  }

  exists "jq" || {
    warn "dependency 'jq' not found, some features may not be available"
  }

  exists "dialog" || {
    warn "dependency 'dialog' not found, dialog mode disabled"
  }
}

on_init() (:)

init_app() {
  preflight_check
  on_init
}

on_exit() (:)

clean_up() {
  rm -f $tmp $tmp_res $tmp_ret $tmp_dryrun
  on_exit
  exit
}

config() {
  local conf=()
  while IFS='=' read -r key value ; do
    if [[ ! -z $key && $@ =~ ${key%%_*} ]] ; then
      conf+=("$key")
    fi
  done < $config_dir/main.properties
  
  formbox "Config" "Available configuration:" "${conf[@]}"
}

select_dir() {
  local dirs=($1/* "...")
  dirs=(${dirs[@]##*/})

  local title=$2
  local item=$(echo $2 | tr '[:upper:]' '[:lower:]')
  menubox "$title" "Select $item from the list:" "selected_dir" "${dirs[@]}"

  [[ $? != 0 ]] && return -1

  if [[ $selected_dir == "..." ]] ; then
    local default_value=$3
    inputbox "Input $title" "Input the name of $item" "selected_dir" "$default_value"
  fi
}

select_file() {
  local files=()
  [[ -d $1 ]] && files=($(ls -l $1 | awk '{print $9}' | egrep "^$3" | cut -d . -f 1))
  [[ $@ =~ --allow-none ]] && files+=("none")
  [[ $@ =~ --allow-input ]] && files+=("...")

  local title=$2
  local item=$(echo $2 | tr '[:upper:]' '[:lower:]')
  menubox "$title" "Select $item from the list:" "selected_file" "${files[@]}"
}

cat_query() {
  local choice
  local options=(
    "indices"
    "shards"
    "nodes"
    "..."
  )

  while true ; do
    menubox "cat" "Select an Elasticsearch cat API:" "choice" "${options[@]}"

    [[ $? != 0 ]] && return -1

    case $choice in
      "indices") do_cat_query "indices" ;;
      "shards") do_cat_query "shards" ;;
      "nodes") do_cat_query "nodes" ;;
      "...") do_cat_query ;;
    esac
  done
}

do_cat_query() {
  local cmd=$1
  [[ -z $cmd ]] && inputbox "cat" "Command(press Enter to list all commands)" "cmd"
  [[ ! -z $cmd ]] && cmd="/$cmd?v"

  net_get "_cat$cmd" --silent | to_json | textbox "_cat$cmd"
}

display_time() {
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  (( $D > 0 )) && printf '%d ' $D
  (( $H > 0 )) && printf '%02d:' $H
  (( $M > 0 )) && printf '%02d:' $M
  printf '%02d\n' $S
}

to_json() {
  jq --raw-input --raw-output '. as $line | try fromjson catch $line'
}

value_of() {
  jq $1 ${@:2} 2>/dev/null
}

has_key() {
  jq -e "has(\"$1\")" 2>/dev/null
}

if ! exists "jq" ; then
  to_json() {
    cat
  }

  value_of() {
    grep -o "\"${1:1}\":\s*\"\?[^\"^,]*" | grep -o '[^"]*$' | sed -e 's/^://'
  }

  has_key() {
    grep -o "\"$1\":" && echo true || echo false
  }
fi

[[ $@ =~ --quiet ]] && is_quiet=1

[ -f $config_dir/main.properties ] && . $config_dir/main.properties
[ -f $bin_dir/common/log.sh ] && . $bin_dir/common/log.sh
[ -f $bin_dir/common/net.sh ] && . $bin_dir/common/net.sh
[ -f $bin_dir/common/task.sh ] && . $bin_dir/common/task.sh

if [[ $@ =~ --ui-dialog ]] ; then
  if exists "dialog" ; then
    [[ -f $bin_dir/ui/dialog.sh ]] && . $bin_dir/ui/dialog.sh
  else
    error "can not run in dialog mode due to 'dialog' not found"
    exit 1
  fi
elif [[ $@ =~ --ui-text ]] ; then
  [ -f $bin_dir/ui/text.sh ] && . $bin_dir/ui/text.sh
else
  [ -f $bin_dir/ui/cli-base.sh ] && . $bin_dir/ui/cli-base.sh
  [ -f $bin_dir/ui/cli-seq.sh ] && . $bin_dir/ui/cli-seq.sh
fi
