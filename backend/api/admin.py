from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html import format_html
from django.urls import path
from django.http import JsonResponse
from django.db.models import Count
from django.utils import timezone
from datetime import timedelta
from .models import NeqatUser, PasswordResetToken, SystemLog, UserActivity, AdminSettings, Notification, Tag, UserPreference, News, TelegramMessage

# Enhanced User Admin with more functionality
class NeqatUserAdmin(UserAdmin):
    list_display = ('user_name', 'email', 'first_name', 'last_name', 'date_joined', 'is_active', 'is_staff', 'profile_image_preview')
    list_filter = ('is_staff', 'is_superuser', 'is_active', 'date_joined')
    search_fields = ('user_name', 'email', 'first_name', 'last_name')
    ordering = ('-date_joined',)
    readonly_fields = ('date_joined',)
    actions = ['disable_accounts', 'enable_accounts', 'reset_password']
    
    fieldsets = (
        (None, {'fields': ('user_name', 'email', 'password')}),
        ('Personal Info', {'fields': ('first_name', 'last_name', 'profile_image')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('Important dates', {'fields': ('date_joined', 'last_login')}),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('user_name', 'email', 'password1', 'password2', 'is_staff', 'is_superuser'),
        }),
    )
    
    def profile_image_preview(self, obj):
        if obj.profile_image:
            return format_html('<img src="{}" width="50" height="50" style="border-radius: 50%;" />', obj.profile_image.url)
        return "No Image"
    profile_image_preview.short_description = 'Profile Image'
    
    def disable_accounts(self, request, queryset):
        queryset.update(is_active=False)
        self.message_user(request, f"{queryset.count()} accounts have been disabled.")
    disable_accounts.short_description = "Disable selected user accounts"
    
    def enable_accounts(self, request, queryset):
        queryset.update(is_active=True)
        self.message_user(request, f"{queryset.count()} accounts have been enabled.")
    enable_accounts.short_description = "Enable selected user accounts"
    
    def reset_password(self, request, queryset):
        count = 0
        for user in queryset:
            # Create a password reset token
            token = PasswordResetToken(user=user)
            token.save()
            count += 1
        self.message_user(request, f"Password reset initiated for {count} users. Tokens have been created.")
    reset_password.short_description = "Initiate password reset for selected users"
    
    # Add custom admin views
    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path('analytics/user-growth/', self.admin_site.admin_view(self.user_growth_view), name='user-growth-analytics'),
            path('analytics/active-users/', self.admin_site.admin_view(self.active_users_view), name='active-users-analytics'),
        ]
        return custom_urls + urls
    
    def user_growth_view(self, request):
        # Get user registration data for the last 30 days
        thirty_days_ago = timezone.now() - timedelta(days=30)
        users_by_day = (
            NeqatUser.objects.filter(date_joined__gte=thirty_days_ago)
            .extra({'date': "date(date_joined)"})
            .values('date')
            .annotate(count=Count('id'))
            .order_by('date')
        )
        
        data = {
            'labels': [item['date'] for item in users_by_day],
            'data': [item['count'] for item in users_by_day],
        }
        
        return JsonResponse(data)
    
    def active_users_view(self, request):
        # Get active users in the last 7 days
        seven_days_ago = timezone.now() - timedelta(days=7)
        active_users = (
            NeqatUser.objects.filter(last_login__gte=seven_days_ago)
            .count()
        )
        
        data = {
            'active_users_count': active_users,
            'total_users': NeqatUser.objects.count(),
        }
        
        return JsonResponse(data)

# Register Password Reset Token Model
class PasswordResetTokenAdmin(admin.ModelAdmin):
    list_display = ('user', 'created_at', 'expires_at', 'is_expired')
    list_filter = ('created_at', 'expires_at')
    search_fields = ('user__email', 'user__user_name')
    readonly_fields = ('token', 'created_at', 'expires_at')
    
    def is_expired(self, obj):
        return obj.is_expired()
    is_expired.boolean = True
    is_expired.short_description = 'Expired'

