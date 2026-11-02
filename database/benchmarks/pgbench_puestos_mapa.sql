SELECT codigo_puesto, posicion_fila, posicion_columna, estado_puesto, ancho_metros, largo_metros, es_zona_riesgo
FROM feria_core.puestos
WHERE id_sector = 'a0000000-0000-0000-0000-000000000001'::uuid
  AND estado_puesto = 'DISPONIBLE';
