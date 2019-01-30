#!/bin/bash

app_cmd="Reindex"
#app_home=${app_home:-$(dirname `pwd`)}
app_home=${app_home:-$(dirname $(cd "$(dirname "$0")" && pwd))}
bin_dir=$app_home/bin

[ -f $bin_dir/common/base.sh ] && . $bin_dir/common/base.sh

config_reindex_dir="$config_dir/reindex"

run() {
  init_job $reindex_wait_for_completion

  [[ $? != 0 ]] && return -1

  local dir=$config_reindex_dir
  select_file $dir "Reindex Request" "request"

  [[ $? != 0 ]] && return -1

  local reindex_file=$selected_file
  if exists "jq" ; then
    select_file $dir "Reindex Queries" "queries" --allow-none
  else
    selected_file=none
  fi

  [[ $? != 0 ]] && return -1

  local queries_file=$selected_file
  if [[ $queries_file == "none" ]] ; then
    reindex "$(cat $dir/$reindex_file.json)"
  else
    reindex_by_query $reindex_file $queries_file
  fi

  [[ $reindex_wait_for_completion == true ]] && gen_report true
}

reindex() {
  local reindex_post=$(echo $1 | \
    sed -e "s/@@connect_timeout/$reindex_connect_timeout/g" | \
    sed -e "s/@@socket_timeout/$reindex_socket_timeout/g" | \
    sed -e "s/@@size/$reindex_size/g")

  echo $reindex_post | to_json | log

  local wait="wait_for_completion=$reindex_wait_for_completion"
  local timeout="timeout=$reindex_timeout"

  SECONDS=0
  net_post "_reindex?$wait&$timeout" --data "$reindex_post" --output $tmp_res | programbox
  local running_time=$(( SECONDS*1000000000 ))

  if [[ $(cat $tmp_ret) == 0 ]] ; then
    cat $tmp_res | to_json | textbox "Reindex Results"

    if [[ $(cat $tmp_res | has_key "error") == false ]] ; then
      if [[ $reindex_wait_for_completion == false ]] ; then
        task_id=$(cat $tmp_res | value_of .task --raw-output)
        add_task_to_job $task_id
      else
        local total=$(cat $tmp_res | value_of .total)
        local created=$(cat $tmp_res | value_of .created)
        local updated=$(cat $tmp_res | value_of .updated)
        local deleted=$(cat $tmp_res | value_of .deleted)
        local batches=$(cat $tmp_res | value_of .batches)
        update_job_info $total $created $updated $deleted $batches $running_time
      fi
    fi
  fi
}

reindex_by_query() {
  local dir=$config_reindex_dir
  local reindex_file=$1
  local queries_file=$2
  local num=$(jq '. | length' $dir/$queries_file.json)
  for (( i=0; i<$num; i++)) ; do
    reindex "$(cat $dir/$reindex_file.json | \
      jq --argfile q $dir/$queries_file.json \
         --arg i $i '.source.query = $q[$i|tonumber]')"
  done
}

init_app

choice=
options=(
  "cat"
  "run"
  "tasks"
  "report"
  "config"
)

while true
do
  menubox "Main Menu" "Select a function:" "choice" "${options[@]}"

  [[ $? != 0 ]] && exit

  case $choice in
    "cat") cat_query ;;
    "run") run ;;
    "tasks") tasks "*reindex" ;;
    "report") report $reindex_wait_for_completion ;;
    "config") config "net" "reindex" ;;
  esac
done
