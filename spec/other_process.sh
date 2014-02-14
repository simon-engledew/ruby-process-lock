#!/bin/bash
#
# For testing with jruby because it doesnt have fork
# and it was a pain getting the script right from ruby system call.

file=${1:-/dev/null}
secs=${2:-0}
(
sleep ${secs} <&- >&- 2>&- &
echo $! > "$file"
echo "Background process: sleep $secs & echo $! > $file"
) &
wait
exit 0
