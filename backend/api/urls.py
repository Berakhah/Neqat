from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView
from django.conf import settings
from django.conf.urls.static import static
from .views import (
    NeqatLogin, NeqatLogout, NeqatUserProfile, ForgotPasswordView, ResetPasswordView, 
    SocialLoginView, AdminUserViewSet, AdminDashboardView, NotificationViewSet,
    PostViewSet, CommentViewSet, ContentFlagViewSet, AdminPostViewSet, 
    AdminCommentViewSet, AdminContentFlagViewSet, NeqatRegister,
    SystemLogViewSet, TelegramMessageLookupView, UserActivityViewSet, TagViewSet, UserPreferenceViewSet, 
    NewsViewSet, UserContentInteractionViewSet, NewsBulkCreateView, 
    NewsListView, NewsSearchView, CommentListCreateView, TelegramMessageViewSet, TranslateTextView, TranslationDetailView
)

# Create a router for our viewsets
router = DefaultRouter()
router.register(r'admin/users', AdminUserViewSet, basename='admin-user')
router.register(r'admin/posts', AdminPostViewSet, basename='admin-post')
router.register(r'admin/comments', AdminCommentViewSet, basename='admin-comment')
router.register(r'admin/content-flags', AdminContentFlagViewSet, basename='admin-content-flag')
router.register(r'notifications', NotificationViewSet, basename='notification')
router.register(r'posts', PostViewSet, basename='post')
router.register(r'comments', CommentViewSet, basename='comment')
router.register(r'content-flags', ContentFlagViewSet, basename='content-flag')
router.register(r'tags', TagViewSet)
router.register(r'preferences', UserPreferenceViewSet, basename='preferences')
router.register(r'interactions', UserContentInteractionViewSet, basename='interactions')
router.register(r'news', NewsViewSet)
router.register(r'telegram-messages', TelegramMessageViewSet, basename='telegram-messages')

urlpatterns = [
    # Explicit path for delete_interaction
    path('api/interactions/delete_interaction/', UserContentInteractionViewSet.as_view({'delete': 'delete_interaction'}), name='delete-interaction'),
    
    # News bulk create endpoint (must be first and most specific)
    path('news/bulk/create/', NewsBulkCreateView.as_view(), name='news-bulk-create'),
    path('news/search/', NewsSearchView.as_view(), name='news-search'),
    path('', include(router.urls)),
    
    # News retrieval patterns
    path('news/', NewsListView.as_view(), name='news-list'),
    
    # Regular user routes
    path('register/', NeqatRegister.as_view(), name='register'),
    path('login/', NeqatLogin.as_view(), name='login'),
    path('user/', NeqatUserProfile.as_view(), name='user'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('logout/', NeqatLogout.as_view(), name='logout'),
    path('login/google/', SocialLoginView.as_view(), name='google-login'),
    path('login/facebook/', SocialLoginView.as_view(), name='facebook-login'),
    path('login/apple/', SocialLoginView.as_view(), name='apple-login'),
    path('forgot-password/', ForgotPasswordView.as_view(), name='forgot-password'),
    path('reset-password/<str:token>/', ResetPasswordView.as_view(), name='reset-password'),
    path('user/profile/', NeqatUserProfile.as_view(), name='user-profile'),
    
    # Admin panel routes
    path('admin/dashboard/', AdminDashboardView.as_view(), name='admin-dashboard'),
    
    # Comment related
    path('comments/', CommentListCreateView.as_view(), name='comment-list-create'),
    path('telegram-messages/lookup/', TelegramMessageLookupView.as_view(), name='telegram-message-lookup'),
    
    # Translation related
    path('translate/', TranslateTextView.as_view(), name='translate'),
    path('translations/<int:pk>/', TranslationDetailView.as_view(), name='translation-detail'),
    
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)