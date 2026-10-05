import sys
import os

# Add Backend/apps/api to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "apps", "api")))

from app.core.database import SessionLocal
from app.seed.loader import seed_reference_data

def main():
    db = SessionLocal()
    try:
        counts = seed_reference_data(db)
        print(f"Reference data seed completed successfully: {counts}")
    finally:
        db.close()

if __name__ == "__main__":
    main()
