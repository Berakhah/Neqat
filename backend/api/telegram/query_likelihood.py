# query_likelihood_lm.py

import math
from collections import Counter
from typing import List


class QueryLikelihoodLM:

    def __init__(self, corpus: List[List[str]], mu: float = 2000):
        #Think of μ as a "trust dial." A big μ (like 1500) 
        # means we trust the collection’s trends more; 
        # a small μ means we trust the document’s own words more
        """
        Initialize model by precomputing document and collection statistics.

        Args:
            corpus: A list of documents; each document is a list of string tokens.
            mu: Smoothing hyperparameter. Higher mu → heavier reliance on
                collection probabilities.
        """
        self.corpus = corpus
        self.mu = mu

        # Number of documents
        self.N = len(corpus)

        # Precompute document lengths
        self.doc_lens = [len(doc) for doc in corpus]

        # Build collection-wide term counts
        self.coll_counts = Counter()
        for doc in corpus:
            self.coll_counts.update(doc)

        # Total number of tokens in the collection
        self.total_terms = sum(self.doc_lens)

    def score(self, query: List[str]) -> List[float]:
        """
        Compute the log-likelihood score for each document given the query.

        We use Dirichlet smoothing:
            P(t | d) = ( c(t,d) + mu * ( c(t,C) / |C| ) ) / ( |d| + mu )

        Then:
            score(d) = sum_{t in query} log P(t | d)

        Args:
            query: List of query tokens (strings).

        Returns:
            A list of length N where each entry is the log-likelihood score
            of the query under that document’s language model.
        """
        scores = []

        # Iterate through each document
        for idx, doc in enumerate(self.corpus):
            dl = self.doc_lens[idx]                  # length of current document
            doc_counts = Counter(doc)               # term counts in this document
            doc_score = 0.0

            # Score each query term
            for t in query:
                c_td = doc_counts.get(t, 0)         # term count in doc
                c_tc = self.coll_counts.get(t, 0)   # term count in collection

                # Compute smoothed probability
                p_td = (c_td + self.mu * (c_tc / self.total_terms)) \
                       / (dl + self.mu)

                # Sum log-probabilities for all query terms
                 # avoid log(0)
                p_td = max(p_td, 1e-12)
                doc_score += math.log(p_td) #we use logarithms to smooth out very tiny numbers.

            scores.append(doc_score)

        return scores

    def rank(self, query: List[str], top_k: int = 10) -> List[int]:
        """
        Return the indices of the top-k highest-scoring documents.

        Args:
            query: List of query tokens.
            top_k: How many top documents to return.

        Returns:
            A list of document indices sorted by descending score.
        """
        scores = self.score(query)
        # Sort document indices by score descending
        ranked = sorted(range(self.N), key=lambda i: scores[i], reverse=True)
        return ranked[:top_k]


if __name__ == "__main__":
    # Example usage
    sample_corpus = [
        ["the", "cat", "in", "the", "hat"],
        ["the", "quick", "brown", "fox"],
        ["lorem", "ipsum", "dolor", "sit", "amet"]
    ]
    model = QueryLikelihoodLM(sample_corpus, mu=1500)

    query = ["the", "fox"]
    scores = model.score(query)
    ranked_docs = model.rank(query, top_k=3)

    print("Scores:", scores)           # log-likelihood scores
    print("Ranked docs:", ranked_docs) # indices of highest-scoring docs
