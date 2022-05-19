#!/usr/bin/env bash
CURRENT_DIR=$PWD

if [[ $# != 0 ]]; then
    echo "USAGE:  usb-list"
    exit
fi

# If cmd.exe not on PATH, go find it
CMD="cmd.exe"
[[ ! $(type -P "cmd.exe") ]] && CMD="$(wslpath 'C:\Windows\System32\cmd.exe')"

# Sometimes need to run CMD from a windows directory for it to work
cd "$(wslpath 'C:\Windows\System32')"

"$CMD" /c usbipd wsl list

cd "$CURRENT_DIR"
