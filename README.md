# Growth Metrics in SQL

Twelve ready-to-run SQL queries for the metrics growth and product teams use every week, each with a comment
explaining what it answers, the technique, and how to read the result. They run on DuckDB (PostgreSQL-style
syntax) against a **synthetic** quick-commerce app dataset (8,000 users over 90 days) generated with realistic
patterns: early drop-off, channels of different quality, a habit that decays, and an A/B test.

## The queries
| # | Metric | Techniques |
| --- | --- | --- |
| 01 | DAU, rolling WAU and MAU, stickiness (DAU/MAU) | range join, `COUNT(DISTINCT) FILTER` |
| 02 | Purchase funnel, step and overall conversion (first 7 days) | `LAG`, `FIRST_VALUE` |
| 03 | Weekly cohort retention triangle | `DATE_TRUNC`, `DATE_DIFF`, CTEs |
| 04 | D1 / D7 / D30 retention by channel | self-joins on dates, `FILTER` |
| 05 | Growth accounting: new, retained, resurrected, churned buyers | month-over-month joins |
| 06 | AOV, purchase frequency and 60-day LTV by channel | conditional aggregates |
| 07 | CAC and payback by paid channel | joins of spend and value |
| 08 | A/B test readout: lift, z-score and sample-ratio check | statistics in SQL |
| 09 | Medians and 90th percentiles vs averages | `QUANTILE_CONT`, `MEDIAN` |
| 10 | First-touch vs last-touch attribution | `ROW_NUMBER() OVER (PARTITION BY ...)` |
| 11 | Power-user curve (days active in the last 28) | distribution with window share |
| 12 | Cart abandonment by hour | time-window joins |

## What the sample data shows
- **Funnel:** 25% of new users buy in their first week; the biggest drop is from viewing a product to adding to cart.
- **Retention:** weekly cohorts fall to about a quarter by week 6; referral users retain best (D30 12%) and paid social worst (4%).
- **Payback:** referral pays back in about 1.6 months; paid social and search take about 6.
- **Attribution:** paid social earns 42% of first-touch revenue but only 22% of last-touch, so it starts journeys
  that other channels finish; judging it on last touch alone would undervalue it.
- **A/B test:** variant B converts 0.9 points better, but z = 0.85, so the result is **not significant**, and the
  sample-ratio check is clean. The honest call is "no evidence of a difference yet".

The numbers come from synthetic data; the SQL and the way to read each metric are the point.

## Run it
```bash
pip install -r requirements.txt
pytest -q                      # every query checked on hand-made data with known answers
python scripts/make_data.py    # generate the synthetic dataset
python run.py                  # run all 12 queries (or: python run.py 08)
```
