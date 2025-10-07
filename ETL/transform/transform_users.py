import pandas as pd

def transform_users(df: pd.DataFrame) -> pd.DataFrame:
    """
    Limpieza mínima para users:
    - Selección y renombre de columnas útiles  
    - Tipos: edad (num), fecha_nacimiento (datetime)
    - Normaliza email (lower/strip) y descarta si falta
    - Quita duplicados por user_id y por email
    """
    if not isinstance(df, pd.DataFrame) or df.empty:
        return df if isinstance(df, pd.DataFrame) else pd.DataFrame()

    # Seleccion de Columnas útiles a mantener
    cols = [
        "id",
        "firstName",
        "lastName",
        "email",
        "gender",
        "age",
        "phone",
        "username",
        "birthDate",
        "address.city",
        "address.state",
        "address.postalCode",
        "address.address"
    ]
    cols = [c for c in cols if c in df.columns]
    df_copy = df[cols].copy()

    # Renombrando las columnas
    df_copy.rename(columns={
        "id": "user_id",
        "firstName": "nombre",
        "lastName": "apellido",
        "email": "email",
        "gender": "genero",
        "age": "edad",
        "phone": "telefono",
        "username": "usuario",
        "birthDate": "fecha_nacimiento",
        "address.city": "ciudad",
        "address.state": "provincia",
        "address.postalCode": "cp",
        "address.address": "direccion",
    }, inplace=True)

    # Tipos de datos
    if "edad" in df_copy.columns:
        df_copy["edad"] = pd.to_numeric(df_copy["edad"], errors="coerce")
    if "fecha_nacimiento" in df_copy.columns:
        df_copy["fecha_nacimiento"] = pd.to_datetime(df_copy["fecha_nacimiento"], errors="coerce")

    # Normalizacion y Verificacion de email (Check de validez en campo email_valido)
    if "email" in df_copy.columns:
        df_copy["email"] = df_copy["email"].astype(str).str.strip().str.lower()
        # Guardar usuarios sin email ("email valido") para futuras referencias
        df_copy["email_valido"] = df_copy["email"].notna() & (df_copy["email"].str.len() > 0)

    # Check de Duplicados
    if "user_id" in df_copy.columns:
        df_copy = df_copy.drop_duplicates(subset=["user_id"])
    if "email" in df_copy.columns:
        df_copy = df_copy.drop_duplicates(subset=["email"], keep="first")

    return df_copy.reset_index(drop=True)