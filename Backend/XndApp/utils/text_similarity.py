"""
텍스트 유사도 계산 유틸리티
한국어 텍스트 간의 의미적 유사도를 계산합니다.
"""

from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

# 한국어 임베딩 모델 로드 (전역 변수로 한 번만 로드)
_model = None

def get_embedding_model():
    """한국어 임베딩 모델 반환 (싱글톤 패턴)"""
    global _model
    if _model is None:
        try:
            # 한국어에 특화된 경량 모델 사용
            _model = SentenceTransformer('jhgan/ko-sroberta-multitask')
            print("✅ 텍스트 임베딩 모델 로드 성공")
        except Exception as e:
            print(f"⚠️ 임베딩 모델 로드 실패, 간단한 매칭으로 대체: {e}")
            _model = None
    return _model


def calculate_text_similarity(text1, text2):
    """
    두 텍스트 간의 의미적 유사도를 계산합니다.

    Args:
        text1 (str): 첫 번째 텍스트
        text2 (str): 두 번째 텍스트

    Returns:
        float: 유사도 점수 (0.0 ~ 1.0, 높을수록 유사)
    """
    if not text1 or not text2:
        return 0.0

    model = get_embedding_model()

    # 모델이 없으면 간단한 문자열 매칭으로 대체
    if model is None:
        return _simple_text_similarity(text1, text2)

    try:
        # 텍스트를 임베딩 벡터로 변환
        embeddings = model.encode([text1, text2])

        # 코사인 유사도 계산
        similarity = cosine_similarity([embeddings[0]], [embeddings[1]])[0][0]

        return float(similarity)
    except Exception as e:
        print(f"임베딩 계산 오류, 간단한 매칭 사용: {e}")
        return _simple_text_similarity(text1, text2)


def _simple_text_similarity(text1, text2):
    """간단한 문자열 매칭 (임베딩 실패 시 대체)"""
    text1 = text1.lower().strip()
    text2 = text2.lower().strip()

    if text1 == text2:
        return 1.0

    if text1 in text2 or text2 in text1:
        return 0.8

    # 공통 부분 문자열 비율
    shorter = text1 if len(text1) < len(text2) else text2
    longer = text2 if len(text1) < len(text2) else text1

    max_common = 0
    for i in range(len(shorter)):
        for j in range(i + 2, len(shorter) + 1):
            substr = shorter[i:j]
            if substr in longer:
                max_common = max(max_common, len(substr))

    if max_common > 0:
        similarity = max_common / max(len(text1), len(text2))
        return min(similarity, 0.7)

    return 0.0


def find_most_similar(target_text, candidate_texts, threshold=0.5):
    """
    target_text와 가장 유사한 candidate_texts 중 하나를 찾습니다.

    Args:
        target_text (str): 비교 대상 텍스트
        candidate_texts (list): 후보 텍스트 리스트
        threshold (float): 유사도 임계값 (기본값 0.5)

    Returns:
        tuple: (가장 유사한 텍스트, 유사도 점수) 또는 (None, 0.0)
    """
    if not target_text or not candidate_texts:
        return None, 0.0

    model = get_embedding_model()

    # 모델이 없으면 간단한 반복 방식 사용
    if model is None:
        max_similarity = 0.0
        best_match = None

        for candidate in candidate_texts:
            similarity = calculate_text_similarity(target_text, candidate)
            if similarity > max_similarity:
                max_similarity = similarity
                best_match = candidate

        if max_similarity >= threshold:
            return best_match, max_similarity
        return None, 0.0

    try:
        # 모든 텍스트를 임베딩 벡터로 변환
        target_embedding = model.encode([target_text])
        candidate_embeddings = model.encode(candidate_texts)

        # 각 후보와의 유사도 계산
        similarities = cosine_similarity(target_embedding, candidate_embeddings)[0]

        # 가장 높은 유사도와 해당 인덱스 찾기
        max_idx = np.argmax(similarities)
        max_similarity = similarities[max_idx]

        # 임계값 이상인 경우에만 반환
        if max_similarity >= threshold:
            return candidate_texts[max_idx], float(max_similarity)

        return None, 0.0
    except Exception as e:
        print(f"find_most_similar 오류: {e}")
        # 오류 발생 시 간단한 방식으로 대체
        max_similarity = 0.0
        best_match = None
        for candidate in candidate_texts:
            similarity = _simple_text_similarity(target_text, candidate)
            if similarity > max_similarity:
                max_similarity = similarity
                best_match = candidate

        if max_similarity >= threshold:
            return best_match, max_similarity
        return None, 0.0


def check_ingredient_match(ingredient_name, survey_ingredients, threshold=0.6):
    """
    레시피 재료가 사용자 선호 재료와 일치하는지 확인합니다.

    Args:
        ingredient_name (str): 레시피 재료명
        survey_ingredients (list): 사용자가 선호하는 재료 리스트
        threshold (float): 유사도 임계값 (기본값 0.6)

    Returns:
        bool: 일치 여부
    """
    if not ingredient_name or not survey_ingredients:
        return False

    # 각 선호 재료와의 유사도 계산
    for survey_ingredient in survey_ingredients:
        similarity = calculate_text_similarity(ingredient_name, survey_ingredient)
        if similarity >= threshold:
            return True

    return False


def calculate_recipe_category_match(recipe_name, recipe_steps, favorite_recipe, threshold=0.5):
    """
    레시피가 사용자가 선호하는 요리 종류와 일치하는지 확인합니다.
    레시피명과 조리 순서 텍스트를 함께 고려합니다.

    Args:
        recipe_name (str): 레시피명
        recipe_steps (str): 조리 순서 전체 텍스트
        favorite_recipe (str): 사용자가 선호하는 요리 종류
        threshold (float): 유사도 임계값

    Returns:
        bool: 일치 여부
    """
    if not favorite_recipe:
        return False

    # 레시피명과의 유사도
    name_similarity = calculate_text_similarity(recipe_name, favorite_recipe)

    # 조리 순서가 있으면 함께 고려
    if recipe_steps:
        steps_similarity = calculate_text_similarity(recipe_steps[:500], favorite_recipe)  # 텍스트 길이 제한
        # 둘 중 높은 유사도 사용
        max_similarity = max(name_similarity, steps_similarity)
    else:
        max_similarity = name_similarity

    return max_similarity >= threshold
