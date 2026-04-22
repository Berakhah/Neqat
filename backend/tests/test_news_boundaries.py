import urllib
import pytest
from django.urls import reverse

from .factories import NewsFactory
from api.models import News

pytestmark = pytest.mark.django_db


@pytest.mark.parametrize("initial_count", [0, 1, 20])
def test_news_list_count(admin_client, initial_count):
    """
    GET /api/news/ (NewsListView) now returns a dict:
      {
        "original_query": "",
        "stemmed_query": [],
        "count": <total>,
        "results": [ … ]
      }
    We just care that `count` and `len(results)` both match how many we created.
    """
    NewsFactory.create_batch(initial_count)
    resp = admin_client.get(reverse("news-list"))
    assert resp.status_code == 200

    body = resp.data
    assert isinstance(body, dict)
    assert body["count"] == initial_count
    assert isinstance(body["results"], list)
    assert len(body["results"]) == initial_count


@pytest.mark.parametrize("query", [
    "",                    # empty
    "A",                   # single char
    "Ab",                  # two chars
    "x" * 255,             # long but within typical limits
    "y" * 1024             # oversized
])
def test_news_search_length_and_shape(admin_client, query):
    """
    GET /api/news/search/?search=<q> (NewsSearchView) returns:
      {
        "original_query": <string>,
        "stemmed_query":  <string>,   # always a str
        "results":       [ … ]
      }
    Always 200, echo back original_query exactly, never crash.
    """
    # ensure at least one article matching 'Ab'
    NewsFactory(title="Abacus", content="counts")

    url = reverse("news-search") + f"?search={urllib.parse.quote_plus(query)}"
    resp = admin_client.get(url)
    assert resp.status_code == 200

    body = resp.data
    # shape
    assert body["original_query"] == query
    assert isinstance(body["stemmed_query"], str)
    assert isinstance(body["results"], list)

    # if they passed at least 2 characters containing "ab", we should see our fixture
    if len(query) >= 2 and "ab" in query.lower():
        assert len(body["results"]) >= 1


@pytest.mark.parametrize("db_size,search_term,expected", [
    (0, "nothing", 0),     # no articles match
    (1, "unique-t", 1),    # one exact match
    (5, "common",   5),    # five all match
])
def test_news_search_counts(admin_client, db_size, search_term, expected):
    """
    GET /api/news/search/?search=… must return exactly the right number of hits.
    """
    News.objects.all().delete()
    for i in range(db_size):
        NewsFactory(title=f"{search_term} #{i}", content=f"{search_term} #{i}")

    url = reverse("news-search") + f"?search={search_term}"
    resp = admin_client.get(url)
    assert resp.status_code == 200

    assert len(resp.data["results"]) == expected


@pytest.mark.parametrize("url_param,expected", [
    (None,           3),   # no filter → all
    ("http://foo/1", 1),   # exact existing
    ("http://foo/999",0),  # valid but no match
    ("%zz%%%bad",    0),   # malformed encoding
])
def test_news_list_url_filter(admin_client, url_param, expected):
    """
    GET /api/news/?url=… must filter on decoded URL
    """
    NewsFactory(url="http://foo/1")
    NewsFactory(url="http://foo/2")
    NewsFactory(url="http://foo/3")

    base = reverse("news-list")
    full = base if url_param is None else f"{base}?url={urllib.parse.quote_plus(url_param)}"

    resp = admin_client.get(full)
    assert resp.status_code == 200

    body = resp.data
    assert isinstance(body, dict)
    assert body["count"] == expected
    assert len(body["results"]) == expected
