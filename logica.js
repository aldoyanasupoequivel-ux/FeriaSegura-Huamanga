/**
 * ============================================================================
 * PROYECTO: FERIASEGURA HUAMANGA (FSH)
 * ARCHIVO: logica.js
 * CURSO: Construcción y Evolución de Software
 * 
 * APLICACIÓN DE PRINCIPIOS SOLID (Fácil de explicar al docente):
 * - S (Responsabilidad Única): 
 *     * ValidadorDni: Solo valida el formato del DNI peruano.
 *     * AlmacenUsuarios: Solo gestiona la memoria de usuarios y comerciantes.
 *     * ServicioAutenticacion: Solo orquesta el inicio de sesión y registro.
 * - D (Inversión de Dependencias):
 *     * El servicio de autenticación recibe el almacén como parámetro,
 *       no depende rígidamente de una base de datos específica.
 * ============================================================================
 */

// ----------------------------------------------------------------------------
// 1. VALIDADOR DE DNI (Principio S: Responsabilidad Única)
// ----------------------------------------------------------------------------
const ValidadorDni = {
  /**
   * Comprueba que el DNI tenga exactamente 8 dígitos y sean solo números.
   * @param {string} dni 
   * @returns {{ esValido: boolean, mensaje: string }}
   */
  validar(dni) {
    if (!dni || typeof dni !== 'string') {
      return { esValido: false, mensaje: 'Debe ingresar un número de DNI.' };
    }

    const dniLimpio = dni.trim();

    if (dniLimpio.length !== 8) {
      return { esValido: false, mensaje: 'El DNI debe tener exactamente 8 dígitos.' };
    }

    // Expresión regular: solo números del 0 al 9
    const soloDigitos = /^[0-9]{8}$/.test(dniLimpio);
    if (!soloDigitos) {
      return { esValido: false, mensaje: 'El DNI solo puede contener números, sin letras ni símbolos.' };
    }

    return { esValido: true, mensaje: 'DNI correcto.' };
  }
};

// ----------------------------------------------------------------------------
// 2. ALMACÉN DE USUARIOS (Principio S y D)
// Guarda los comerciantes del padrón y los trabajadores de la municipalidad.
// ----------------------------------------------------------------------------
class AlmacenUsuarios {
  constructor() {
    // Comerciantes empadronados de prueba (Datos Semilla)
    this.comerciantes = [
      {
        dni: '45871234',
        nombreCompleto: 'Juan Carlos Pérez Flores',
        telefono: '966123456',
        giro: 'Artesanía y Retablos',
        clave: '123456',
        estado: 'EMPADRONADO'
      },
      {
        dni: '72345678',
        nombreCompleto: 'María Elena Quispe Alanya',
        telefono: '966789123',
        giro: 'Gastronomía Tradicional',
        clave: '123456',
        estado: 'EMPADRONADO'
      }
    ];

    // Funcionarios municipales para fiscalización y administración (FSH-22)
    this.usuariosInternos = [
      {
        usuario: 'fiscalizador',
        alias: 'fiscalizador@mph.gob.pe',
        nombreCompleto: 'Carlos Mendoza Bendezú',
        rol: 'Fiscalizador',
        clave: '123456'
      },
      {
        usuario: 'admin',
        alias: 'admin@mph.gob.pe',
        nombreCompleto: 'Aldo Marcos Yanasupo',
        rol: 'Gestión MPH',
        clave: 'admin123'
      }
    ];
  }

  // Buscar un comerciante por su DNI (FSH-24)
  buscarComerciantePorDni(dni) {
    return this.comerciantes.find(c => c.dni === dni.trim());
  }

  // Guardar un nuevo comerciante en el padrón (FSH-10, FSH-36)
  registrarComerciante(nuevoComerciante) {
    this.comerciantes.push(nuevoComerciante);
    return nuevoComerciante;
  }

  // Buscar funcionario municipal por su usuario institucional
  buscarUsuarioInterno(usuario) {
    if (!usuario) return null;
    const uLimpio = usuario.trim().toLowerCase();
    return this.usuariosInternos.find(u => 
      u.usuario.toLowerCase() === uLimpio || 
      (u.alias && u.alias.toLowerCase() === uLimpio)
    );
  }
}

