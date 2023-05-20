#!/usr/bin/env bash

set -e

mkdir -p cadence
pushd cadence

echo $PDK_DIR
env
exit 1

if ["$PDK_DIR" != ""]; then
    # run cadence setup script
    $PDK_DIR/ncsu_basekit/cdssetup/setup.csh
else
    echo "PDK_DIR is not defined in env"
    exit 1
fi
