#!/bin/bash

app_cmd="Index"
#app_home=${app_home:-$(dirname `pwd`)}
app_home=${app_home:-$(dirname $(cd "$(dirname "$0")" && pwd))}
bin_dir=$app_home/bin

[ -f $bin_dir/common/base.sh ] && . $bin_dir/common/base.sh

config_index_dir="$config_dir/index"

test_index() {
  net_head $1 --write-out %{http_code} --silent --output /dev/null
}

create() {
  while true ; do
    select_dir $config_index_dir "Index" "$index_name"

    [[ $? != 0 ]] && return 255

    local index=$selected_dir
    select_file $config_index_dir/$index "Index Request" "index" --allow-none

    [[ $? != 0 ]] && return 255

    local index_req={}
    if [[ $selected_file != none ]] ; then
      index_req="@$config_index_dir/$index/$selected_file.json"
    fi

    # local res_code=$(test_index $index)
    # if [[ $res_code == 404 ]] ; then
      net_put $index --data "$index_req" --silent | to_json | textbox "Create $index"
    # elif [[ $res_code == 200 ]] ; then
    #   msgbox "Error" "Index $index has already existed!"
    # else
    #   msgbox "Error" "$res_code"
    # fi
  done
}

bulk() {
  while true ; do
    select_dir $config_index_dir "Index" "$index_name"

    [[ $? != 0 ]] && return 255

    local dir=$config_index_dir/$selected_dir
    while true ; do
      select_file $dir "Bulk Request" "bulk"

      [[ $? != 0 ]] && break

      net_post "_bulk" --header "Content-Type: application/x-ndjson" \
        --data-binary "@$dir/$selected_file.json" --output $tmp_res | programbox

      [[ $(cat $tmp_ret) == 0 ]] && cat $tmp_res | to_json | textbox "Bulk to $selected_dir"
    done
  done
}

doc_api() {
  while true ; do
    select_dir $config_index_dir "Index" "$index_name"

    [[ $? != 0 ]] && return 255

    local index=$selected_dir doc_type
    inputbox "Document Type" "Input a document type" "doc_type"

    [[ $? != 0 ]] && return 255

    if [[ -z $doc_type ]] ; then 
      msgbox "Error" "Document type is required!"
    else
      case $1 in
      "add")
        local index=$selected_dir
        local dir=$config_index_dir/$index
        while true ; do
          select_file $dir "Document" "doc"

          [[ $? != 0 ]] && break

          net_post "$index/$doc_type" \
            --data "@$dir/$selected_file.json" --silent | \
            to_json | textbox "Add $selected_file"
        done ;;
      esac
    fi
  done
}

doc() {
  local choice
  local options=(
    "add"
  )

  while true ; do
    menubox "Doc" "Select a function:" "choice" "${options[@]}"

    [[ $? != 0 ]] && return 255

    case $choice in
      "add") doc_api add ;;
    esac
  done
}

update_settings() {
  while true ; do
    select_dir $config_index_dir "Index" "$index_name"

    [[ $? != 0 ]] && return 255

    local index=$selected_dir
    select_file $config_index_dir/$index "Index Settings" "settings"

    [[ $? != 0 ]] && return 255

    local settings_req=$(cat $config_index_dir/$index/$selected_file.json | \
      sed -e "s/@@index_number_of_replicas/$index_number_of_replicas/g" | \
      sed -e "s/@@index_refresh_interval/$index_refresh_interval/g")

    echo $settings_req | to_json | log

    net_put "$index/_settings" --data "$settings_req" --silent | \
      to_json | textbox "Update $index Settings"
  done
}

update() {
  local choice
  local options=(
    "settings"
  )

  while true ; do
    menubox "Update" "Select a function:" "choice" "${options[@]}"

    [[ $? != 0 ]] && return 255

    case $choice in
      "settings") update_settings add ;;
    esac
  done
}

delete() {
  while true ; do
    select_dir $config_index_dir "Index" "$index_name"

    [[ $? != 0 ]] && return 255

    local index=$selected_dir
    net_del $index --silent | to_json | textbox "Delete $index"
  done
}

search() {
  while true ; do
    select_dir $config_index_dir "Index" "$index_name"

    [[ $? != 0 ]] && return 255

    local index=$selected_dir
    local dir=$config_index_dir/$index
    select_file $config_index_dir/$index "Search Request" "search"

    [[ $? != 0 ]] && return 255

    local search_req="@$dir/$selected_file.json"

    net_post "$index/_search" --data "$search_req" --silent | \
      to_json | textbox "The Search Results"
  done
}

alias_api() {
  case $1 in
    "list")
      net_get "_aliases" --silent | to_json | textbox "List Alias" ;;
    "add"|"delete")
      while true ; do
        select_dir $config_index_dir "Index" "$index_name"

        [[ $? != 0 ]] && return 255

        local index=$selected_dir
        local alias_name

        inputbox "Alias Name" "Input alias name" "alias_name"

        local op="add" title="Add Alias"
        [[ $1 == delete ]] && op="remove" && title="Delete Alias"
        net_post "_aliases" --silent --data "{
          \"actions\" : [
            { \"$op\" : { \"index\" : \"$index\", \"alias\" : \"$alias_name\" } }
          ]
        }" | to_json | textbox $title
      done ;;
  esac
}

index_alias() {
  local choice
  local options=(
    "add"
    "list"
    "delete"
  )

  while true ; do
    menubox "Alias" "Select a function:" "choice" "${options[@]}"

    [[ $? != 0 ]] && return 255

    case $choice in
      "add") alias_api add ;;
      "list") alias_api list ;;
      "delete") alias_api delete ;;
    esac
  done
}

init_app

options=(
  "cat"
  "create"
  "update"
  "delete"
  "alias"
  "doc"
  "bulk"
  "search"
  "config"
)

while true ; do
  menubox "Main Menu" "Select a function:" "choice" "${options[@]}"

  [[ $? != 0 ]] && exit

  case $choice in
    "cat") cat_query ;;
    "create") create ;;
    "update") update ;;
    "delete") delete ;;
    "alias") index_alias ;;
    "doc") doc ;;
    "bulk") bulk ;;
    "search") search ;;
    "config") config "net" "index" ;;
  esac
done