// ----------------------------------------------------------------------------
// 3. SERVICIO DE AUTENTICACIÓN (Principio S: Orquestar el Login)
// ----------------------------------------------------------------------------
class ServicioAutenticacion {
  constructor(almacen = new AlmacenUsuarios()) {
    // Inyección de dependencias (Principio D)
    this.almacen = almacen;
  }

  /**
   * Iniciar sesión como comerciante con DNI y clave (Jira: FSH-24)
   */
  iniciarSesionComerciante(dni, clave) {
    // 1. Validar formato de DNI usando el Validador
    const resultadoValidacion = ValidadorDni.validar(dni);
    if (!resultadoValidacion.esValido) {
      return { exito: false, mensaje: resultadoValidacion.mensaje };
    }

    if (!clave || clave.trim() === '') {
      return { exito: false, mensaje: 'Por favor, ingrese su contraseña.' };
    }

    // 2. Buscar en el padrón de comerciantes
    const comerciante = this.almacen.buscarComerciantePorDni(dni);
    if (!comerciante) {
      return { 
        exito: false, 
        mensaje: 'El DNI no está empadronado. Por favor, regístrese primero en el padrón municipal.' 
      };
    }

    // 3. Validar contraseña
    if (comerciante.clave !== clave) {
      return { exito: false, mensaje: 'Contraseña incorrecta. Intente de nuevo.' };
    }

    return {
      exito: true,
      mensaje: `¡Bienvenido(a), ${comerciante.nombreCompleto}!`,
      usuario: {
        dni: comerciante.dni,
        nombre: comerciante.nombreCompleto,
        giro: comerciante.giro,
        rol: 'Comerciante'
      }
    };
  }

  /**
   * Iniciar sesión como Fiscalizador o Administrador MPH (Jira: FSH-22)
   */
  iniciarSesionInterno(usuario, clave, rolEsperado) {
    if (!usuario || usuario.trim() === '') {
      return { exito: false, mensaje: 'Debe ingresar su usuario institucional o correo.' };
    }
    if (!clave || clave.trim() === '') {
      return { exito: false, mensaje: 'Debe ingresar su contraseña.' };
    }

    const funcionario = this.almacen.buscarUsuarioInterno(usuario);
    if (!funcionario) {
      return { exito: false, mensaje: 'Usuario no registrado en el sistema de la municipalidad.' };
    }

    if (funcionario.clave !== clave) {
      return { exito: false, mensaje: 'Contraseña incorrecta.' };
    }

    if (rolEsperado && funcionario.rol !== rolEsperado) {
      return { 
        exito: false, 
        mensaje: `Acceso denegado: este usuario pertenece al rol ${funcionario.rol}.` 
      };
    }

    return {
      exito: true,
      mensaje: `¡Acceso concedido! Bienvenido ${funcionario.nombreCompleto}`,
      usuario: {
        usuario: funcionario.usuario,
        nombre: funcionario.nombreCompleto,
        rol: funcionario.rol
      }
    };
  }

  /**
   * Registrar nuevo comerciante en el padrón municipal (Jira: FSH-10, FSH-36)
   */
  registrarNuevoComerciante(datos) {
    const { dni, nombreCompleto, telefono, giro, clave } = datos;

    // 1. Validar DNI
    const validacionDni = ValidadorDni.validar(dni);
    if (!validacionDni.esValido) {
      return { exito: false, mensaje: validacionDni.mensaje };
    }

    // 2. Validar que no esté repetido (Regla de unicidad de DNI)
    const existente = this.almacen.buscarComerciantePorDni(dni);
    if (existente) {
      return { exito: false, mensaje: 'Este número de DNI ya está empadronado en el sistema.' };
    }

    // 3. Validar campos obligatorios
    if (!nombreCompleto || nombreCompleto.trim().length < 3) {
      return { exito: false, mensaje: 'Debe ingresar sus nombres y apellidos completos.' };
    }
    if (!clave || clave.length < 4) {
      return { exito: false, mensaje: 'La contraseña debe tener al menos 4 caracteres.' };
    }

    // 4. Guardar
    const nuevo = {
      dni: dni.trim(),
      nombreCompleto: nombreCompleto.trim(),
      telefono: telefono || '',
      giro: giro || 'Comercio General',
      clave: clave,
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

// Exportar para que funcione tanto en Node.js (pruebas) como en el Navegador
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { ValidadorDni, AlmacenUsuarios, ServicioAutenticacion };
}
