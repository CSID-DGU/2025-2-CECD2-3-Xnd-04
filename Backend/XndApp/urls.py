# XndApp/urls.py
from django.urls import path
from XndApp.Views.RecipeViews import RecipeView, RecipeDetailView
from XndApp.Views.loginViews import KakaoLoginView
from XndApp.Views.loginViews import NaverLoginView
from XndApp.Views.createFridgeViews import CreateFridgeView
from XndApp.Views.fridgesViews import FridgeViews
from XndApp.Views.fridgeDetailViews import FridgeDetailView
from XndApp.Views.IngredientViews import IngredientView

urlpatterns = [
    path('api/recipes/', RecipeView.as_view(), name='recipe-list'), # ?query ?keyword ?ingredient
    path('api/recipes/<int:recipe_id>/', RecipeDetailView.as_view(), name='recipe-detail'),
    path('api/ingredients/<int:id>/', IngredientView.as_view(), name='ingredient-detail'),
    path('api/auth/kakao-login/', KakaoLoginView.as_view(), name='kakao_login'),
    path('api/auth/naver-login/',NaverLoginView.as_view(),name='naver_login'),
    path('api/fridge/',FridgeViews.as_view(),name='fridges'),
    path('api/fridge/<int:fridge_id>/',FridgeDetailView.as_view(),name='fridgeDetails'),
    path('api/fridge/create/',CreateFridgeView.as_view(),name='create_fridge'),
]