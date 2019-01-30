#!/bin/bash

app_args=("$@")

on_init() {
  if array_contains app_args "--help" ; then
    local file=$(echo $app_cmd | tr '[:upper:]' '[:lower:]')
    cat $app_home/help/$file.txt
    exit
  fi
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
  case $title in
    "error") error "$message" ;;
    "warn") warn "$message" ;;
    "info") info "$message" ;;
    *) echo $title: $message ;;
  esac
}

textbox() {
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