# System Logs Model Admin
class SystemLogAdmin(admin.ModelAdmin):
    list_display = ('user', 'action', 'timestamp', 'ip_address')
    list_filter = ('action', 'timestamp')
    search_fields = ('user__email', 'user__user_name', 'action', 'details')
    readonly_fields = ('user', 'action', 'details', 'timestamp', 'ip_address', 'user_agent')
    date_hierarchy = 'timestamp'
    def has_delete_permission(self, request, obj=None):
        return False
    def has_change_permission(self, request, obj=None):
        return False
    def has_add_permission(self, request):
        return False
    # Add a comment for future maintainers
    # SystemLog is append-only and must not be edited or deleted from the admin.

# User Activity Admin
class UserActivityAdmin(admin.ModelAdmin):
    list_display = ('user', 'last_active', 'login_count')
    list_filter = ('last_active',)
    search_fields = ('user__email', 'user__user_name')
    readonly_fields = ('user', 'last_active', 'login_count', 'session_duration')

# Admin Settings Admin
class AdminSettingsAdmin(admin.ModelAdmin):
    list_display = ('setting_key', 'setting_value', 'updated_at')
    search_fields = ('setting_key', 'description')
    readonly_fields = ('created_at', 'updated_at')

# Notification Admin
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('title', 'notification_type', 'is_global', 'created_at', 'is_expired', 'created_by')
    list_filter = ('notification_type', 'is_global', 'created_at')
    search_fields = ('title', 'message')
    filter_horizontal = ('target_users',)
    actions = ['mark_expired']
    
    def is_expired(self, obj):
        return obj.is_expired()
    is_expired.boolean = True
    is_expired.short_description = 'Expired'
    
    def mark_expired(self, request, queryset):
        queryset.update(expires_at=timezone.now())
        self.message_user(request, f"{queryset.count()} notifications marked as expired.")
    mark_expired.short_description = "Mark selected notifications as expired"

# Tag Admin
class TagAdmin(admin.ModelAdmin):
    list_display = ('name', 'description')
    search_fields = ('name', 'description')

# UserPreference Admin
class UserPreferenceAdmin(admin.ModelAdmin):
    list_display = ('user', 'tag', 'preference_level', 'updated_at')
    list_filter = ('tag', 'preference_level', 'updated_at')
    search_fields = ('user__user_name', 'user__email', 'tag__name')
    readonly_fields = ('created_at', 'updated_at')

# News Admin
class NewsAdmin(admin.ModelAdmin):
    list_display = ('title', 'language', 'timestamp')
    list_filter = ('language', 'timestamp')
    search_fields = ('title', 'content', 'author', 'source')
    filter_horizontal = ('tags',)
    readonly_fields = ('timestamp',)

# Telegram Message Admin
class TelegramMessageAdmin(admin.ModelAdmin):
    list_display = ('channel_name', 'sender_id', 'date', 'created_at')
    list_filter = ('channel_name', 'date', 'created_at')
    search_fields = ('channel_name', 'sender_id', 'message')
    date_hierarchy = 'date'
    readonly_fields = ('sender_id', 'message', 'date', 'channel_name', 'created_at', 'updated_at')
    
    def has_add_permission(self, request):
        return False

# Register all models with the admin site
admin.site.register(NeqatUser, NeqatUserAdmin)
admin.site.register(PasswordResetToken, PasswordResetTokenAdmin)
admin.site.register(SystemLog, SystemLogAdmin)
admin.site.register(UserActivity, UserActivityAdmin)
admin.site.register(AdminSettings, AdminSettingsAdmin)
admin.site.register(Notification, NotificationAdmin)
admin.site.register(Tag, TagAdmin)
admin.site.register(UserPreference, UserPreferenceAdmin)
admin.site.register(News, NewsAdmin)
admin.site.register(TelegramMessage, TelegramMessageAdmin)

# Customize Admin Site
admin.site.site_header = "Neqat Administration"
admin.site.site_title = "Neqat Admin Portal"
admin.site.index_title = "Welcome to Neqat Admin Panel"