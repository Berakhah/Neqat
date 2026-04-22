from rest_framework import serializers
from .models import (
    NeqatUser, PasswordResetToken, SystemLog, UserActivity, 
    AdminSettings, Notification, Post, Comment, ContentFlag, Tag, UserPreference, News, UserContentInteraction, TelegramMessage, ModerationHistory, AdminLog
)
import uuid

class AdminLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = AdminLog
        fields = '__all__'

class NeqatUserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    
    class Meta:
        model = NeqatUser
        fields = ['id', 'user_name', 'email', 'first_name', 'last_name', 'profile_image', 'date_joined', 'password', 'is_superuser']
        read_only_fields = ['id', 'date_joined', 'is_superuser']
        extra_kwargs = {'password': {'write_only': True}}

    def validate_email(self, value):
        if self.instance is None and NeqatUser.objects.filter(email=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def validate_user_name(self, value):
        if self.instance is None and NeqatUser.objects.filter(user_name=value).exists():
            raise serializers.ValidationError("A user with this username already exists.")
        return value

class SocialLoginSerializer(serializers.Serializer):
    provider = serializers.CharField(required=True)
    access_token = serializers.CharField(required=True)

class ForgotPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField()

class ResetPasswordSerializer(serializers.Serializer):
    token = serializers.CharField()
    new_password = serializers.CharField(min_length=8)

class UUIDStringMixin:
    def to_representation(self, instance):
        rep = super().to_representation(instance)
        for field in self.fields:
            value = rep.get(field)
            if isinstance(value, uuid.UUID):
                rep[field] = str(value)
        return rep

class SystemLogSerializer(UUIDStringMixin, serializers.ModelSerializer):
    id = serializers.UUIDField(format='hex')
    user = serializers.SerializerMethodField()
    action_display = serializers.CharField(source='get_action_display', read_only=True)
    
    class Meta:
        model = SystemLog
        fields = ['id', 'user', 'action', 'action_display', 'details', 'timestamp', 'ip_address', 'user_agent']
        read_only_fields = fields
    
    def get_user(self, obj):
        if obj.user:
            return {
                'id': str(obj.user.id),
                'user_name': obj.user.user_name,
                'email': obj.user.email,
                'first_name': obj.user.first_name,
                'last_name': obj.user.last_name,
            }
        return None

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

class PostSerializer(UUIDStringMixin, serializers.ModelSerializer):
    id = serializers.UUIDField(format='hex')
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

    def to_representation(self, instance):
        rep = super().to_representation(instance)
        if 'id' in rep and rep['id'] is not None:
            rep['id'] = str(rep['id'])
        if rep.get('created_by') and rep['created_by'].get('id'):
            rep['created_by']['id'] = str(rep['created_by']['id'])
        if rep.get('moderated_by') and rep['moderated_by'].get('id'):
            rep['moderated_by']['id'] = str(rep['moderated_by']['id'])
        return rep

class CommentSerializer(serializers.ModelSerializer):
    id = serializers.UUIDField(format='hex', read_only=True)
    created_by = serializers.SlugRelatedField(slug_field='user_name', read_only=True)
    moderated_by = serializers.SlugRelatedField(slug_field='user_name', queryset=NeqatUser.objects.all(), allow_null=True, required=False)
    news_id = serializers.CharField(write_only=True)

    class Meta:
        model = Comment
        fields = ['id', 'news_id', 'content', 'created_by', 'created_at', 'status', 'moderation_notes', 'moderated_by', 'moderated_at']
        read_only_fields = ['id', 'created_by', 'created_at', 'status', 'moderation_notes', 'moderated_by', 'moderated_at']

    def validate(self, data):
        if not data.get('news_id'):
            raise serializers.ValidationError('news_id must be provided.')
        if not data.get('content').strip():
            raise serializers.ValidationError('Comment content cannot be empty.')
        return data

    def create(self, validated_data):
        news_id = validated_data.pop('news_id')
        validated_data['created_by'] = self.context['request'].user
        try:
            validated_data['news'] = News.objects.get(id=news_id)
        except News.DoesNotExist:
            raise serializers.ValidationError(f'News article with id {news_id} does not exist.')
        return Comment.objects.create(**validated_data)

    def to_representation(self, instance):
        rep = super().to_representation(instance)
        if 'id' in rep and rep['id'] is not None:
            rep['id'] = str(rep['id'])
        return rep

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
    def to_representation(self, instance):
        rep = super().to_representation(instance)
        if 'id' in rep and rep['id'] is not None:
            rep['id'] = str(rep['id'])
        if rep.get('created_by') and rep['created_by'].get('id'):
            rep['created_by']['id'] = str(rep['created_by']['id'])
        if rep.get('moderated_by') and rep['moderated_by'].get('id'):
            rep['moderated_by']['id'] = str(rep['moderated_by']['id'])
        return rep

class AdminCommentSerializer(CommentSerializer):
    def to_representation(self, instance):
        rep = super().to_representation(instance)
        if 'id' in rep and rep['id'] is not None:
            rep['id'] = str(rep['id'])
        return rep

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
        fields = ['id', 'sender_id', 'message', 'date', 'channel_name', 'created_at', 'updated_at']
        read_only_fields = ['created_at', 'updated_at']

class ModerationHistorySerializer(serializers.ModelSerializer):
    actor = serializers.StringRelatedField()
    action_display = serializers.CharField(source='get_action_display', read_only=True)
    content_type_display = serializers.CharField(source='get_content_type_display', read_only=True)

    class Meta:
        model = ModerationHistory
        fields = [
            'id', 'content_type', 'content_type_display', 'content_id', 'action', 'action_display',
            'actor', 'timestamp', 'notes', 'before', 'after'
        ]
        read_only_fields = ['id', 'timestamp', 'actor', 'before', 'after']