#!/bin/bash

COLUMNS=1

on_init() {
  cat $app_home/help/welcome.txt
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
  for field in "${fields[@]}" ; do
    items+=("$field")
  done
  items+=("return")

  local PS3="# Choose one item:"
  select field in "${items[@]}" ; do
    if [[ ! -z $field ]] ; then
      [[ $field == "return" ]] && return -1

      local value=$(eval "echo \$$field") input
      read -r -p "$field(press Enter to use '$value'):" input

      eval "$field=${input:-\"$value\"}"
    fi
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
}

menubox() {
  local title=$1
  local text=$2
  local selected=$3
  local items=("${@:4}" "return")

  header "$title" "$text"

  local item
  local PS3="# $text"
  select item in "${items[@]}" ; do
    if [[ ! -z $item ]] ; then
      eval "$selected=\"$item\""

      [[ $item == "return" ]] && return -1 || return 0
    fi
  done
}

msgbox() {
  local title=$1
  local text=$2

  header "$title" "$text"

  case $title in
    "error") error "$text" ;;
    "warn") warn "$text" ;;
    "info") info "$text" ;;
    *) echo $title: $text ;;
  esac
}

textbox() {
  local title=$1
  header "$title"

  local lines=1
  while IFS= read -r line || [[ -n $line ]] ; do
    (( $lines > $MAX_LINES )) && echo "(trancated...)" && break
    echo "$line"
    (( ++lines ))
  done
}

programbox() {
  header "Progress"
  cat
}
