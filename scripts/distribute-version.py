import subprocess
import time


def push_pod(name):
    while True:
        status = subprocess.run('pod repo update && pod trunk push ' + name + '.podspec', shell=True)
        if status.returncode == 0:
            break
        time.sleep(10)


push_pod('MapboxCoreNavigation')
push_pod('MapboxNavigation')
