import math
from collections import Counter, defaultdict

class BM25:
    """
    A simple BM25 implementation (Okapi BM25) over a tokenized corpus.
    """
    def __init__(self, corpus: list[list[str]], k1: float = 1.5, b: float = 0.75):
        self.corpus = corpus
        self.k1 = k1
        self.b = b
        self.N = len(corpus)
        # Compute average document length
        self.avgdl = sum(len(doc) for doc in corpus) / self.N if self.N > 0 else 0

        # Document frequencies and term frequencies
        # This is a list outlining how many times a word
        # appears in a docuemnt like ["cat", "dog", "cat"], it’d be {"cat": 2, "dog": 1}.
        self.doc_freqs: list[Counter] = []

        #is a dictionary tracking how many documents each word appears in. 
        # If "dog" is in 3 out of 5 documents, df["dog"] = 3
        self.df: dict[str, int] = defaultdict(int)
        for doc in corpus:
            freq = Counter(doc)
            self.doc_freqs.append(freq)
            for term in freq.keys():
                self.df[term] += 1
        # Precompute IDF for each term
        self.idf: dict[str, float] = {}
        for term, freq in self.df.items():
            # Okapi BM25 IDF formula with added 1 for stability
            idf_value = math.log((self.N - freq + 0.5) / (freq + 0.5) + 1)
            self.idf[term] = idf_value

    def get_scores(self, query: list[str]) -> list[float]:
        """
        Computes BM25 scores for each document in the corpus for the given query tokens.
        """
        scores = [0.0] * self.N
        for q in query:
            if q not in self.idf:
                continue
            idf = self.idf[q]
            for idx, freq in enumerate(self.doc_freqs):
                f = freq.get(q, 0)
                if f == 0:
                    continue
                dl = len(self.corpus[idx])
                denom = f + self.k1 * (1 - self.b + self.b * dl / self.avgdl)
                numer = f * (self.k1 + 1)
                scores[idx] += idf * (numer / denom)
        return scores
