#!/usr/bin/env python3

import sys
from pathlib import Path
import numpy

def noop(*args, **kwargs): pass

debug_print=print
#debug_print=noop

class BenchmarkExecutionData:
  def __init__(self, dse_data):
    self.dse_data_lines = Path(dse_data).read_text().splitlines()

  def get_cost(self, cvt, addsub, mul, div):
    c_cvt = [1.358, 1.278, 1.278, 1.278]
    c_addsub = [(1.498+1.598)/2.0, 1.498, (1.199+1.278)/2, (1.199+1.278)/2]
    c_mul = [1.498, 1.498, 1.199, 1.199]
    c_div = [3.354, 3.115, 2.596, 2.077]
    return c_cvt[cvt]+c_addsub[addsub]+c_mul[mul]+c_div[div] + 0.0000001 * ((((3-cvt))+(3-addsub))+(3-mul))+(3-div)

  def gen_arg_str(self, cvt, addsub, mul, div):
    mant_sizes=['24', '16', '12', '8']
    return '-cvt-mant='+mant_sizes[cvt]+' -add-mant='+mant_sizes[addsub]+' -sub-mant='+mant_sizes[addsub]+' -mul-mant='+mant_sizes[mul]+' -div-mant='+mant_sizes[div]

  def get_label(self, benchmark, args, label):
    index = self.dse_data_lines.index(args)
    the_table_header = next(l for l in self.dse_data_lines[index:] if 'e_abs' in l)
    the_line = next(l for l in self.dse_data_lines[index:] if benchmark in l)
    index = the_table_header.split().index(label)+1
    return float(the_line.split()[index])

  def get_abs_err(self, benchmark, args):
    return self.get_label(benchmark, args, 'e_abs')

  def get_rel_err(self, benchmark, args):
    return self.get_label(benchmark, args, 'e_perc')


def branch_and_bound(bed: BenchmarkExecutionData, benchmark, max_abs_error, max_rel_error, max_runs=999):
  debug_print()
  debug_print('******************************* ', benchmark)
  debug_print()

  def cost(cvt, addsub, mul, div):
    abs_err = bed.get_abs_err(benchmark, bed.gen_arg_str(cvt, addsub, mul, div))
    if abs_err > max_abs_error:
      debug_print('simrun: ', cvt, addsub, mul, div, 'NOT OK abserr:', abs_err)
      return 99999.0
    rel_err = bed.get_rel_err(benchmark, bed.gen_arg_str(cvt, addsub, mul, div))
    if rel_err > max_rel_error:
      debug_print('simrun: ', cvt, addsub, mul, div, 'NOT OK relerr:', rel_err)
      return 99999.0
    res = bed.get_cost(cvt, addsub, mul, div)
    debug_print('simrun: ', cvt, addsub, mul, div, 'OK res:', res, 'abserr:', abs_err, 'relerr:', rel_err)
    return res

  def best_sol(min_sol, max_sol):
    cvt, addsub, mul, div = max(min_sol, max_sol)
    return bed.get_cost(cvt, addsub, mul, div)

  def branch(min_sol, max_sol):
    # 4D space partitioning
    a, b, c, d = min_sol
    aa, bb, cc, dd = tuple(numpy.subtract(max_sol, min_sol))
    w, x, y, z = max_sol
    if aa > 0:
      return [((0, b, c, d), (0, x, y, z)), ((1, b, c, d), (1, x, y, z)), ((2, b, c, d), (2, x, y, z)), ((3, b, c, d), (3, x, y, z))]
    elif bb > 0:
      return [((a, 0, c, d), (w, 0, y, z)), ((a, 1, c, d), (w, 1, y, z)), ((a, 2, c, d), (w, 2, y, z)), ((a, 3, c, d), (w, 3, y, z))]
    elif cc > 0:
      return [((a, b, 0, d), (w, x, 0, z)), ((a, b, 1, d), (w, x, 1, z)), ((a, b, 2, d), (w, x, 2, z)), ((a, b, 3, d), (w, x, 3, z))]
    elif dd > 0:
      return [((a, b, c, 0), (w, x, y, 0)), ((a, b, c, 1), (w, x, y, 1)), ((a, b, c, 2), (w, x, y, 2)), ((a, b, c, 3), (w, x, y, 3))]
    return None

  cur_best = (0,0,0,0)
  cur_best_cost = bed.get_cost(*cur_best)
  runs = 0
  failed_runs = 0
  cache = {}

  def visit(min_sol, max_sol):
    nonlocal cur_best, cur_best_cost, runs, failed_runs
    debug_print('visit', min_sol, max_sol)

    best_possible_cost = best_sol(min_sol, max_sol)
    if best_possible_cost > cur_best_cost:
      debug_print('visit STOP: best_possible_cost > cur_best_cost (', max(min_sol, max_sol),
                  best_possible_cost, cur_best_cost, ')')
      return False

    this_solution = tuple(numpy.floor_divide(numpy.add(min_sol, max_sol), 2.0).astype(int))
    try:
      this_cost = cache[this_solution]
    except:
      if runs >= max_runs:
        debug_print('visit STOP: max run budget exceeded')
        return False
      this_cost = cost(*this_solution)
      if this_cost == 99999.0:
        failed_runs += 1
      runs += 1
      cache[this_solution] = this_cost

    if this_cost < cur_best_cost:
      debug_print('visit NEW BEST: ', this_solution, this_cost)
      cur_best = this_solution
      cur_best_cost = this_cost

    if min_sol == max_sol:
      return False
    return True

  def dfs(min_sol, max_sol):
    stack = [(min_sol, max_sol)]
    while len(stack) > 0:
      a, b = stack.pop()
      if visit(a, b):
        v = branch(a, b)
        stack += v

  def bfs(min_sol, max_sol):
    stack = [(min_sol, max_sol)]
    while len(stack) > 0:
      a, b = stack.pop(0)
      if visit(a, b):
        v = branch(a, b)
        stack += v

  dfs((0, 0, 0, 0), (3, 3, 3, 3))
  return (cur_best), runs, failed_runs


def main():
  all_benchs=[
    'correlation',
    'covariance',
    '2mm',
    '3mm',
    'atax',
    'bicg',
    'doitgen',
    'mvt',
    'gemm',
    'gemver',
    'gesummv',
    'symm',
    'syr2k',
    'syrk',
    'trmm',
    'cholesky',
    'durbin',
    'gramschmidt',
    'lu',
    'ludcmp',
    'trisolv',
    'deriche',
    'floyd-warshall',
    'nussinov',
    'adi',
    'fdtd-2d',
    'heat-3d',
    'jacobi-1d',
    'jacobi-2d',
    'seidel-2d'
  ]
  bed = BenchmarkExecutionData(sys.argv[1])
  for bench in all_benchs:
    cur_best, runs, failed_runs = branch_and_bound(bed, bench, 9999, 3.0, 999)
    print('{:>15}  failed runs: {:>3} / {:<3}  result: {}'.format(bench, failed_runs, runs, bed.gen_arg_str(*cur_best)))


if __name__ == '__main__':
  main()

