from app.models import Base, User, Tracker, PriceSnapshot, UrlJob


def test_all_tables_registered():
    names = set(Base.metadata.tables.keys())
    assert {"users", "trackers", "price_snapshots", "url_jobs"} <= names


def test_price_snapshot_composite_index():
    table = Base.metadata.tables["price_snapshots"]
    indexed_cols = {col.name for idx in table.indexes for col in idx.columns}
    assert "tracker_id" in indexed_cols
    assert "scraped_at" in indexed_cols
