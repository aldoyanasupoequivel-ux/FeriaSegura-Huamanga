/**
 * ============================================================================
 * PROYECTO: FERIASEGURA HUAMANGA (FSH)
 * ARCHIVO: pruebas.js
 * CURSO: Construcción y Evolución de Software
 * 
 * TDD (Test-Driven Development) - Pruebas Unitarias Automatizadas
 * Se ejecutan directamente con: node pruebas.js o npm test
 * ============================================================================
 */

const assert = require('assert');
const { 
  ValidadorDni, 
  ControladorAccesoACL, 
  AlmacenUsuarios, 
  ServicioAutenticacion,
  MATRIZ_ROLES_PERMISOS
} = require('./logica');

console.log('\n======================================================================');
console.log('🧪 FERIASEGURA HUAMANGA - SUITE DE PRUEBAS UNITARIAS (TDD + ACL)');
console.log('Curso: Construcción y Evolución de Software (2026-II)');
console.log('======================================================================\n');

let totalPruebas = 0;
let pruebasExitosas = 0;

function ejecutarPrueba(descripcion, pruebaFn) {
  totalPruebas++;
  try {
    pruebaFn();
    pruebasExitosas++;
    console.log(`  ✅ [PASÓ] Prueba ${totalPruebas}: ${descripcion}`);
  } catch (error) {
    console.error(`  ❌ [FALLÓ] Prueba ${totalPruebas}: ${descripcion}`);
    console.error(`     Detalle del fallo: ${error.message}\n`);
  }
}

// ----------------------------------------------------------------------------
// BLOQUE 1: PRUEBAS DEL VALIDADOR DE DNI (FSH-10, FSH-36)
// ----------------------------------------------------------------------------
console.log('--- 📋 1. Pruebas de Validación de DNI (SOLID: Responsabilidad Única) ---');

ejecutarPrueba('Aceptar un DNI válido de exactamente 8 dígitos numéricos', () => {
  const resultado = ValidadorDni.validar('45871234');
  assert.strictEqual(resultado.esValido, true);
  assert.strictEqual(resultado.mensaje, 'DNI correcto.');
});

ejecutarPrueba('Rechazar un DNI con menos de 8 dígitos (ej. 7 dígitos)', () => {
  const resultado = ValidadorDni.validar('1234567');
  assert.strictEqual(resultado.esValido, false);
  assert.strictEqual(resultado.mensaje, 'El DNI debe tener exactamente 8 dígitos.');
});

ejecutarPrueba('Rechazar un DNI con más de 8 dígitos (ej. 9 dígitos)', () => {
  const resultado = ValidadorDni.validar('123456789');
  assert.strictEqual(resultado.esValido, false);
  assert.strictEqual(resultado.mensaje, 'El DNI debe tener exactamente 8 dígitos.');
});

ejecutarPrueba('Rechazar un DNI que contenga letras o símbolos', () => {
  const resultado = ValidadorDni.validar('4587123A');
  assert.strictEqual(resultado.esValido, false);
  assert.strictEqual(resultado.mensaje, 'El DNI solo puede contener números, sin letras ni símbolos.');
});

ejecutarPrueba('Rechazar DNI vacío o nulo', () => {
  const resultado = ValidadorDni.validar('');
  assert.strictEqual(resultado.esValido, false);
  assert.strictEqual(resultado.mensaje, 'Debe ingresar un número de DNI.');
});

// ----------------------------------------------------------------------------
// BLOQUE 2: CONTROLADOR DE ACCESO ACL (Access Control List)
// ----------------------------------------------------------------------------
console.log('\n--- 🛡️ 2. Pruebas de Control de Acceso ACL (Permisos y Restricciones) ---');

ejecutarPrueba('Comerciante debe tener permisos para reservar puestos pero NO para fiscalizar ni crear ferias', () => {
  const acl = new ControladorAccesoACL();
  assert.strictEqual(acl.tienePermiso('COMERCIANTE', 'PUESTO_RESERVAR'), true);
  assert.strictEqual(acl.tienePermiso('COMERCIANTE', 'ELECTRICO_DECLARAR'), true);
  assert.strictEqual(acl.tienePermiso('COMERCIANTE', 'QR_ESCANEAR_VERIFICAR'), false);
  assert.strictEqual(acl.tienePermiso('COMERCIANTE', 'FERIA_CREAR'), false);
});

ejecutarPrueba('Fiscalizador de Serenazgo debe tener permisos para escanear QR y registrar actas', () => {
  const acl = new ControladorAccesoACL();
  assert.strictEqual(acl.tienePermiso('FISCALIZADOR_MUNICIPAL', 'QR_ESCANEAR_VERIFICAR'), true);
  assert.strictEqual(acl.tienePermiso('FISCALIZADOR_MUNICIPAL', 'ACTA_INFRACCION_REGISTRAR'), true);
  assert.strictEqual(acl.tienePermiso('FISCALIZADOR_MUNICIPAL', 'PUESTO_RESERVAR'), false);
});

ejecutarPrueba('Administrador Municipal cuenta con permiso maestro sobre todo el sistema', () => {
  const acl = new ControladorAccesoACL();
  assert.strictEqual(acl.tienePermiso('ADMINISTRADOR_MUNICIPAL', 'FERIA_CREAR'), true);
  assert.strictEqual(acl.tienePermiso('ADMINISTRADOR_MUNICIPAL', 'USUARIO_ASIGNAR_ROL'), true);
  assert.strictEqual(acl.tienePermiso('ADMINISTRADOR_MUNICIPAL', 'PUESTO_BLOQUEAR_RIESGO'), true);
});

