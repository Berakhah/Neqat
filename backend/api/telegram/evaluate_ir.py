#!/usr/bin/env python3
import matplotlib.pyplot as plt
import os

def precision_at_k(retrieved, relevant, k):
    """
    Precision at cutoff k.
    retrieved: list of retrieved doc IDs (in rank order)
    relevant: set of relevant doc IDs
    """
    if k == 0:
        return 0.0
    top_k = retrieved[:k]
    return sum(1 for doc in top_k if doc in relevant) / k

def recall_at_k(retrieved, relevant, k):
    """
    Recall at cutoff k.
    """
    if not relevant:
        return 0.0
    top_k = retrieved[:k]
    return sum(1 for doc in top_k if doc in relevant) / len(relevant)

def f1_at_k(retrieved, relevant, k):
    """
    F1 at cutoff k = 2 * (P@k * R@k) / (P@k + R@k)
    """
    p = precision_at_k(retrieved, relevant, k)
    r = recall_at_k(retrieved, relevant, k)
    if p + r == 0:
        return 0.0
    return 2 * (p * r) / (p + r)

def average_precision(retrieved, relevant):
    """
    Average Precision (AP) for a single query.
    """
    if not relevant:
        return 0.0
    hit_count = 0
    score = 0.0
    for idx, doc in enumerate(retrieved, start=1):
        if doc in relevant:
            hit_count += 1
            score += hit_count / idx
    return score / len(relevant)

def mean_average_precision(results, relevant_sets):
    """
    Compute MAP over multiple queries.
    """
    aps = []
    for qid, retrieved in results.items():
        ap = average_precision(retrieved, relevant_sets[qid])
        aps.append(ap)
    return sum(aps) / len(aps) if aps else 0.0

def plot_map(models_map):
    """
    Bar chart of MAP for each IR method.
    """
    names = list(models_map.keys())
    values = [models_map[n] for n in names]
    plt.figure()
    plt.bar(names, values)
    plt.title('Mean Average Precision (MAP)')
    plt.ylabel('MAP')
    plt.xlabel('IR Method')
    plt.ylim(0, 1)
    plt.grid(axis='y')

def plot_pr_curve(retrieved, relevant, method_name, qid):
    """
    Precision–Recall curve for one query & one method.
    """
    ks = range(1, len(retrieved) + 1)
    precisions = [precision_at_k(retrieved, relevant, k) for k in ks]
    recalls    = [recall_at_k(retrieved, relevant, k) for k in ks]
    plt.figure()
    plt.plot(recalls, precisions, marker='o')
    plt.title(f'Precision–Recall ({method_name}, Q={qid})')
    plt.xlabel('Recall')
    plt.ylabel('Precision')
    plt.grid(True)

def plot_f1_curve(retrieved, relevant, method_name, qid):
    """
    F1@k curve for one query & one method.
    """
    ks = range(1, len(retrieved) + 1)
    f1s = [f1_at_k(retrieved, relevant, k) for k in ks]
    plt.figure()
    plt.plot(ks, f1s, marker='o')
    plt.title(f'F1@k ({method_name}, Q={qid})')
    plt.xlabel('k')
    plt.ylabel('F1 Score')
    plt.ylim(0, 1)
    plt.grid(True)

def main():
    print("=== IR Evaluation Script ===")
    num_queries = int(input("Number of queries to evaluate: ").strip())
    output_dir = "evaluations"


    relevant_sets       = {}
    translation_results = {}
    custom_results      = {}

    for i in range(1, num_queries + 1):
        print(f"\n--- Query {i} ---")
        qid = input("Query ID (any label): ").strip()
        rel = input("Enter relevant doc IDs (comma-separated): ")
        relevant = set(tok.strip() for tok in rel.split(',') if tok.strip())
        relevant_sets[qid] = relevant

        ret_trans = input("translation_based_ir retrieved doc IDs (rank order, comma-separated): ")
        translation_results[qid] = [tok.strip() for tok in ret_trans.split(',') if tok.strip()]

        ret_custom = input("custom_amharic_ir retrieved doc IDs (rank order, comma-separated): ")
        custom_results[qid] = [tok.strip() for tok in ret_custom.split(',') if tok.strip()]

    # Compute MAP for each method
    map_trans  = mean_average_precision(translation_results, relevant_sets)
    map_custom = mean_average_precision(custom_results, relevant_sets)
    print(f"\ntranslation_based_ir MAP: {map_trans:.4f}")
    print(f"custom_amharic_ir   MAP: {map_custom:.4f}")

    # Plot & save MAP comparison
    plot_map({
        'translation_based_ir': map_trans,
        'custom_amharic_ir':   map_custom
    })
    plt.savefig(os.path.join(output_dir,"map_comparison.png"), dpi=300, bbox_inches="tight")
    print("→ Saved MAP chart as map_comparison.png")

    # Plot & save P–R and F1 curves per query and method
    for qid in relevant_sets:
        # P–R curves
        plot_pr_curve(
            translation_results[qid],
            relevant_sets[qid],
            'translation_based_ir',
            qid
        )
        fname_pr_t = f'pr_curve_translation_q{qid}.png'
        plt.savefig(os.path.join(output_dir,fname_pr_t), dpi=300, bbox_inches="tight")
        print(f"→ Saved P–R curve: {fname_pr_t}")

        plot_pr_curve(
            custom_results[qid],
            relevant_sets[qid],
            'custom_amharic_ir',
            qid
        )
        fname_pr_c = f'pr_curve_custom_q{qid}.png'
        plt.savefig(os.path.join(output_dir,fname_pr_c), dpi=300, bbox_inches="tight")
        print(f"→ Saved P–R curve: {fname_pr_c}")

        # F1@k curves
        plot_f1_curve(
            translation_results[qid],
            relevant_sets[qid],
            'translation_based_ir',
            qid
        )
        fname_f1_t = f'f1_curve_translation_q{qid}.png'
        plt.savefig(os.path.join(output_dir,fname_f1_t), dpi=300, bbox_inches="tight")
        print(f"→ Saved F1 curve: {fname_f1_t}")

        plot_f1_curve(
            custom_results[qid],
            relevant_sets[qid],
            'custom_amharic_ir',
            qid
        )
        fname_f1_c = f'f1_curve_custom_q{qid}.png'
        plt.savefig(os.path.join(output_dir,fname_f1_c), dpi=300, bbox_inches="tight")
        print(f"→ Saved F1 curve: {fname_f1_c}")

    print("\nDisplaying plots…")
    plt.show()

if __name__ == '__main__':
    main()
