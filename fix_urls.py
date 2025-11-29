import os
import re

# Services 디렉토리
services_dir = r'Frontend\lib\Services'
os.chdir(services_dir)

files = [f for f in os.listdir('.') if f.endswith('.dart') and f != 'authService.dart']

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    fixed_lines = []
    for line in lines:
        # ${HOST}${APIURLS['...'!; 패턴 찾기
        if '${HOST}${APIURLS[' in line and not line.strip().startswith("'"):
            # : ${HOST}${... -> : '${HOST}${...
            line = line.replace(': ${HOST}${APIURLS[', ": '${HOST}${APIURLS[")
            # !; -> !}';
            line = line.replace('!;', "!}';")

        # ${HOST}api/...' 패턴 찾기
        elif '${HOST}api/' in line and ": ${HOST}api/" in line:
            line = line.replace(": ${HOST}api/", ": '${HOST}api/")

        # ${HOST}api/cart/$cartId/' 같은 패턴
        elif '${HOST}api/cart/$' in line and ": ${HOST}api/" in line:
            line = line.replace(": ${HOST}api/", ": '${HOST}api/")

        fixed_lines.append(line)

    with open(file, 'w', encoding='utf-8') as f:
        f.writelines(fixed_lines)

    print(f'Fixed: {file}')

# PushService 디렉토리
os.chdir(r'..\..\PushService')

with open('fcmService.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

fixed_lines = []
for line in lines:
    if '${HOST}api/' in line and ": ${HOST}api/" in line:
        line = line.replace(": ${HOST}api/", ": '${HOST}api/")
    fixed_lines.append(line)

with open('fcmService.dart', 'w', encoding='utf-8') as f:
    f.writelines(fixed_lines)

print('Fixed: fcmService.dart')
print('\nAll files fixed successfully!')
