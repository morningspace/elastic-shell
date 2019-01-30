#!/bin/bash

app_args=("$@")
dryrun=()

on_init() {
  if array_contains app_args "--help" ; then
    local file=$(echo $app_cmd | tr '[:upper:]' '[:lower:]')
    cat $app_home/help/$file.txt
    exit
  fi

  if array_contains app_args "--dry-run" || ! exists 'curl' ; then
    if [[ -f $config_dir/dryrun.properties ]] ; then
      local OLDIFS=$IFS
      IFS=$'\r\n'
      dryrun=($(<$config_dir/dryrun.properties))
      echo 0 > $tmp_dryrun
      IFS=$OLDIFS
    fi

    curl() {
      local args=("$@")

      local pos=$(array_find args "--output")
      if (( pos >= 0 )) ; then
        (( pos+=2 )) ; echo "(dry run...)" > ${!pos}
      fi

      local res="(dry run...)"
      if [[ "$@" =~ (http[s]?[^ ]*) ]] ; then
        local url=${BASH_REMATCH[1]}
        local dryrun_pos=$(cat $tmp_dryrun) run
        while (( dryrun_pos < ${#dryrun[@]} )) ; do
          run=(${dryrun[$dryrun_pos]})
          [[ $run =~ ^# ]] && (( ++dryrun_pos )) && continue
          [[ ${run[0]} == $url ]] && (( ++dryrun_pos )) && res=${run[@]:1}
          break
        done
        echo $dryrun_pos > $tmp_dryrun
      fi
      echo $res
    }
  fi

  log_app_start
}

on_exit() {
  log_app_stop
}

to_input() {
  if [[ $1 == --* ]] ; then
    echo ${1#*--} | tr '-' ' '
  else
    echo $1
  fi
}

array_contains() { 
  local arr="$1[@]"
  local in=1
  for el in "${!arr}" ; do
    [[ $el == $2 ]] && in=0 && break
  done
  return $in
}

array_find() {
  local arr="$1[@]"
  local pos=0
  for el in "${!arr}" ; do
    [[ $el == $2 || $el == $3 ]] && echo $pos && return
    (( pos++ ))
  done
  echo -1
}

msgbox() {
  local title=$(echo $1 | tr '[:upper:]' '[:lower:]')
  local message=$(echo $2 | tr '[:upper:]' '[:lower:]')
  (
  case $title in
    "error") error "$message" ;;
    "warn") warn "$message" ;;
    "info") info "$message" ;;
    *) echo $title: $message ;;
  esac
  ) | tee >(log)
}

textbox() {
  (
  echo
  local title=$1
  echo $title
  echo ------------------------------------------------------------------------------
  local lines=1
  while IFS= read -r line || [[ -n $line ]] ; do
    (( $lines > $MAX_LINES )) && echo "(trancated...)" && break
    echo "$line"
    (( ++lines ))
  done
  ) | tee >(log)
}

programbox() {
  echo
  echo "Progress"
  echo ------------------------------------------------------------------------------
  cat
}

state_progress() {
  if [[ -z $1 ]] ; then
    echo -n "."
  else
    state=$1

    [[ ! $state =~ ^start_ ]] && echo "[done]"
    [[ $state =~ _end$ ]] && echo "$(date) $2" || echo -n "$(date) $2"
  fi
}
