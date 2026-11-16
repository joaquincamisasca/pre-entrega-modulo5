# Análisis avanzado de ventas con Window Functions (PostgreSQL)

**Autor:** Joaquín Camisasca Benítez
**Curso:** SQL con PostgreSQL · Pre-entrega Módulo 5

## Contenido

| Archivo | Descripción |
|---|---|
| `preentrega_analisis_avanzado.sql` | Reporte mensual por categoría armado con CTEs, funciones de ventana y `CASE WHEN` |

## Qué resuelve

El área comercial necesita un reporte que muestre, para cada mes y categoría:

| Columna | Qué muestra | Cómo se calcula |
|---|---|---|
| `mes`, `categoria` | Identificadores | `DATE_TRUNC('month', fecha_venta)` y la tabla `categorias` |
| `venta_total` | Venta total del mes y la categoría | `SUM(cantidad * precio_unitario)` |
| `ranking_mes` | Puesto de la categoría dentro del mes | `RANK() OVER (PARTITION BY mes ORDER BY venta_total DESC)` |
| `ventas_acumuladas` | Venta acumulada de la categoría mes a mes | `SUM() OVER (PARTITION BY categoria ORDER BY mes)` |
| `comparativa` | Si el mes superó o no el promedio histórico de la categoría | `CASE WHEN` → `Exitoso` / `Bajo el promedio` |

### Estructura de la consulta
1. **CTE `ventas_mensuales`:** une `ventas`, `productos` y `categorias`, y agrupa las ventas en una fila por mes y categoría.
2. **CTE `metricas_ventana`:** sobre esa tabla calcula el ranking del mes, el running total por categoría y el promedio histórico de cada categoría, sin perder el detalle de las filas.
3. **SELECT final:** con un `CASE WHEN` compara cada mes contra el promedio de su categoría y lo etiqueta como `Exitoso` o `Bajo el promedio`.

## Cómo ejecutarlo

La consulta usa la base `retail_project` de las entregas anteriores. Antes hay que ejecutar, en este orden:

1. `retail_project.sql` (Pre-entrega 2): crea la base y las tablas `clientes`, `productos` y `ventas`.
   Repositorio: https://github.com/joaquincamisasca/retail-project-sql
2. `pre-entrega-modulo4.sql` (Pre-entrega 4): crea la tabla `categorias` y carga más ventas.
   Repositorio: https://github.com/joaquincamisasca/pre-entrega-modulo4
3. `preentrega_analisis_avanzado.sql`: abrilo en pgAdmin o DBeaver conectado a `retail_project` y ejecutalo, o desde la terminal:
   ```bash
   psql -U postgres -d retail_project -f preentrega_analisis_avanzado.sql
   ```

Con los datos de las entregas anteriores, el reporte devuelve 13 filas, de abril a septiembre de 2026. Por ejemplo, Deportes lidera agosto y septiembre, y en los dos meses queda como `Exitoso`.
