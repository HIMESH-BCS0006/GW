import os
import sys
import pytest
from starlette.testclient import TestClient
from sqlalchemy.orm import Session

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

from app.seed.loader import seed_all
from app.seed.day_generator import seed_walkthrough_data
from scripts.walkthrough import WalkthroughRunner


@pytest.fixture
def clean_seeded_db(db: Session):
    seed_all(db, force=True)
    seed_walkthrough_data(db, force=True)


def test_full_judge_walkthrough_e2e(client: TestClient, db: Session, clean_seeded_db):
    """Executes the full 12-step judge walkthrough against the test client and asserts 100% pass."""
    runner = WalkthroughRunner(client, "/api/v1")
    success = runner.run()
    assert success is True
    assert len(runner.results_table) == 12
    assert all(r["passed"] for r in runner.results_table)
