# backend/api/telegram/amh_ir.py

import os
import re
import math
import numpy as np
import joblib
from pathlib import Path
from django.conf import settings
from django.utils import timezone
from collections import Counter
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import linear_kernel
from google.cloud import translate_v3 as translate

from api.telegram.bm25 import BM25
from api.telegram.query_likelihood import QueryLikelihoodLM
from api.news.porter_stemmer import porter_analyzer
from api.models import TelegramMessage
from api.telegram.stemmer_reference import (
    AMHARIC_ABBREVIATIONS,
    ETHIOPIC_PUNCTUATION,
    ETHIOPIC_NUMERALS,
    FIDEL_TO_LATIN,
    AMHARIC_PREFIXES,
    AMHARIC_SUFFIXES,
    AMHARIC_STOP_WORDS,
)

# where we dump/load our index
INDEX_PATH = Path(settings.BASE_DIR) / 'amh_ir_index.joblib'


# ------------------------------------------------------------------------------
# 1) Amharic text normalization & stemming (unchanged)
# ------------------------------------------------------------------------------

def expand_abbreviations(text: str) -> str:
    for abbr, full in AMHARIC_ABBREVIATIONS.items():
        text = text.replace(abbr, full)
    return text

def remove_punctuation(text: str) -> str:
    all_punc = set(ETHIOPIC_PUNCTUATION)
    all_punc.update({'.', ',', ';', ':', '!', '?', '-', '_',
                     '(', ')', '[', ']', '"', "'"})
    return ''.join(' ' if ch in all_punc else ch for ch in text)

def get_sixth_form(fidel: str) -> str:
    if not ('\u1200' <= fidel <= '\u137F'):
        return fidel
    code = ord(fidel)
    base = (code - 0x1200) // 8 * 8 + 0x1200
    sixth_form_code = base + 5
    return chr(sixth_form_code) if sixth_form_code <= 0x137F else fidel

def replace_ye_with_me(token: str) -> str:
    return re.sub(r'^ይ([\u1200-\u137F])', r'መ\1', token)

def rm_suffixes_am(token: str) -> str:
    changed = True
    while changed and len(token) > 2:
        changed = False
        for suf in sorted(AMHARIC_SUFFIXES, key=len, reverse=True):
            if token.endswith(suf) and len(token) - len(suf) >= 2:
                token, changed = token[:-len(suf)], True
                break
    return token

def rm_prefixes_am(token: str, skip_me=False) -> str:
    changed = True
    while changed and len(token) > 2:
        changed = False
        for pre in sorted(AMHARIC_PREFIXES, key=len, reverse=True):
            if pre != 'መ' or not skip_me:
                if token.startswith(pre) and len(token) - len(pre) >= 2:
                    token, changed = token[len(pre):], True
                    break
    return token

def stem_token(token: str) -> str:
    orig = token
    token = replace_ye_with_me(token)
    token = rm_suffixes_am(token)
    used_me = (token != orig and token.startswith('መ'))
    token = rm_prefixes_am(token, skip_me=used_me)
    if token:
        token = token[:-1] + get_sixth_form(token[-1])
    return token

# Precompute both original & stemmed stop words
STEMMED_STOP_WORDS = set(AMHARIC_STOP_WORDS) | {
    stem_token(sw) for sw in AMHARIC_STOP_WORDS if stem_token(sw)
}

def stem_word(text: str) -> list[str]:
    # 1) Expand abbreviations
    w = expand_abbreviations(text)
    # 2) Remove punctuation
    w = remove_punctuation(w)
    # 3) Normalize whitespace
    w = re.sub(r'\s+', ' ', w).strip()
    # 4) Tokenize into words
    toks = [t for t in w.split(' ') if t]
    # 5) Remove stop words before stemming
    toks = [t for t in toks if t not in AMHARIC_STOP_WORDS]
    stems = [stem_token(t) for t in toks]
    return [s for s in stems if s and s not in STEMMED_STOP_WORDS]

def analyzer(text: str) -> list[str]:
    return stem_word(text)


# ------------------------------------------------------------------------------
# 2) Build both Amharic & English indices (with one-time translation caching)
# ------------------------------------------------------------------------------

