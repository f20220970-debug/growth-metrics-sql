"""Run the real SQL files on tiny hand-made tables whose answers can be checked by hand."""
from pathlib import Path

import duckdb
import pytest

SQL = Path(__file__).resolve().parents[1] / "sql"


def q(con, name):
    return con.execute((SQL / name).read_text().replace("{margin}", "0.30")).df()


@pytest.fixture
def con():
    c = duckdb.connect()
    c.execute("""CREATE TABLE users AS SELECT * FROM (VALUES
        (1, '2026-07-01', 'referral', 'Bengaluru'), (2, '2026-07-01', 'paid_social', 'Delhi'),
        (3, '2026-07-02', 'paid_social', 'Delhi'), (4, '2026-07-02', 'search', 'Mumbai'))
        t(user_id, signup_date, channel, city)""")
    c.execute("""CREATE TABLE events AS SELECT * FROM (VALUES
        (1, '2026-07-01 09:00:00', 'app_open'), (1, '2026-07-01 09:01:00', 'view_product'),
        (1, '2026-07-01 09:03:00', 'add_to_cart'), (1, '2026-07-01 09:05:00', 'checkout'),
        (1, '2026-07-01 09:06:00', 'purchase'), (1, '2026-07-02 10:00:00', 'app_open'),
        (1, '2026-07-08 10:00:00', 'app_open'),
        (2, '2026-07-01 18:00:00', 'app_open'), (2, '2026-07-01 18:01:00', 'view_product'),
        (2, '2026-07-01 18:03:00', 'add_to_cart'),
        (3, '2026-07-02 20:00:00', 'app_open'),
        (4, '2026-07-02 21:00:00', 'app_open'), (4, '2026-07-02 21:01:00', 'view_product'))
        t(user_id, event_time, event_name)""")
    c.execute("""CREATE TABLE orders AS SELECT * FROM (VALUES
        (1, 1, '2026-07-01 09:06:00', 500.0), (2, 1, '2026-08-03 09:00:00', 700.0))
        t(order_id, user_id, order_time, amount)""")
    c.execute("""CREATE TABLE touches AS SELECT * FROM (VALUES
        (1, '2026-06-28 10:00:00', 'paid_social'), (1, '2026-06-30 10:00:00', 'referral'))
        t(user_id, touch_time, channel)""")
    c.execute("""CREATE TABLE experiment AS SELECT * FROM (VALUES
        (1, 'B', '2026-07-01'), (2, 'A', '2026-07-01'), (3, 'A', '2026-07-02'), (4, 'B', '2026-07-02'))
        t(user_id, variant, assigned_date)""")
    c.execute("CREATE TABLE spend AS SELECT * FROM (VALUES ('2026-07-01', 'paid_social', 600.0)) t(spend_date, channel, amount)")
    return c


def test_funnel_counts_users_per_step(con):
    f = q(con, "02_funnel.sql").set_index("step")["users"]
    assert list(f) == [4, 3, 2, 1, 1]          # open 4, view 3, cart 2 (users 1,2), checkout 1, purchase 1


def test_n_day_retention(con):
    r = q(con, "04_n_day_retention.sql").set_index("channel")
    assert r.loc["referral", "d1"] == 1.0 and r.loc["referral", "d7"] == 1.0   # user 1 opened on day 1 and day 7


def test_growth_accounting(con):
    g = q(con, "05_growth_accounting.sql")
    jul, aug = g.iloc[0], g.iloc[1]
    assert jul.new_buyers == 1 and aug.retained == 1 and aug.churned == 0


def test_ab_test_and_srm(con):
    r = q(con, "08_ab_test.sql").iloc[0]
    assert r.n_a == 2 and r.n_b == 2 and r.conversion_b == 0.5 and r.conversion_a == 0
    assert r.srm_chi_square == 0                # perfectly balanced split


def test_attribution_first_vs_last(con):
    a = q(con, "10_attribution.sql").set_index("channel")
    assert a.loc["paid_social", "first_touch_revenue"] == 1200 and a.loc["paid_social", "last_touch_revenue"] == 0
    assert a.loc["referral", "last_touch_revenue"] == 1200


def test_cart_abandonment(con):
    r = q(con, "12_cart_abandonment.sql")
    assert r["carts"].sum() == 2 and r.set_index("hour").loc[18, "abandonment_rate"] == 1.0


def test_every_query_runs(con):
    for f in sorted(SQL.glob("*.sql")):
        q(con, f.name)                          # no errors on the tiny dataset either
