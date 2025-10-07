import logging
# Configuracion de Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


# ETL PRODUCTOS
from ETL.extract.extract_products import extract_products
from ETL.transform.transform_products import transform_products

#ETL CARRITOS
from ETL.extract.extract_carts import extract_all_carts,carts_to_items_df
from ETL.transform.transform_carts import transform_cart_items

#ETL USERS
from ETL.extract.extract_users import extract_users
from ETL.transform.transform_users import transform_users

from utils.save_csv import guardar_csv

def main():
    logger.info("Iniciando ETL de API - Productos")
    
    df_raw = extract_products()
    logger.info(f"- Datos Crudos: {df_raw.shape}")

    df_clean = transform_products(df_raw)
    logger.info(f"- Datos Limpios: {df_clean.shape}")

    # Guardar CSV usando tu utils.io
    guardar_csv(df_clean, "outputs/products_clean.csv")
    
    logger.info("ETL de API - Productos (Finalizado).\n")
    
    logger.info("Iniciando ETL de API - Carts")

    carts = extract_all_carts()
    df_carts_raw = carts_to_items_df(carts)
    logger.info(f"- Datos Crudos: {df_carts_raw.shape}")

    df_cart_clean = transform_cart_items(df_carts_raw)
    logger.info(f"- Datos Limpios: {df_cart_clean.shape}")

    guardar_csv(df_cart_clean, "outputs/carts_clean.csv")

    logger.info("ETL de API - Carts (Finalizado).\n")
    
    logger.info("Iniciando ETL de API - Usuarios")
    df_users_raw = extract_users()
    logger.info(f"- Datos Crudos: {df_users_raw.shape}")
    
    df_users_clean = transform_users(df_users_raw)
    logger.info(f"- Datos Limpios: {df_users_clean.shape}")  

    guardar_csv(df_users_clean, "outputs/users_clean.csv")

    logger.info("ETL de API - Usuarios (Finalizado).\n")

if __name__ == "__main__":
    main()

