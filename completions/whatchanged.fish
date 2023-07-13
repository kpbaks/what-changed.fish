set -l C complete --command whatchanged

set -l verbs on off status

$C -n "not __fish_seen_subcommand_from $verbs" -a on -d "turn on"
$C -n "not __fish_seen_subcommand_from $verbs" -a off -d "turn off"
$C -n "not __fish_seen_subcommand_from $verbs" -a status -d "show status"
