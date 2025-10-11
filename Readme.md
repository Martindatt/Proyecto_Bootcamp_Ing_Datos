# 🚀 Proyecto ETL - In-nova Tech (DummyJSON API)

Este proyecto realiza la extracción, limpieza y guardado de datos provenientes de la API pública de DummyJSON, simulando un pipeline real de e-commerce para la empresa ficticia **In-nova Tech**.

### 🧩 APIs utilizadas:

- `/products` → catálogo de productos
- `/carts` → carritos de compras (nivel ítem)
- `/users` → clientes

---

## ✅ ¿Qué se limpió y por qué?

### 🛍️ Productos (`/products`)

**Objetivo:** garantizar que todos los productos sean válidos para análisis de ventas.

**Limpiezas aplicadas:**

- Se seleccionaron las columnas relevantes (`id`, `title`, `price`, `discountPercentage`, etc.).
- Se convirtieron a tipos numéricos (`precio`, `stock`, `rating`, `descuento_pct`) para evitar errores de cálculo.
- Se eliminaron productos con:
  - `precio` nulo o menor a 0.
- Se imputó `descuento_pct` faltante con `0`.
- Se completó `categoria` con `"Sin categoría"` cuando venía vacía.
- Se eliminaron duplicados por `product_id`.

---

### 🛒 Carritos (`/carts`)

**Objetivo:** obtener una tabla detallada por producto en el carrito, con cantidades y totales.

**Limpiezas aplicadas:**

- Se aplanaron los carritos para obtener una fila por producto (`cart_id`, `product_id`, `cantidad`, etc.).
- Se eliminaron líneas con `cantidad <= 0`.
- Se imputó `descuento_pct` faltante con `0`.
- Se redondearon los campos `total` y `total_con_descuento` a 2 decimales.
- Se eliminaron duplicados por combinación (`cart_id`, `product_id`) para evitar líneas repetidas exactas en un mismo carrito.

---

### 👤 Usuarios (`/users`)

**Objetivo:** conservar usuarios válidos para análisis de comportamiento y vinculación con carritos.

**Limpiezas aplicadas:**

- Se seleccionaron campos clave (`id`, `nombre`, `apellido`, `email`, `ciudad`, etc.).
- Se normalizó el `email` (`lower`, sin espacios).
- Se agregó una columna `email_valido`:
  - `True` si el email existe y no está vacío.
  - `False` si falta o está en blanco.
- Se conservaron todos los usuarios (incluso los sin email), para trazabilidad.
- Se eliminaron duplicados por `user_id` y por `email`.

---

## 📁 Archivos generados (outputs/)

- `products_clean.csv`
- `carts_clean.csv`
- `users_clean.csv`

---

## 🧮 Transformaciones SQL con DuckDB

En esta fase se consolidó todo el pipeline de datos usando **DuckDB** como motor local para ejecutar consultas.
El objetivo fue unir las tablas principales (usuarios, carritos y productos), calcular métricas reales de negocio e iniciar la preparación del modelo analítico.

Se creó un script único `transformaciones.sql` que:

1. Lee los CSV limpios (productos, usuarios y carritos)
2. Construye la tabla de hechos `fact_ventas`

   - Unen los hechos de compras -Carts- con Productos y Clientes.
   - Se obtienen metricas relevantes para un analisis de ventas.

3. Genera el agregado `ventas_por_categoria`

   - Se agrupan las ventas por categoria de productos.
   - Se incluyen metricas para un analisis a nivel venta/categoria de producto.

4. Exporta ambas tablas a la carpeta `outputs/`

## 📁 Archivos generados (outputs/)

- `fact_ventas.csv`
- `ventas_por_categoria.csv`

## 🛠️ Tecnologías utilizadas

- **Python** → extracción y limpieza con `requests` y `pandas`
- **DuckDB (SQL)** → modelado de hechos y agregaciones
- **Pandas** → normalización y validaciones
- **CSV / ETL modular** → outputs ordenados por fase

## 🧠 Qué aprendí

- A utilizar **DuckDB** como motor analítico local sobre archivos CSV.
- A modelar una **tabla de hechos** e integrar dimensiones (productos y usuarios).
- A calcular métricas reales de negocio: ingresos, descuentos y unidades vendidas.
- A estructurar un **flujo ETL SQL modular**, reproducible y automatizado desde Python.
- A documentar y versionar un pipeline siguiendo **buenas prácticas de ingeniería de datos**.

## ⚙️ Ejecutar todo el pipeline SQL

```bash
python3 scripts_sql/run_sql.py
```
