#!/bin/bash

COLUMNS=1

on_init() {
  log_app_start
  cat $app_home/help/welcome.txt
}

on_exit() {
  log_app_stop
}

header() {
  echo
  echo "##################################################"
  echo "#"
  echo "# $1"
  echo "#"
  echo "##################################################"
  [[ ! -z $2 ]] && echo "# $2"
}

formbox() {
  local title=$1
  local text=$2
  local fields=("${@:3}")

  header "$title" "$text"

  local items=()
  local field value
  for field in "${fields[@]}" ; do
    value=$(eval "echo \$$field")
    items+=("$field=$value")
  done
  items+=("return")

  local PS3="# Choose one item:"
  local item input
  while true ; do
    select item in "${items[@]}" ; do
      if [[ ! -z $item ]] ; then
        [[ $item == "return" ]] && return 255

        field=${item%=*}
        value=${item#*=}

        read -r -p "$field(press Enter to use '$value'):" input

        value=${input:-$value}
        eval "$field=$value"
        items[$((REPLY-1))]="$field=$value"
        log info "User input: $field=$value"

        break
      fi
    done
  done
}

inputbox() {
  local title=$1
  local text="# $2:"
  local field=$3
  local value=$4
  if [[ ! -z $value ]] ; then
    text="# $2(press Enter to use '$value'):"
  fi

  header "$title"

  local input
  read -r -p "$text" input

  eval "$field=${input:-\"$value\"}"
  log info "User input: $field=${input:-$value}"
}

menubox() {
  local title=$1
  local text=$2
  local selected=$3
  local items=("${@:4}" "return")

  header "$title" "$text"

  log info "Available options: ${items[@]}"

  local item
  local PS3="# $text"
  select item in "${items[@]}" ; do
    if [[ ! -z $item ]] ; then
      eval "$selected=\"$item\""
      log info "User choice: $selected=$item"

      [[ $item == "return" ]] && return 255 || return 0
    fi
  done
}

msgbox() {
  local title=$1
  local text=$2

  header "$title" "$text"

  (
  case $title in
    "error") error "$text" ;;
    "warn") warn "$text" ;;
    "info") info "$text" ;;
    *) echo $title: $text ;;
  esac
  ) | log
}

textbox() {
  local title=$1
  header "$title"
  log info "$title"

  (
  local lines=1
  while IFS= read -r line || [[ -n $line ]] ; do
    (( $lines > $common_max_read_lines )) && echo "(trancated...)" && break
    echo "$line"
    (( ++lines ))
  done
  ) | tee >(log)
}

programbox() {
  header "Progress"
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
