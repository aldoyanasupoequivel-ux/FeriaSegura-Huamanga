/**
 * ============================================================================
 * PROYECTO: FERIASEGURA HUAMANGA (FSH)
 * ARCHIVO: logica.js
 * CURSO: Construcción y Evolución de Software
 * 
 * APLICACIÓN DE PRINCIPIOS DE INGENIERÍA DE SOFTWARE:
 * - SOLID:
 *     * S (Single Responsibility):
 *         - ValidadorDni: Solo valida el formato del DNI peruano.
 *         - AlmacenUsuarios: Solo gestiona persistencia y búsqueda de usuarios.
 *         - ControladorAccesoACL: Gestiona la matriz de roles y permisos (ACL).
 *         - ServicioAutenticacion: Orquesta el login unificado y registro.
 *     * D (Dependency Inversion):
 *         - El servicio recibe el almacén y el controlador ACL por inyección.
 * - ACL (Access Control List):
 *     - Sistema unificado de autenticación: El usuario NO elige su rol en la UI.
 *     - El sistema detecta su identidad, consulta la lista de control de acceso
 *       (ACL) y determina qué permisos y recursos tiene permitidos.
 * ============================================================================
 */

// ----------------------------------------------------------------------------
// 1. MATRIZ DE ROLES Y PERMISOS ACL (Alineado con esquema PostgreSQL FSH-28)
// ----------------------------------------------------------------------------
const MATRIZ_ROLES_PERMISOS = {
  COMERCIANTE: [
    'PUESTO_CONSULTAR_MAPA',
    'PUESTO_RESERVAR',
    'ELECTRICO_DECLARAR',
    'PAGO_ADJUNTAR_COMPROBANTE',
    'CREDENTIAL_DESCARGAR'
  ],
  FISCALIZADOR_MUNICIPAL: [
    'QR_ESCANEAR_VERIFICAR',
    'ACTA_INFRACCION_REGISTRAR',
    'PUESTO_CONSULTAR_MAPA'
  ],
  ADMINISTRADOR_MUNICIPAL: [
    '*' // Acceso total: catastro, zonificación, ferias, auditoría, asignación de roles
  ],
  ENCARGADO_TESORERIA: [
    'PAGO_VALIDAR_TESORERIA',
    'PUESTO_CONSULTAR_MAPA'
  ],
  INSPECTOR_DEFENSA_CIVIL: [
    'ELECTRICO_MONITOREAR',
    'PUESTO_BLOQUEAR_RIESGO',
    'PUESTO_CONSULTAR_MAPA'
  ]
};

// ----------------------------------------------------------------------------
// 2. VALIDADOR DE DNI (Principio S: Responsabilidad Única)
// ----------------------------------------------------------------------------
const ValidadorDni = {
  validar(dni) {
    if (!dni || typeof dni !== 'string') {
      return { esValido: false, mensaje: 'Debe ingresar un número de DNI.' };
    }

    const dniLimpio = dni.trim();

    if (dniLimpio.length !== 8) {
      return { esValido: false, mensaje: 'El DNI debe tener exactamente 8 dígitos.' };
    }

    const soloDigitos = /^[0-9]{8}$/.test(dniLimpio);
    if (!soloDigitos) {
      return { esValido: false, mensaje: 'El DNI solo puede contener números, sin letras ni símbolos.' };
    }

    return { esValido: true, mensaje: 'DNI correcto.' };
  }
};

// ----------------------------------------------------------------------------
// 3. CONTROLADOR DE ACCESO ACL (Principio S: Control de Permisos y Recursos)
// ----------------------------------------------------------------------------
class ControladorAccesoACL {
  constructor(matriz = MATRIZ_ROLES_PERMISOS) {
    this.matriz = matriz;
  }

  obtenerPermisos(rol) {
    return this.matriz[rol] || [];
  }

  tienePermiso(rol, codigoPermiso) {
    if (!rol) return false;
    const permisos = this.obtenerPermisos(rol);
    if (permisos.includes('*')) return true; // Permiso maestro (Admin)
    return permisos.includes(codigoPermiso);
  }
}

