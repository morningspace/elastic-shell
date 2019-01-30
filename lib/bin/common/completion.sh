#!/bin/bash

common="--ui-text --ui-dialog --dry-run --help"

dynamic_completions() {
  local followers=255
  local first=${COMP_WORDS[1]}
  local num=${#COMP_WORDS[@]}

  for (( i=num-2 ; i>=2 ; i-- )) ; do
    local word=${COMP_WORDS[$i]}
    local processed=$(( num-i-1 ))

    case $first in
      "reindex") followers=$(reindex_word_followers $word) ;;
      "snapshot") followers=$(snapshot_word_followers $word) ;;
      "upgrade") followers=$(upgrade_word_followers $word) ;;
    esac

    [[ $followers != 255 ]] && break;
  done

  (( processed<=followers )) && echo "" || echo "${@}"
}

default_completions() {
  case $1 in
    "cat"|"indices"|"shards"|"nodes"|"...") echo "indices shards nodes ..." ;;
    "config"|"--dry-run") echo "${@:2}" ;;
    *) echo "$(dynamic_completions ${@:2})" ;;
  esac
}

index_completions() {
  local top="cat create update delete doc bulk search config"
  case $1 in
    "index") echo "$top $common" ;;
    "update") echo "settings" ;;
    "doc") echo "add" ;;
    *) echo "$(default_completions $1 $top)" ;;
  esac
}

reindex_completions() {
  local top="cat run tasks report config"
  case $1 in
    "reindex") echo "$top $common" ;;
    "tasks") echo "running completed" ;;
    *) echo "$(default_completions $1 $top)" ;;
  esac
}

reindex_word_followers() {
  case $1 in
    "run") echo 3 ;;
    "running") echo 0 ;;
    "completed") echo 1 ;;
    "report") echo 1 ;;
    *) echo 255 ;;
  esac
}

snapshot_completions() {
  local top="cat repo create list restore config"
  case $1 in
    "snapshot") echo "$top $common" ;;
    "repo") echo "new" ;;
    *) echo "$(default_completions $1 $top)" ;;
  esac
}

snapshot_word_followers() {
  case $1 in
    "new") echo 1 ;;
    "create") echo 2 ;;
    "list") echo 1 ;;
    "restore") echo 2 ;;
    *) echo 255 ;;
  esac
}

upgrade_completions() {
  local top="cat full rolling report config"
  case $1 in
    "upgrade") echo "$top $common" ;;
    *) echo "$(default_completions $1 $top)" ;;
  esac
}

upgrade_word_followers() {
  case $1 in
    "full"|"report") echo 0 ;;
    "rolling") echo 1 ;;
    *) echo 255 ;;
  esac
}

elash_completions() {
  local words="index reindex snapshot upgrade"
  local first=${COMP_WORDS[1]}
  local last=${COMP_WORDS[@]:(-1)}
  local last_but_one=${COMP_WORDS[@]:(-2)}

  case $first in
    "index") words="$(index_completions $last_but_one)" ;;
    "reindex") words="$(reindex_completions $last_but_one)" ;;
    "snapshot") words="$(snapshot_completions $last_but_one)" ;;
    "upgrade") words="$(upgrade_completions $last_but_one)" ;;
  esac

  COMPREPLY=($(compgen -W "$words" -- "$last"))
}

complete -o nosort -F elash_completions elash
