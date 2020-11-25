#!/usr/bin/env bash

NSEEDS=100

if [ -z "$HERBIE" ]; then
  echo "ERROR: environment variable HERBIE must point to herbie directory."
  exit 1
fi

# determine physical directory of this script
src="${BASH_SOURCE[0]}"
while [ -L "$src" ]; do
  dir="$(cd -P "$(dirname "$src")" && pwd)"
  src="$(readlink "$src")"
  [[ $src != /* ]] && src="$dir/$src"
done
MYDIR="$(cd -P "$(dirname "$src")" && pwd)"

# allocate space for output
tstamp="$(date "+%Y-%m-%d_%H:%M:%S")"
output="$MYDIR/../output/seed-variance/$tstamp"
mkdir -p "$output"

# sample herbie behavior
for seed in $(seq $NSEEDS); do
  seed_output="$output/$(printf "%03d" "$seed")"
  mkdir -p "$seed_output"

  racket "$HERBIE/src/herbie.rkt" report \
    --threads yes \
    --seed "$seed" \
    "$HERBIE/bench/hamming/" \
    "$seed_output"
done

# tell subsequent scripts where to find output
echo "$output"
