#!/usr/bin/env bash

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

cd "$MYDIR/src"

output="$(sample-seeds.sh)"
collect-results.sh "$output"
plot-results.sh "$output"
