/**
 * ============================================================================
 * PROYECTO: FERIASEGURA HUAMANGA (FSH)
 * ARCHIVO: app.js
 * CURSO: Construcción y Evolución de Software
 * 
 * Controlador de la interfaz web que conecta el formulario con logica.js
 * ============================================================================
 */

// Instanciamos el servicio de autenticación con su almacén (SOLID)
const almacen = new AlmacenUsuarios();
const servicioAuth = new ServicioAutenticacion(almacen);

// Estado actual
let rolActual = 'Comerciante';

// ----------------------------------------------------------------------------
// 1. CAMBIO DE ROL (Comerciante, Fiscalizador, Gestión MPH)
// ----------------------------------------------------------------------------
function cambiarRol(nuevoRol) {
  rolActual = nuevoRol;
  ocultarAlerta();

  // Actualizar clases de las pestañas
  document.getElementById('tab-comerciante').classList.toggle('activa', nuevoRol === 'Comerciante');
  document.getElementById('tab-fiscalizador').classList.toggle('activa', nuevoRol === 'Fiscalizador');
  document.getElementById('tab-gestion').classList.toggle('activa', nuevoRol === 'Gestión MPH');

  const etiquetaId = document.getElementById('etiqueta-identidad');
  const campoId = document.getElementById('campo-identidad');
  const iconoId = document.getElementById('icono-campo-id');
  const badgeRegla = document.getElementById('badge-regla-negocio');
  const bloqueRegistro = document.getElementById('bloque-registro-comerciante');

  campoId.value = '';
  document.getElementById('campo-clave').value = '';

  if (nuevoRol === 'Comerciante') {
    etiquetaId.textContent = 'DNI DEL COMERCIANTE';
    campoId.placeholder = 'Ingrese su número de DNI (8 dígitos)';
    campoId.maxLength = 8;
    iconoId.innerHTML = '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="M7 15h.01"/><path d="M7 9h.01"/><rect x="11" y="9" width="6" height="6"/></svg>';
    badgeRegla.textContent = '1 puesto por DNI';
    bloqueRegistro.style.display = 'block';
  } else if (nuevoRol === 'Fiscalizador') {
    etiquetaId.textContent = 'USUARIO INSTITUCIONAL (FISCALIZADOR)';
    campoId.placeholder = 'Ingrese su usuario institucional (ej. fiscalizador)';
    campoId.maxLength = 30;
    iconoId.innerHTML = '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>';
    badgeRegla.textContent = 'Móvil Serenazgo';
    bloqueRegistro.style.display = 'none';
  } else {
    etiquetaId.textContent = 'USUARIO DE ADMINISTRACIÓN MPH';
    campoId.placeholder = 'Ingrese su usuario de gestión (ej. admin)';
    campoId.maxLength = 30;
    iconoId.innerHTML = '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="4" y="2" width="16" height="20" rx="2"/><path d="M9 22v-4h6v4"/></svg>';
    badgeRegla.textContent = 'Acceso Restringido';
    bloqueRegistro.style.display = 'none';
  }
}

// ----------------------------------------------------------------------------
// 2. RESTRICCIÓN DE DNI EN TIEMPO REAL (SOLO NÚMEROS)
// ----------------------------------------------------------------------------
document.getElementById('campo-identidad').addEventListener('input', function(e) {
  if (rolActual === 'Comerciante') {
    // Si escribe letras o símbolos en DNI, se limpian automáticamente
    this.value = this.value.replace(/[^0-9]/g, '');
  }
});

// ----------------------------------------------------------------------------
// 3. ALTERNAR VISIBILIDAD DE CONTRASEÑA (VER / OCULTAR)
// ----------------------------------------------------------------------------
function alternarVisibilidadClave() {
  const campoClave = document.getElementById('campo-clave');
  if (campoClave.type === 'password') {
    campoClave.type = 'text';
  } else {
    campoClave.type = 'password';
  }
}

// ----------------------------------------------------------------------------
// 4. CREDENCIALES DEMO DE ACCESO RÁPIDO (PARA LA PRESENTACIÓN)
// ----------------------------------------------------------------------------
function cargarDemo(tipo) {
  ocultarAlerta();
  if (tipo === 'comerciante') {
    cambiarRol('Comerciante');
    document.getElementById('campo-identidad').value = '45871234';
    document.getElementById('campo-clave').value = '123456';
  } else if (tipo === 'fiscalizador') {
    cambiarRol('Fiscalizador');
    document.getElementById('campo-identidad').value = 'fiscalizador';
    document.getElementById('campo-clave').value = '123456';
  } else if (tipo === 'admin') {
    cambiarRol('Gestión MPH');
    document.getElementById('campo-identidad').value = 'admin';
    document.getElementById('campo-clave').value = 'admin123';
  }
}

