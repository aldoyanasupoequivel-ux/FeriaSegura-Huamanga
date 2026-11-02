-- ==============================================================================
-- FERIA SEGURA HUAMANGA (FeriaSegura)
-- Migración 007: Semilla de Datos Maestros
-- ==============================================================================

-- 1. Roles del Sistema
INSERT INTO auth_acl.roles (nombre_rol, descripcion) VALUES
('ADMINISTRADOR_MUNICIPAL', 'Gestión integral de ferias, zonificación urbana, catastro de puestos y asignación de roles'),
('COMERCIANTE', 'Postulación, consulta de cuadrícula, reserva de puesto, declaración eléctrica y pagos TUPA'),
('ENCARGADO_TESORERIA', 'Revisión y validación de vouchers de pago TUPA y aprobación formal de solicitudes'),
('INSPECTOR_DEFENSA_CIVIL', 'Monitoreo de seguridad eléctrica, carga por sector e inspección de puestos en zonas de riesgo'),
('FISCALIZADOR_MUNICIPAL', 'Inspección en campo mediante escaneo de códigos QR y levantamiento de actas de infracción')
ON CONFLICT (nombre_rol) DO NOTHING;

-- 2. Catálogo de Permisos Atómicos
INSERT INTO auth_acl.permisos (codigo_permiso, modulo, descripcion) VALUES
-- Módulo Catastro y Ferias
('FERIA_CREAR', 'CATASTRO', 'Permite crear y registrar ferias temporales'),
('FERIA_EDITAR', 'CATASTRO', 'Permite actualizar datos generales de ferias'),
('SECTOR_REGISTRAR', 'CATASTRO', 'Permite delimitar sectores y vías'),
('PUESTO_CREAR', 'CATASTRO', 'Permite registrar y numerar puestos comerciales'),
('PUESTO_BLOQUEAR_RIESGO', 'CATASTRO', 'Permite bloquear puestos en zonas de riesgo (hidrantes, salidas)'),
-- Módulo Puestos y Reservas
('PUESTO_CONSULTAR_MAPA', 'RESERVAS', 'Permite visualizar la cuadrícula y estado de los puestos'),
('PUESTO_RESERVAR', 'RESERVAS', 'Permite postular y reservar un puesto disponible'),
-- Módulo Seguridad Eléctrica
('ELECTRICO_DECLARAR', 'SEGURIDAD_ELECTRICA', 'Permite declarar artefactos eléctricos para un puesto'),
('ELECTRICO_MONITOREAR', 'SEGURIDAD_ELECTRICA', 'Permite monitorear la demanda acumulada en kW de los sectores'),
-- Módulo Pagos y Formalización
('PAGO_ADJUNTAR_COMPROBANTE', 'PAGOS', 'Permite cargar comprobante de pago de tasa TUPA'),
('PAGO_VALIDAR_TESORERIA', 'PAGOS', 'Permite al encargado de tesorería validar o rechazar pagos'),
('CREDENTIAL_DESCARGAR', 'FORMALIZACION', 'Permite descargar la Ficha Municipal con QR firmado'),
-- Módulo Fiscalización
('QR_ESCANEAR_VERIFICAR', 'FISCALIZACION', 'Permite escanear y validar credenciales QR en campo'),
('ACTA_INFRACCION_REGISTRAR', 'FISCALIZACION', 'Permite levantar actas de infracción con evidencia fotográfica'),
('ACTA_INFRACCION_ANULAR', 'FISCALIZACION', 'Permite anular un acta de infracción fundamentada'),
-- Módulo Seguridad y Usuarios
('USUARIO_ASIGNAR_ROL', 'SEGURIDAD', 'Permite al administrador municipal asignar roles a usuarios internos'),
('AUDITORIA_CONSULTAR', 'SEGURIDAD', 'Permite consultar la bitácora inmutable de eventos críticos')
ON CONFLICT (codigo_permiso) DO NOTHING;

