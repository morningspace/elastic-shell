#!/bin/bash

arg_pos=0
ignored_args=("--dry-run")

next_arg_pos() {
  while (( arg_pos < ${#app_args[@]} )) ; do
    local arg=${app_args[$arg_pos]}
    if array_contains ignored_args "$arg" ; then
      (( arg_pos++ ))
    else
      break
    fi
  done
  echo $arg_pos
}

print_options() {
  info
  [[ $# == 0 ]] && set -- "none"
  info "Options:" "${@/#/  }"
}

formbox() {
  (
  local title=$1
  echo
  echo "$title:"
  local fields=("${@:3}")
  for field in "${fields[@]}" ; do
    local value=$(eval "echo \$$field")
    echo "  $field=$value"
  done
  ) | tee >(log)
}

menubox() {
  local items=("${@:4}")

  if (( arg_pos >= ${#app_args[@]} )) ; then
    print_options "${items[@]}"
    exit
  fi

  local seleted=$3
  arg_pos=$(next_arg_pos)
  local arg=${app_args[$arg_pos]}
  local item=$(to_input "$arg")

  if array_contains items "$item" ; then
    (( arg_pos++ ))
  else
    if [[ ${items[@]} =~ "..." ]] ; then
      item="..."
    else
      error "illegal option $arg"
      print_options "${items[@]}"
      exit 1
    fi
  fi

  eval "$seleted=\"$item\""
  log info "Current arg: $arg, available options: ${items[@]}"
  log info "User choice: $seleted=$item"
}

inputbox() {
  local field=$3
  local default_value=$4
  arg_pos=$(next_arg_pos)
  local arg=${app_args[$arg_pos]}
  local input=$(to_input "$arg")
  local value=${input:-$default_value}

  ((arg_pos++))

  eval "$field=\"$value\""
  log info "User input: $field=$value"
}
