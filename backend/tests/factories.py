import factory
from django.utils import timezone
from api.models import NeqatUser, Tag, News, Comment, TelegramMessage

class NeqatUserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = NeqatUser
        skip_postgeneration_save = True  # Avoid deprecation warning

    user_name = factory.Sequence(lambda n: f"user_{n}")
    email = factory.Sequence(lambda n: f"user_{n}@example.com")
    password = factory.PostGenerationMethodCall('set_password', 'testpass123')
    is_active = True

class TagFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Tag

    name = factory.Sequence(lambda n: f"tag_{n}")

class TelegramMessageFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = TelegramMessage

    sender_id = factory.Sequence(lambda n: f"sender_{n}")
    message = "Test message in Amharic መልእክት"
    date = factory.LazyFunction(timezone.now)
    channel_name = "test_channel"

class NewsFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = News
        skip_postgeneration_save = False  # Explicitly keep save for tags

    title = factory.Sequence(lambda n: f"News {n}")
    content = "This is a test news article."
    url = factory.Sequence(lambda n: f"https://example.com/news/{n}")
    timestamp = factory.LazyFunction(timezone.now)
    language = "en"
    source = "Test Source"  # Added per NewsSerializer
    author = "Test Author"  # Added per NewsSerializer

    @factory.post_generation
    def tags(self, create, extracted, **kwargs):
        if not create:
            return
        if extracted:
            for tag in extracted:
                self.tags.add(tag)
            self.save()  # Explicit save for tags

class CommentFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Comment

    content = "This is a test comment."
    created_by = factory.SubFactory(NeqatUserFactory)
    status = "APPROVED"