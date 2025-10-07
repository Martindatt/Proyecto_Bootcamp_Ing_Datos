import pandas as pd
from utils.login import get_json  # tu helper simple

def extract_users(limit: int = 100) -> pd.DataFrame:
    """
    Descarga todos los usuarios (paginado limit/skip) y devuelve un DataFrame crudo.
    """
    items = []
    skip = 0
    while True:
        data = get_json("users", params={"limit": limit, "skip": skip})
        batch = data.get("users", [])
        if not batch:
            break
        items.extend(batch)
        skip += limit
        if skip >= data.get("total", len(items)):
            break
    return pd.json_normalize(items)