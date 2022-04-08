#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Test Spyder typing latency
"""

import time, keyboard
time.sleep(3)
t0 = time.time_ns()
keyboard.write('The quick brown fox ', delay=0.05)
t1 = time.time_ns()
time.sleep(1.9)
t2 = time.time_ns()
keyboard.write('jumped over the lazy dog. The quick brown fox', delay=0.05)
t3 = time.time_ns()
dt1 = (t1 - t0) / 1e6
dt2 = (t3 - t2) / 1e6
print(f'Fast = {dt1:0.0f} ms; Slow = {dt2:0.0f} ms; Slow - Fast = {dt2-dt1:0.0f} ms')
