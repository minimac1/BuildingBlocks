#!/usr/bin/env bash
# maybe do some logic to work out path so i can move around without breaking
if [[ -f "/user.env" ]]; then
    echo "Set your user variables first in a user.env file"
    exit 1
fi

set -a
echo "Extracting config to ENV from user.env"
source user.env
set +a

script_path="scripts/commands/${1}.sh"
shift
exec "${script_path}" "${@}"
