# views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.shortcuts import get_object_or_404

from XndApp.Models.user import User
from XndApp.Models.ingredients import Ingredient
from XndApp.Models.cart import Cart
from XndApp.serializers.cart_serializers import CartSerializer, CartDetailSerializer


class CartListView(APIView):
    """
    사용자의 카트 목록을 조회하는 API
    """
    permission_classes = [AllowAny] #테스트용
    #permission_classes = [IsAuthenticated]

    def get(self, request):

        # 현재 로그인한 사용자의 카트 아이템 조회
        # user = request.user
        try:
            user = User.users.get(user_id=111) # 테스트용
            if user.is_anonymous:
                return Response({"error": "로그인이 필요합니다."}, status=status.HTTP_401_UNAUTHORIZED)

            cart_items = Cart.objects.filter(user=user)

            # 장바구니가 비어있을 때
            if not cart_items.exists():
                return Response({
                    "items": [],
                    "message": "장바구니에 담긴 상품이 없습니다."
                })

            serializer = CartDetailSerializer(cart_items, many=True)
            return Response({
                "items": serializer.data
            })
        
        except Exception as e:
            return Response(
                {
                    'error':'접근 오류',
                    'message':str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class CartManageView(APIView):
    """
    카트에 식재료 추가 및 수량 관리 API
    """
    permission_classes = [AllowAny]

    # user=request.user,
    user = User.objects.get(user_id=111) # 테스트용

    """ 장바구니 아이템 추가 (검색 결과 → 장바구니) """
    def post(self, request):
        try:
            ingredient_id = request.data.get('ingredient_id')
            quantity = request.data.get('quantity', 1)

            if not ingredient_id:
                return Response({"error": "식재료 ID가 필요합니다."}, status=status.HTTP_400_BAD_REQUEST)

            ingredient = get_object_or_404(Ingredient, id=ingredient_id)

            # 이미 카트에 있는지 확인
            cart_item, created = Cart.objects.get_or_create(
                #user=request.user,
                user=User.users.get(user_id=111), #테스트용
                ingredient=ingredient,
                defaults={
                    'quantity': quantity
                }
            )

            # 이미 있었다면 수량만 증가
            if not created:
                cart_item.quantity += quantity
                cart_item.save()

            serializer = CartSerializer(cart_item)
            return Response(serializer.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)
        
        except Exception as e:
            return Response(
                {
                    'error':'접근 오류',
                    'message':str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    """ 장바구니 아이템의 수량 변경 (장바구니 페이지에서 +-클릭시) """
    def patch(self, request, cart_id):

        try: 
        
            cart_item = get_object_or_404(Cart, id=cart_id,
                                        # user=request.user
                                        user=User.users.get(user_id=111) #테스트용
                                        )

            action = request.data.get('action')
            if action == 'increase':
                cart_item.quantity += 1
            elif action == 'decrease':
                cart_item.quantity = max(0, cart_item.quantity - 1)
                # 수량이 0이면 카트에서 제거
                if cart_item.quantity == 0:
                    cart_item.delete()
                    return Response(status=status.HTTP_204_NO_CONTENT)

            cart_item.save()
            serializer = CartSerializer(cart_item)
            return Response(serializer.data)
        
        except Exception as e:
            return Response(
                {
                    'error':'접근 오류',
                    'message':str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    """ 장바구니에서 아이템 제거 (장바구니 페이지에서 X 클릭시) """
    def delete(self, request, cart_id):
        try:
            cart_item = get_object_or_404(Cart, id=cart_id,
                                        #user=request.user
                                        user=User.users.get(user_id=111) #테스트용
                                        )
            cart_item.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except Exception as e:
            return Response(
                {
                    'error':'접근 오류',
                    'message':str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )