#!/bin/bash

app_cmd="Snapshot"
#app_home=${app_home:-$(dirname `pwd`)}
app_home=${app_home:-$(dirname $(cd "$(dirname "$0")" && pwd))}
bin_dir=$app_home/bin

[ -f $bin_dir/common/base.sh ] && . $bin_dir/common/base.sh

config_snapshot_dir="$config_dir/snapshot"

repo=
snapshot=

input_repo() {
  inputbox "Repository Name" "Input repository name" "repo" $snapshot_repository
}

input_name() {
  inputbox "Snapshot Name" "Input snapshot name" "snapshot"
  if [[ -z $snapshot ]] ; then
    msgbox "Error" "Snapshot name is required!"
    return -1
  fi
}

new_repo() {
  input_repo

  [[ $? != 0 ]] && return -1

  net_put "_snapshot/$repo" \
    --data "$(cat $config_snapshot_dir/repo.json)" --silent | \
    to_json | textbox "Create Repository $repo"
}

repo() {
  local choice
  local options=(
    "new"
  )

  menubox "Repo" "Select a function:" "choice" "${options[@]}"

  [[ $? != 0 ]] && return -1

  case $choice in
    "new") new_repo ;;
  esac
}

create() {
  input_repo

  [[ $? != 0 ]] && return -1

  input_name

  [[ $? != 0 ]] && return -1

  net_put "_snapshot/$repo/$snapshot?wait_for_completion=true" --silent | \
    to_json | textbox "Create Snapshot $snapshot"
}

list() {
  input_repo

  [[ $? != 0 ]] && return -1

  net_get "_snapshot/$repo/_all" --silent | \
    to_json | textbox "List Snapshots"
}

restore() {
  input_repo

  [[ $? != 0 ]] && return -1

  input_name

  [[ $? != 0 ]] && return -1

  net_post "_snapshot/$repo/$snapshot/_restore" --silent | \
    to_json | textbox "Restore Snapshot $snapshot"
}

init_app

choice=
options=(
  "cat"
  "repo"
  "create"
  "list"
  "restore"
  "config"
)

while true
do
  menubox "Main Menu" "Select a function:" "choice" "${options[@]}"

  [[ $? != 0 ]] && exit

  case $choice in
    "cat") cat_query ;;
    "repo") repo ;;
    "create") create ;;
    "list") list ;;
    "restore") restore ;;
    "config") config "net" "snapshot" ;;
  esac
done
