CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    fecha_nacimiento DATE,
    peso_kg DECIMAL(5, 2) NOT NULL,
    estatura_m DECIMAL(3, 2) NOT NULL,
    genero VARCHAR(10) CHECK (genero IN ('Masculino', 'Femenino')),
    nivel_actividad VARCHAR(20) CHECK (nivel_actividad IN ('Sedentario', 'Ligeramente activo', 'Moderado', 'Muy activo')),
    meta_calorica INT DEFAULT 2200,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);