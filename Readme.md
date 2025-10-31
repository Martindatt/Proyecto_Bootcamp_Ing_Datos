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

## 📁 Archivos generados (outputs/silver)

- `products_clean.csv`
- `carts_clean.csv`
- `users_clean.csv`

---

## 🧮 Transformaciones SQL con DuckDB

En esta fase se consolidó todo el pipeline de datos usando **DuckDB** como motor local para ejecutar consultas.
El objetivo fue unir las tablas principales (usuarios, carritos y productos), calcular métricas reales de negocio e iniciar la preparación del modelo analítico.

Se creó un script único `transformaciones.sql` que:

1. Carga de fuentes limpias (silver/) como vistas (v_products, v_carts, v_users).

2. Validación de integridad referencial (FKs):

- Detecta carritos con product_id o user_id inexistentes.
- Exporta auditorías (fk_prod_missing.csv, fk_user_missing.csv).

3. Creación de la tabla de hechos `fact_ventas`:

- Solo incluye filas con FKs válidas.
- Calcula métricas de negocio: ingreso_bruto, ingreso_neto, descuento_importe.

4. Generación de la tabla analítica `ventas_por_categoria`:

- Agrega métricas por categoría.
- Incluye análisis adicional con CTEs:
  - % de participación por categoría.
  - Cantidad y porcentaje de productos sobre el promedio de su categoría.

5. 📁 Export de resultados (gold/):

- `fact_ventas.csv`
- `ventas_por_categoria.csv`

6. 📁 Export de auditorías (auditoria/):

- Reportes de FKs faltantes y conteos de control.

--- 

## 🧱 Modelo Estrella - Datawharehouse

En esta fase se implementó el modelo de datos analítico bajo un esquema estrella, que permite analizar métricas de ventas desde distintas perspectivas: producto, cliente y tiempo.

El script `create_schema.sql` crea la capa DW (Data Warehouse) dentro del archivo innova_tech_dw.duckdb, a partir de las tablas generadas en la etapa anterior.

## 📊 Tablas creadas

1️⃣ Dimensiones

- **dim_usuario**
Contiene información descriptiva de cada cliente:
user_id, nombre, apellido, email, ciudad, provincia, cp, direccion.

- **dim_producto**
Describe los productos y su clasificación:
product_id, nombre_producto, categoria, marca.

- **dim_fecha**
Estructura de calendario para análisis temporal:
fecha_id, anio, mes, nombre_mes, trimestre, dia, dia_semana.
Los registros se generan automáticamente a partir de las fechas presentes en fact_ventas_dw.

2️⃣ Tabla de Hechos

**fact_ventas_dw**
Registra cada línea de venta (nivel ítem de carrito) y enlaza con las dimensiones.
Métricas calculadas:

cantidad

precio_unitario

ingreso_bruto

descuento_importe

ingreso_neto

descuento_pct

---

## 🔗 Relaciones

       dim_usuario          dim_producto
       (user_id PK)         (product_id PK)
             │                    │
             └──────┬──────────────┘
                    ▼
              fact_ventas_dw
                     │
                     ▼
                dim_fecha


---

## 📈 Métricas posibles

- Ventas totales por mes / trimestre / año

- Ingresos brutos / netos por categoría o marca

- Top usuarios y productos más vendidos

- Ticket promedio (ingreso_neto / cantidad)

- % de descuento aplicado por periodo o categoría

- Comparativos YoY / QoQ (año contra año, trimestre contra trimestre)


## 🛠️ Tecnologías utilizadas

- **Python** → extracción y limpieza de APIs con `requests` y `pandas`.
- **DuckDB (SQL)** → modelado analítico y transformaciones.
- **Pandas** → normalización y validaciones.
- **Logging + Audtioría FK** → validación de integridad previa.
- **CSV / ETL modular** → outputs ordenados por fase y separación clara de capas de datos.

## 🧠 Qué aprendí

- A estructurar un **pipeline ETL** completo y modular, desde la extracción hasta la capa analítica.
- A utilizar **DuckDB** como motor SQL embebido para procesamiento local de datos.
- A aplicar **validaciones FK** antes de generar tablas de hechos.
- A usar **CTEs y funciones VIEW** para cálculos analíticos (% participación, productos sobre promedio).
- A organizar la información bajo una **arquitectura Silver / Gold / Auditoría**.
- A documentar y versionar un pipeline siguiendo **buenas prácticas de ingeniería de datos**.

## ⚙️ Ejecutar todo el pipeline SQL

```bash
python3 scripts_sql/run_sql.py
```