// ----------------------------------------------------------------------------
// 4. ALMACÉN DE USUARIOS (Persistencia desacoplada - Principio S y D)
// ----------------------------------------------------------------------------
class AlmacenUsuarios {
  constructor() {
    // Comerciantes empadronados de prueba (Datos Semilla)
    this.comerciantes = [
      {
        identificador: '45871234',
        dni: '45871234',
        nombreCompleto: 'Juan Carlos Pérez Flores',
        telefono: '966123456',
        giro: 'Artesanía y Retablos',
        clave: '123456',
        rol: 'COMERCIANTE',
        tipoUsuario: 'COMERCIANTE',
        estado: 'EMPADRONADO'
      },
      {
        identificador: '72345678',
        dni: '72345678',
        nombreCompleto: 'María Elena Quispe Alanya',
        telefono: '966789123',
        giro: 'Gastronomía Tradicional',
        clave: '123456',
        rol: 'COMERCIANTE',
        tipoUsuario: 'COMERCIANTE',
        estado: 'EMPADRONADO'
      }
    ];

    // Funcionarios municipales institucionales (FSH-22, FSH-28)
    this.usuariosInternos = [
      {
        identificador: 'fiscalizador',
        alias: 'fiscalizador@mph.gob.pe',
        dni: '10203040',
        nombreCompleto: 'Carlos Mendoza Bendezú',
        cargo: 'Inspector de Serenazgo y Fiscalización',
        rol: 'FISCALIZADOR_MUNICIPAL',
        tipoUsuario: 'FUNCIONARIO_INTERNO',
        clave: '123456'
      },
      {
        identificador: 'admin',
        alias: 'admin@mph.gob.pe',
        dni: '40506070',
        nombreCompleto: 'Aldo Marcos Yanasupo',
        cargo: 'Subgerente de Comercio y Mercados',
        rol: 'ADMINISTRADOR_MUNICIPAL',
        tipoUsuario: 'FUNCIONARIO_INTERNO',
        clave: 'admin123'
      },
      {
        identificador: 'defensacivil',
        alias: 'defensacivil@mph.gob.pe',
        dni: '30405060',
        nombreCompleto: 'Roberto Castillo Huamán',
        cargo: 'Inspector de Seguridad y Riesgos Eléctricos',
        rol: 'INSPECTOR_DEFENSA_CIVIL',
        tipoUsuario: 'FUNCIONARIO_INTERNO',
        clave: '123456'
      },
      {
        identificador: 'tesoreria',
        alias: 'tesoreria@mph.gob.pe',
        dni: '20304050',
        nombreCompleto: 'Rosa Gutiérrez Prado',
        cargo: 'Responsable de Caja y Pagos TUPA',
        rol: 'ENCARGADO_TESORERIA',
        tipoUsuario: 'FUNCIONARIO_INTERNO',
        clave: '123456'
      }
    ];
  }

  // Búsqueda polimórfica y unificada por identificador (DNI, usuario o correo)
  buscarPorIdentificador(identificador) {
    if (!identificador || typeof identificador !== 'string') return null;
    const idLimpio = identificador.trim().toLowerCase();

    // 1. Si tiene 8 dígitos numéricos, buscar en comerciantes por DNI
    if (/^[0-9]{8}$/.test(idLimpio)) {
      const comerciante = this.comerciantes.find(c => c.dni === idLimpio);
      if (comerciante) return comerciante;

      // También puede ser el DNI de un funcionario interno
      const internoPorDni = this.usuariosInternos.find(u => u.dni === idLimpio);
      if (internoPorDni) return internoPorDni;
    }

    // 2. Buscar en usuarios internos por usuario o alias (correo institucional)
    return this.usuariosInternos.find(u => 
      u.identificador.toLowerCase() === idLimpio || 
      (u.alias && u.alias.toLowerCase() === idLimpio)
    ) || null;
  }

  buscarComerciantePorDni(dni) {
    if (!dni) return null;
    return this.comerciantes.find(c => c.dni === dni.trim()) || null;
  }

  buscarUsuarioInterno(usuario) {
    return this.buscarPorIdentificador(usuario);
  }

  registrarComerciante(nuevoComerciante) {
    this.comerciantes.push(nuevoComerciante);
    return nuevoComerciante;
  }
}

// ----------------------------------------------------------------------------
// 5. SERVICIO DE AUTENTICACIÓN Y CONTROL DE ACCESO (SOLID + ACL)
// ----------------------------------------------------------------------------
class ServicioAutenticacion {
  constructor(almacen = new AlmacenUsuarios(), controladorAcl = new ControladorAccesoACL()) {
    // Inyección de dependencias (Principio D)
    this.almacen = almacen;
    this.controladorAcl = controladorAcl;
  }

