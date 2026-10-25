import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pantalla_principal.dart';
import 'calculadora_nutricional.dart';

class PantallaDatosPersonales extends StatefulWidget {
  const PantallaDatosPersonales({super.key});

  @override
  State<PantallaDatosPersonales> createState() =>
      _PantallaDatosPersonalesState();
}

class _PantallaDatosPersonalesState extends State<PantallaDatosPersonales> {
  // Controladores de campos de texto para métricas de usuario
  final _nombreController = TextEditingController();
  final _pesoController = TextEditingController();
  final _estaturaController = TextEditingController();
  final _metaCaloricaController = TextEditingController();

  // Estados locales del formulario
  DateTime? _fechaNacimiento;
  String? _genero;
  String? _nivelActividad;

  // Catálogos estáticos para selectores
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
          if (generoDb == 'Masculino' || generoDb == 'M') {
            _genero = 'Masculino';
          } else if (generoDb == 'Femenino' || generoDb == 'F') {
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

  /// Calcula la edad en años con base en la fecha de nacimiento ingresada.
  int _calcularEdad(DateTime fechaNacimiento) {
    final hoy = DateTime.now();
    int edad = hoy.year - fechaNacimiento.year;

    if (hoy.month < fechaNacimiento.month ||
        (hoy.month == fechaNacimiento.month && hoy.day < fechaNacimiento.day)) {
      edad--;
    }
    return edad;
  }

  /// Valida el formulario, ejecuta los cálculos calóricos y guarda los datos en Firestore.
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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final edad = _calcularEdad(_fechaNacimiento!);
    final peso = double.tryParse(_pesoController.text.trim()) ?? 0.0;
    final altura = double.tryParse(_estaturaController.text.trim()) ?? 0.0;
    final factorActividad = double.tryParse(_nivelActividad!) ?? 1.2;

    double tmbCalculada = CalculadoraNutricional.calcularTMB(
      genero: _genero!,
      pesoKg: peso,
      alturaCm: altura,
      edad: edad,
    );

    double caloriasMantenimiento = CalculadoraNutricional.calcularMantenimiento(
      tmbCalculada,
      factorActividad,
    );

    double metaFinal = caloriasMantenimiento;
    if (_metaCaloricaController.text.trim().isNotEmpty) {
      metaFinal =
          double.tryParse(_metaCaloricaController.text.trim()) ??
          caloriasMantenimiento;
    }

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set(
        {
          'nombre': _nombreController.text.trim(),
          'fechaNacimiento': _fechaNacimiento?.toIso8601String(),
          'peso_kg': peso,
          'altura_cm': altura,
          'genero': _genero,
          'edad': edad,
          'nivelActividad': _nivelActividad,
          'tmb': tmbCalculada,
          'calorias_mantenimiento': caloriasMantenimiento,
          'meta_calorica': metaFinal,
          'fechaRegistro': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PantallaPrincipal()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al guardar datos: $e')));
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
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 16),
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
