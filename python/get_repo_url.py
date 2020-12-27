import subprocess
import re

def run():
    is_init_cmd = 'git rev-parse --git-dir'
    is_init = not not subprocess.run(is_init_cmd.split(), stdout=subprocess.PIPE).stdout

    if not is_init:
        return None

    remote_cmd = 'git config --get remote.origin.url'

    remote_url = subprocess.run(remote_cmd.split(), stdout=subprocess.PIPE).stdout.decode('utf-8').strip()

    matched = re.match('(?:git@|https:\/\/)github\.com(?::|\/)(?P<user>.*)/(?P<repo>.*)',
                      remote_url)

    if not matched:
        return None

    groups = matched.groupdict()

    return 'https://github.com/{}/{}'.format(groups['user'], groups['repo'])
