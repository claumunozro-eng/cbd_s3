-- Aplicando funciones de agrupación
-- Ejecutar con F5 en PRY2205_ACTIVIDAD_S3 después de poblar el esquema.
SET DEFINE ON

-- Caso 1. Una fila por tipo de propiedad.
-- El umbral se compara con la suma sin formato y debe superarse.
SELECT p.id_tipo_propiedad AS TIPO,
       COUNT(*) AS TOTAL_PROPIEDADES,
       TO_CHAR(MAX(p.valor_arriendo), 'FM$999G999G990',
               'NLS_NUMERIC_CHARACTERS = '',.''') AS MAX_ARRIENDO,
       TO_CHAR(ROUND(AVG(p.valor_arriendo)), 'FM$999G999G990',
               'NLS_NUMERIC_CHARACTERS = '',.''') AS PROMEDIO_ARRIENDO,
       TO_CHAR(MIN(p.valor_arriendo), 'FM$999G999G990',
               'NLS_NUMERIC_CHARACTERS = '',.''') AS MIN_ARRIENDO,
       CASE
           WHEN MAX(p.valor_arriendo) > 1000000 THEN 'PREMIUM'
           ELSE 'ESTÁNDAR'
       END AS CLASIFICACION,
       TO_CHAR(SUM(NVL(p.valor_gasto_comun, 0)), 'FM$999G999G999G990',
               'NLS_NUMERIC_CHARACTERS = '',.''') AS TOTAL_GASTOS_COMUNES
FROM propiedad p
GROUP BY p.id_tipo_propiedad
HAVING SUM(NVL(p.valor_gasto_comun, 0)) > &VALOR_TOTAL_GASTO_COMUN
ORDER BY SUM(NVL(p.valor_gasto_comun, 0)) DESC;

-- Caso 2. Ejecutivos de arriendo con más de cinco años de servicio.
-- La antigüedad mostrada usa años cumplidos. El filtro usa el aniversario.
SELECT e.nombre_empleado AS "Nombre Empleado",
       TO_CHAR(e.sueldo_emp, 'FM$999G999G990',
               'NLS_NUMERIC_CHARACTERS = '',.''') AS "Sueldo con Formato",
       CASE
           WHEN e.sueldo_emp > 2000000 THEN 'ALTO'
           ELSE 'MEDIO'
       END AS "Clasificación Sueldo",
       e.anios_antiguedad AS "Años Antigüedad",
       'Corresponde bono ' || LPAD(e.porcentaje_bono, 2) || '%: '
           || LPAD(TO_CHAR(ROUND(e.sueldo_emp * e.porcentaje_bono / 100),
                           'FM$999G999G990', 'NLS_NUMERIC_CHARACTERS = '',.'''), 11)
           AS BONO
FROM (
    SELECT d.nombre_empleado,
           d.sueldo_emp,
           d.anios_antiguedad,
           CASE
               WHEN d.anios_antiguedad >= 21 THEN 15
               WHEN d.anios_antiguedad >= 11 THEN 10
               ELSE 5
           END AS porcentaje_bono
    FROM (
        SELECT UPPER(TRIM(emp.nombre_emp) || ' ' || TRIM(emp.appaterno_emp))
                   AS nombre_empleado,
               emp.sueldo_emp,
               TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), TRUNC(emp.fecing_emp)) / 12)
                   AS anios_antiguedad
        FROM empleado emp
        WHERE emp.id_categoria_emp = 3
          AND emp.id_sucursal <> &CODIGO_SUCURSAL
          AND ADD_MONTHS(TRUNC(emp.fecing_emp), 60) < TRUNC(SYSDATE)
    ) d
) e
ORDER BY e.sueldo_emp DESC;

-- Caso 3. Se clasifica la renta individual antes de calcular el promedio.
-- Se usa el celular porque el teléfono fijo es obligatorio en el modelo.
SELECT c.clasificacion_renta AS CLASIFICACION_RENTA,
       COUNT(*) AS CANTIDAD_CLIENTES,
       TO_CHAR(ROUND(AVG(c.renta_cli)), 'FM$999G999G990',
               'NLS_NUMERIC_CHARACTERS = '',.''') AS RENTA_PROMEDIO,
       CASE
           WHEN COUNT(c.celular_cli) = 0 THEN 'Clientes Sin Teléfono'
           ELSE 'Clientes con Teléfono'
       END AS ESTADO_TELEFONO
FROM (
    SELECT cli.renta_cli,
           cli.celular_cli,
           CASE
               WHEN cli.renta_cli >= 1000000 THEN 'PREMIUM'
               WHEN cli.renta_cli >= 600000 THEN 'ALTA'
               WHEN cli.renta_cli >= 300000 THEN 'MEDIA'
               ELSE 'BAJA'
           END AS clasificacion_renta
    FROM cliente cli
) c
GROUP BY c.clasificacion_renta
HAVING AVG(c.renta_cli) > 200000;
