import subprocess
import time


def push_pod(name, max_attempts):
    for attempt in range(0, max_attempts):
        status = subprocess.run('pod repo update && pod trunk push ' + name + '.podspec', shell=True)
        if status.returncode == 0:
            return
        time.sleep(60 * pow(2, attempt))
    raise Exception('Maximum number of attempts have been made for ' + name)


push_pod('MapboxCoreNavigation', 5)
time.sleep(60)
push_pod('MapboxNavigation', 5)
