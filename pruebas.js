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
const { ValidadorDni, AlmacenUsuarios, ServicioAutenticacion } = require('./logica');

console.log('\n======================================================================');
console.log('🧪 FERIASEGURA HUAMANGA - SUITE DE PRUEBAS UNITARIAS (TDD)');
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
// BLOQUE 2: PRUEBAS DE INICIO DE SESIÓN DE COMERCIANTE (Jira: FSH-24)
// ----------------------------------------------------------------------------
console.log('\n--- 🔑 2. Pruebas de Inicio de Sesión de Comerciante (FSH-24) ---');

ejecutarPrueba('Iniciar sesión exitosamente con DNI y clave correctos', () => {
  const servicio = new ServicioAutenticacion(new AlmacenUsuarios());
  const respuesta = servicio.iniciarSesionComerciante('45871234', '123456');
  
  assert.strictEqual(respuesta.exito, true);
  assert.strictEqual(respuesta.usuario.rol, 'Comerciante');
  assert.strictEqual(respuesta.usuario.dni, '45871234');
});

ejecutarPrueba('Rechazar inicio de sesión con contraseña equivocada', () => {
  const servicio = new ServicioAutenticacion(new AlmacenUsuarios());
  const respuesta = servicio.iniciarSesionComerciante('45871234', 'clave_incorrecta');
  
  assert.strictEqual(respuesta.exito, false);
  assert.strictEqual(respuesta.mensaje, 'Contraseña incorrecta. Intente de nuevo.');
});

ejecutarPrueba('Rechazar inicio de sesión si el DNI no está en el padrón', () => {
  const servicio = new ServicioAutenticacion(new AlmacenUsuarios());
  const respuesta = servicio.iniciarSesionComerciante('99999999', '123456');
  
  assert.strictEqual(respuesta.exito, false);
  assert.ok(respuesta.mensaje.includes('El DNI no está empadronado'));
});

// ----------------------------------------------------------------------------
// BLOQUE 3: PRUEBAS DE USUARIOS MUNICIPALES (Jira: FSH-22)
// ----------------------------------------------------------------------------
console.log('\n--- 🏛️ 3. Pruebas de Funcionarios Municipales (FSH-22) ---');

ejecutarPrueba('Iniciar sesión como Fiscalizador con usuario institucional', () => {
  const servicio = new ServicioAutenticacion(new AlmacenUsuarios());
  const respuesta = servicio.iniciarSesionInterno('fiscalizador', '123456', 'Fiscalizador');
  
  assert.strictEqual(respuesta.exito, true);
  assert.strictEqual(respuesta.usuario.rol, 'Fiscalizador');
});

ejecutarPrueba('Iniciar sesión como Administrador de Gestión MPH', () => {
  const servicio = new ServicioAutenticacion(new AlmacenUsuarios());
  const respuesta = servicio.iniciarSesionInterno('admin', 'admin123', 'Gestión MPH');
  
  assert.strictEqual(respuesta.exito, true);
  assert.strictEqual(respuesta.usuario.rol, 'Gestión MPH');
});

// ----------------------------------------------------------------------------
// BLOQUE 4: PRUEBAS DE REGISTRO / EMPADRONAMIENTO (Jira: FSH-10, FSH-36)
// ----------------------------------------------------------------------------
console.log('\n--- 📝 4. Pruebas de Registro y Unicidad de DNI (FSH-10, FSH-36) ---');

ejecutarPrueba('Registrar un nuevo comerciante en el padrón y luego iniciar sesión', () => {
  const servicio = new ServicioAutenticacion(new AlmacenUsuarios());
  
  const registro = servicio.registrarNuevoComerciante({
    dni: '88776655',
    nombreCompleto: 'Edson Huaman Huacre',
    telefono: '987654321',
    giro: 'Venta de Textiles Tradicionales',
    clave: 'mi_clave_segura'
  });

  assert.strictEqual(registro.exito, true);

  // Probar que el nuevo usuario ahora sí puede iniciar sesión
  const login = servicio.iniciarSesionComerciante('88776655', 'mi_clave_segura');
  assert.strictEqual(login.exito, true);
  assert.strictEqual(login.usuario.nombre, 'Edson Huaman Huacre');
});

ejecutarPrueba('Rechazar el registro si el DNI ya existe (Regla de unicidad)', () => {
  const servicio = new ServicioAutenticacion(new AlmacenUsuarios());
  
  // DNI 45871234 ya existe en los datos semilla
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
