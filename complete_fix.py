import os
import re

# 수정할 파일들과 패턴 정의
fixes = [
    # (file_path, line_pattern, correct_line)
    (
        r'Frontend\lib\PushService\fcmService.dart',
        '      ${HOST}api/devices/toggle/',
        "      '${HOST}api/devices/toggle/';"
    ),
    (
        r'Frontend\lib\Services\loadFridgeIngredientInfoService.dart',
        "  '${HOST}${APIURLS['loadFridge']! + '${refrigerator.id}/',",
        "  '${HOST}${APIURLS['loadFridge']!}${refrigerator.id}/';"
    ),
    (
        r'Frontend\lib\Services\loadRecipeQueryService.dart',
        "  '${HOST}${APIURLS['loadRecipe']! + '?query=${query}';",
        "  '${HOST}${APIURLS['loadRecipe']!}?query=$query';"
    ),
    (
        r'Frontend\lib\Services\loadIngredientService.dart',
        "  '${HOST}${APIURLS['loadRecipe']! + '${recipe.id}/',",
        "  '${HOST}${APIURLS['loadRecipe']!}${recipe.id}/';"
    ),
    (
        r'Frontend\lib\Services\loadDetailRecipeService.dart',
        "  '${HOST}${APIURLS['loadRecipe']! + '?ingredient=${ingredient.ingredientName}';",
        "  '${HOST}${APIURLS['loadRecipe']!}?ingredient=${ingredient.ingredientName}';"
    ),
    (
        r'Frontend\lib\Services\loadRViewIngredientInfoService.dart',
        "  '${HOST}${APIURLS['loadFridge']! + '${id}/' + 'ingredients/' + '${fiid}/',",
        "  '${HOST}${APIURLS['loadFridge']!}$id/ingredients/$fiid/';"
    ),
]

# loadRecipeQueryService.dart는 두 군데 수정 필요
query_service_fixes = [
    ("  '${HOST}${APIURLS['loadRecipe']! + '?query=${query}';", "  '${HOST}${APIURLS['loadRecipe']!}?query=$query';"),
    ("  '${HOST}${APIURLS['loadRecipe']! + '?keyword=${keyword}';", "  '${HOST}${APIURLS['loadRecipe']!}?keyword=$keyword';"),
]

# 각 파일 수정
for file_path, pattern, replacement in fixes:
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # 패턴을 찾아서 교체
        if pattern in content:
            content = content.replace(pattern, replacement)

            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)

            print(f'Fixed: {file_path}')
        else:
            print(f'Pattern not found in: {file_path}')

    except Exception as e:
        print(f'Error fixing {file_path}: {e}')

# loadRecipeQueryService.dart 특별 처리
query_file = r'Frontend\lib\Services\loadRecipeQueryService.dart'
try:
    with open(query_file, 'r', encoding='utf-8') as f:
        content = f.read()

    for pattern, replacement in query_service_fixes:
        if pattern in content:
            content = content.replace(pattern, replacement)

    with open(query_file, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f'Fixed (additional): {query_file}')
except Exception as e:
    print(f'Error fixing {query_file}: {e}')

print('\nAll critical errors fixed!')
