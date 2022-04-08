#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
IPython Console Report
"""

import os
import sys

syspp   = '\t\n'.join(os.environ.get('PYTHONPATH', '').split(os.pathsep))
spypp   = '\t\n'.join(os.environ.get('SPY_PYTHONPATH', '').split(os.pathsep))
syspath = '\t\n'.join(sys.path)

print(f'PYTHONPATH =\n{syspp}')
print(f'SPY_PYTHONPATH =\n{spypp}')
print(f'sys.path =\n{syspath}')
