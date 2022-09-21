#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Sep 20 15:05:37 2022

@author: rclary
"""

import turtle
import time
import random

window = turtle.Screen()
window.colormode(255)
window.title('Title')
window.bgcolor((0, 0, 0))
window.tracer(0)

x = window.window_width()
y = window.window_height()


xmin = 0 - x // 2
xmax = x // 2
ymin = 0 - y // 2
ymax = y // 2

for i in range(10000):
    tx = random.randrange(xmin, xmax)
    ty = random.randrange(ymin, ymax)
    box = turtle.Turtle()
    box.shape('square')

    r = 0
    g = 0
    b = 0
    if tx > 0:
        r = 255
    elif tx < 0:
        b = 255
    else:
        r = 125
        g = 125
        b = 125

    if ty >= 0 and ty < ymax * 0.5:
        r = r * 0.75
        g = g * 0.75
        b = b * 0.75
    elif ty < 0 and ty >= ymin * 0.5:
        r = r * 0.5
        g = g * 0.5
        b = b * 0.5
    elif ty < ymin * 0.5:
        r = r * 0.25
        g = g * 0.25
        b = b * 0.25

    r = int(r)
    g = int(g)
    b = int(b)
    box.color((r, g, b))
    box.up()
    box.goto(tx, ty)
    window.update()
    # time.sleep(0.001)
turtle.done()
turtle.bye()
