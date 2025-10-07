import pandas as pd
from utils.login import get_json

def extract_all_carts(limit: int = 100) -> list:
    """
    Descarga todos los carritos con paginación (lista de dicts).
    Cada carrito tiene una lista de productos.
    1 carrito = N productos (items)
    Por eso, luego hay que aplanar a nivel de ÍTEM.
    1 carrito = 1 fila en el JSON original
    """
    items = []
    skip = 0
    while True:
        data = get_json("carts", params={"limit": limit, "skip": skip})
        batch = data.get("carts", [])
        if not batch:
            break
        items.extend(batch)
        skip += limit
        if skip >= data.get("total", len(items)):
            break
    return items

def carts_to_items_df(carts: list) -> pd.DataFrame:
    """
    Aplana cada carrito a nivel de ÍTEM (una fila por producto dentro del carrito).
    """
    rows = []
    for c in carts:
        cart_id = c.get("id")
        user_id = c.get("userId")
        for p in c.get("products", []):
            rows.append({
                "cart_id": cart_id,
                "user_id": user_id,
                "product_id": p.get("id"),
                "title": p.get("title"),
                "price": p.get("price"),
                "quantity": p.get("quantity"),
                "discountPercentage": p.get("discountPercentage"),
                "total": p.get("total"),
                "discounted_total": p.get("discountedTotal"),
            })
    return pd.DataFrame(rows)

def fetch_all_cart_items(limit = 100) -> pd.DataFrame:
    return carts_to_items_df(extract_all_carts(limit=limit))