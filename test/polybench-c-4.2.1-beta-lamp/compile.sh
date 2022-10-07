#!/bin/bash -x

trap "trap - SIGTERM && kill -- -$$ && exit 1" SIGINT SIGTERM SIGKILL

SCRIPTPATH=$(dirname "$BASH_SOURCE")
cd "$SCRIPTPATH"

export TIMEOUT='timeout'
if [[ -z $(which $TIMEOUT) ]]; then
  export TIMEOUT='gtimeout'
fi
if [[ ! ( -z $(which $TIMEOUT) ) ]]; then
  export TIMEOUT="$TIMEOUT 120"
else
  printf 'warning: timeout command not found\n'
  export TIMEOUT=''
fi

if [[ -z $LLVM_DIR ]]; then
  echo -e '\033[33m'"Warning"'\033[39m'" using default llvm/clang";
else
  export llvmbin="$LLVM_DIR/bin/";
  export CLANG=$llvmbin/clang
  if [[ $(uname -s) == 'Darwin' ]]; then
    export CLANG="xcrun $CLANG"
  fi
fi
if [[ -z "$OPT" ]]; then export OPT=${llvmbin}opt; fi

if [[ -z $LAMPSIM ]]; then
  echo -e '\031[33m'"Error"'\033[39m'" Set LAMPSIM to the path to LAMPSimulator.so";
fi


compile_one()
{
  benchpath=$1
  xparams=$2
  benchdir=$(dirname $benchpath)
  tmp=$(basename $benchpath)
  benchname="${tmp%.*}"
  
  $CLANG \
    -O3 \
    -o build/"$benchname"_normal \
    "$benchpath" \
    -I"$benchdir" \
    -I./utilities \
    -I./ \
    $xparams \
    -lm
  
  $CLANG \
    -O1 \
    -S -emit-llvm \
    -o build/"$benchname"_normal.ll \
    "$benchpath" \
    -I"$benchdir" \
    -I./utilities \
    -I./ \
    $xparams
  $OPT \
    -S \
    -load $LAMPSIM \
    -lampsim \
    $MANTISSA \
    -O3 \
    build/"$benchname"_normal.ll \
    -o build/"$benchname"_lamp.ll \
      2> build/${benchname}_lamp.log || return $?
  $CLANG \
    -o build/"$benchname"_lamp \
    build/"$benchname"_lamp.ll \
    -I"$benchdir" \
    -I./utilities \
    -I./ \
    $xparams \
    -O3 \
    -lm
}
export -f compile_one

compile_one_wrapper()
{
  set -x
  bench=$1
  #printf '[....] %s' "$bench"
  compile_one "$bench" \
    "-DPOLYBENCH_TIME -DPOLYBENCH_DUMP_ARRAYS -DPOLYBENCH_STACK_ARRAYS \
     -D$D_CONF -D$D_STANDARD_DATASET -D$D_DATA_TYPE"
  bpid_fc=$?
  if [[ $bpid_fc == 0 ]]; then
    bpid_fc=' ok '
  fi
  printf '[%4s] %s\n' "$bpid_fc" "$bench"
}
export -f compile_one_wrapper


export D_MINI_DATASET="MINI_DATASET"
export D_SMALL_DATASET="SMALL_DATASET"
export D_STANDARD_DATASET="MEDIUM_DATASET"
export D_LARGE_DATASET="LARGE_DATASET"
export D_EXTRALARGE_DATASET="EXTRALARGE_DATASET"
export D_DATA_TYPE='DATA_TYPE_IS_FLOAT'
export ONLY='.*'
export MANTISSA=''
export D_CONF="CONF_GOOD"

for arg; do
  case $arg in
    64bit)
      export D_DATA_TYPE='DATA_TYPE_IS_DOUBLE'
      ;;
    [A-Z]*_DATASET)
      export D_MINI_DATASET=$arg
      export D_SMALL_DATASET=$arg
      export D_STANDARD_DATASET=$arg
      export D_LARGE_DATASET=$arg
      export D_EXTRALARGE_DATASET=$arg
      ;;
    CONF_[A-Z]*)
      export D_CONF=$arg
      ;;
    -only=*)
      export ONLY="${arg#*=}"
      ;;
    -mantissa=* | -cvt-mant=* | -add-mant=* | -sub-mant=* | -mul-mant=* | -div-mant=*)
      export MANTISSA="$MANTISSA $arg"
      ;;
    *)
      echo Unrecognized option $arg
      exit 1
  esac
done

mkdir -p build
rm -f build.log

gen_todo_list()
{
  all_benchs=$(cat ./utilities/benchmark_list)
  skipped_all=1
  for bench in $all_benchs; do
    if [[ "$bench" =~ $ONLY ]]; then
      skipped_all=0
      echo compile_one_wrapper "$bench"
    fi
  done
  
  if [[ $skipped_all -eq 1 ]]; then
    echo 'warning: you specified to skip all tests'
  fi
}

gen_todo_list | parallel

