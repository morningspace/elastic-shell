#!/bin/bash

script_name=${0##*/}
log_facility=local7

log() {
  local log_level=${1:-info}

  if (( $# <= 1 )) ; then
    while IFS= read -r line || [[ -n $line ]] ; do
      echo "$line"
    done | logger -p $log_facility.$log_level
  elif (( $# >= 2 )) ; then
    logger -p $log_facility.$log_level "${@:2}"
  fi
}

log_app_start() {
  log info "##################################################"
  log info "# $script_name started at $(date)"
  log info "##################################################"
}

log_app_stop() {
  log info "##################################################"
  log info "# $script_name stopped at $(date)"
  log info "##################################################"
}

info() {
  console_log info "$@"
}

warn() {
  console_log warn "$@"
}

error() {
  console_log error "$@"
}

console_log() {
  [[ $is_quiet ]] && return

  if [[ $1 == info ]] ; then
    echo "$2"
  else
    echo "$script_name: ($1) $2"
  fi
  for line in "${@:3}" ; do
    echo "$line"
  done
}
