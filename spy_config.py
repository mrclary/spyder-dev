#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Write the following default configurations for Spyder on new systems
* Custom interpreter set to c2w_310 environment
* Qt5 as graphics backend
* ...

Activate the c2w_310 environment in a terminal and execute this script.

$ python spyder_config.py

"""
# ---- Imports
from configparser import ConfigParser
import os
from pathlib import Path
import sys

# ---- Define the configuration files
WINDOWS = os.name == 'nt'
MACOS = sys.platform == 'darwin'
LINUX = sys.platform.startswith('linux')

if LINUX:
    config_root = Path.home() / '.config' / 'spyder-py3' / 'config'
elif MACOS:
    config_root = Path.home() / '.spyder-py3' / 'config'
elif WINDOWS:
    config_root = Path.home() / '.spyder-py3' / 'config'

my_spyder_cfg_file = Path(__file__).parent / "spyder.ini"
spyder_cfg_file = config_root / 'spyder.ini'
# transient_cfg_file = config_root / 'transient.ini'

# ---- Load configurations
my_spyder_cfg = ConfigParser()
my_spyder_cfg.read(my_spyder_cfg_file)

spyder_cfg = ConfigParser()
if spyder_cfg_file.exists():
    spyder_cfg.read(spyder_cfg_file)
else:
    spyder_cfg_file.parent.mkdir(parents=True, exist_ok=True)

# transient_cfg_file = config_root / 'transient.ini'
# transient_cfg = ConfigParser()
# if transient_cfg_file.exists():
#     transient_cfg.read(transient_cfg_file)
# else:
#     transient_cfg_file.parent.mkdir(parents=True, exist_ok=True)

# ---- Update the configurations
spyder_cfg.update(my_spyder_cfg)
# transient_cfg.update(my_transient_cfg)

# ---- Write the configurations to files
with open(spyder_cfg_file, 'w') as f:
    spyder_cfg.write(f)

# with open(transient_cfg_file, 'w') as f:
#     transient_cfg.write(f)
