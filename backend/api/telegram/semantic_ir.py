#!/usr/bin/env python3
import os
import pandas as pd
import numpy as np
import torch
from sentence_transformers import SentenceTransformer, CrossEncoder, util

# Paths
CORPUS_CSV       = 'telegrammessage_202505241634.csv'
DF_CACHE         = 'corpus_df.pkl'
EMBEDDINGS_FILE  = 'corpus_embeddings.npy'

# Models
BI_ENCODER_NAME   = 'sentence-transformers/paraphrase-multilingual-mpnet-base-v2'
CROSS_ENCODER_NAME= 'cross-encoder/ms-marco-MiniLM-L-6-v2'

# Retrieval / rerank params
TOP_K_CANDIDATES  = 50    # how many to retrieve with bi-encoder
TOP_K_FINAL       = 50     # how many to return after cross-encoder
BI_THRESHOLD      = 0.2   # (optional) quick cut on bi-encoder scores

def build_and_cache_embeddings():
    df = pd.read_csv(CORPUS_CSV).dropna(subset=['message']).reset_index(drop=True)
    df.to_pickle(DF_CACHE)
    model = SentenceTransformer(BI_ENCODER_NAME)
    corpus_embs = model.encode(df['message'].tolist(),
                               convert_to_tensor=True,
                               show_progress_bar=True)
    np.save(EMBEDDINGS_FILE, corpus_embs.cpu().numpy())
    print(f"Cached {len(df)} docs and embeddings.")
    return df, corpus_embs

def load_cached_embeddings():
    if not os.path.exists(DF_CACHE) or not os.path.exists(EMBEDDINGS_FILE):
        return None, None
    df = pd.read_pickle(DF_CACHE)
    emb_np = np.load(EMBEDDINGS_FILE)
    corpus_embs = torch.from_numpy(emb_np) 
    print(f"Loaded {len(df)} docs and embeddings.")
    return df, corpus_embs

def semantic_query(query_text, bi_threshold=BI_THRESHOLD):
    # 1) load / build corpus
    df, corpus_embs = load_cached_embeddings()
    if corpus_embs is None:
        df, corpus_embs = build_and_cache_embeddings()

    # 2) bi-encoder retrieval
    bi_encoder = SentenceTransformer(BI_ENCODER_NAME)
    q_emb = bi_encoder.encode(query_text, convert_to_tensor=True)
    bi_scores = util.cos_sim(q_emb, corpus_embs)[0].cpu().numpy()

    # pick top-K (with optional bi_threshold)
    candidate_idxs = np.argsort(bi_scores)[-TOP_K_CANDIDATES:][::-1]
    if bi_threshold > 0:
        # filter out very low bi-scores
        candidate_idxs = [i for i in candidate_idxs if bi_scores[i] >= bi_threshold]

    # debug: show coarse top 5
    print("Coarse top 5:")
    for i in candidate_idxs[:5]:
        print(f"  ID={df.loc[i,'id']} bi_score={bi_scores[i]:.3f}")

    # 3) cross-encoder reranking
    cross_encoder = CrossEncoder(CROSS_ENCODER_NAME)
    # build (query, doc) pairs
    pairs = [(query_text, df.loc[i, 'message']) for i in candidate_idxs]
    cross_scores = cross_encoder.predict(pairs)  # returns a float score for each pair

    # pair them up and sort
    reranked = sorted(
        zip(candidate_idxs, cross_scores),
        key=lambda x: x[1],
        reverse=True
    )

    # debug: show rerank top 5
    print("\nReranked top 5:")
    for idx, sc in reranked[:5]:
        print(f"  ID={df.loc[idx,'id']} cross_score={sc:.3f}")

    # pick final top K
    final = [str(df.loc[idx,'id']) for idx, _ in reranked[:TOP_K_FINAL]]
    return final

if __name__ == '__main__':
    q1 = (
        "Road safety warning posts following recent accidents. "
        "መንገድ ደህንነት ማስጠንቀቂያ መኪና አደጋ"
    )
    q2 = (
    "Fano Shene clashes in Amhara region. "
    "በአማራ ክልል ፋኖ ሸነ ግጭቶች"
    )

    q3 = (
        "How much foreign currency in dollars can visitors import into Ethiopia? "
        "እንግዴዎች ወደ ኢትዮጵያ በዶላር ምን ያህል የውጭ ገንዘብ ማስገባት ይቻላል?"
    )

    q4 = (
        "Can Tecno Mobile phones access Safaricom  "
        "ቲክኖ ሞባይል ስልኮች በኢትዮጵያ የሳፋሪኮም?"
    )

    q5 = (
        "Information on support services for domestic violence survivors in Ethiopia. "
        "በኢትዮጵያ ለቤተሰብ ጥቃት ተጎዳኝ የሚያገለግሉ ድጋፍ አገልግሎቶች መረጃ"
    )

    q6 = (
        "Statistics on civilian fatalities in the Tigray conflict. "
        "በትግራይ ግጭት የዜጎች ሞት ስታቲስቲክስ"
    )

    q7 = (
        "Reports on Eritrean forces clashes at the Ethiopia Kenya border. "
        "በኢትዮጵያ ኬኒያ ድረስ የኤርትራ ኃይሎች ግጭቶች ሪፖርቶች"
    )

    q8 = (
        "Health care professionals Strike"
        "የጤና ባለሙያዎች አድማ አደረጉ"
    )

    q9 = (
        "Information on Ethiopias national health insurance program. "
        "የኢትዮጵያ ብሔራዊ የጤና መድህን ፕሮግራም መረጃ"
    )

    q10 = (
        "Transaction fees and daily limits for Fayda mobile money service. "
        "ለፋይዳ የሞባይል ገንዘብ አገልግሎት የትራንስካክሽን ክፍያዎች እና የቀን ወሰኖች"
    )

    ids = semantic_query(q8)
    print("\nFinal IDs:")
    print(", ".join(ids))
