from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from XndApp.Models.notification import Device
from XndApp.serializers.notification_serializers import DeviceSerializer

@api_view(['POST'])
@permission_classes([IsAuthenticated])

def register_device(request):

    print("=== DEBUG INFO ===")
    print("request.user:", request.user)
    print("request.data:", request.data)
    print("is_authenticated:", request.user.is_authenticated)

    serializer = DeviceSerializer(data=request.data)
    print("serializer.is_valid():", serializer.is_valid())
    print("serializer.errors:", serializer.errors)

    if serializer.is_valid():
        device, created = Device.objects.update_or_create(
            user=request.user,
            fcm_token=serializer.validated_data['fcm_token'],
            defaults=serializer.validated_data
        )
        return Response({'message': '기기 등록 성공'}, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
