from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    NeqatLogin, NeqatLogout, NeqatUserProfile, ForgotPasswordView, ResetPasswordView, 
    SocialLoginView, AdminUserViewSet, AdminDashboardView, NotificationViewSet,
    PostViewSet, CommentViewSet, ContentFlagViewSet, AdminPostViewSet, 
    AdminCommentViewSet, AdminContentFlagViewSet, NeqatRegister,
    SystemLogViewSet, UserActivityViewSet, TagViewSet, UserPreferenceViewSet, 
    NewsViewSet, UserContentInteractionViewSet, NewsBulkCreateView, 
    NewsListView, NewsSearchView, CommentListCreateView, TelegramMessageViewSet,
    SocialAuthCallbackView, KeycloakTokenRefreshView, EmailVerificationView,
    proxy_image, UserPermissionsView, AdminSettingsViewSet, ModerationHistoryViewSet
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
router.register(r'admin/logs', SystemLogViewSet, basename='admin-log')
router.register(r'admin/settings', AdminSettingsViewSet, basename='admin-settings')
router.register(r'admin/moderation-history', ModerationHistoryViewSet, basename='admin-moderation-history')
router.register(r'useractivity', UserActivityViewSet, basename='user-activity')

urlpatterns = [
    # News retrieval patterns (must be first)
    path('news/bulk/', NewsBulkCreateView.as_view(), name='news-bulk-create'),
    path('news/', NewsListView.as_view(), name='news-list'),
    path('news/search/', NewsSearchView.as_view(), name='news-search'),
    # Regular user routes
    path('register/', NeqatRegister.as_view(), name='register'),
    path('login/', NeqatLogin.as_view(), name='login'),
    path('user/', NeqatUserProfile.as_view(), name='user'),
    # Token refresh endpoint - using our Keycloak implementation instead of simple-jwt
    path('token/refresh/', KeycloakTokenRefreshView.as_view(), name='token_refresh'),
    # Use the proper logout view
    path('logout/', NeqatLogout.as_view(), name='logout'),
    # path('login/google/', SocialLoginView.as_view(), name='google-login'),
    # path('login/facebook/', SocialLoginView.as_view(), name='facebook-login'),
    # path('login/apple/', SocialLoginView.as_view(), name='apple-login'),
    path('forgot-password/', ForgotPasswordView.as_view(), name='forgot-password'),
    path('reset-password/<str:token>/', ResetPasswordView.as_view(), name='reset-password'),
    path('user/profile/', NeqatUserProfile.as_view(), name='user-profile'),

    # Social login provider path must come before router includes
    path('login/<str:provider>/', SocialLoginView.as_view(), name='social-login-provider'),

    # Admin panel routes
    path('admin/logs/export/', SystemLogViewSet.as_view({'get': 'export'}), name='admin-log-export'),
    path('', include(router.urls)),
    path('admin/dashboard/', AdminDashboardView.as_view(), name='admin-dashboard'),
    #Commented out the redundant router URL inclusion
    # Router URLs (last)
    # path('', include(router.urls)),

    #Comment related
    path('comments/', CommentListCreateView.as_view(), name='comment-list-create'),

    # Authentication endpoints
    path('register/', NeqatRegister.as_view(), name='register'),
    path('login/', NeqatLogin.as_view(), name='login'),
    path('logout/', NeqatLogout.as_view(), name='logout'),
    path('forgot-password/', ForgotPasswordView.as_view(), name='forgot-password'),
    path('reset-password/', ResetPasswordView.as_view(), name='reset-password'),
    path('user/', NeqatUserProfile.as_view(), name='user'),
    
    # Social login endpoints
    path('social-login/', SocialLoginView.as_view(), name='social-login'),
    path('auth/callback/', SocialAuthCallbackView.as_view(), name='auth-callback'),
    path('verify-email/', EmailVerificationView.as_view(), name='verify-email'),

    # Proxy for external images (to bypass CORS)
    path('proxy-image/', proxy_image, name='proxy-image'),

    path('user/permissions/', UserPermissionsView.as_view(), name='user-permissions'),
]