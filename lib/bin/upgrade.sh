#!/bin/bash

app_cmd="Upgrade"
app_home=${app_home:-$(dirname $(cd "$(dirname "$0")" && pwd))}
bin_dir=$app_home/bin

[ -f $bin_dir/common/base.sh ] && . $bin_dir/common/base.sh

selected_host=
selected_hostname=
upgraded_hosts=
upgrade_matrix=

get_host_version() {
  local ret
  if exists "jq" ; then
    ret=$(net_get "" --silent | value_of --raw-output .version.number)
  fi
  echo ${ret:-"n/a"}
}

gen_upgrade_matrix() {
  local original_net_host=$net_host
  local hosts=(${upgrade_hosts//,/ })
  local host host_version upgraded

  upgraded_hosts=0
  upgrade_matrix=()

  for host in "${hosts[@]}" ; do
    net_host=$host
    host_version=$(get_host_version)
    case $host_version in
      "$upgrade_from_version") upgraded="no" ;;
      "$upgrade_to_version") upgraded="yes" ;;
      "n/a") upgraded="n/a" ;;
      *) upgraded="partial" ;;
    esac
    upgrade_matrix+=("$host $host_version $upgraded")
    [[ $host_version == $upgrade_to_version ]] && (( ++upgraded_hosts ))
  done

  net_host=$original_net_host
}

get_target_health() {
  gen_upgrade_matrix
  [[ $upgraded_hosts == ${#upgrade_matrix[@]} ]] && echo "green" || echo "yellow|green"
}

get_host_health() {
  local health=$(net_get "_cat/health" --silent)
  [[ $health =~ (green|yellow|red) ]] && echo ${BASH_REMATCH[1]}
}

select_host() {
  local hosts=(${upgrade_hosts//,/ }) host
  local options=() choice
  for host in "${hosts[@]}" ; do
    [[ $host =~ ^http[s]?://(.*): ]] && options+=(${BASH_REMATCH[1]})
  done

  menubox "hosts" "Select a host:" "choice" "${options[@]}"

  for host in "${hosts[@]}" ; do
    if [[ $host =~ ^http[s]?://$choice: ]] ; then
      selected_hostname=$choice
      selected_host=$host
      break;
    fi
  done
}

pick_host() {
  local hosts=(${upgrade_hosts//,/ }) host
  local blacklist=(${1//,/ })
  for host in "${hosts[@]}" ; do
    [[ ! ${blacklist[@]} =~ $host ]] && selected_host=$host && break
  done
}

set_shard_allocation() {
  local enabled
  [[ ! -z $1 ]] && enabled="\"$1\"" || enabled=null

  net_put "_cluster/settings" --silent --data "{
    \"persistent\": {
      \"cluster.routing.allocation.enable\": $enabled
    }
  }" | to_json | textbox "Set Shard Allocation"
}

perform_synced_flush() {
  [[ $upgrade_synced_flush == true ]] && \
    net_post "_flush/synced" --silent | to_json | textbox "Perform Synced Flush"
}

do_upgrade() {
  local src_version=$(get_host_version)

  set_shard_allocation "none"
  perform_synced_flush
  (
    state_progress "start_to_be_stopped" "waiting for $1 to be stopped"
    while true ; do
      state_progress

      local health=$(get_host_health)
      if [[ $state == start_to_be_stopped && ! $health =~ red|yellow|green ]] ; then
        state_progress "stopped" "waiting for $1 to be started"
      elif [[ $state == stopped && $health =~ red|yellow|green ]] ; then
        state_progress "started_end" "$1 has been restarted"
        break
      fi

      sleep 1
    done
  ) | programbox

  local dest_version=$(get_host_version)
  local target_health=$(get_target_health)

  set_shard_allocation
  (
    state_progress "start_to_be_$target_health" "waiting for $1 to be $target_health"
    while true ; do
      state_progress

      local health=$(get_host_health)
      if [[ $state == start_to_be_$target_health && $health =~ $target_health ]] ; then
        state_progress $target_health"_end" "$1 has become $health"
        break
      fi

      sleep 1
    done

    echo "$1 has been upgraded from $src_version to $dest_version"
  ) | programbox
}

full() {
  pick_host

  net_host=$selected_host
  do_upgrade "the cluster"
}

rolling() {
  select_host
  [[ $? != 0 ]] && return -1
  
  net_host=$selected_host
  do_upgrade $selected_hostname
}

report() {
  gen_upgrade_matrix
  (
  local from=$upgrade_from_version
  local to=$upgrade_to_version
    printf "%30s %10s %10s %10s %10s\n" "Host" "From" "Current" "To" "Upgraded"
    echo "------------------------------------------------------------------------------"

    for line in "${upgrade_matrix[@]}" ; do
      local s=($line)
      printf "%30s %10s %10s %10s %10s\n" ${s[0]} $from ${s[1]} $to ${s[2]}
    done

    echo "------------------------------------------------------------------------------"
    [[ $upgraded_hosts == ${#upgrade_matrix[@]} ]] && \
      echo "all nodes have been upgraded from $from to $to"
  ) | textbox "Report of Upgrades"
}

init_app

options=(
  "cat"
  "full"
  "rolling"
  "report"
  "config"
)

while true ; do
  menubox "Main Menu" "Select a function:" "choice" "${options[@]}"

  [[ $? != 0 ]] && exit

  case $choice in
    "cat") cat_query ;;
    "full") full ;;
    "rolling") rolling ;;
    "report") report ;;
    "config") config "net" "upgrade" ;;
  esac
done
