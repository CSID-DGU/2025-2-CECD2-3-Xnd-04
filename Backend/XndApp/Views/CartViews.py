# views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.shortcuts import get_object_or_404

from XndApp.Models.user import User
from XndApp.Models.ingredients import Ingredient
from XndApp.Models.cart import Cart
from XndApp.Models.recipes import Recipes
from XndApp.serializers.cart_serializers import CartSerializer, CartDetailSerializer


class CartListView(APIView):
    """
    사용자의 카트 목록을 조회하는 API
    """

    def get(self, request):
        try:
            # 현재 로그인한 사용자의 카트 아이템 조회
            user = request.user.user_id

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
                    'error': '접근 오류',
                    'message': str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class CartManageView(APIView):
    """
    카트에 식재료 추가 및 수량 관리 API
    """
    # user_id = request.user.user_id  # 이 줄 삭제!

    """ 장바구니 아이템 추가 (레시피 상세 뷰 → 장바구니) """

    def post(self, request):
        try:
            user_id = request.user.user_id
            ingredient_id = request.data.get('ingredient_id')
            recipe_id = request.data.get('recipe_id')
            quantity = request.data.get('quantity', '1')

            if not ingredient_id:
                return Response({"error": "식재료 ID가 필요합니다."}, status=status.HTTP_400_BAD_REQUEST)

            ingredient = get_object_or_404(Ingredient, id=ingredient_id)
            recipe = None
            if recipe_id:
                recipe = get_object_or_404(Recipes, recipe_id=recipe_id)

            # 이미 카트에 있는지 확인 (user, ingredient, recipe 조합으로)
            cart_item, created = Cart.objects.get_or_create(
                user_id=user_id,
                ingredient=ingredient,
                recipe=recipe,
                defaults={
                    'quantity': quantity
                }
            )

            # 이미 있었다면 기존 것 유지 (중복 방지)
            if not created:
                return Response({
                    "message": "이미 장바구니에 추가된 재료입니다.",
                    "data": CartSerializer(cart_item).data
                }, status=status.HTTP_200_OK)

            serializer = CartSerializer(cart_item)
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        except Exception as e:
            return Response(
                {
                    'error': '접근 오류',
                    'message': str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    """ 장바구니 아이템의 수량 변경 (장바구니 페이지에서 +-클릭시) """

    def patch(self, request, cart_id):
        try:
            user_id = request.user.user_id  # 수정

            cart_item = get_object_or_404(Cart, id=cart_id, user=user_id)  # 수정

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
                    'error': '접근 오류',
                    'message': str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    """ 장바구니에서 아이템 제거 (장바구니 페이지에서 X 클릭시) """

    def delete(self, request, cart_id):
        try:
            user_id = request.user.user_id

            cart_item = get_object_or_404(Cart, id=cart_id, user=user_id)
            cart_item.delete()
            return Response({"message": "장바구니에서 삭제되었습니다."}, status=status.HTTP_200_OK)

        except Exception as e:
            return Response(
                {
                    'error': '접근 오류',
                    'message': str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class CartBulkDeleteView(APIView):
    """
    장바구니 선택 삭제 및 전체 삭제 API
    """

    def post(self, request):
        """선택한 아이템들 삭제"""
        try:
            user_id = request.user.user_id
            cart_ids = request.data.get('cart_ids', [])

            if not cart_ids:
                return Response({"error": "삭제할 아이템을 선택해주세요."}, status=status.HTTP_400_BAD_REQUEST)

            # 사용자의 장바구니 아이템만 삭제
            deleted_count = Cart.objects.filter(
                id__in=cart_ids,
                user_id=user_id
            ).delete()[0]

            return Response({
                "message": f"{deleted_count}개의 아이템이 삭제되었습니다.",
                "deleted_count": deleted_count
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response(
                {
                    'error': '접근 오류',
                    'message': str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def delete(self, request):
        """전체 삭제"""
        try:
            user_id = request.user.user_id

            # 해당 사용자의 모든 장바구니 아이템 삭제
            deleted_count = Cart.objects.filter(user_id=user_id).delete()[0]

            return Response({
                "message": "장바구니가 비워졌습니다.",
                "deleted_count": deleted_count
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response(
                {
                    'error': '접근 오류',
                    'message': str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )