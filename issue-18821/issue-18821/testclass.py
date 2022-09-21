#!/usr/bin/env python3
# -*- coding: utf-8 -*-

class TestClass(dict):
    def __setitem__(self, k, v):
        check = False
        if check:
            if k in self:
                dict.__setitem__(self, k, v)
            else:
                raise Exception(f"Key {k} not yet in dict.")
        else:
            dict.__setitem__(self, k, v)
