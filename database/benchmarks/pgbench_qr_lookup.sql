SELECT c.id_autorizacion, c.estado_autorizacion, c.fecha_emision, p.codigo_puesto, com.nombres, com.apellidos, com.dni, g.nombre_giro
FROM feria_core.credenciales_autorizacion c
JOIN feria_core.postulaciones_reservas r ON r.id_reserva = c.id_reserva
JOIN feria_core.puestos p ON p.id_puesto = r.id_puesto
JOIN auth_acl.comerciante_perfil com ON com.id_comerciante = r.id_comerciante
JOIN feria_core.giros_comerciales g ON g.id_giro = r.id_giro
WHERE c.codigo_qr_identificador = 'b0000000-0000-0000-0000-000000000001'::uuid;
