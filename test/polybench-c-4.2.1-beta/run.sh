#!/bin/bash

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM SIGKILL

SCRIPTPATH=$(dirname "$BASH_SOURCE")
cd "$SCRIPTPATH"

export TIMEOUT='timeout'
if [[ -z $(which $TIMEOUT) ]]; then
  export TIMEOUT='gtimeout'
fi
if [[ ! ( -z $(which $TIMEOUT) ) ]]; then
  export TIMEOUT="$TIMEOUT 10"
else
  printf 'warning: timeout command not found\n'
  export TIMEOUT=''
fi

export TASKSET=""
which taskset > /dev/null
if [ $? -eq 0 ]; then
  export TASKSET="taskset -c 0 "
fi

STACKSIZE='unlimited'
if [ $(uname -s) = "Darwin" ]; then
  STACKSIZE='65532';
fi
ulimit -s $STACKSIZE


run_one()
{
  benchpath=$1
  datadir=$2
  times=$3
  benchdir=$(dirname $benchpath)
  benchname=$(basename $benchdir)
  fix_out=build/"$benchname"_lamp
  flt_out=build/"$benchname"_normal
  
  $TASKSET $flt_out 2> $datadir/$benchname.float.csv > $datadir/$benchname.float.time.txt || return $?
  for ((i=1; i<$times; i++)); do
    $TASKSET $flt_out 2> /dev/null >> $datadir/$benchname.float.time.txt || return $?
  done
  $TASKSET $fix_out 2> $datadir/$benchname.csv > $datadir/$benchname.time.txt || return $?
  for ((i=1; i<$times; i++)); do
    $TASKSET $fix_out 2> /dev/null >> $datadir/$benchname.time.txt || return $?
  done
}
export -f run_one

run_one_wrapper()
{
  bench=$1
  #printf '[....] %s' "$bench"
  run_one "$bench" ./results-out $TIMES
  bpid_fc=$?
  if [[ $bpid_fc == 0 ]]; then
    bpid_fc=' ok '
  fi
  printf '[%4s] %s\n' "$bpid_fc" "$bench"
}
export -f run_one_wrapper


export ONLY='.*'
export TIMES=1

for arg; do
  case $arg in
    --only=*)
      export ONLY="${arg#*=}"
      ;;
    --times=*)
      export TIMES=$((${arg#*=}))
      ;;
    *)
      echo Unrecognized option $arg
      exit 1
  esac
done

mkdir -p results-out

gen_todo_list()
{
  all_benchs=$(cat ./utilities/benchmark_list)
  skipped_all=1
  for bench in $all_benchs; do
    if [[ "$bench" =~ $ONLY ]]; then
      skipped_all=0
      echo run_one_wrapper "$bench"
    fi
  done

  if [[ $skipped_all -eq 1 ]]; then
    echo 'warning: you specified to skip all tests'
  fi
}

gen_todo_list | parallel

