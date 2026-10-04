// Cargar librería de PostgreSQL
const { Pool } = require('pg');

// Configuración de conexión a PostgreSQL (usa tu contraseña)
const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'nutriapp_db',
    password: 'alejo', // <-- Sustituye esto con tu contraseña de PostgreSQL
    port: 5432,
});

// SCRUM-11: Función para calcular Tasa Metabólica Basal (TMB - Fórmula Mifflin-St Jeor)
function calcularTMB(pesoKg, estaturaM, edad, genero) {
    const estaturaCm = estaturaM * 100;
    if (genero.toLowerCase() === 'masculino') {
        return (10 * pesoKg) + (6.25 * estaturaCm) - (5 * edad) + 5;
    } else {
        return (10 * pesoKg) + (6.25 * estaturaCm) - (5 * edad) - 161;
    }
}

// SCRUM-12: Función para calcular Calorías de Mantenimiento
function calcularCaloriasMantenimiento(tmb, nivelActividad) {
    const factores = {
        'sedentario': 1.2,
        'ligeramente activo': 1.375,
        'moderado': 1.55,
        'muy activo': 1.725
    };
    const factor = factores[nivelActividad.toLowerCase()] || 1.2;
    return Math.round(tmb * factor);
}

// Función principal para probar con los datos de PostgreSQL (SCRUM-9)
async function procesarUsuario(idUsuario) {
    try {
        const res = await pool.query('SELECT * FROM usuarios WHERE id = $1', [idUsuario]);
        
        if (res.rows.length === 0) {
            console.log('Usuario no encontrado');
            return;
        }

        const usuario = res.rows[0];
        
        // Calcular edad
        const hoy = new Date();
        const nacimiento = new Date(usuario.fecha_nacimiento);
        let edad = hoy.getFullYear() - nacimiento.getFullYear();

        // SCRUM-11: Calcular TMB
        const tmb = calcularTMB(parseFloat(usuario.peso_kg), parseFloat(usuario.estatura_m), edad, usuario.genero);

        // SCRUM-12: Calcular Calorías de Mantenimiento
        const caloriasMantenimiento = calcularCaloriasMantenimiento(tmb, usuario.nivel_actividad);

        console.log('--- RESULTADOS PARA EL USUARIO ---');
        console.log(`Nombre: ${usuario.nombre}`);
        console.log(`Peso: ${usuario.peso_kg} kg | Estatura: ${usuario.estatura_m} m | Género: ${usuario.genero}`);
        console.log(`Tasa Metabólica Basal (TMB - SCRUM-11): ${Math.round(tmb)} kcal/día`);
        console.log(`Calorías de Mantenimiento (SCRUM-12): ${caloriasMantenimiento} kcal/día`);
        
    } catch (err) {
        console.error('Error ejecutando la consulta:', err.stack);
    } finally {
        pool.end();
    }
}

// Ejecutar prueba con el primer usuario (ID 1)
procesarUsuario(1);