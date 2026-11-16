-- =====================================================================
-- Proyecto Retail · Pre-entrega Módulo 5
-- Script de análisis avanzado con CTEs, Window Functions y CASE WHEN
-- Autor: Joaquín Camisasca Benítez
-- Motor: PostgreSQL · Base: retail_project
--
-- Requisitos previos (en este orden):
--   1. retail_project.sql        (pre-entrega 2: clientes, productos, ventas)
--   2. pre-entrega-modulo4.sql   (pre-entrega 4: tabla categorias + más ventas)
--
-- Problema de negocio: el equipo comercial quiere un reporte mensual por
-- categoría que responda tres preguntas a la vez:
--   · ¿Qué categoría lideró cada mes?           → ranking del mes
--   · ¿Cómo viene creciendo cada categoría?     → ventas acumuladas
--   · ¿Este mes fue bueno o malo para la categoría, comparado con lo que
--     suele vender?                              → Exitoso / Bajo el promedio
-- =====================================================================

WITH
-- ---------------------------------------------------------------------
-- CTE 1 · ventas_mensuales
-- Lleva todas las ventas al mismo nivel de detalle: UNA fila por mes y
-- categoría. DATE_TRUNC('month', ...) normaliza cada fecha al primer día
-- de su mes (ej. 2026-05-20 → 2026-05-01), así todas las ventas de mayo
-- caen en el mismo grupo. Se unen ventas → productos → categorias para
-- obtener el nombre de la categoría de cada venta.
-- ---------------------------------------------------------------------
ventas_mensuales AS (
    SELECT
        DATE_TRUNC('month', v.fecha_venta)::DATE   AS mes,
        cat.nombre                                 AS categoria,
        SUM(v.cantidad * v.precio_unitario)        AS venta_total
    FROM ventas v
    JOIN productos  p   ON p.id_producto    = v.id_producto
    JOIN categorias cat ON cat.id_categoria = p.id_categoria
    GROUP BY DATE_TRUNC('month', v.fecha_venta)::DATE, cat.nombre
),

-- ---------------------------------------------------------------------
-- CTE 2 · metricas_ventana
-- Sobre la tabla mensual calcula métricas con funciones de ventana, que
-- agregan SIN colapsar filas (cada mes/categoría sigue siendo una fila):
--
--  · ranking_mes: RANK() con PARTITION BY mes → reinicia el ranking en
--    cada mes y ordena las categorías por venta, de mayor a menor. Si dos
--    categorías empatan, comparten puesto (y el siguiente se saltea).
--
--  · ventas_acumuladas (running total): SUM() con PARTITION BY categoria
--    y ORDER BY mes → suma la venta del mes más la de todos los meses
--    anteriores de esa categoría. Sin el ORDER BY, devolvería el total
--    general en todas las filas en lugar de la suma progresiva.
--
--  · promedio_categoria: AVG() con PARTITION BY categoria y SIN ORDER BY
--    → promedio histórico de venta mensual de la categoría (el mismo valor
--    en todas sus filas). Es la vara contra la que se compara cada mes.
-- ---------------------------------------------------------------------
metricas_ventana AS (
    SELECT
        mes,
        categoria,
        venta_total,
        RANK() OVER (
            PARTITION BY mes
            ORDER BY venta_total DESC
        )                                          AS ranking_mes,
        SUM(venta_total) OVER (
            PARTITION BY categoria
            ORDER BY mes
        )                                          AS ventas_acumuladas,
        AVG(venta_total) OVER (
            PARTITION BY categoria
        )                                          AS promedio_categoria
    FROM ventas_mensuales
)

-- ---------------------------------------------------------------------
-- SELECT final · reporte
-- Arma las cinco columnas pedidas y agrega la lógica de negocio con
-- CASE WHEN: si la venta del mes iguala o supera el promedio histórico de
-- su categoría, el mes fue "Exitoso"; si no, quedó "Bajo el promedio".
-- Todas las métricas están a nivel mes/categoría (misma granularidad), así
-- que la comparación es válida.
-- ---------------------------------------------------------------------
SELECT
    TO_CHAR(mes, 'YYYY-MM')                        AS mes,
    categoria,
    venta_total,
    ranking_mes,
    ventas_acumuladas,
    CASE
        WHEN venta_total >= promedio_categoria THEN 'Exitoso'
        ELSE 'Bajo el promedio'
    END                                            AS comparativa
FROM metricas_ventana
ORDER BY mes, ranking_mes;
