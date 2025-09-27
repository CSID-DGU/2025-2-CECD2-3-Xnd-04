# [API 진입 & ⑤ DB 등록] POST 요청을 처리하고, pipeline_logic.py를 호출하여 결과를 DB에 저장하는 최종 역할을 수행합니다.

from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status

# 🚨 임시 뷰 함수: 아직 로직은 없지만, URL 연결을 위해 존재해야 합니다.
@api_view(['POST'])
def handle_detection_post(request):
    """
    CV 파이프라인의 API 진입점입니다.
    현재는 연결 확인을 위해 임시로 200 OK를 반환합니다.
    """
    # TODO: 최종적으로는 pipeline_logic.process_image_pipeline을 호출해야 함

    # 💡 URL 연결 확인용 임시 응답
    return Response(
        {"message": "CV Detection API endpoint is connected (Temporary Response)."},
        status=status.HTTP_200_OK
    )