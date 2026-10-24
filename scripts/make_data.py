"""Generate a realistic SYNTHETIC dataset for a quick-commerce-style app (90 days, ~8,000 users).

Tables: users, touches (marketing touchpoints), events (app funnel), orders, spend (daily
marketing spend by channel), experiment (A/B test assignment). Patterns are built in on
purpose (e.g. referral users retain better, variant B converts slightly better) so every
query has something to find. The numbers are made up; the SQL is what matters.
"""
import csv
import random
from datetime import date, datetime, timedelta
from pathlib import Path

random.seed(11)
OUT = Path(__file__).resolve().parents[1] / "data"
OUT.mkdir(exist_ok=True)
START, DAYS = date(2026, 7, 1), 90
CHANNELS = {"paid_social": (0.35, 0.55), "search": (0.25, 0.70), "referral": (0.20, 0.85), "organic": (0.20, 0.75)}
CPI = {"paid_social": 260, "search": 340, "referral": 150, "organic": 0}   # cost per signup, for spend
CITIES = ["Bengaluru", "Mumbai", "Delhi", "Hyderabad"]

users, touches, events, orders, spend, exp = [], [], [], [], [], []
oid = 0
for uid in range(1, 8001):
    ch = random.choices(list(CHANNELS), [w for w, _ in CHANNELS.values()])[0]
    quality = CHANNELS[ch][1]
    signup = START + timedelta(days=random.randint(0, DAYS - 1))
    users.append([uid, signup.isoformat(), ch, random.choice(CITIES)])
    # marketing touches before signup: first touch may differ from last touch
    # paid social often starts journeys that other channels finish (shows up in attribution)
    first = ("paid_social" if random.random() < 0.6 else random.choice(list(CHANNELS))) if random.random() < 0.40 else ch
    touches.append([uid, (datetime.combine(signup, datetime.min.time()) - timedelta(days=random.randint(1, 6))).isoformat(), first])
    touches.append([uid, (datetime.combine(signup, datetime.min.time()) - timedelta(hours=random.randint(1, 20))).isoformat(), ch])
    variant = random.choice(["A", "B"]) if random.random() < 0.985 else "A"   # tiny imbalance on purpose
    exp.append([uid, variant, signup.isoformat()])
    lift = 1.12 if variant == "B" else 1.0
    day, active_p = signup, 0.55 + 0.25 * quality
    if random.random() < 0.35 - 0.2 * quality:      # many installs never come back after day 0
        active_p = 0.0
    while day < START + timedelta(days=DAYS):
        if day == signup or random.random() < active_p:
            t = datetime.combine(day, datetime.min.time()) + timedelta(hours=random.choice([8, 9, 12, 18, 19, 20, 21]), minutes=random.randint(0, 59))
            events.append([uid, t.isoformat(), "app_open"])
            if random.random() < 0.60:
                events.append([uid, (t + timedelta(minutes=1)).isoformat(), "view_product"])
                if random.random() < 0.40:
                    events.append([uid, (t + timedelta(minutes=3)).isoformat(), "add_to_cart"])
                    if random.random() < 0.60:
                        events.append([uid, (t + timedelta(minutes=5)).isoformat(), "checkout"])
                        if random.random() < 0.75 * quality * lift:
                            oid += 1
                            amt = round(random.lognormvariate(6.3, 0.45), 2)
                            events.append([uid, (t + timedelta(minutes=6)).isoformat(), "purchase"])
                            orders.append([oid, uid, (t + timedelta(minutes=6)).isoformat(), amt])
        active_p = max(0.02, active_p * (0.86 + 0.10 * quality))   # habit decays; better channels decay slower
        day += timedelta(days=1)

for d in range(DAYS):
    day = START + timedelta(days=d)
    for ch, cpi in CPI.items():
        n = sum(1 for u in users if u[1] == day.isoformat() and u[2] == ch)
        if cpi:
            spend.append([day.isoformat(), ch, round(n * cpi * random.uniform(0.85, 1.15), 2)])

def write(name, header, rows):
    with open(OUT / f"{name}.csv", "w", newline="") as f:
        w = csv.writer(f); w.writerow(header); w.writerows(rows)

write("users", ["user_id", "signup_date", "channel", "city"], users)
write("touches", ["user_id", "touch_time", "channel"], touches)
write("events", ["user_id", "event_time", "event_name"], events)
write("orders", ["order_id", "user_id", "order_time", "amount"], orders)
write("spend", ["spend_date", "channel", "amount"], spend)
write("experiment", ["user_id", "variant", "assigned_date"], exp)
print(f"users {len(users):,} · events {len(events):,} · orders {len(orders):,} · spend rows {len(spend):,}")
