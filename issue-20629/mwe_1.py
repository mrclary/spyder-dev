import os
import subprocess as sp
import time

pid = os.fork()
if pid == 0:
    print("calling Popen")
    p = sp.Popen(["python", "testchild.py"]) # hangs here
    print("after Popen call")
    time.sleep(10000)
else:
    time.sleep(10000)
