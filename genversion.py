
###
### Generate a version label
###

import re
from datetime import datetime

build = 0
version_raw = "0.0.0"

date_str = datetime.today().strftime('%Y-%m-%d')

with open("src/version.asm", "r") as version_file:
    version_raw = version_file.readline()

with open("src/version.asm", "w") as version_file:
    match = re.search('v(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)(?P<tag>\-\w+){0,1}(\+(?P<build>\d+)){0,1}', version_raw)
    if match:
        major = int(match.group('major'))
        minor = int(match.group('minor'))
        patch = int(match.group('patch'))
        tag = ""
        if match.group('tag'):
            tag = match.group('tag')
        if match.group('build'):
            build = int(match.group('build'))
            version_file.write(".text \"v{}.{}.{}{}+{} ({})\"".format(major, minor, patch, tag, build+1, date_str))
        else:
            version_file.write(".text \"v{}.{}.{}{} ({})\"".format(major, minor, patch, tag, date_str))

