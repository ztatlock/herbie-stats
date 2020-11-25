#!/usr/bin/env bash

# determine physical directory of this script
src="${BASH_SOURCE[0]}"
while [ -L "$src" ]; do
  dir="$(cd -P "$(dirname "$src")" && pwd)"
  src="$(readlink "$src")"
  [[ $src != /* ]] && src="$dir/$src"
done
MYDIR="$(cd -P "$(dirname "$src")" && pwd)"

# caller should pass path to output from sampler
cd "$1"

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

  # warn about timeouts that will be filtered out
  timeouts="$(jq '.tests | map(select(.status == "timeout"))' "$rj")"
  if [ "$timeouts" != "[]" ]; then
    echo "WARNING: filtering out timeouts in $rj"
    echo "$timeouts"
  fi

  cat "$rj" \
    | jq --argjson SEED "$seed" \
         --argjson NPTS "$npts" \
         --argjson HERBIE_ITERS "$herbie_iters" \
      '.tests | map(
         select(.status != "timeout") |
         { "test" : .name
         , "input" : .input
         , "output" : .output
         , "output_parens" : (.output | [match("[(]"; "g")] | length)
         , "avg_bits_err_input": .start
         , "avg_bits_err_output": .end
         , "avg_bits_err_improve": (.start - .end)
         , "avg_ulps_err_input": pow(2; .start)
         , "avg_ulps_err_output": pow(2; .end)
         , "avg_ulps_err_improve": (pow(2; .start) - pow(2; .end))
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
