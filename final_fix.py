import os
import re

os.chdir(r'Frontend\lib\Services')

files = [f for f in os.listdir('.') if f.endswith('.dart') and f != 'authService.dart']

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()

    # 패턴 1: ${HOST}${APIURLS['...']!}' -> '${HOST}${APIURLS['...']!}';
    if '${HOST}${APIURLS[' in content and "'${HOST}${APIURLS[" not in content:
        content = content.replace('${HOST}${APIURLS[', "'${HOST}${APIURLS[")
        content = re.sub(r"!}'", r"!}';", content)

    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f'Fixed: {file}')

print('\nAll Service files fixed!')
