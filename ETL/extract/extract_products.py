from utils.login import get_json
import pandas as pd


"""
Extrae todos los productos de la API y los devuelve como un DataFrame de pandas.
"""
def extract_products(limit=100) -> pd.DataFrame:
    """
    Descarga todos los productos con paginación (DataFrame).
    skip = cuántos productos "saltar" (no traer)
    limit = cuántos productos "traer" (máximo 100 por request)    
    batch = productos traidos en cada request
    items = lista acumulada de productos traidos
    El bucle while True sigue hasta que no haya más productos para traer.
    not bach rompe el bucle cuando no hay más productos para traer o si skip >= total: (N° productos en la pagina).
    """
    items = [] 
    skip = 0 
    while True:
        data = get_json("products", params={"limit": limit, "skip": skip})
        # almacena los productos traidos en la variable batch
        batch = data.get("products", [])
        #
        if not batch:
            break
        items.extend(batch)
        # incrementa del skip
        skip += limit
        if skip >= data.get("total", len(items)):
            break
    # convierte la lista de productos en un DataFrame de pandas y lo devuelve   
    return pd.json_normalize(items)