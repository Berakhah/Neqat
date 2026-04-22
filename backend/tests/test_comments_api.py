import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from django.contrib.auth import get_user_model
from tests.factories import NewsFactory, TelegramMessageFactory, CommentFactory
from api.models import Comment

User = get_user_model()

@pytest.fixture
def api_client():
    return APIClient()

@pytest.fixture
def finhas_user(db):
    """
    Ensure there is a user with credentials finhas / NEQ@T2025.
    """
    user, _ = User.objects.get_or_create(
        user_name="finhas",
        defaults={
            "email": "finhas@example.com",
            "is_active": True,
            "is_staff": False,
        }
    )
    user.set_password("NEQ@T2025")
    user.save()
    return user

@pytest.fixture
def auth_client(api_client, finhas_user):
    """
    Log in as 'finhas' to get a JWT access token.
    """
    url = reverse("login")
    resp = api_client.post(
        url,
        {"user_name": "finhas", "password": "NEQ@T2025"},
        format="json"
    )
    assert resp.status_code == 200, f"Login failed: {resp.data}"
    token = resp.data["access"]
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return api_client

@pytest.fixture
def staff_user(db):
    user, _ = User.objects.get_or_create(
        user_name="finhas_staff",
        defaults={
            "email": "staff@example.com",
            "is_active": True,
            "is_staff": True,
        }
    )
    user.set_password("NEQ@T2025")
    user.save()
    return user

@pytest.fixture
def staff_client(api_client, staff_user):
    """
    Log in as the staff user to get a JWT access token.
    """
    url = reverse("login")
    resp = api_client.post(
        url,
        {"user_name": "finhas_staff", "password": "NEQ@T2025"},
        format="json"
    )
    assert resp.status_code == 200, f"Staff login failed: {resp.data}"
    token = resp.data["access"]
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return api_client


@pytest.mark.django_db
class TestCommentsAPI:

    def test_create_comment_on_news(self, auth_client, finhas_user):
        """
        POST /comments/ with news_id should create a PENDING comment by finhas.
        """
        news = NewsFactory()
        url = reverse("comment-list")

        payload = {
            "content": "Great read!",
            "news_id": str(news.id)
        }
        resp = auth_client.post(url, payload, format="json")
        assert resp.status_code == 201, resp.data

        # DRF returns the new comment's data (including "id"), but not "news"
        comment_id = resp.data["id"]

        # Fetch it directly
        c = Comment.objects.get(id=comment_id)
        assert c.content == "Great read!"
        assert str(c.news_id) == str(news.id)
        assert str(c.created_by_id) == str(finhas_user.id)
        assert c.status == "PENDING"

    def test_list_only_approved_and_own_pending(self, auth_client, finhas_user):
        """
        Non-staff GET returns only APPROVED + finhas's own PENDING comments.
        """
        news = NewsFactory()

        approved = CommentFactory(news=news, status="APPROVED")
        CommentFactory(news=news, status="PENDING")  # another user's
        own = CommentFactory(news=news, status="PENDING", created_by=finhas_user)

        url = reverse("comment-list") + f"?news_id={news.id}"
        resp = auth_client.get(url, format="json")
        assert resp.status_code == 200

        results = resp.data["results"]
        returned = {c["id"] for c in results}

        # should see the one approved + finhas's own pending
        assert str(approved.id) in returned
        assert str(own.id)      in returned
        assert len(results) == 2

    def test_staff_sees_all(self, staff_client):
        """
        Staff GET sees APPROVED, PENDING, FLAGGED—all comments.
        """
        news = NewsFactory()
        c1 = CommentFactory(news=news, status="APPROVED")
        c2 = CommentFactory(news=news, status="PENDING")
        c3 = CommentFactory(news=news, status="FLAGGED")

        url = reverse("comment-list") + f"?news_id={news.id}"
        resp = staff_client.get(url, format="json")
        assert resp.status_code == 200

        results = resp.data["results"]
        returned = {c["id"] for c in results}
        expected = {str(c1.id), str(c2.id), str(c3.id)}
        assert expected.issubset(returned)
        assert len(results) >= 3

    def test_filter_by_telegram_message(self, auth_client):
        """
        GET /comments/?telegram_message_id=... returns only those comments
        that a non-staff may see (approved + own). Here, only APPROVED.
        """
        tm = TelegramMessageFactory()
        c1 = CommentFactory(telegram_message=tm, status="APPROVED")
        CommentFactory(telegram_message=tm, status="PENDING")  # other user’s
        # an unrelated comment on a news article
        CommentFactory(news=NewsFactory(), status="APPROVED")

        url = reverse("comment-list") + f"?telegram_message_id={tm.id}"
        resp = auth_client.get(url, format="json")
        assert resp.status_code == 200

        results = resp.data["results"]
        returned = {c["id"] for c in results}

        # non-staff sees only the APPROVED one
        assert returned == {str(c1.id)}

    def test_unauthenticated_cannot_post(self, api_client):
        """
        POST without credentials should be 401.
        """
        news = NewsFactory()
        url = reverse("comment-list")
        resp = api_client.post(
            url,
            {"content": "nope", "news_id": str(news.id)},
            format="json"
        )
        assert resp.status_code == 401
