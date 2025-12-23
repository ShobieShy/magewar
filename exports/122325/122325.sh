#!/bin/sh
printf '\033c\033]0;%s\a' MagewarAI
base_path="$(dirname "$(realpath "$0")")"
"$base_path/122325.x86_64" "$@"
