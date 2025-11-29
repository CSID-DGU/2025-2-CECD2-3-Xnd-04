import os
import re

os.chdir(r'Frontend\lib')

# authService.dart는 이미 수정되어 있으므로 제외
files_to_fix = [
    ('Services/loadFridgeIngredientInfoService.dart', 13),
    ('Services/loadIngredientService.dart', 18),
    ('Services/loadRViewIngredientInfoService.dart', 13),
    ('Services/loadDetailRecipeService.dart', 14),
    ('Services/loadRecipeQueryService.dart', [13, 41]),
    ('Services/loadFridgeService.dart', 18),
    ('Services/loadSavedRecipeService.dart', 14),
    ('Services/loadRecipeService.dart', 15),
    ('Services/createFridgeService.dart', 14),
    ('Services/createSavedRecipeService.dart', 14),
    ('Services/cart_service.dart', [13, 49, 85, 116, 150]),
    ('Services/surveyService.dart', [12, 52]),
    ('PushService/fcmService.dart', 222),
]

for file_info in files_to_fix:
    if len(file_info) == 2:
        filepath, line_nums = file_info
    else:
        continue

    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    if not isinstance(line_nums, list):
        line_nums = [line_nums]

    for line_num in line_nums:
        idx = line_num - 1
        line = lines[idx]

        # 'http://' + HOST! 패턴을 HOST!로 변경
        if "'http://' + HOST!" in line:
            lines[idx] = line.replace("'http://' + HOST!", "HOST!")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(lines)

    print(f'Fixed: {filepath}')

print('\nAll files have been correctly fixed!')