// ----------------------------------------------------------------------------
// 5. PROCESAR EL INGRESO (FORMULARIO PRINCIPAL)
// ----------------------------------------------------------------------------
function procesarIngreso(event) {
  event.preventDefault();
  ocultarAlerta();

  const identidad = document.getElementById('campo-identidad').value.trim();
  const clave = document.getElementById('campo-clave').value;

  let resultado;

  if (rolActual === 'Comerciante') {
    resultado = servicioAuth.iniciarSesionComerciante(identidad, clave);
  } else {
    resultado = servicioAuth.iniciarSesionInterno(identidad, clave, rolActual);
  }

  if (!resultado.exito) {
    mostrarAlerta(resultado.mensaje, 'error');
    return;
  }

  // Si fue exitoso, mostrar el modal de bienvenida
  mostrarModalExito(resultado.usuario);
}

// ----------------------------------------------------------------------------
// 6. MODAL DE REGISTRO EN VIVO (EMPADRONAMIENTO NUEVO COMERCIANTE)
// ----------------------------------------------------------------------------
function abrirModalRegistro(e) {
  if (e) e.preventDefault();
  document.getElementById('modal-registro').classList.add('activo');
}

function cerrarModalRegistro() {
  document.getElementById('modal-registro').classList.remove('activo');
}

function procesarRegistro(event) {
  event.preventDefault();

  const datos = {
    dni: document.getElementById('reg-dni').value.trim(),
    nombreCompleto: document.getElementById('reg-nombre').value.trim(),
    telefono: document.getElementById('reg-telefono').value.trim(),
    giro: document.getElementById('reg-giro').value,
    clave: document.getElementById('reg-clave').value
  };

  const resultado = servicioAuth.registrarNuevoComerciante(datos);

  if (!resultado.exito) {
    alert('Error: ' + resultado.mensaje);
    return;
  }

  cerrarModalRegistro();
  cambiarRol('Comerciante');
  document.getElementById('campo-identidad').value = datos.dni;
  document.getElementById('campo-clave').value = datos.clave;
  mostrarAlerta('¡Registro exitoso! Puede presionar "Ingresar al Sistema".', 'exito');
}

// ----------------------------------------------------------------------------
// 7. ALERTAS Y MODALES INFORMATIVOS
// ----------------------------------------------------------------------------
function mostrarAlerta(mensaje, tipo) {
  const caja = document.getElementById('caja-alerta');
  caja.className = 'mensaje-alerta ' + tipo;
  caja.textContent = mensaje;
}

function ocultarAlerta() {
  const caja = document.getElementById('caja-alerta');
  caja.className = 'mensaje-alerta';
  caja.textContent = '';
}

function mostrarModalExito(usuario) {
  document.getElementById('exito-titulo').textContent = `¡Bienvenido(a), ${usuario.nombre}!`;
  document.getElementById('exito-detalle').textContent = `Has ingresado con éxito al portal de FeriaSegura Huamanga.`;
  
  const contenedorDatos = document.getElementById('exito-datos');
  if (usuario.rol === 'Comerciante') {
    contenedorDatos.innerHTML = `
      <strong>Rol autenticado:</strong> Comerciante Empadronado<br>
      <strong>DNI:</strong> ${usuario.dni}<br>
      <strong>Giro Comercial:</strong> ${usuario.giro}<br>
      <strong>Estado:</strong> Habilitado para postular a puesto
    `;
  } else {
    contenedorDatos.innerHTML = `
      <strong>Rol autenticado:</strong> ${usuario.rol}<br>
      <strong>Usuario institucional:</strong> ${usuario.usuario}<br>
      <strong>Permisos:</strong> Control y Operativos en Vía Pública
    `;
  }

  document.getElementById('modal-exito').classList.add('activo');
}

function cerrarModalExito() {
  document.getElementById('modal-exito').classList.remove('activo');
}

function alertaOlvido(e) {
  e.preventDefault();
  alert('Para restablecer su clave, acérquese a la Subgerencia de Comercio y Mercados de la Municipalidad Provincial de Huamanga.');
}

function alertaGoogle() {
  alert('La autenticación con Google SSO estará disponible en el Sprint 2 para cuentas @mph.gob.pe institucionales.');
}
