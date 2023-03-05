import os
import subprocess
import time

pid1 = os.fork()
if pid1 == 0:
    print("child 1")
    pid2 = os.fork() # seems to hang here
    print("child 1 post-second-fork")
    if pid2 == 0:
        print("child 2")
        os.execlp("python", "python", "testchild.py")
    else:
        time.sleep(1000)
else:
    time.sleep(10000)
