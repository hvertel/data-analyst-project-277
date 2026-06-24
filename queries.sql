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
-- ============================================================================
-- REPORTE 1: Clientes por grupo de edad
-- ============================================================================
/* Esta consulta clasifica a los clientes en tres categorías de edad (16-25, 
   26-40 y 40+) usando la estructura CASE WHEN, cuenta el total de personas 
   en cada grupo y los ordena de forma lógica.
*/
SELECT 
    CASE 
        WHEN age BETWEEN 16 AND 25 THEN '16–25'
        WHEN age BETWEEN 26 AND 40 THEN '26–40'
        WHEN age > 40 THEN '40+'
    END AS age_category,
    COUNT(customer_id) AS age_count
FROM customers
GROUP BY 
    CASE 
        WHEN age BETWEEN 16 AND 25 THEN '16–25'
        WHEN age BETWEEN 26 AND 40 THEN '26–40'
        WHEN age > 40 THEN '40+'
    END
ORDER BY 
    -- Orden personalizado para que aparezcan en secuencia cronológica de edad
    MIN(age) ASC;


-- ============================================================================
-- REPORTE 2: Clientes únicos e ingresos por mes
-- ============================================================================
/* Esta consulta agrupa las ventas por año y mes en formato 'YYYY-MM'. 
   Calcula la cantidad de clientes únicos (sin repetir) mediante COUNT(DISTINCT) 
   y la facturación total mensual acumulada redondeada hacia abajo.
*/
SELECT 
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales s
INNER JOIN products p 
    ON s.product_id = p.product_id
GROUP BY 
    TO_CHAR(s.sale_date, 'YYYY-MM')
ORDER BY 
    selling_month ASC;


-- ============================================================================
-- REPORTE 3: Clientes cuya primera compra fue en promoción (Precio = 0)
-- ============================================================================
/* Esta consulta utiliza una CTE y la función ROW_NUMBER() para ordenar todas 
   las compras de cada cliente cronológicamente. Luego, en la consulta externa, 
   filtra únicamente la primera compra (rn = 1) y verifica si ocurrió bajo 
   una promoción de precio cero.
*/
WITH ranked_purchases AS (
    SELECT 
        s.customer_id,
        TRIM(c.first_name || ' ' || c.last_name) AS customer,
        s.sale_date,
        TRIM(e.first_name || ' ' || e.last_name) AS seller,
        p.price,
        -- Numeramos las compras de cada cliente de la más antigua a la más reciente
        ROW_NUMBER() OVER(
            PARTITION BY s.customer_id 
            ORDER BY s.sale_date ASC, s.sales_id ASC
        ) AS rn
    FROM sales s
    INNER JOIN customers c 
        ON s.customer_id = c.customer_id
    INNER JOIN employees e 
        ON s.sales_person_id = e.employee_id
    INNER JOIN products p 
        ON s.product_id = p.product_id
)
SELECT 
    customer,
    sale_date,
    seller
FROM ranked_purchases
WHERE 
    rn = 1          -- Filtra para quedarse solo con la PRIMERA compra
    AND price = 0   -- Verifica que haya sido una promoción de precio cero
ORDER BY 
    customer_id ASC;
