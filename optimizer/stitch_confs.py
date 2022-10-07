#!/usr/bin/env python3

import sys
from pathlib import Path


def main():
  dse_data = sys.argv[1]
  election_data = sys.argv[2]

  election_data_lines = Path(election_data).read_text().splitlines()
  election_data_lines = list(filter(lambda l: "build" in l or '-mant=' in l, election_data_lines))
  election_data_dict = dict(zip([l[6:-4] for l in election_data_lines[0::2]], [l[10:] for l in election_data_lines[1::2]]))
  #print(election_data_lines)

  dse_data_lines = Path(dse_data).read_text().splitlines()

  for benchname, commandline in election_data_dict.items():
    index = dse_data_lines.index(commandline)
    the_line = next(l for l in dse_data_lines[index:] if benchname in l)
    print(the_line, commandline)
    pass


if __name__ == '__main__':
  main()

