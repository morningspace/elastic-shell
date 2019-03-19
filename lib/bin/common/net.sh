#!/bin/bash

net_host=${net_host:-http://elasticsearch:9200}
net_use_ssl=${net_use_ssl:-false}

net_req() {
  local action=$1
  local api=$2
  shift 2

  if [[ ! $@ =~ Content-Type:* ]] ; then
    set -- "$@" --header 'Content-Type: application/json'
  fi

  if [[ $net_use_ssl == true ]] ; then
    if [[ $net_ssl_no_validate == true ]] ; then
      set -- "$@" --insecure
    fi
    if [[ ! -z $net_client_cert ]] ; then
      set -- "$@" --cert $net_client_cert
    fi
    if [[ ! -z $net_client_key ]] ; then
      set -- "$@" --key  $net_client_key
    fi
    if [[ ! -z $net_certificate ]] ; then
      set -- "$@" --cacert $net_certificate
    fi
  fi
  
  set -- "$@" --show-error

  if [[ $action == "HEAD" ]] ; then
    echo "curl $@ -I $net_host/$api 2>&1" | log
    curl "$@" -I $net_host/$api 2>&1
  else
    echo "curl $@ -X $action $net_host/$api 2>&1" | log
    curl "$@" -X $action $net_host/$api 2>&1
  fi

  echo $? >$tmp_ret
}

net_head() {
  net_req "HEAD" "$@"
}

net_post() {
  net_req "POST" "$@"
}

net_put() {
  net_req "PUT" "$@"
}

net_get() {
  net_req "GET" "$@"
}

net_del() {
  net_req "DELETE" "$@"
}
