# tests/test_ir_metrics.py
import pytest
import matplotlib
matplotlib.use("Agg")  # non-interactive backend for CI

import matplotlib.pyplot as plt

from api.telegram.evaluate_ir import (
    precision_at_k,
    recall_at_k,
    f1_at_k,
    average_precision,
    mean_average_precision,
    plot_map,
    plot_pr_curve,
    plot_f1_curve,
)

@pytest.mark.parametrize("retrieved,relevant,k,expected", [
    ([],        set(),      0,  0.0),
    ([],        set(),      5,  0.0),
    ([1,2,3],   {1,3},      1,  1.0),  # only doc 1 in top-1 and is relevant
    ([1,2,3],   {1,3},      2,  0.5),  # {1} in top-2 of size 2
    ([4,5,6],   {1,2,3},    3,  0.0),  # no overlap
    ([1,2,3,4], {2,4},      3,  1/3),  # only 2 in top-3
])
def test_precision_at_k(retrieved, relevant, k, expected):
    assert precision_at_k(retrieved, relevant, k) == pytest.approx(expected)

@pytest.mark.parametrize("retrieved,relevant,k,expected", [
    ([],          set(),     1,  0.0),
    ([],          {1,2},     1,  0.0),
    ([1,2,3],     {1,3},     1,  1/2),  # hit=1 of 2 relevant
    ([1,2,3],     {1,3},     2,  1/2),  # still only 1 hit out of 2
    ([1,2,3,4],   {2,4},     3,  1/2),  # hit {2} in top-3
    ([1,2,3,4],   {2,4},     4,  2/2),  # both 2 & 4 in top-4
])
def test_recall_at_k(retrieved, relevant, k, expected):
    assert recall_at_k(retrieved, relevant, k) == pytest.approx(expected)

@pytest.mark.parametrize("retrieved,relevant,k,expected", [
    ([],      set(),     1,  0.0),
    ([],      {1,2},     1,  0.0),
    ([1],     {1},       1,  1.0),     # perfect precision & recall
    ([1,2],   {1,3},     2,  2*(0.5*0.5)/(0.5+0.5)),  # P=R=0.5 → F1=0.5
    ([1,2,3], {1,3},     3,  2*(2/3*1)/(2/3+1)),     # P=2/3,R=1→F1≈0.8
    ([1,2,3], {4,5},     3,  0.0),     # no hits → 0
])
def test_f1_at_k(retrieved, relevant, k, expected):
    assert f1_at_k(retrieved, relevant, k) == pytest.approx(expected)

@pytest.mark.parametrize("retrieved,relevant,expected", [
    ([],        set(),      0.0),
    ([1,2,3],   set(),      0.0),
    ([1,2,3],   {2},       (1/2)/1.0),   # first hit at pos 2 → precision@2 = .5, /1 relevant
    ([1,2,3,4], {2,4},    (1/2 + 2/4)/2.0),
    ([1,2,3,4], {5},      0.0),          # no hits
])
def test_average_precision(retrieved, relevant, expected):
    assert average_precision(retrieved, relevant) == pytest.approx(expected)

def test_mean_average_precision_multiple_queries():
    results = {
        "q1": ["a","b","c","d"],
        "q2": ["x","y","z"],
    }
    relevant_sets = {
        "q1": {"b","d"},
        "q2": {"x"},
    }
    # AP(q1) = (1/2 + 2/4)/2 = (0.5 + 0.5)/2 = 0.5
    # AP(q2) = (1/1)/1 = 1.0
    expected_map = (0.5 + 1.0) / 2
    assert mean_average_precision(results, relevant_sets) == pytest.approx(expected_map)

def test_mean_average_precision_empty():
    assert mean_average_precision({}, {}) == 0.0

@pytest.mark.parametrize("func,args", [
    (plot_map,      ({"m1":0.3,"m2":0.7},)),
    (plot_pr_curve, ([1,2,3,4], {2,4}, "m", "Q1")),
    (plot_f1_curve, ([1,2,3,4], {2,4}, "m", "Q1")),
])
def test_plot_functions_do_not_error(func, args):
    # each plotting helper should at least create a figure without error
    prior = len(plt.get_fignums())
    func(*args)
    after = len(plt.get_fignums())
    assert after == prior + 1
    plt.close('all')
