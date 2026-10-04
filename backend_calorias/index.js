/**
 * NutriApp - Backend API
 * Microservicio para el cálculo de la Tasa Metabólica Basal (TMB) y calorías de mantenimiento.
 * Basado en la ecuación de Harris-Benedict.
 */

const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Configuración de Middlewares
app.use(cors()); // Permite peticiones desde el frontend web/móvil
app.use(express.json()); 

/**
 * Endpoint: GET /calcular
 * Descripción: Calcula las métricas calóricas basadas en datos fisiológicos.
 * Query Params: peso (kg), altura (cm), edad (años), genero (M/F), actividad (factor numérico)
 */
app.get('/calcular', (req, res) => {
    const { peso, altura, edad, genero, actividad } = req.query;

    // 1. Validación de parámetros faltantes
    if (!peso || !altura || !edad || !genero || !actividad) {
        return res.status(400).json({ 
            error: "Faltan parámetros. Ejemplo de uso: /calcular?peso=70&altura=175&edad=25&genero=M&actividad=1.55" 
        });
    }

    // 2. Conversión de tipos de datos
    const pesoKg = parseFloat(peso);
    const alturaCm = parseFloat(altura);
    const edadAnios = parseInt(edad, 10);
    const factorActividad = parseFloat(actividad);

    // 3. Validación de seguridad (evitar strings no numéricos)
    if (isNaN(pesoKg) || isNaN(alturaCm) || isNaN(edadAnios) || isNaN(factorActividad)) {
        return res.status(400).json({ 
            error: "Los parámetros de peso, altura, edad y actividad deben ser valores numéricos válidos." 
        });
    }

    // 4. Cálculo de la Tasa Metabólica Basal (Harris-Benedict)
    let tmb = 0;
    const esMasculino = genero.toUpperCase() === 'M';

    if (esMasculino) {
        tmb = 88.362 + (13.397 * pesoKg) + (4.799 * alturaCm) - (5.677 * edadAnios);
    } else {
        tmb = 447.593 + (9.247 * pesoKg) + (3.098 * alturaCm) - (4.330 * edadAnios);
    }

    // 5. Cálculo de Calorías de Mantenimiento
    const caloriasMantenimiento = tmb * factorActividad;

    // 6. Respuesta al cliente
    res.json({
        genero: esMasculino ? 'Masculino' : 'Femenino',
        peso_kg: pesoKg,
        altura_cm: alturaCm,
        edad_anios: edadAnios,
        tmb: Math.round(tmb),
        calorias_mantenimiento: Math.round(caloriasMantenimiento)
    });
});

// Inicialización del servidor
app.listen(PORT, () => {
    console.log(`Servidor de NutriApp corriendo en http://localhost:${PORT}`);
});