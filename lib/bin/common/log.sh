#!/bin/bash

script_name=${0##*/}

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
  if [[ $1 == info ]] ; then
    echo "$2"
  else
    echo "$script_name: ($1) $2"
  fi
  for line in "${@:3}" ; do
    echo "$line"
  done
}
