#!/bin/bash

mantissa_opts="24 16 12 8"
rm -f results-out/_all_combination.txt

i=0
for mantissa_opt_cvt in $mantissa_opts; do
  for mantissa_opt_add in $mantissa_opts; do
    for mantissa_opt_sub in $mantissa_opts; do
      for mantissa_opt_mul in $mantissa_opts; do
        for mantissa_opt_div in $mantissa_opts; do
          mant_opt="-cvt-mant=${mantissa_opt_cvt} -add-mant=${mantissa_opt_add} -sub-mant=${mantissa_opt_sub} -mul-mant=${mantissa_opt_mul} -div-mant=${mantissa_opt_div}"
          echo $mant_opt
          echo $i / $(( 4 ** 5 ))
          i=$(( i + 1 ))
          ./compile.sh $mant_opt || exit $?
          ./run.sh || exit $?
          echo '***' >> results-out/_all_combination.txt
          echo $mant_opt >> results-out/_all_combination.txt
          echo '***' >> results-out/_all_combination.txt
          ./validate.py >> results-out/_all_combination.txt || exit $?
        done
      done
    done
  done
done

