# Proyecto ETL - In-nova Tech (DummyJSON API)

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
