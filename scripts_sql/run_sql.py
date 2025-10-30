# Scripts para correr sentencias SQL usando DuckDB

import duckdb
import os

"""
Ejecuta un archivo SQL usando DuckDB y devuelve el resultado.
"""
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SQL_DIR = os.path.join(BASE_DIR, "..", "sql")

""" Conexión a DuckDB """
con= duckdb.connect()

""" Función para ejecutar un script SQL desde un archivo para mostrar el resultado"""
def run_sql_script(sql_file, show_result=False):
    path = os.path.join(SQL_DIR, sql_file)
    with open(path, 'r',encoding="utf-8") as file:
        sql_script = file.read()
    result=con.execute(sql_script)
    print(f"Ejecutado: {sql_file}")
    """ Lectura de los archivos SQL desde VsCode y mostrar el resultado del ultimo SELECT"""
    if show_result:
        try:
            print(result.fetchdf())
        except Exception:
            pass
    """ Si la palalbra 'export' está en el nombre del archivo, muestra mensaje de exportación """
    if "export" in sql_file.lower() or "transfomaciones" in sql_file.lower():
        print("Exportación finalizada correctamente:")
        print(" -> outputs/gold/fact_ventas.csv\n")
        print(" -> outputs/gold/ventas_por_categoria.csv\n")

"""Ejecutar el script completo"""
run_sql_script("transformaciones.sql")

""" Ejecutar los scripts SQL en orden """
#run_sql_script("#0_fuentes_csv.sql", show_result=True)
#run_sql_script("#1_fact_ventas.sql", show_result=True)
#run_sql_script("#2_ventas_categoria.sql", show_result=True)
#run_sql_script("#3_export_csv.sql") # Exporta outputs generados


print("Proceso finalizado.")