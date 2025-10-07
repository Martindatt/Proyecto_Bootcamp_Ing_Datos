import pandas as pd

def transform_cart_items(df: pd.DataFrame) -> pd.DataFrame:
    """
    Limpieza mínima para carts a nivel ítem.
    - Renombra columnas
    - Convierte numéricos
    - Cantidad > 0
    - descuento faltante a 0 
    - Quita duplicados por (cart_id, product_id), por si existen productos duplicados en el mismo carrito
    """
    if not isinstance(df, pd.DataFrame) or df.empty:
        return df if isinstance(df, pd.DataFrame) else pd.DataFrame()

    # Selección de columnas y renombre
    cols = [
        "cart_id","user_id","product_id","title",
        "price","quantity","discountPercentage",
        "total","discounted_total"
    ]
    cols = [c for c in cols if c in df.columns]
    df_copy = df[cols].copy()

    df_copy.rename(columns={
        "title": "titulo",
        "price": "precio",
        "quantity": "cantidad",
        "discountPercentage": "descuento_pct",
        "discounted_total": "total_con_descuento"
    }, inplace=True)

    # Columnas Numericas a tipo numérico
    for c in ["precio","cantidad","descuento_pct","total","total_con_descuento"]:
        if c in df_copy.columns:
            df_copy[c] = pd.to_numeric(df_copy[c], errors="coerce")
    
    # Redondeo de totales a 2 decimales
    if "total" in df_copy.columns:
        df_copy["total"] = df_copy["total"].round(2)
    if "total_con_descuento" in df_copy.columns:
        df_copy["total_con_descuento"] = df_copy["total_con_descuento"].round(2)

    # cantidad > 0
    if "cantidad" in df_copy.columns:
        df_copy = df_copy[df_copy["cantidad"].notna() & (df_copy["cantidad"] > 0)].copy()

    # Descuento faltante igualar a 0
    if "descuento_pct" in df_copy.columns:
        df_copy["descuento_pct"] = df_copy["descuento_pct"].fillna(0)
    else:
        df_copy["descuento_pct"] = 0

    #  Duplicados por (cart_id, product_id)
    if set(["cart_id","product_id"]).issubset(df_copy.columns):
        df_copy = df_copy.drop_duplicates(subset=["cart_id","product_id"]).reset_index(drop=True)

    return df_copy