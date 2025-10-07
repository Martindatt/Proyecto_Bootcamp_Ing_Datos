import requests

BASE_URL = "https://dummyjson.com"

def get_json(endpoint: str, params: dict = None) -> dict:
    """
    Realiza una solicitud GET simple a la API y devuelve el JSON como dict.
    """
    url = f"{BASE_URL}/{endpoint}"
    try:
        response = requests.get(url, params=params,timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"❌ Error en {url}: {e}")
        raise