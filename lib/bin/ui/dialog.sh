#!/bin/bash

on_init() {
  log_app_start
  backtitle="Elastic Shell - $app_cmd"
  dialog --backtitle "$backtitle" --textbox $app_home/help/welcome.txt 21 66
}

on_exit() {
  clear
  log_app_stop
}

formbox() {
  local title=$1
  local text=$2
  local fields=("${@:3}")
  local num=${#fields[@]}
  local items=()

  for i in ${!fields[@]} ; do
    local field=(${fields[$i]})
    local value=$(eval "echo \$$field")
    items+=("$field:" $((i+1)) 1 "$value" $((i+1)) 25 35 100)
  done

  dialog --backtitle "$backtitle" --title "$title" \
    --form "$text" $((num+7)) 65 $num "${items[@]}" 2>$tmp

  [[ $? != 0 ]] && return -1

  # local inputs=($(cat $tmp))
  local inputs=()
  while IFS='' read -r line || [[ -n "$line" ]] ; do
    inputs+=("$line")
  done < $tmp
  
  for i in ${!fields[@]} ; do
    local field=(${fields[$i]})
    local value=$(eval "echo \$$field")

    eval "$field=${inputs[i]:-\"$value\"}"
    log info "User input: $field=${inputs[i]:-$value}"
  done
}

menubox() {
  local title=$1
  local text=$2
  local selected=$3
  local items=("${@:4}")
  local num=${#items[@]}
  local options=()

  for i in ${!items[@]} ; do
    options+=($i "${items[$i]}")
  done

  dialog --backtitle "$backtitle" --title "$title" --menu "$text" \
    $(($num+7)) 50 $num "${options[@]}" 2>$tmp

  [[ $? != 0 ]] && return -1

  local item=${items[$(cat $tmp)]}
  eval "$selected=\"$item\""
  log info "Available options: ${items[@]}"
  log info "User choice: $selected=$item"
}

inputbox() {
  local title=$1
  local text=$2
  local field=$3
  local value=$4

  dialog --backtitle "$backtitle" --title "$title" \
    --inputbox "$text" 8 60 "$value" 2>$tmp

  [[ $? != 0 ]] && return -1

  local input=$(cat $tmp)
  eval "$field=${input:-\"$value\"}"
  log info "User input: $field=${input:-$value}"
}

msgbox() {
  local title=$1
  local text=$2

  dialog --backtitle "$backtitle" --title "$title" --msgbox "$text" 5 60

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
  (
  local lines=1
  while IFS= read -r line || [[ -n $line ]] ; do
    (( $lines > $common_max_read_lines )) && echo "(trancated...)" && break
    echo "$line"
    (( ++lines ))
  done
  ) | tee $tmp >(log)

  dialog --backtitle "$backtitle" --title "$title" --no-mouse --textbox "$tmp" 36 126
}

programbox() {
  dialog --backtitle "$backtitle" --programbox 36 126
}

state_progress() {
  if [[ $1 ]] ; then
    state=$1

    [[ $state =~ _end$ ]] && echo "$(date) $2" || echo "$(date) $2..."
  fi
}
