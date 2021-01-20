#!/usr/bin/env bash

set -e

# support for exporting bash environment to parallel
source $(which env_parallel.bash)
env_parallel --record-env

# determine physical directory of this script
src="${BASH_SOURCE[0]}"
while [ -L "$src" ]; do
  dir="$(cd -P "$(dirname "$src")" && pwd)"
  src="$(readlink "$src")"
  [[ $src != /* ]] && src="$dir/$src"
done
MYDIR="$(cd -P "$(dirname "$src")" && pwd)"

if [ -z "$HERBIE" ]; then
  echo "ERROR: environment variable HERBIE must point to herbie directory."
  exit 1
fi

NSEEDS=100
PARALLEL_SEEDS=3

#
#   SAMPLE SEEDS
#

# allocate space for output
tstamp="$(date "+%Y-%m-%d_%H%M")"
output="$MYDIR/output/seed-variance/$tstamp"
mkdir -p "$output"

function do_seed {
  seed="$1"

  seed_output="$output/$(printf "%03d" "$seed")"
  mkdir -p "$seed_output"

  racket "$HERBIE/src/herbie.rkt" report \
    --threads yes \
    --seed "$seed" \
    "$HERBIE/bench/hamming/" \
    "$seed_output"
}

seq $NSEEDS \
  | env_parallel \
      --env _ \
      --jobs $PARALLEL_SEEDS \
      --halt now,fail=1 \
      do_seed

## # sample herbie behavior
## for seed in $(seq $NSEEDS); do
##   seed_output="$output/$(printf "%03d" "$seed")"
##   mkdir -p "$seed_output"
##
##   racket "$HERBIE/src/herbie.rkt" report \
##     --threads yes \
##     --seed "$seed" \
##     "$HERBIE/bench/hamming/" \
##     "$seed_output"
## done

#
#   COLLECT OUTPUT
#

pushd "$output"

echo "[" > all.json
first=true

for rj in $(find . -name 'results.json' | sort); do
  if $first; then
    first=false
  else
    echo "," >> all.json
  fi

  seed="$(jq '.seed' "$rj")"
  npts="$(jq '.points' "$rj")"
  herbie_iters="$(jq '.iterations' "$rj")"

  # warn about errors and timeouts that will be filtered out

  errors="$(jq '.tests | map(select(.status == "error"))' "$rj")"
  if [ "$errors" != "[]" ]; then
    echo "WARNING: filtering out errors in $rj on seed $seed"
    echo "$errors"
    echo "$seed" >> errors.json
    echo "$errors" >> errors.json
  fi

  timeouts="$(jq '.tests | map(select(.status == "timeout"))' "$rj")"
  if [ "$timeouts" != "[]" ]; then
    echo "WARNING: filtering out timeouts in $rj on seed $seed"
    echo "$timeouts"
    echo "$seed" >> timeouts.json
    echo "$timeouts" >> timeouts.json
  fi

  cat "$rj" \
    | jq --argjson SEED "$seed" \
         --argjson NPTS "$npts" \
         --argjson HERBIE_ITERS "$herbie_iters" \
      '.tests | map(
         select(.status != "error") |
         select(.status != "timeout") |
         { "test" : .name
         , "input" : .input
         , "output" : .output
         , "output_parens" : (.output | [match("[(]"; "g")] | length)
         , "avg_bits_err_input": .start
         , "avg_bits_err_output": .end
         , "avg_bits_err_improve": (.start - .end)
         , "time_improve": .time
         , "seed": $SEED
         , "npts": $NPTS
         , "herbie_iters": $HERBIE_ITERS
         })' \
    >> all.json
done
echo "]" >> all.json

# flatten array of array of results to an array
jq 'flatten' all.json > all.json.tmp
mv all.json.tmp all.json

popd

#
#   PLOT RESULTS
#

$MYDIR/src/plot-results.sh "$output"