def build_index():
    # --- fetch raw Amharic messages and IDs ---
    qs = TelegramMessage.objects.all().order_by('id')
    msgs      = []
    en_texts  = []
    ids       = []
    new_cnt   = 0
    reuse_cnt = 0

    # prepare translation client
    client     = translate.TranslationServiceClient()
    project_id = os.getenv("GOOGLE_PROJECT_ID")
    parent     = f"projects/{project_id}/locations/global"

    for tm in qs:
        ids.append(tm.id)
        msgs.append(tm.message)

        # translate once, cache in DB
        raw = tm.message or ""
        if not raw.strip():
            # nothing to translate
            reuse_cnt += 1
            en = ""
        elif tm.english_text:
            reuse_cnt += 1
            en = tm.english_text
        else:
            resp = client.translate_text(
                request={
                    "parent": parent,
                    "contents": [raw],
                    "mime_type": "text/plain",
                    "source_language_code": "am",
                    "target_language_code": "en",
                }
            )
            en = resp.translations[0].translated_text
            tm.english_text = en
            tm.english_translated_at = timezone.now()
            tm.save(update_fields=['english_text','english_translated_at'])
            new_cnt += 1

        en_texts.append(en)

    print(f"→ Translated {new_cnt} messages, reused {reuse_cnt}")

    # — Amharic TF–IDF —
    tfidf_vec    = TfidfVectorizer(analyzer=analyzer, lowercase=False)
    tfidf_mat    = tfidf_vec.fit_transform(msgs)

    # — Amharic BM25 & QL-LM —
    tokenized    = [analyzer(m) for m in msgs]
    bm25         = BM25(tokenized, k1=1.5, b=0.75)
    ql_model     = QueryLikelihoodLM(tokenized, mu=2000)

    # — English TF–IDF —
    tfidf_vec_en = TfidfVectorizer(analyzer=porter_analyzer, lowercase=False)
    tfidf_mat_en = tfidf_vec_en.fit_transform(en_texts)

    # — English BM25 & QL-LM —
    tokenized_en = [porter_analyzer(t) for t in en_texts]
    bm25_en      = BM25(tokenized_en, k1=1.5, b=0.75)
    ql_model_en  = QueryLikelihoodLM(tokenized_en, mu=2000)

    # — dump everything —
    joblib.dump({
        'ids':            ids,
        'tfidf_vec':      tfidf_vec,
        'tfidf_mat':      tfidf_mat,
        'bm25':           bm25,
        'ql_model':       ql_model,
        'tfidf_vec_en':   tfidf_vec_en,
        'tfidf_mat_en':   tfidf_mat_en,
        'bm25_en':        bm25_en,
        'ql_model_en':    ql_model_en,
    }, INDEX_PATH)

    print(f"  → indices written to {INDEX_PATH}")


def load_index():
    """
    Load the dumped index from disk.
    Returns a dict with keys:
      ids, tfidf_vec, tfidf_mat, bm25, ql_model,
      tfidf_vec_en, tfidf_mat_en, bm25_en, ql_model_en
    """
    return joblib.load(INDEX_PATH)


# ------------------------------------------------------------------------------
# 3) Search across either Amharic or English index
# ------------------------------------------------------------------------------

def search(
    query:     str,
    top_k:     int    = 20,
    model:     str   = 'tfidf',
    translate_: bool = False
):
    if top_k <= 0:
       return []
    """
    model ∈ {'tfidf','bm25','qlm'}
    translate_=True → use English index (messages machine-translated to EN)
    translate_=False→ use Amharic index
    """
    if not hasattr(search, '_cache'):
        data = load_index()
        # Amharic
        search.ids          = data['ids']
        search.tfidf_vec    = data['tfidf_vec']
        search.tfidf_mat    = data['tfidf_mat']
        search.bm25         = data['bm25']
        search.ql_model     = data['ql_model']
        # English
        search.tfidf_vec_en = data['tfidf_vec_en']
        search.tfidf_mat_en = data['tfidf_mat_en']
        search.bm25_en      = data['bm25_en']
        search.ql_model_en  = data['ql_model_en']
        search._cache       = True

    valid = {'tfidf','bm25','qlm'}
    m = model.lower()
    if m not in valid:
        raise ValueError(f"Unknown model '{model}', choose one of {valid!r}")

    if translate_:
        # → English pipeline
        if m == 'bm25':
            tok = porter_analyzer(query)
            scores = np.array(search.bm25_en.get_scores(tok))
        elif m == 'qlm':
            tok = porter_analyzer(query)
            scores = np.array(search.ql_model_en.score(tok))
        else:
            qv = search.tfidf_vec_en.transform([query])
            scores = linear_kernel(qv, search.tfidf_mat_en).flatten()
    else:
        # → Amharic pipeline
        if m == 'bm25':
            tok = analyzer(query)
            scores = np.array(search.bm25.get_scores(tok))
        elif m == 'qlm':
            tok = analyzer(query)
            scores = np.array(search.ql_model.score(tok))
        else:
            qv = search.tfidf_vec.transform([query])
            scores = linear_kernel(qv, search.tfidf_mat).flatten()

    # return top_k with positive score
    idxs = np.argsort(scores)[::-1]
    hits = []
    for i in idxs:
        if scores[i] <= 0 and m !='qlm':
            break
        hits.append((search.ids[i], float(scores[i])))
        if len(hits) >= top_k:
            break
    return hits
