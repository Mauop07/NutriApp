import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Dependencias de Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Pantallas locales
import 'pantalla_principal.dart';

/// Pantalla de captura y actualizacion de datos fisiologicos.
/// Gestiona metricas fisicas, consumo del backend de calculo y persistencia en Firestore.
class PantallaDatosPersonales extends StatefulWidget {
  const PantallaDatosPersonales({super.key});

  @override
  State<PantallaDatosPersonales> createState() =>
      _PantallaDatosPersonalesState();
}

class _PantallaDatosPersonalesState extends State<PantallaDatosPersonales> {
  // Controladores de campos de texto
  final _nombreController = TextEditingController();
  final _pesoController = TextEditingController();
  final _estaturaController = TextEditingController();
  final _metaCaloricaController = TextEditingController();

  // Estado local del formulario
  DateTime? _fechaNacimiento;
  String? _genero;
  String? _nivelActividad;

  // Catalogos para selectores
  final List<String> _opcionesGenero = ['Femenino', 'Masculino'];
  final List<Map<String, dynamic>> _opcionesActividad = [
    {'label': 'Sedentario', 'value': '1.2'},
    {'label': 'Ligero', 'value': '1.375'},
    {'label': 'Moderado', 'value': '1.55'},
    {'label': 'Activo', 'value': '1.725'},
    {'label': 'Muy Activo', 'value': '1.9'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosActuales();
  }

  /// Carga el perfil actual desde Firestore si existe un registro previo.
  Future<void> _cargarDatosActuales() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _nombreController.text = data['nombre'] ?? '';
          _pesoController.text = (data['peso_kg'] ?? '').toString();
          _estaturaController.text = (data['altura_cm'] ?? '').toString();

          if (data['fechaNacimiento'] != null) {
            _fechaNacimiento = DateTime.parse(data['fechaNacimiento']);
          }

          final generoDb = data['genero'];
          if (generoDb == 'M') {
            _genero = 'Masculino';
          } else if (generoDb == 'F') {
            _genero = 'Femenino';
          }

          _nivelActividad = data['nivelActividad']?.toString();
          _metaCaloricaController.text = (data['meta_calorica'] ?? '')
              .toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _pesoController.dispose();
    _estaturaController.dispose();
    _metaCaloricaController.dispose();
    super.dispose();
  }

  /// Despliega el selector nativo de fecha para la fecha de nacimiento.
  Future<void> _seleccionarFecha(BuildContext context) async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (fechaSeleccionada != null) {
      setState(() {
        _fechaNacimiento = fechaSeleccionada;
      });
    }
  }

  /// Calcula la edad en años con base en la fecha de nacimiento.
  int _calcularEdad(DateTime fechaNacimiento) {
    final hoy = DateTime.now();
    int edad = hoy.year - fechaNacimiento.year;

    if (hoy.month < fechaNacimiento.month ||
        (hoy.month == fechaNacimiento.month && hoy.day < fechaNacimiento.day)) {
      edad--;
    }
    return edad;
  }

  /// Valida el formulario, solicita el calculo calorico al backend y persiste en Firestore.
  Future<void> _guardarYContinuar() async {
    if (_nombreController.text.trim().isEmpty ||
        _fechaNacimiento == null ||
        _pesoController.text.isEmpty ||
        _estaturaController.text.isEmpty ||
        _genero == null ||
        _nivelActividad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos obligatorios.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final edad = _calcularEdad(_fechaNacimiento!);
    final generoBackend = _genero == 'Masculino' ? 'M' : 'F';
    final peso = _pesoController.text.trim();
    final altura = _estaturaController.text.trim();

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = Uri.parse(
        'http://127.0.0.1:3000/calcular?peso=$peso&altura=$altura&edad=$edad&genero=$generoBackend&actividad=$_nivelActividad&t=$timestamp',
      );

      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final datosCalculados = json.decode(response.body);
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .set({
                'nombre': _nombreController.text.trim(),
                'fechaNacimiento': _fechaNacimiento?.toIso8601String(),
                'peso_kg': datosCalculados['peso_kg'],
                'altura_cm': datosCalculados['altura_cm'],
                'genero': datosCalculados['genero'],
                'edad': datosCalculados['edad_anios'],
                'nivelActividad': _nivelActividad,
                'tmb': datosCalculados['tmb'],
                'calorias_mantenimiento':
                    datosCalculados['calorias_mantenimiento'],
                'meta_calorica': _metaCaloricaController.text.isNotEmpty
                    ? int.parse(_metaCaloricaController.text)
                    : datosCalculados['calorias_mantenimiento'],
                'fechaRegistro': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PantallaPrincipal()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error del servidor: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error de conexion: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Completa tu perfil',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Estos datos son necesarios para calcular tu meta calorica ideal.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),

              // Nombre completo
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Fecha de nacimiento
              InkWell(
                onTap: () => _seleccionarFecha(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de Nacimiento',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _fechaNacimiento == null
                        ? 'Selecciona tu fecha'
                        : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Peso y Estatura
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pesoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Peso (kg)',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _estaturaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Estatura (cm)',
                        prefixIcon: Icon(Icons.height),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Genero
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Genero',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                initialValue: _genero,
                items: _opcionesGenero.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => _genero = newValue),
              ),
              const SizedBox(height: 16),

              // Nivel de Actividad
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Nivel de Actividad',
                  prefixIcon: Icon(Icons.directions_run),
                ),
                initialValue: _nivelActividad,
                items: _opcionesActividad.map((map) {
                  return DropdownMenuItem<String>(
                    value: map['value'],
                    child: Text(map['label']),
                  );
                }).toList(),
                onChanged: (newValue) =>
                    setState(() => _nivelActividad = newValue),
              ),
              const SizedBox(height: 16),

              // Meta Calorica opcional
              TextField(
                controller: _metaCaloricaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Meta Calorica (Opcional)',
                  hintText: 'Ej. 2000',
                  prefixIcon: Icon(Icons.local_fire_department_outlined),
                ),
              ),
              const SizedBox(height: 40),

              // Boton de Envio
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardarYContinuar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
