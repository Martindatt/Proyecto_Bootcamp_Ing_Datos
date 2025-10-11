import duckdb

# Consultar los 3 CSVs limpios desde la carpeta outputs y mostrar las primeras 3 filas de cada uno.

print("Leyendo products_clean.csv:")
print(duckdb.sql("SELECT * FROM read_csv_auto ('outputs/products_clean.csv', HEADER=TRUE) LIMIT 3;").df())

print("\nLeyendo carts_clean.csv:")
print(duckdb.sql("SELECT * FROM read_csv_auto('outputs/carts_clean.csv', HEADER=TRUE) LIMIT 3;").df())

print("\nLeyendo users_clean.csv:")
print(duckdb.sql("SELECT * FROM read_csv_auto('outputs/users_clean.csv', HEADER=TRUE) LIMIT 3;").df())