// ----------------------------------------------------------------------------
// BLOQUE 3: LOGIN UNIFICADO CON DETERMINACIÓN AUTOMÁTICA DE ROL
// ----------------------------------------------------------------------------
console.log('\n--- 🔑 3. Pruebas de Login Unificado (Sin selección manual de usuario) ---');

ejecutarPrueba('Inicio de sesión unificado con DNI reconoce automáticamente al Comerciante con sus permisos', () => {
  const servicio = new ServicioAutenticacion(new AlmacenUsuarios());
  const respuesta = servicio.iniciarSesion('45871234', '123456');

  assert.strictEqual(respuesta.exito, true);
  assert.strictEqual(respuesta.usuario.rol, 'COMERCIANTE');
  assert.strictEqual(respuesta.usuario.dni, '45871234');
  assert.strictEqual(respuesta.usuario.tienePermiso('PUESTO_RESERVAR'), true);
  assert.strictEqual(respuesta.usuario.tienePermiso('ACTA_INFRACCION_REGISTRAR'), false);
});

ejecutarPrueba('Inicio de sesión unificado con usuario de Fiscalizador reconoce el rol institucional', () => {
  const servicio = new ServicioAutenticacion(new AlmacenUsuarios());
  const respuesta = servicio.iniciarSesion('fiscalizador', '123456');

  assert.strictEqual(respuesta.exito, true);
  assert.strictEqual(respuesta.usuario.rol, 'FISCALIZADOR_MUNICIPAL');
  assert.strictEqual(respuesta.usuario.tienePermiso('QR_ESCANEAR_VERIFICAR'), true);
  assert.strictEqual(respuesta.usuario.tienePermiso('PUESTO_RESERVAR'), false);
});

ejecutarPrueba('Inicio de sesión unificado con correo institucional de Administración', () => {
  const servicio = new ServicioAutenticacion(new AlmacenUsuarios());
  const respuesta = servicio.iniciarSesion('admin@mph.gob.pe', 'admin123');

  assert.strictEqual(respuesta.exito, true);
  assert.strictEqual(respuesta.usuario.rol, 'ADMINISTRADOR_MUNICIPAL');
  assert.strictEqual(respuesta.usuario.tienePermiso('FERIA_CREAR'), true);
});

ejecutarPrueba('Rechazar inicio de sesión con contraseña equivocada', () => {
  const servicio = new ServicioAutenticacion(new AlmacenUsuarios());
  const respuesta = servicio.iniciarSesion('45871234', 'clave_incorrecta');
  
  assert.strictEqual(respuesta.exito, false);
  assert.strictEqual(respuesta.mensaje, 'Contraseña incorrecta. Intente de nuevo.');
});

ejecutarPrueba('Rechazar inicio de sesión si el DNI no está en el padrón', () => {
  const servicio = new ServicioAutenticacion(new AlmacenUsuarios());
  const respuesta = servicio.iniciarSesion('99999999', '123456');
  
  assert.strictEqual(respuesta.exito, false);
  assert.ok(respuesta.mensaje.includes('El DNI no se encuentra empadronado'));
});

// ----------------------------------------------------------------------------
// BLOQUE 4: REGISTRO Y EMPADRONAMIENTO (FSH-10, FSH-36)
// ----------------------------------------------------------------------------
console.log('\n--- 📝 4. Pruebas de Registro y Unicidad de DNI (FSH-10, FSH-36) ---');

ejecutarPrueba('Registrar nuevo comerciante en el padrón y autenticar por flujo unificado', () => {
  const servicio = new ServicioAutenticacion(new AlmacenUsuarios());
  
  const registro = servicio.registrarNuevoComerciante({
    dni: '88776655',
    nombreCompleto: 'Edson Huaman Huacre',
    telefono: '987654321',
    giro: 'Venta de Textiles Tradicionales',
    clave: 'mi_clave_segura'
  });

  assert.strictEqual(registro.exito, true);

  // Probar login unificado directo
  const login = servicio.iniciarSesion('88776655', 'mi_clave_segura');
  assert.strictEqual(login.exito, true);
  assert.strictEqual(login.usuario.nombre, 'Edson Huaman Huacre');
  assert.strictEqual(login.usuario.rol, 'COMERCIANTE');
  assert.strictEqual(login.usuario.tienePermiso('PUESTO_RESERVAR'), true);
});

ejecutarPrueba('Rechazar registro si el DNI ya existe (Regla de unicidad de DNI)', () => {
  const servicio = new ServicioAutenticacion(new AlmacenUsuarios());
  
  const registroDuplicado = servicio.registrarNuevoComerciante({
    dni: '45871234',
    nombreCompleto: 'Otro Comerciante',
    clave: '123456'
  });

  assert.strictEqual(registroDuplicado.exito, false);
  assert.strictEqual(registroDuplicado.mensaje, 'Este número de DNI ya está empadronado en el sistema.');
});

// ----------------------------------------------------------------------------
// RESUMEN FINAL
// ----------------------------------------------------------------------------
console.log('\n======================================================================');
if (pruebasExitosas === totalPruebas) {
  console.log(`🎉 RESULTADO: ${pruebasExitosas}/${totalPruebas} PRUEBAS EN VERDE (100% ÉXITO)`);
  console.log('✅ Criterios de aceptación cumplidos (Definition of Done - DoD)');
  console.log('======================================================================\n');
  process.exit(0);
} else {
  console.log(`⚠️ RESULTADO: ${pruebasExitosas}/${totalPruebas} pasaron.`);
  console.log('======================================================================\n');
  process.exit(1);
}
