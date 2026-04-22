"""
tests/test_search.py

Unit tests for the Amharic IR pipeline in api.telegram.amh_ir, including:
  - stem_word(): Amharic normalization & stemming
  - build_index(): constructing both Amharic & English indices (with caching)
  - search(): querying both Amharic and English indices (TF-IDF, BM25, Query-Likelihood)
"""

# ------------------------------------------------------------------------------
# Standard library imports
# ------------------------------------------------------------------------------
from pathlib import Path

# ------------------------------------------------------------------------------
# Third-party imports
# ------------------------------------------------------------------------------
import pytest
import joblib
import numpy as np
from django.utils import timezone

# ------------------------------------------------------------------------------
# Django settings / project imports
# ------------------------------------------------------------------------------
from django.conf import settings

# ------------------------------------------------------------------------------
# Application imports
# ------------------------------------------------------------------------------
from api.telegram.amh_ir import stem_word, build_index, search
from api.telegram.stemmer_reference import AMHARIC_STOP_WORDS, AMHARIC_ABBREVIATIONS
from tests.factories import TelegramMessageFactory


# ------------------------------------------------------------------------------
# 1) Amharic stemming tests
# ------------------------------------------------------------------------------
@pytest.mark.django_db
def test_stem_word_basics():
    """
    Verify that stem_word():
      - removes stop words and punctuation
      - expands known abbreviations
      - strips valid prefixes/suffixes
      - returns an empty list on blank or punctuation-only input
    """
    # a) Remove stop words + punctuation, expect a single stemmed token
    text = "መልእክቶች ነው።"
    stems = stem_word(text)
    assert isinstance(stems, list)
    assert len(stems) == 1
    assert stems[0] not in AMHARIC_STOP_WORDS
    assert stems[0].startswith("መል")

    # b) Abbreviation expansion: ዶ/ር → “ዶክተር”
    text = "ዶ/ር መልእክት"
    stems = stem_word(text)
    assert any("ዶክተር" in s for s in stems)

    # c) Prefix/suffix removal: “የ…ቶች”
    text = "የመልእክቶች"
    stems = stem_word(text)
    assert len(stems) == 1
    assert not stems[0].startswith("የ")
    assert not stems[0].endswith("ኦች")

    # d) Edge cases: empty or punctuation-only input
    assert stem_word("") == []
    assert stem_word("።፣፡") == []

    # e) Stop-word-only input
    assert stem_word("ነው") == []


# ------------------------------------------------------------------------------
# 2) Index‐building tests (Amharic & English)
# ------------------------------------------------------------------------------
@pytest.mark.django_db
def test_build_index_creates_complete_index(mocker, tmp_path):
    """
    Ensure build_index():
      - writes out all required vectors/models for both languages
      - honors existing english_text values and caches new translations
    """
    # a) Create three TelegramMessage instances
    tm1 = TelegramMessageFactory(message="Test መልእክት", english_text="Test message")
    tm2 = TelegramMessageFactory(message="Another መልእክት", english_text=None)
    tm3 = TelegramMessageFactory(message="", english_text="")  # blank message

    # b) Stub out the Google Translate call for tm2
    mocker.patch(
        "google.cloud.translate_v3.TranslationServiceClient.translate_text",
        return_value=mocker.Mock(translations=[mocker.Mock(translated_text="Another message")])
    )

    # c) Redirect INDEX_PATH into our temporary directory
    index_path = tmp_path / "amh_ir_index.joblib"
    mocker.patch("api.telegram.amh_ir.INDEX_PATH", index_path)

    # d) Run and verify file creation
    build_index()
    assert index_path.exists()

    # e) Load and inspect the dump
    idx = joblib.load(index_path)
    expected_keys = {
        'ids', 'tfidf_vec', 'tfidf_mat', 'bm25', 'ql_model',
        'tfidf_vec_en', 'tfidf_mat_en', 'bm25_en', 'ql_model_en'
    }
    assert set(idx.keys()) == expected_keys
    assert idx['tfidf_mat'].shape[0] == 3
    assert idx['tfidf_mat_en'].shape[0] == 3
    assert idx['ids'] == [tm1.id, tm2.id, tm3.id]

    # f) Confirm translation caching into DB
    tm2.refresh_from_db()
    assert tm2.english_text == "Another message"
    assert tm2.english_translated_at is not None

    tm3.refresh_from_db()
    assert tm3.english_text == ""


# ------------------------------------------------------------------------------
# 3) Search functionality tests
# ------------------------------------------------------------------------------
@pytest.mark.django_db
def test_search_various_models_and_languages(mocker, tmp_path):
    """
    Validate that search():
      - returns up to top_k hits for each model (tfidf, bm25, qlm)
      - correctly handles translate_=False (Amharic) and translate_=True (English)
      - raises on invalid model names
      - returns empty lists on top_k <= 0 or empty query
    """
    # 1) Seed 5 identical messages into the DB
    TelegramMessageFactory.create_batch(
        5,
        message="Test መልእክት",
        english_text="Test message"
    )

    # 2) Build a fresh index in our temp path
    index_path = tmp_path / "amh_ir_index.joblib"
    mocker.patch("api.telegram.amh_ir.INDEX_PATH", index_path)
    build_index()

    # 3) Amharic TF-IDF
    hits = search("መልእክት", top_k=3, model="tfidf", translate_=False)
    assert isinstance(hits, list)
    assert len(hits) <= 3
    if hits:
        id0, score0 = hits[0]
        assert isinstance(id0, int)
        assert isinstance(score0, float)

    # 4) English TF-IDF
    hits = search("message", top_k=3, model="tfidf", translate_=True)
    assert isinstance(hits, list)
    assert len(hits) <= 3

    # 5) Amharic BM25 & QL-LM
    for model_name in ("bm25", "qlm"):
        hits = search("መልእክት", top_k=2, model=model_name, translate_=False)
        assert isinstance(hits, list)
        assert len(hits) <= 2

    # 6) Boundary conditions
    assert search("መልእክት", top_k=0, model="tfidf") == []
    with pytest.raises(ValueError):
        search("መልእክት", top_k=3, model="invalid")
    assert search("", top_k=3, model="tfidf") == []

    # 7) Exercise English BM25 & QL-LM branches (with translation stubbed)
    mocker.patch(
        "google.cloud.translate_v3.TranslationServiceClient.translate_text",
        return_value=mocker.Mock(translations=[mocker.Mock(translated_text="message")])
    )
    for model_name in ("bm25", "qlm"):
        hits = search("መልእክት", top_k=2, model=model_name, translate_=True)
        assert isinstance(hits, list)
        assert len(hits) <= 2
