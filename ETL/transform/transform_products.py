import pandas as pd

def transform_products(df: pd.DataFrame) -> pd.DataFrame:
    #  Chequeo inicial del DataFrame
    # Si no es un DataFrame o esta vacio, retornar el mismo
    if not isinstance(df, pd.DataFrame) or df.empty:
        return df
    

    #  Tomar solo columnas claves que existan
    cols = ["id","title","description","price","discountPercentage","rating","stock","brand","category"]
    # Revisar que las columnas existan en el DataFrame
    cols = [c for c in cols if c in df.columns]
    df = df[cols].copy()

    # Renombrar columnas a español (nombres descriptivos)
    df.rename(columns={
        "id":"product_id", 
        "title":"titulo", 
        "description":"descripcion",
        "price":"precio", 
        "discountPercentage":"descuento_pct",
        "rating":"rating", 
        "stock":"stock",
        "brand":"marca",
        "category":"categoria"
    }, inplace=True)

    # Convertir las columnas numericas a tipo numerico.
    for c in ["precio","descuento_pct","rating","stock"]:
        if c in df.columns:
            df[c] = pd.to_numeric(df[c], errors="coerce")

    # Verificacion de Nulos o valores negativos, en las columnas numericas.
    # Precio
    if "precio" in df.columns:
        df = df[df["precio"].notna() & (df["precio"] > 0)].copy()
    # Descuento_pct
    if "descuento_pct" in df.columns:
        df["descuento_pct"] = df["descuento_pct"].fillna(0)
    
    # Verificacion en Columna categorica, en caso de valo nulo, aplicar valor "Sin categoría"
    if "categoria" in df.columns:
        df["categoria"] = df["categoria"].fillna("Sin categoría")
    else:
        df["categoria"] = "Sin categoría"

    # 6) Eliminar Duplicados de Productos por product_id 
    if "product_id" in df.columns:
        df = df.drop_duplicates(subset=["product_id"]).reset_index(drop=True)

    return df
