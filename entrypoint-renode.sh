#!/usr/bin/env bash
set -euxo pipefail

# Renode sometimes fails to launch if a localization .so file is already sitting in /tmp
rm -rf /tmp/renode-* || true

#Define cleanup procedure
cleanup() {
    # Renode doesn't respond to SIGTERM, so just straight up SIGKILL it
    kill -9 ${pid}
}

#Trap SIGTERM
trap 'cleanup' SIGTERM

/opt/renode/renode --disable-xwt -e "${RENODE_SCRIPT}" &
pid=$!
wait ${pid}
