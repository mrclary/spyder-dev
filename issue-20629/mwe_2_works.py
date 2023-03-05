import os
import time

pid1 = os.fork()
if pid1 == 0:
    print("child 1:", os.getpid())
    print("parent of ch1:", os.getppid())
    pid2 = os.fork()  # Does not hang
    print("child 1 post-second-fork")  # prints twice: pid1 and pid2
    if pid2 == 0:
        try:
            print("child 2:", os.getpid())
            os.execlp("python", "python", "testchild.py")  # replaces child 2 process
            # The subprocess closes fine; since it replaced the child 2 process,
            # there is no need to close child 2 here, but is still good practice
        finally:
            os._exit(0)
    else:
        time.sleep(1)
        os._exit(0)  # close child 1
else:
    time.sleep(2)
    print("parent:", os.getpid())
