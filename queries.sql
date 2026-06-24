select count (*) as customers_count
from customers;
/* 
   Esta consulta cuenta todos los registros que hay en la tabla "customers y devuelve ese valor
*/
-- Reporte 1: Los 10 vendedores con más ingresos
/* Esta consulta calcula el rendimiento del Top 10 de vendedores. 
   Une el nombre y apellido en la columna 'seller', cuenta las transacciones 
   en 'operations' y calcula el ingreso total en 'income', redondeado hacia abajo.
*/
SELECT 
    (e.first_name || ' ' || e.last_name) AS seller,
    COUNT(s.sales_id) AS operations,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales s
INNER JOIN employees e 
    ON s.sales_person_id = e.employee_id
INNER JOIN products p 
    ON s.product_id = p.product_id
GROUP BY 
    e.employee_id, 
    e.first_name, 
    e.last_name
ORDER BY 
    income DESC
LIMIT 10;
-- ============================================================================
-- REPORTE 2: Vendedores con ingresos por debajo del promedio
-- ============================================================================
/* Esta consulta calcula el promedio de ingresos por venta de cada empleado
   y filtra para mostrar solo a aquellos que están por debajo del promedio 
   general de ventas de toda la empresa. Los ordena de menor a mayor.
*/
SELECT 
    TRIM(e.first_name || ' ' || e.last_name) AS seller,
    FLOOR(AVG(s.quantity * p.price)) AS average_income
FROM sales s
INNER JOIN employees e 
    ON s.sales_person_id = e.employee_id
INNER JOIN products p 
    ON s.product_id = p.product_id
GROUP BY 
    e.employee_id, 
    e.first_name, 
    e.last_name
HAVING 
    AVG(s.quantity * p.price) < (
        -- Subconsulta: Calcula el promedio general de ingresos por venta de toda la empresa
        SELECT AVG(s2.quantity * p2.price) 
        FROM sales s2
        INNER JOIN products p2 ON s2.product_id = p2.product_id
    )
ORDER BY 
    average_income ASC;

-- ============================================================================
-- REPORTE 3: Ingresos por vendedor y día de la semana
-- ============================================================================
/* Esta consulta desglosa los ingresos totales de cada vendedor según el día 
   de la semana. Convierte la fecha al nombre del día en inglés, en minúsculas 
   y limpia los espacios en blanco. Ordena por día (DOW) y luego por nombre.
*/
SELECT 
    TRIM(e.first_name || ' ' || e.last_name) AS seller,
    TRIM(LOWER(TO_CHAR(s.sale_date, 'Day'))) AS day_of_week,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales s
INNER JOIN employees e 
    ON s.sales_person_id = e.employee_id
INNER JOIN products p 
    ON s.product_id = p.product_id
GROUP BY 
    e.employee_id, 
    e.first_name, 
    e.last_name,
    EXTRACT(DOW FROM s.sale_date),
    TO_CHAR(s.sale_date, 'Day')
ORDER BY 
    EXTRACT(DOW FROM s.sale_date) ASC,
    seller ASC;
