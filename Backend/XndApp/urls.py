# XndApp/urls.py
from django.urls import path
from XndApp.Views.RecipeViews import RecipeView, RecipeDetailView
from XndApp.Views.IngredientViews import IngredientView

urlpatterns = [
    path('api/recipes/', RecipeView.as_view(), name='recipe-list'),
    path('api/recipes/<int:recipe_id>/', RecipeDetailView.as_view(), name='recipe-detail'),

    path('api/ingredients/<int:id>/', IngredientView.as_view(), name='ingredient-detail')
]