  /**
   * INICIO DE SESIÓN UNIFICADO (Sin selección manual de rol)
   * El sistema valida la identidad del usuario y aplica ACL para determinar su rol y permisos.
   * @param {string} identificador DNI de 8 dígitos o usuario/correo institucional
   * @param {string} clave Contraseña
   */
  iniciarSesion(identificador, clave) {
    if (!identificador || identificador.trim() === '') {
      return { exito: false, mensaje: 'Por favor, ingrese su DNI o usuario institucional.' };
    }

    if (!clave || clave.trim() === '') {
      return { exito: false, mensaje: 'Por favor, ingrese su contraseña.' };
    }

    const idLimpio = identificador.trim();

    // 1. Buscar al usuario en el almacén de forma unificada
    const usuario = this.almacen.buscarPorIdentificador(idLimpio);

    if (!usuario) {
      // Mensaje orientativo si intentó con un número de DNI
      if (/^[0-9]{8}$/.test(idLimpio)) {
        return { 
          exito: false, 
          mensaje: 'El DNI no se encuentra empadronado. Por favor, regístrese primero en el padrón municipal.' 
        };
      }
      return { 
        exito: false, 
        mensaje: 'Usuario o credencial no encontrada en el sistema municipal.' 
      };
    }

    // 2. Verificar contraseña
    if (usuario.clave !== clave) {
      return { exito: false, mensaje: 'Contraseña incorrecta. Intente de nuevo.' };
    }

    // 3. Aplicar ACL: Obtener los permisos autorizados para el rol del usuario
    const permisosAutorizados = this.controladorAcl.obtenerPermisos(usuario.rol);

    return {
      exito: true,
      mensaje: `¡Bienvenido(a), ${usuario.nombreCompleto}!`,
      usuario: {
        identificador: usuario.identificador,
        dni: usuario.dni,
        nombre: usuario.nombreCompleto,
        rol: usuario.rol,
        tipoUsuario: usuario.tipoUsuario,
        giro: usuario.giro || null,
        cargo: usuario.cargo || null,
        permisos: permisosAutorizados,
        // Método de verificación directa de ACL
        tienePermiso: (codigoPermiso) => this.controladorAcl.tienePermiso(usuario.rol, codigoPermiso)
      }
    };
  }

  /**
   * Métodos auxiliares para compatibilidad con código anterior o pruebas específicas
   */
  iniciarSesionComerciante(dni, clave) {
    const validacion = ValidadorDni.validar(dni);
    if (!validacion.esValido) {
      return { exito: false, mensaje: validacion.mensaje };
    }
    return this.iniciarSesion(dni, clave);
  }

  iniciarSesionInterno(usuario, clave, rolEsperado = null) {
    const resultado = this.iniciarSesion(usuario, clave);
    if (!resultado.exito) return resultado;

    if (rolEsperado) {
      const rolNormalizado = rolEsperado.toUpperCase().replace(/\s+/g, '_');
      const rolUsuario = resultado.usuario.rol.toUpperCase();
      if (!rolUsuario.includes(rolNormalizado) && !rolNormalizado.includes(rolUsuario)) {
        return {
          exito: false,
          mensaje: `Acceso denegado: el usuario no cuenta con el rol requerido.`
        };
      }
    }
    return resultado;
  }

  /**
   * Registro de Comerciante en el Padrón Municipal (FSH-10, FSH-36)
   */
  registrarNuevoComerciante(datos) {
    const { dni, nombreCompleto, telefono, giro, clave } = datos;

    // 1. Validar DNI
    const validacionDni = ValidadorDni.validar(dni);
    if (!validacionDni.esValido) {
      return { exito: false, mensaje: validacionDni.mensaje };
    }

    // 2. Regla de unicidad de DNI
    const existente = this.almacen.buscarPorIdentificador(dni);
    if (existente) {
      return { exito: false, mensaje: 'Este número de DNI ya está empadronado en el sistema.' };
    }

    // 3. Validaciones de datos obligatorios
    if (!nombreCompleto || nombreCompleto.trim().length < 3) {
      return { exito: false, mensaje: 'Debe ingresar sus nombres y apellidos completos.' };
    }
    if (!clave || clave.length < 4) {
      return { exito: false, mensaje: 'La contraseña debe tener al menos 4 caracteres.' };
    }

    // 4. Registro con rol COMERCIANTE asignado automáticamente por el sistema
    const nuevo = {
      identificador: dni.trim(),
      dni: dni.trim(),
      nombreCompleto: nombreCompleto.trim(),
      telefono: telefono || '',
      giro: giro || 'Comercio General',
      clave: clave,
      rol: 'COMERCIANTE',
      tipoUsuario: 'COMERCIANTE',
      estado: 'EMPADRONADO'
    };

    this.almacen.registrarComerciante(nuevo);

    return {
      exito: true,
      mensaje: '¡Empadronamiento exitoso! Ya puede iniciar sesión con su DNI.',
      comerciante: nuevo
    };
  }
}

// Exportación para pruebas en Node.js y uso en el navegador
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    ValidadorDni,
    ControladorAccesoACL,
    AlmacenUsuarios,
    ServicioAutenticacion,
    MATRIZ_ROLES_PERMISOS
  };
}
