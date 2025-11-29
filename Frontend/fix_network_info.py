import os
import re

# 서비스 파일들 경로
service_dir = r'c:\Users\HOME\Desktop\study\Capstone Design\Frontend\lib\Services'

# 수정할 파일 목록 (loadFridgeService.dart는 이미 수정됨)
files_to_fix = [
    'surveyService.dart',
    'cart_service.dart',
    'createSavedRecipeService.dart',
    'createFridgeService.dart',
    'loadRecipeService.dart',
    'loadSavedRecipeService.dart',
    'loadRecipeQueryService.dart',
    'loadDetailRecipeService.dart',
    'loadRViewIngredientInfoService.dart',
    'loadIngredientService.dart',
    'loadFridgeIngredientInfoService.dart',
    'updateFridgeIngredientService.dart',
    'shoppingListService.dart',
    'purchaseService.dart',
    'expenseService.dart',
    'deleteFridgeIngredientService.dart',
    'accountBookService.dart',
]

def fix_file(filepath):
    """파일에서 NetworkInfo 패턴을 buildApiUrl 사용으로 변경"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # 1. network_info_plus import 제거
    content = re.sub(
        r"import 'package:network_info_plus/network_info_plus\.dart';\n?",
        "",
        content
    )

    # 2. NetworkInfo().getWifiIP() 패턴을 buildApiUrl로 변경
    # 패턴 1: final String? ip = await NetworkInfo().getWifiIP(); 라인 제거
    content = re.sub(
        r"\s*final String\? ip = await NetworkInfo\(\)\.getWifiIP\(\);\n",
        "",
        content
    )

    # 패턴 2: (ip!.startsWith('10.0.2')) 조건문을 buildApiUrl 호출로 변경
    # 예: final String surveyURL = (ip!.startsWith('10.0.2'))
    #       ? 'http://10.0.2.2:8000/api/survey/'
    #       : HOST! + ':8000/api/survey/';
    # -> final String surveyURL = await buildApiUrl('/api/survey/');

    # 이 패턴은 매우 다양하므로, 개별적으로 처리해야 할 수도 있습니다
    # 일단 간단한 패턴 매칭 시도

    pattern = r"final String (\w+) = \(ip!\.startsWith\('10\.0\.2'\)\)\s*\?\s*'http://10\.0\.2\.2:8000(/[^']+)'\s*:\s*HOST! \+ '[^']*';"

    def replacer(match):
        var_name = match.group(1)
        path = match.group(2)
        return f"final String {var_name} = await buildApiUrl('{path}');"

    content = re.sub(pattern, replacer, content)

    # 파일이 변경되었는지 확인
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ 수정 완료: {os.path.basename(filepath)}")
        return True
    else:
        print(f"⚠️ 변경 없음: {os.path.basename(filepath)}")
        return False

# 모든 파일 처리
print("🔧 서비스 파일 수정 시작...\n")
fixed_count = 0

for filename in files_to_fix:
    filepath = os.path.join(service_dir, filename)
    if os.path.exists(filepath):
        if fix_file(filepath):
            fixed_count += 1
    else:
        print(f"❌ 파일 없음: {filename}")

print(f"\n✅ 총 {fixed_count}개 파일 수정 완료")
