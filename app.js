/**
 * ============================================================================
 * PROYECTO: FERIASEGURA HUAMANGA (FSH)
 * ARCHIVO: app.js
 * CURSO: Construcción y Evolución de Software
 * 
 * Controlador de la interfaz web que conecta el formulario unificado con logica.js
 * Cumple con principios SOLID y evaluación de control de acceso por ACL.
 * ============================================================================
 */

// Instanciamos el almacén, el controlador ACL y el servicio de autenticación (SOLID)
const almacen = new AlmacenUsuarios();
const controladorAcl = new ControladorAccesoACL();
const servicioAuth = new ServicioAutenticacion(almacen, controladorAcl);

// ----------------------------------------------------------------------------
// 1. ALTERNAR VISIBILIDAD DE CONTRASEÑA (VER / OCULTAR)
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
// 2. CREDENCIALES DEMO DE ACCESO RÁPIDO (PARA SUSTENTACIÓN ANTE EL DOCENTE)
// Autocompletan el identificador y clave, demostrando cómo el sistema
// infiere el rol y permisos vía ACL sin requerir selección manual del usuario.
// ----------------------------------------------------------------------------
function cargarDemo(tipo) {
  ocultarAlerta();
  const campoId = document.getElementById('campo-identidad');
  const campoClave = document.getElementById('campo-clave');

  if (tipo === 'comerciante') {
    campoId.value = '45871234';
    campoClave.value = '123456';
    mostrarAlerta('Credenciales de comerciante cargadas (DNI: 45871234). Presione "Ingresar al Sistema".', 'exito');
  } else if (tipo === 'fiscalizador') {
    campoId.value = 'fiscalizador';
    campoClave.value = '123456';
    mostrarAlerta('Credenciales institucionales de Fiscalizador cargadas. Presione "Ingresar al Sistema".', 'exito');
  } else if (tipo === 'admin') {
    campoId.value = 'admin';
    campoClave.value = 'admin123';
    mostrarAlerta('Credenciales de Administrador Municipal cargadas. Presione "Ingresar al Sistema".', 'exito');
  }
}

// ----------------------------------------------------------------------------
// 3. PROCESAR EL INGRESO UNIFICADO (LOGIN CON ACL)
// ----------------------------------------------------------------------------
function procesarIngreso(event) {
  event.preventDefault();
  ocultarAlerta();

  const identificador = document.getElementById('campo-identidad').value.trim();
  const clave = document.getElementById('campo-clave').value;

  // El servicio de autenticación evalúa la identidad y aplica ACL
  const resultado = servicioAuth.iniciarSesion(identificador, clave);

  if (!resultado.exito) {
    mostrarAlerta(resultado.mensaje, 'error');
    return;
  }

  // Si fue exitoso, mostrar el modal de bienvenida y permisos autorizados por ACL
  mostrarModalExito(resultado.usuario);
}

// ----------------------------------------------------------------------------
// 4. MODAL DE REGISTRO / EMPADRONAMIENTO (FSH-10, FSH-36)
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
  document.getElementById('campo-identidad').value = datos.dni;
  document.getElementById('campo-clave').value = datos.clave;
  mostrarAlerta('¡Empadronamiento exitoso! Se asignó el rol COMERCIANTE mediante ACL. Ya puede presionar "Ingresar al Sistema".', 'exito');
}

// ----------------------------------------------------------------------------
// 5. ALERTAS Y MODALES CON DETALLE DE ACL
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
  document.getElementById('exito-detalle').textContent = `Sesión autenticada y permisos asignados mediante Access Control List (ACL).`;
  
  const contenedorDatos = document.getElementById('exito-datos');
  
  // Determinar clase de badge según el rol
  let claseBadge = 'badge-rol-comerciante';
  if (usuario.rol === 'FISCALIZADOR_MUNICIPAL') claseBadge = 'badge-rol-fiscalizador';
  if (usuario.rol === 'ADMINISTRADOR_MUNICIPAL') claseBadge = 'badge-rol-admin';

  // Renderizar los chips de permisos ACL
  const listaPermisosHtml = usuario.permisos.map(p => `
    <span class="chip-permiso">✓ ${p}</span>
  `).join('');

  let detalleAdicional = '';
  if (usuario.tipoUsuario === 'COMERCIANTE') {
    detalleAdicional = `
      <div class="fila-dato">
        <strong>DNI:</strong> <span>${usuario.dni}</span>
      </div>
      <div class="fila-dato">
        <strong>Giro Comercial:</strong> <span>${usuario.giro}</span>
      </div>
    `;
  } else {
    detalleAdicional = `
      <div class="fila-dato">
        <strong>Identificador:</strong> <span>${usuario.identificador}</span>
      </div>
      <div class="fila-dato">
        <strong>Cargo:</strong> <span>${usuario.cargo || 'Funcionario'}</span>
      </div>
    `;
  }

  contenedorDatos.innerHTML = `
    <div class="fila-dato">
      <strong>Rol asignado por ACL:</strong>
      <span class="badge-rol-acl ${claseBadge}">${usuario.rol}</span>
    </div>
    ${detalleAdicional}
    <div class="titulo-permisos">Atribuciones autorizadas en el sistema (ACL):</div>
    <div class="chips-permisos">
      ${listaPermisosHtml}
    </div>
  `;

  document.getElementById('modal-exito').classList.add('activo');
}

function cerrarModalExito() {
  document.getElementById('modal-exito').classList.remove('activo');
}

function alertaOlvido(e) {
  e.preventDefault();
  alert('Para restablecer su clave, acérquese a la Subgerencia de Comercio y Mercados de la Municipalidad Provincial de Huamanga.');
}
