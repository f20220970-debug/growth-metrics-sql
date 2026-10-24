"""Load the CSVs into DuckDB and run every query in sql/, printing a preview and saving
each result to results/<name>.csv.

    python scripts/make_data.py    # generate the synthetic dataset (once)
    python run.py                  # run all 12 queries
    python run.py 08               # run one query (by number)
"""
import sys
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parent
TABLES = ["users", "touches", "events", "orders", "spend", "experiment"]
PARAMS = {"margin": 0.30}


def connect(data_dir=ROOT / "data"):
    con = duckdb.connect()
    for t in TABLES:
        f = data_dir / f"{t}.csv"
        if not f.exists():
            raise SystemExit(f"Missing {f}. Run: python scripts/make_data.py")
        con.execute(f"CREATE TABLE {t} AS SELECT * FROM read_csv_auto('{f.as_posix()}')")
    return con


def sql_text(path: Path) -> str:
    text = path.read_text()
    for k, v in PARAMS.items():
        text = text.replace("{" + k + "}", str(v))
    return text


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else None
    con = connect()
    (ROOT / "results").mkdir(exist_ok=True)
    for f in sorted((ROOT / "sql").glob("*.sql")):
        if only and not f.name.startswith(only):
            continue
        df = con.execute(sql_text(f)).df()
        df.to_csv(ROOT / "results" / f"{f.stem}.csv", index=False)
        print(f"\n=== {f.stem} ({len(df)} rows) ===")
        print(df.head(12).to_string(index=False))


if __name__ == "__main__":
    main()
