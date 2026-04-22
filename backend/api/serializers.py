from rest_framework import serializers
from django.db.models import Q
from .models import (
    NeqatUser, PasswordResetToken, SystemLog, UserActivity, 
    AdminSettings, Notification, Post, Comment, ContentFlag, Tag, UserPreference, News, UserContentInteraction, TelegramMessage, Translation
)

class NeqatUserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    # profile_photo_url = serializers.SerializerMethodField(read_only=True)
     
    class Meta:
        model = NeqatUser
        fields = ['id', 'user_name', 'email', 'first_name', 'last_name', 'profile_image', 'date_joined', 'password', 'is_superuser']
        read_only_fields = ['id', 'date_joined', 'is_superuser']
        extra_kwargs = {'password': {'write_only': True}}
        
    # def get_profile_photo_url(self, obj):
    #     if obj.profile_image:
    #         request = self.context.get('request')
    #         if request:
    #             return request.build_absolute_uri(obj.profile_image.url)
    #         return obj.profile_image.url
    #     return None

    def validate_email(self, value):
        if self.instance is None and NeqatUser.objects.filter(email=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def validate_user_name(self, value):
        if self.instance is None and NeqatUser.objects.filter(user_name=value).exists():
            raise serializers.ValidationError("A user with this username already exists.")
        return value

    def update(self, instance, validated_data):
        # Get the profile_photo from validated_data
        profile_photo = validated_data.pop('profile_photo', None)
        
        # Update other fields first
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        
        # Handle profile photo separately
        if profile_photo:
            instance.profile_photo = profile_photo
        
        instance.save()
        return instance

class SocialLoginSerializer(serializers.Serializer):
    provider = serializers.CharField(required=True)
    access_token = serializers.CharField(required=True)

class ForgotPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField()

class ResetPasswordSerializer(serializers.Serializer):
    token = serializers.CharField()
    new_password = serializers.CharField(min_length=8)

class SystemLogSerializer(serializers.ModelSerializer):
    user = NeqatUserSerializer(read_only=True)
    action_display = serializers.CharField(source='get_action_display', read_only=True)
    
    class Meta:
        model = SystemLog
        fields = ['id', 'user', 'action', 'action_display', 'details', 'timestamp', 'ip_address', 'user_agent']
        read_only_fields = fields
    
    def to_representation(self, instance):
        representation = super().to_representation(instance)
        if 'id' in representation and representation['id'] is not None:
            representation['id'] = str(representation['id'])
        return representation

class UserActivitySerializer(serializers.ModelSerializer):
    user = NeqatUserSerializer(read_only=True)
    
    class Meta:
        model = UserActivity
        fields = ['user', 'last_active', 'login_count', 'session_duration']
        read_only_fields = fields

class AdminSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = AdminSettings
        fields = ['id', 'setting_key', 'setting_value', 'description', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']

class NotificationSerializer(serializers.ModelSerializer):
    created_by = NeqatUserSerializer(read_only=True)
    notification_type_display = serializers.CharField(source='get_notification_type_display', read_only=True)
    is_expired = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = Notification
        fields = ['id', 'title', 'message', 'notification_type', 'notification_type_display', 
                 'target_users', 'is_global', 'created_at', 'expires_at', 'created_by', 'is_expired']
        read_only_fields = ['id', 'created_at', 'created_by', 'is_expired']

    def create(self, validated_data):
        user = self.context['request'].user
        validated_data['created_by'] = user
        return super().create(validated_data)

class PostSerializer(serializers.ModelSerializer):
    created_by = NeqatUserSerializer(read_only=True)
    moderated_by = NeqatUserSerializer(read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = Post
        fields = ['id', 'title', 'content', 'image', 'created_by', 'created_at', 
                 'updated_at', 'status', 'status_display', 'moderation_notes', 
                 'moderated_by', 'moderated_at']
        read_only_fields = ['id', 'created_at', 'updated_at', 'moderated_at']
        
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)

class CommentSerializer(serializers.ModelSerializer):
    created_by = serializers.SlugRelatedField(slug_field='user_name', read_only=True)
    moderated_by = serializers.SlugRelatedField(slug_field='user_name', queryset=NeqatUser.objects.all(), allow_null=True, required=False)
    news_id = serializers.CharField(write_only=True, required=False)
    telegram_message_id = serializers.CharField(write_only=True, required=False)  # New field
    parent_comment = serializers.CharField(write_only=True, required=False, allow_null=True)
    replies = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Comment
        fields = [
            'id', 'news_id', 'telegram_message_id', 'content', 'created_by', 'created_at', 'status',
            'moderation_notes', 'moderated_by', 'moderated_at', 'parent_comment', 'replies'
        ]
        read_only_fields = [
            'id', 'created_by', 'created_at', 'status', 'moderation_notes',
            'moderated_by', 'moderated_at', 'replies'
        ]

    def get_replies(self, obj):
        replies = obj.replies.filter(Q(status='PENDING') | Q(status='APPROVED')).order_by('created_at')
        return CommentSerializer(replies, many=True, context=self.context).data

    def validate(self, data):
        news_id = data.get('news_id')
        telegram_message_id = data.get('telegram_message_id')
        parent_comment_id = data.get('parent_comment')
        content = data.get('content', '')

        if not content.strip():
            raise serializers.ValidationError('Comment content cannot be empty.')

        if news_id and telegram_message_id:
            raise serializers.ValidationError('A comment cannot be linked to both a News article and a Telegram message.')

        if news_id:
            try:
                News.objects.get(id=news_id)
            except News.DoesNotExist:
                raise serializers.ValidationError(f'News article with id {news_id} does not exist.')

        if telegram_message_id:
            try:
                TelegramMessage.objects.get(id=telegram_message_id)
            except TelegramMessage.DoesNotExist:
                raise serializers.ValidationError(f'Telegram message with id {telegram_message_id} does not exist.')

        if parent_comment_id:
            try:
                parent = Comment.objects.get(id=parent_comment_id)
                # Ensure parent comment belongs to the same content
                if news_id and parent.news_id != news_id:
                    raise serializers.ValidationError('Parent comment must belong to the same news article.')
                if telegram_message_id and parent.telegram_message_id != telegram_message_id:
                    raise serializers.ValidationError('Parent comment must belong to the same Telegram message.')
            except Comment.DoesNotExist:
                raise serializers.ValidationError(f'Parent comment with id {parent_comment_id} does not exist.')

        return data

    def create(self, validated_data):
        news_id = validated_data.pop('news_id', None)
        telegram_message_id = validated_data.pop('telegram_message_id', None)
        parent_comment_id = validated_data.pop('parent_comment', None)
        validated_data['created_by'] = self.context['request'].user

        if news_id:
            validated_data['news'] = News.objects.get(id=news_id)
        if telegram_message_id:
            validated_data['telegram_message'] = TelegramMessage.objects.get(id=telegram_message_id)
        if parent_comment_id:
            validated_data['parent_comment'] = Comment.objects.get(id=parent_comment_id)

        return Comment.objects.create(**validated_data)
class ContentFlagSerializer(serializers.ModelSerializer):
    reported_by = NeqatUserSerializer(read_only=True)
    resolved_by = NeqatUserSerializer(read_only=True)
    reason_display = serializers.CharField(source='get_reason_display', read_only=True)
    
    class Meta:
        model = ContentFlag
        fields = ['id', 'content_type', 'content_id', 'reported_by', 'reason', 
                 'reason_display', 'description', 'created_at', 'resolved', 
                 'resolved_by', 'resolved_at', 'resolution_notes']
        read_only_fields = ['id', 'created_at', 'resolved_at']
        
    def create(self, validated_data):
        validated_data['reported_by'] = self.context['request'].user
        return super().create(validated_data)

class AdminPostSerializer(PostSerializer):
    class Meta(PostSerializer.Meta):
        read_only_fields = ['id', 'created_at', 'updated_at']
        
class AdminCommentSerializer(CommentSerializer):
    class Meta(CommentSerializer.Meta):
        read_only_fields = ['id', 'created_at', 'updated_at']

class TagSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tag
        fields = ['id', 'name', 'description']
        
    def to_representation(self, instance):
        representation = super().to_representation(instance)
        if 'id' in representation and representation['id'] is not None:
            representation['id'] = str(representation['id'])
        return representation

class UserPreferenceSerializer(serializers.ModelSerializer):
    tag_name = serializers.CharField(source='tag.name', read_only=True)
    
    class Meta:
        model = UserPreference
        fields = ['id', 'user', 'tag', 'tag_name', 'preference_level', 'created_at', 'updated_at']
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']
    
    def validate_preference_level(self, value):
        if value < 1 or value > 100:
            raise serializers.ValidationError("Preference level must be between 1 and 100.")
        return value

class UserPreferenceUpdateSerializer(serializers.Serializer):
    tag_id = serializers.CharField(max_length=36)
    preference_level = serializers.IntegerField(min_value=1, max_value=100)

class NewsSerializer(serializers.ModelSerializer):
    tags = TagSerializer(many=True, read_only=True)
    tag_ids = serializers.ListField(
        child=serializers.CharField(max_length=36),
        write_only=True,
        required=False
    )
    
    class Meta:
        model = News
        fields = ['id', 'title', 'content', 'tags', 'tag_ids', 'timestamp', 
                 'language', 'source', 'url', 'author', 'image_url']
        read_only_fields = ['id', 'timestamp']
    
    def create(self, validated_data):
        tag_ids = validated_data.pop('tag_ids', [])
        news = News.objects.create(**validated_data)
        if tag_ids:
            tags = Tag.objects.filter(id__in=tag_ids)
            news.tags.add(*tags)
        return news
        
    def update(self, instance, validated_data):
        tag_ids = validated_data.pop('tag_ids', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if tag_ids is not None:
            instance.tags.clear()
            tags = Tag.objects.filter(id__in=tag_ids)
            instance.tags.add(*tags)
        return instance

class UserContentInteractionSerializer(serializers.ModelSerializer):
    user = NeqatUserSerializer(read_only=True)
    interaction_type_display = serializers.CharField(source='get_interaction_type_display', read_only=True)
    
    class Meta:
        model = UserContentInteraction
        fields = ['id', 'user', 'content_type', 'content_id', 'interaction_type', 
                 'interaction_type_display', 'interaction_value', 'timestamp']
        read_only_fields = ['id', 'timestamp']
        
    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)

class UserPreferenceRecommendationSerializer(serializers.Serializer):
    content_type = serializers.CharField(required=True)
    limit = serializers.IntegerField(required=False, default=10)
    include_tags = serializers.ListField(
        child=serializers.CharField(),
        required=False
    )
    exclude_tags = serializers.ListField(
        child=serializers.CharField(),
        required=False
    )
class TelegramMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = TelegramMessage
        fields = ['id', 'sender_id', 'message', 'date', 'channel_name', 'created_at', 'updated_at', 'image_url']
        read_only_fields = ['created_at', 'updated_at', 'image_url']
        

class TranslationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Translation
        fields = ['id', 'original_text', 'translated_text', 'source_language', 'target_language', 'created_at']