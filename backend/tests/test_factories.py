import pytest
from tests.factories import NeqatUserFactory, TagFactory, TelegramMessageFactory, NewsFactory, CommentFactory

@pytest.mark.django_db
def test_factories():
    user = NeqatUserFactory()
    tag = TagFactory()
    news = NewsFactory(tags=[tag])
    comment = CommentFactory(news=news, created_by=user)
    telegram = TelegramMessageFactory()

    assert user.is_active
    assert "tag_" in tag.name
    assert "News" in news.title
    assert comment.status == "APPROVED"
    assert "መልእክት" in telegram.message