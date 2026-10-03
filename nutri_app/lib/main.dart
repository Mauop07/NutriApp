import 'package:flutter/material.dart';

void main() {
  runApp(const NutriApp());
}

class NutriApp extends StatelessWidget {
  const NutriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PantallaLogin(),
    );
  }
}

// ==========================================
// PANTALLA DE LOGIN
// ==========================================
class PantallaLogin extends StatelessWidget {
  const PantallaLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          // Agregado para evitar errores si el teclado se abre
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 60.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset('assets/icon_login_leaf.png', height: 80),
              const SizedBox(height: 15),

              // Título
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Nutri',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'App',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Input: Correo electrónico
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Input: Contraseña
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_rounded),
                  suffixIcon: Icon(Icons.visibility_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // Botón: Entrar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Entrar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Enlace: Recuperar contraseña
              TextButton(
                onPressed: () {},
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Separador visual
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('o', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 20),

              // Botón: Crear Cuenta
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    // Esta es la instrucción que abre la pantalla de registro
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PantallaRegistro(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Crear Cuenta',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PANTALLA DE REGISTRO
// ==========================================
class PantallaRegistro extends StatelessWidget {
  const PantallaRegistro({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 60.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Título
              const Text(
                'Crear Cuenta',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Por favor, completa los siguientes campos.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Input: Nombre
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Input: Correo electrónico
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Input: Contraseña
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_rounded),
                  suffixIcon: Icon(Icons.visibility_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // Botón: Registrate
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Registrarse',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Enlace: Volver al login
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Regresa a la pantalla anterior
                },
                child: const Text(
                  '¿Ya tienes cuenta? Inicia sesión',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
