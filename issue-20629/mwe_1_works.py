import os
import subprocess as sp

pid = os.fork()
if pid == 0:
    try:
        print("I'm child with ID:", os.getpid())
        print("My parent's ID:", os.getppid())
        p = sp.run(["python", "testchild.py"])  # Does not hang
    finally:
        os._exit(0)  # Be sure to exit child process if running in interactive interpreter
else:
    os.waitpid(pid, 0)  # This will ensure parent print statements are always last
    print("I'm parent with ID:", os.getpid())
    print("My child's ID:", pid)
