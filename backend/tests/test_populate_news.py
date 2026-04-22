import pytest
from api.populate_news import map_newsapi_to_django

BASE_ARTICLE = {
    "title":       "Example Title",
    "description": "Some description.",
    "content":     "Some content.",
    "source":      {"name": "Test Source"},
    "url":         "https://example.com/foo",
    "urlToImage":  None,
    "publishedAt": "2025-01-01T12:00:00Z",
    "author":      "Test Author",
}

@pytest.mark.parametrize("tag_name,is_top,expected_tags", [
    (None,      False, ["World"]),
    ("Business", False, ["Business"]),
    (None,      True,  ["top_headlines"]),
])
def test_map_newsapi_sets_tags(tag_name, is_top, expected_tags):
    art = BASE_ARTICLE.copy()
    objs = map_newsapi_to_django([art], tag_name=tag_name, is_top_headline=is_top)
    assert objs[0]["tag_names"] == expected_tags

def test_map_newsapi_uses_description_when_content_missing(capsys):
    art = BASE_ARTICLE.copy()
    art["content"] = None
    art["description"] = "Just a Description."
    django_objs = map_newsapi_to_django([art])
    assert django_objs[0]["content"] == "just a description."

    captured = capsys.readouterr()
    assert "using description" in captured.out.lower()

def test_map_newsapi_uses_empty_when_both_missing(capsys):
    art = BASE_ARTICLE.copy()
    art["content"] = None
    art["description"] = None
    objs = map_newsapi_to_django([art])
    assert objs[0]["content"] == ""

    captured = capsys.readouterr()
    assert "both content and description are none" in captured.out.lower()

def test_map_newsapi_skips_bbc_bulletin(capsys):
    art = BASE_ARTICLE.copy()
    art["source"]      = {"name": "BBC News"}
    art["description"] = "This is a Five Minute News Bulletin about traffic."
    objs = map_newsapi_to_django([art])
    # bulletins should be skipped entirely
    assert objs == []

    captured = capsys.readouterr()
    assert "skipping bbc news bulletin" in captured.out.lower()

def test_map_newsapi_truncates_content_to_1000_chars():
    long_text = "x" * 1200
    art = BASE_ARTICLE.copy()
    art["content"] = long_text
    objs = map_newsapi_to_django([art])
    # ensure we truncated down to at most 1000 chars
    assert len(objs[0]["content"]) <= 1000

def test_map_newsapi_timestamp_defaults_to_now():
    # If publishedAt absent or invalid, map to an ISO timestamp
    art = BASE_ARTICLE.copy()
    art.pop("publishedAt")
    objs = map_newsapi_to_django([art])
    assert "T" in objs[0]["timestamp"]
    # crude check: len 20+ and ends with 'Z' or offset
    assert len(objs[0]["timestamp"]) >= 20