-- 3. Mapeo Inicial de Rol -> Permisos
-- Administrador: Acceso total a configuración y roles
INSERT INTO auth_acl.rol_permisos (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM auth_acl.roles r, auth_acl.permisos p
WHERE r.nombre_rol = 'ADMINISTRADOR_MUNICIPAL'
ON CONFLICT DO NOTHING;

-- Comerciante: Consultar cuadrícula, reservar, declarar luz, subir voucher y descargar credencial
INSERT INTO auth_acl.rol_permisos (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM auth_acl.roles r, auth_acl.permisos p
WHERE r.nombre_rol = 'COMERCIANTE'
  AND p.codigo_permiso IN ('PUESTO_CONSULTAR_MAPA', 'PUESTO_RESERVAR', 'ELECTRICO_DECLARAR', 'PAGO_ADJUNTAR_COMPROBANTE', 'CREDENTIAL_DESCARGAR')
ON CONFLICT DO NOTHING;

-- Tesorería: Validar pagos y formalizar
INSERT INTO auth_acl.rol_permisos (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM auth_acl.roles r, auth_acl.permisos p
WHERE r.nombre_rol = 'ENCARGADO_TESORERIA'
  AND p.codigo_permiso IN ('PAGO_VALIDAR_TESORERIA', 'PUESTO_CONSULTAR_MAPA')
ON CONFLICT DO NOTHING;

-- Defensa Civil: Monitorear potencia y bloquear puestos por riesgo
INSERT INTO auth_acl.rol_permisos (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM auth_acl.roles r, auth_acl.permisos p
WHERE r.nombre_rol = 'INSPECTOR_DEFENSA_CIVIL'
  AND p.codigo_permiso IN ('ELECTRICO_MONITOREAR', 'PUESTO_BLOQUEAR_RIESGO', 'PUESTO_CONSULTAR_MAPA')
ON CONFLICT DO NOTHING;

-- Fiscalizador: Escaneo de QR y levantamiento de actas
INSERT INTO auth_acl.rol_permisos (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM auth_acl.roles r, auth_acl.permisos p
WHERE r.nombre_rol = 'FISCALIZADOR_MUNICIPAL'
  AND p.codigo_permiso IN ('QR_ESCANEAR_VERIFICAR', 'ACTA_INFRACCION_REGISTRAR', 'PUESTO_CONSULTAR_MAPA')
ON CONFLICT DO NOTHING;

-- 4. Catálogo de Giros Comerciales Frecuentes
INSERT INTO feria_core.giros_comerciales (nombre_giro, requiere_inspeccion_sanitaria) VALUES
('Gastronomía y Comidas Típicas de Huamanga', TRUE),
('Artesanía Tradicional y Retablos Ayacuchanos', FALSE),
('Textilería, Bordados y Trajes Folclóricos', FALSE),
('Platería y Filigrana', FALSE),
('Panadería, Dulces Típicos y Confitería', TRUE),
('Calzado, Marroquinería y Cuero', FALSE),
('Juguetes, Artículos Escolares y Regalos', FALSE),
('Plantas Ornamentales y Vivero', FALSE)
ON CONFLICT (nombre_giro) DO NOTHING;

-- 5. Catálogo de Artefactos Eléctricos Comunes
INSERT INTO feria_core.artefactos_catalogo (nombre_artefacto, potencia_referencial_watts) VALUES
('Foco LED de iluminación (10-20W)', 20.00),
('Reflector LED para puesto (50W)', 50.00),
('Balanza electrónica digital', 30.00),
('Cargador de celular / terminal POS', 25.00),
('Licuadora comercial estándar', 600.00),
('Refrigeradora / Conservadora pequeña', 350.00),
('Congeladora comercial de helados o alimentos', 800.00),
('Hervidor eléctrico de agua', 1500.00),
('Horno microondas mediano', 1200.00)
ON CONFLICT (nombre_artefacto) DO NOTHING;

-- 6. Catálogo de Motivos de Infracción Tipificados
INSERT INTO feria_core.motivos_infraccion (codigo_normativo, descripcion_motivo, gravedad, monto_sancion_uit_porcentaje) VALUES
('INF-01-GIRO', 'Comercialización de giro no autorizado o distinto a la credencial municipal', 'GRAVE', 10.00),
('INF-02-ESPACIO', 'Exceder las dimensiones autorizadas de 2x2 metros invadiendo vías peatonales', 'GRAVE', 15.00),
('INF-03-ELECTRICO', 'Conexión de artefactos eléctricos de alta potencia no declarados previamente', 'MUY_GRAVE', 25.00),
('INF-04-SIN_CREDENCIAL', 'No exhibir de manera visible la Ficha Municipal con Código QR firmado', 'LEVE', 5.00),
('INF-05-TITULARIDAD', 'Uso del puesto comercial por persona distinta al comerciante titular autorizado', 'MUY_GRAVE', 30.00)
ON CONFLICT (codigo_normativo) DO NOTHING;

-- 7. Padrón Histórico de Prueba (FSH-36)
INSERT INTO feria_core.padron_historico (dni, nombres_completos, giro_historico, anio_registro, observaciones) VALUES
('10203040', 'JUAN CARLOS QUISPE PALOMINO', 'Artesanía Tradicional', 2025, 'Empadronado formal Feria Semana Santa 2025'),
('45891234', 'MARIA ELENA ROJAS MEZA', 'Gastronomía Tradicional', 2025, 'Sin sanciones previas')
ON CONFLICT DO NOTHING;
