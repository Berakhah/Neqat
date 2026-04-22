from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
import uuid
from datetime import timedelta
from django.utils import timezone
from django.core.exceptions import ValidationError

# Function to generate UUID strings
def generate_uuid():
    return str(uuid.uuid4())

# NeqatUserManager
class NeqatUserManager(BaseUserManager):
    def create_user(self, user_name, email, password=None, **extra_fields):
        if not user_name:
            raise ValueError('The UserName field must be set')
        if not email:
            raise ValueError('The Email field must be set')
        email = self.normalize_email(email)
        user = self.model(email=email, user_name=user_name, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, user_name, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')
        return self.create_user(user_name, email, password, **extra_fields)

# NeqatUser
class NeqatUser(AbstractBaseUser, PermissionsMixin):
    id = models.CharField(primary_key=True, max_length=100, editable=False, unique=True, default=uuid.uuid4)
    user_name = models.CharField(max_length=50, unique=True)
    first_name = models.CharField(max_length=50, null=True, blank=True)
    last_name = models.CharField(max_length=50, null=True, blank=True)
    email = models.EmailField(max_length=255, unique=True, null=True, blank=False)
    date_joined = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    profile_image = models.ImageField(upload_to='Images/ProfilePics', null=True, blank=True)

    objects = NeqatUserManager()

    USERNAME_FIELD = 'user_name'
    REQUIRED_FIELDS = ['email']
    
    class Meta:
        db_table = 'neqat_neqatuser'

    def __str__(self):
        return self.email

    def get_full_name(self):
        return f"{self.first_name or ''} {self.last_name or ''}".strip()

    def get_short_name(self):
        return self.first_name or ''

# PasswordResetToken
class PasswordResetToken(models.Model):
    user = models.ForeignKey('NeqatUser', on_delete=models.CASCADE)
    token = models.CharField(max_length=100, unique=True, default=uuid.uuid4)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()

    class Meta:
        db_table = 'neqat_passwordresettoken'

    def save(self, *args, **kwargs):
        if not self.expires_at:
            self.expires_at = timezone.now() + timedelta(hours=1)
        super().save(*args, **kwargs)

    def is_expired(self):
        return timezone.now() > self.expires_at

    def __str__(self):
        return f"Token for {self.user.email}"

# SystemLog
class SystemLog(models.Model):
    ACTION_CHOICES = (
        ('LOGIN', 'User Login'),
        ('LOGOUT', 'User Logout'),
        ('REGISTER', 'User Registration'),
        ('PASSWORD_RESET', 'Password Reset'),
        ('PROFILE_UPDATE', 'Profile Update'),
        ('ADMIN_ACTION', 'Admin Action'),
        ('ERROR', 'System Error'),
        ('SECURITY', 'Security Event'),
        ('CONTENT', 'Content Action'),
        ('TEST', 'Test Action'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey('NeqatUser', on_delete=models.SET_NULL, null=True, blank=True, related_name='system_logs')
    action = models.CharField(max_length=50, choices=ACTION_CHOICES)
    details = models.TextField(blank=True, null=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(null=True, blank=True)
    
    class Meta:
        db_table = 'neqat_systemlog'
        ordering = ['-timestamp']
        verbose_name = 'System Log'
        verbose_name_plural = 'System Logs'
    
    def save(self, *args, **kwargs):
        if not self.id:
            self.id = uuid.uuid4()
        super().save(*args, **kwargs)
        
    def __str__(self):
        user_str = self.user.user_name if self.user else 'System'
        return f"{self.get_action_display()} by {user_str} at {self.timestamp.strftime('%Y-%m-%d %H:%M:%S')}"

# UserActivity
class UserActivity(models.Model):
    user = models.ForeignKey('NeqatUser', on_delete=models.CASCADE, related_name='activities')
    last_active = models.DateTimeField(auto_now=True)
    login_count = models.PositiveIntegerField(default=0)
    session_duration = models.DurationField(default=timedelta(seconds=0))
    
    class Meta:
        db_table = 'neqat_useractivity'
        verbose_name = 'User Activity'
        verbose_name_plural = 'User Activities'
        
    def __str__(self):
        return f"Activity for {self.user.user_name}"

# AdminSettings
class AdminSettings(models.Model):
    setting_key = models.CharField(max_length=100, unique=True)
    setting_value = models.TextField()
    description = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'neqat_adminsettings'
        verbose_name = 'Admin Setting'
        verbose_name_plural = 'Admin Settings'
        
    def __str__(self):
        return self.setting_key

# Notification
class Notification(models.Model):
    NOTIFICATION_TYPES = (
        ('ANNOUNCEMENT', 'System Announcement'),
        ('USER_SPECIFIC', 'User Specific'),
        ('ALERT', 'Alert'),
        ('INFO', 'Information'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255)
    message = models.TextField()
    notification_type = models.CharField(max_length=50, choices=NOTIFICATION_TYPES)
    target_users = models.ManyToManyField('NeqatUser', blank=True, related_name='notifications')
    is_global = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    created_by = models.ForeignKey('NeqatUser', on_delete=models.SET_NULL, null=True, related_name='created_notifications')
    
    class Meta:
        db_table = 'neqat_notification'
        ordering = ['-created_at']
        
    def __str__(self):
        return self.title
        
    def is_expired(self):
        if self.expires_at:
            return timezone.now() > self.expires_at
        return False

# Content (Abstract Base Class)
class Content(models.Model):
    CONTENT_STATUS = (
        ('PENDING', 'Pending Review'),
        ('APPROVED', 'Approved'),
        ('REJECTED', 'Rejected'),
        ('FLAGGED', 'Flagged for Review'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    created_by = models.ForeignKey('NeqatUser', on_delete=models.CASCADE, related_name='%(class)s_created')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    status = models.CharField(max_length=20, choices=CONTENT_STATUS, default='PENDING')
    moderation_notes = models.TextField(null=True, blank=True)
    moderated_by = models.ForeignKey('NeqatUser', on_delete=models.SET_NULL, null=True, blank=True, related_name='%(class)s_moderated')
    moderated_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        abstract = True

# Post
class Post(Content):
    title = models.CharField(max_length=255)
    content = models.TextField()
    image = models.ImageField(upload_to='Images/Posts', null=True, blank=True)
    
    class Meta:
        db_table = 'neqat_post'
        ordering = ['-created_at']
        
    def __str__(self):
        return self.title

# Tag
class Tag(models.Model):
    id = models.CharField(max_length=36, primary_key=True, default=generate_uuid, editable=False)
    name = models.CharField(max_length=50, unique=True)
    description = models.TextField(null=True, blank=True)
    
    class Meta:
        db_table = 'neqat_tag'
        verbose_name = 'Tag'
        verbose_name_plural = 'Tags'
        
    def __str__(self):
        return self.name

# News
class News(models.Model):
    id = models.CharField(max_length=36, primary_key=True, default=generate_uuid, editable=False)
    title = models.CharField(max_length=255)
    content = models.TextField()
    tags = models.ManyToManyField('Tag', related_name='news')
    timestamp = models.DateTimeField(auto_now_add=True)
    language = models.CharField(max_length=50, default='English')
    source = models.CharField(max_length=255, null=True, blank=True)
    url = models.URLField(max_length=500, unique=True)
    author = models.CharField(max_length=255, null=True, blank=True)
    image_url = models.URLField(max_length=500, null=True, blank=True)
    
    class Meta:
        db_table = 'neqat_news'
        verbose_name = 'News Article'
        verbose_name_plural = 'News Articles'
        ordering = ['-timestamp']
        
    def __str__(self):
        return self.title

# Comment
class Comment(Content):
    post = models.ForeignKey('Post', on_delete=models.CASCADE, null=True, blank=True, related_name='comments')
    news = models.ForeignKey('News', on_delete=models.CASCADE, null=True, blank=True, related_name='comments')
    telegram_message = models.ForeignKey('TelegramMessage', on_delete=models.CASCADE, null=True, blank=True, related_name='comments')  # New field
    content = models.TextField()
    parent_comment = models.ForeignKey('self', on_delete=models.CASCADE, null=True, blank=True, related_name='replies')

    class Meta:
        db_table = 'neqat_comment'
        ordering = ['-created_at']

    def clean(self):
        # Ensure exactly one content type is linked
        content_types = [self.post, self.news, self.telegram_message]
        if sum(1 for item in content_types if item is not None) != 1:
            raise ValidationError('A comment must be linked to exactly one of Post, News, or TelegramMessage.')

    def save(self, *args, **kwargs):
        self.clean()
        super().save(*args, **kwargs)

    def __str__(self):
        if self.post:
            content_type = 'Post'
            title = self.post.title
        elif self.news:
            content_type = 'News'
            title = self.news.title
        else:
            content_type = 'TelegramMessage'
            title = self.telegram_message.message[:50]
        return f"Comment by {self.created_by.user_name} on {content_type}: {title}"
# ContentFlag
class ContentFlag(models.Model):
    FLAG_REASONS = (
        ('SPAM', 'Spam Content'),
        ('INAPPROPRIATE', 'Inappropriate Content'),
        ('OFFENSIVE', 'Offensive Content'),
        ('MISLEADING', 'Misleading Information'),
        ('COPYRIGHT', 'Copyright Violation'),
        ('OTHER', 'Other Reason'),
    )

    CONTENT_TYPES = (
        ('POST', 'Post'),
        ('COMMENT', 'Comment'),
        ('TELEGRAM', 'TelegramMessage'),  # New content type
    )

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    content_type = models.CharField(max_length=20, choices=CONTENT_TYPES)
    content_id = models.UUIDField()
    reported_by = models.ForeignKey('NeqatUser', on_delete=models.CASCADE, related_name='reported_flags')
    reason = models.CharField(max_length=20, choices=FLAG_REASONS)
    description = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    resolved = models.BooleanField(default=False)
    resolved_by = models.ForeignKey('NeqatUser', on_delete=models.SET_NULL, null=True, blank=True, related_name='resolved_flags')
    resolved_at = models.DateTimeField(null=True, blank=True)
    resolution_notes = models.TextField(null=True, blank=True)

    class Meta:
        db_table = 'neqat_contentflag'
        ordering = ['-created_at']

    def __str__(self):
        return f"Flag for {self.content_type} - Reason: {self.get_reason_display()}"
# UserPreference
class UserPreference(models.Model):
    id = models.CharField(max_length=36, primary_key=True, default=generate_uuid, editable=False)
    user = models.ForeignKey('NeqatUser', on_delete=models.CASCADE, related_name='preferences')
    tag = models.ForeignKey('Tag', on_delete=models.CASCADE, related_name='user_preferences')
    preference_level = models.IntegerField(default=50)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'neqat_userpreference'
        verbose_name = 'User Preference'
        verbose_name_plural = 'User Preferences'
        unique_together = ['user', 'tag']
        
    def __str__(self):
        return f"{self.user.user_name}'s preference for {self.tag.name}: {self.preference_level}"

# UserContentInteraction
class UserContentInteraction(models.Model):
    INTERACTION_TYPES = (
        ('VIEW', 'Viewed Content'),
        ('LIKE', 'Liked Content'),
        ('BOOKMARK', 'Bookmarked Content'),
        ('SHARE', 'Shared Content'),
        ('CLICK', 'Clicked Content'),
        ('TIME_SPENT', 'Time Spent on Content'),
    )

    CONTENT_TYPES = (
        ('NEWS', 'News'),
        ('POST', 'Post'),
        ('TELEGRAM', 'TelegramMessage'),  # New content type
    )

    id = models.CharField(max_length=36, primary_key=True, default=generate_uuid, editable=False)
    user = models.ForeignKey('NeqatUser', on_delete=models.CASCADE, related_name='content_interactions')
    content_type = models.CharField(max_length=20, choices=CONTENT_TYPES)
    content_id = models.CharField(max_length=36)
    interaction_type = models.CharField(max_length=20, choices=INTERACTION_TYPES)
    interaction_value = models.FloatField(default=1.0)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'neqat_usercontentinteraction'
        verbose_name = 'User Content Interaction'
        verbose_name_plural = 'User Content Interactions'
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.user.user_name}'s {self.get_interaction_type_display()} on {self.content_type}"
class TelegramMessage(models.Model):
    sender_id = models.CharField(max_length=255)
    message = models.TextField(
        db_collation="Latin1_General_100_CI_AS_SC_UTF8"
    )
    date = models.DateTimeField()
    channel_name = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    image_url = models.URLField(max_length=500, blank=True, null=True)  # New field for image URL
    english_text = models.TextField(null=True, blank=True)
    english_translated_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.channel_name} - {self.date}"

    class Meta:
        db_table = 'telegrammessage'
        ordering = ['-date']
    
class Translation(models.Model):
    original_text = models.TextField()
    translated_text = models.TextField()
    source_language = models.CharField(max_length=10, default='auto')
    target_language = models.CharField(max_length=10)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.original_text} -> {self.translated_text}"