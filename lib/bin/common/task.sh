#!/bin/bash

mkdir -p .reports .tasks

job_name=
job_state=
tasks=()

input_job_name() {
  inputbox "Job Name" "Input a job name" "job_name" $job_name

  [[ $? != 0 ]] && return 255
  [[ ! -z $job_name ]] && return 0 || (
    msgbox "Error" "The job name is required!"
    return 255
  )
}

find_job_name() {
  select_file .reports "Job" "" --allow-input

  [[ $? != 0 ]] && return 255
  [[ $selected_file == "..." ]] && input_job_name || job_name=$selected_file

  return 0
}

reset_job_info() {
  (( job_total=job_created=job_updated=job_deleted=job_batches=job_time=0 ))
}

init_job() {
  input_job_name

  [[ $? != 0 ]] && return 255

  reset_job_info

  local wait_for_completion=$1
  [[ $wait_for_completion == false ]] && cp /dev/null .tasks/$job_name

  return 0
}

update_job_info() {
  (( job_total+=$1 ))
  (( job_created+=$2 ))
  (( job_updated+=$3 ))
  (( job_deleted+=$4 ))
  (( job_batches+=$5 ))
  if [[ $@ =~ --max-time ]] ; then
    (( job_time=($6>job_time ? $6 : job_time) ))
  else
    (( job_time+=$6 ))
  fi
}

add_task_to_job() {
  local task_id=$1
  tasks+=("$task_id")
  echo $task_id >> .tasks/$job_name
}

tasks_running() {
  net_get "_tasks?detailed=true&actions=$1" --silent | \
    to_json | textbox "Running Tasks"
}

tasks_completed() {
  find_job_name

  [[ $? != 0 ]] && return 255

  load_tasks_local

  [[ $? != 0 ]] && return 255

  cp /dev/null $tmp

  for i in ${!tasks[@]} ; do
    eval "local task=(${tasks[$i]})"
    local id=${task[0]}
    local res=$(net_get ".tasks/task/$id?_source=task" --silent)
    local found=$(echo $res | value_of .found)
    if [[ $found == true ]] ; then
      echo $res | to_json >> $tmp
    else
      echo "(pending...)" >> $tmp
    fi
  done

  cat $tmp | textbox "Completed Tasks"
}

tasks() {
  local choice
  local options=(
    "running"
    "completed"
  )

  menubox "Tasks" "Select a category:" "choice" "${options[@]}"

  [[ $? != 0 ]] && return 255

  local actions=$1 # e.g. *reindex
  case $choice in
    "running") tasks_running $actions;;
    "completed") tasks_completed ;;
  esac
}

load_tasks_local() {
  if [[ -f .tasks/$job_name ]] ; then
    tasks=($(<.tasks/$job_name))
    return 0
  else
    msgbox "Error" "Task data for job '$job_name' not found!"
    return 255
  fi
}

get_tasks() {
  for i in ${!tasks[@]} ; do
    eval "local task=(${tasks[$i]})"
    local id=${task[0]}
    local state=${task[1]}
    local total=${task[2]}
    local created=${task[3]}
    local updated=${task[4]}
    local deleted=${task[5]}
    local batches=${task[6]}
    local running_time=${task[7]}
    local desc=${task[8]}

    if [[ $state != completed ]] ; then
      local res=$(net_get ".tasks/task/$id" --silent)
      local found=$(echo $res | jq .found)
      if [[ $found == true ]] ; then
        state=completed

        local status=$(echo $res | jq ._source.task.status)
        total=$(echo $status | jq .total)
        created=$(echo $status | jq .created)
        updated=$(echo $status | jq .updated)
        deleted=$(echo $status | jq .deleted)
        batches=$(echo $status | jq .batches)
        running_time=$(echo $res | jq ._source.task.running_time_in_nanos)
        desc=$(echo $res | jq ._source.task.description)
        local info="$total $created $updated $deleted $batches $running_time"
        tasks[$i]="$id $state $info $desc"
      else
        job_state=running
      fi
    fi

    if [[ $state == completed ]] ; then
      update_job_info $total $created $updated $deleted $batches $running_time --max-time
    fi

    gen_summary "${tasks[$i]}" >> $tmp
  done
}

gen_report() {
  cp /dev/null $tmp

  job_state=completed
  local wait_for_completion=$1
  if [[ $wait_for_completion == false ]] ; then
    reset_job_info
    load_tasks_local

    [[ $? != 0 ]] && return 255

    exists "jq" && get_tasks

    [[ $? != 0 ]] && return 255
  fi

  local info="$job_total $job_created $job_updated $job_deleted $job_batches $job_time"
  gen_summary "$job_name $job_state $info" >> $tmp

  local report=.reports/$job_name
  if [[ $job_state != completed ]] ; then
    mv $tmp $report.tmp
  else
    mv $tmp $report.txt
    rm -f $report.tmp
  fi
}

print_stats() {
  echo "Name       : $1"
  if [[ $2 != completed ]] ; then
    echo "(pending...)"
  else
    echo "Total      : ${3:-0}(+${4:-0}, *${5:-0}, -${6:-0})"
    echo "Batches    : ${7:-0}"
    echo "Time       : $(display_time $((${8:-0} / 1000000000)))" # in sec
  fi
}

gen_summary() {
  eval "local info=($1)"

  print_stats ${info[0]} ${info[1]} ${info[2]} ${info[3]} \
              ${info[4]} ${info[5]} ${info[6]} ${info[7]}

  if [[ ${info[0]} == $job_name ]] ; then
    echo "# of tasks : ${#tasks[@]}"
  elif [[ ! -z ${info[8]} ]] ; then
    echo "Description:"
    echo -e "${info[8]}"
  fi

  echo
}

report() {
  find_job_name

  [[ $? != 0 ]] && return 255

  local wait_for_completion=$1
  local report=.reports/$job_name
  if [[ ! -f $report.txt ]] ; then
    gen_report $wait_for_completion
  fi

  [[ $? != 0 ]] && return 255

  (
    [[ -f $report.txt ]] && cat $report.txt || cat $report.tmp
  ) | textbox "Report of Job '$job_name'"
}
