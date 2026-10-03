const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/calcular', (req, res) => {
    const { peso, altura, edad, genero, actividad } = req.query;

    if (!peso || !altura || !edad || !genero || !actividad) {
        return res.status(400).json({ 
            error: "Faltan parámetros. Usa: /calcular?peso=70&altura=175&edad=25&genero=M&actividad=1.55" 
        });
    }

    const p = parseFloat(peso);
    const a = parseFloat(altura);
    const e = parseInt(edad);
    const act = parseFloat(actividad);

    let tmb = 0;
    if (genero.toUpperCase() === 'M') {
        tmb = 88.362 + (13.397 * p) + (4.799 * a) - (5.677 * e);
    } else {
        tmb = 447.593 + (9.247 * p) + (3.098 * a) - (4.330 * e);
    }

    const mantenimiento = tmb * act;

    res.json({
        genero: genero.toUpperCase() === 'M' ? 'Masculino' : 'Femenino',
        peso_kg: p,
        altura_cm: a,
        edad_anios: e,
        tmb: Math.round(tmb),
        calorias_mantenimiento: Math.round(mantenimiento)
    });
});

app.listen(PORT, () => {
    console.log(`Servidor corriendo en http://localhost:${PORT}`);
});