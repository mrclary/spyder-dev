#!/bin/bash
set -e

mamba run --no-capture-output -p $PREFIX python $SPYREPO/install_dev_repos.py --not-editable
