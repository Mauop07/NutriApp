import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';
import 'pantalla_configuracion_notificaciones.dart';
import 'pantalla_registro_alimentos.dart';
import 'pantalla_progreso.dart';
import 'pantalla_datos_personales.dart';
import 'pantalla_historial.dart';
import 'main.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  // Estados y variables locales de control
  int _indiceActual = 1; // 0: Historial, 1: Inicio (Dashboard), 2: Perfil
  bool _cargandoDatos = true;

  // Métricas fisiológicas y metas calóricas
  double _tmb = 0.0;
  double _caloriasMantenimiento = 0.0;
  double _caloriasMeta = 2000.0;

  // Estado del Dashboard (Inicio)
  double _caloriasActuales = 0.0;
  final List<Map<String, String>> _comidasDeHoy = [];
  bool get _limiteSuperado => _caloriasActuales > _caloriasMeta;

  // Datos del perfil de usuario
  String _nombreUsuario = 'Usuario';
  String _correoUsuario = '';
  String _fechaNacimiento = '-';
  int _edad = 0;
  double _pesoKg = 0.0;
  double _alturaCm = 0.0;
  String _genero = '-';
  String _nivelActividad = '-';
  String _factorActividad = '-';

  @override
  void initState() {
    super.initState();
    NotificationService().init();
    _cargarDatosUsuario();
  }

  /// Obtiene la fecha actual en formato YYYY-MM-DD para usarla como ID de documento.
  String _obtenerFechaHoy() {
    final ahora = DateTime.now();
    return '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';
  }

  /// Guarda una nueva comida en el historial diario del usuario en Firestore.
  Future<void> _guardarComidaEnFirestore(
    Map<String, dynamic> datosComida,
    String hora,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final fechaHoy = _obtenerFechaHoy();
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('historial_diario')
        .doc(fechaHoy);

    final nuevaComida = Map<String, dynamic>.from(datosComida);
    nuevaComida['hora'] = hora;

    final int kcalTotales = datosComida['calorias_totales'] as int;

    try {
      await docRef.set({
        'calorias_totales': FieldValue.increment(kcalTotales),
        'comidas': FieldValue.arrayUnion([nuevaComida]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error guardando en historial: $e");
    }
  }

  /// Recupera la información del usuario autenticado y su historial de hoy desde Firestore.
  Future<void> _cargarDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() => _correoUsuario = user.email ?? 'Sin correo');

      try {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

        final fechaHoy = _obtenerFechaHoy();
        final historialDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('historial_diario')
            .doc(fechaHoy)
            .get();

        double caloriasGuardadas = 0.0;
        List<Map<String, String>> listaComidasGuardadas = [];

        if (historialDoc.exists && historialDoc.data() != null) {
          final historialData = historialDoc.data()!;
          caloriasGuardadas = (historialData['calorias_totales'] ?? 0)
              .toDouble();

          if (historialData['comidas'] != null) {
            final listaRaw = historialData['comidas'] as List;
            listaComidasGuardadas = listaRaw
                .map(
                  (e) => {
                    'hora': e['hora'].toString(),
                    'comida': e['nombre_visual'].toString(),
                    'calorias': '${e['calorias_totales']} kcal',
                  },
                )
                .toList();
          }
        }

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;

          String fechaFormateada = '-';
          if (data['fechaNacimiento'] != null) {
            final fecha = DateTime.parse(data['fechaNacimiento']);
            fechaFormateada = '${fecha.day}/${fecha.month}/${fecha.year}';
          }

          final actividadRaw = data['nivelActividad']?.toString() ?? '-';
          final actividadTexto = _mapearActividad(actividadRaw);

          setState(() {
            _nombreUsuario = data['nombre'] ?? 'Usuario';
            _caloriasMeta = (data['meta_calorica'] ?? 2000).toDouble();
            _fechaNacimiento = fechaFormateada;
            _edad = data['edad'] ?? 0;
            _pesoKg = (data['peso_kg'] ?? 0).toDouble();
            _alturaCm = (data['altura_cm'] ?? 0).toDouble();
            _genero = data['genero'] ?? '-';
            _nivelActividad = actividadTexto;
            _factorActividad = actividadRaw;
            _tmb = (data['tmb'] ?? 0).toDouble();
            _caloriasMantenimiento = (data['calorias_mantenimiento'] ?? 0)
                .toDouble();

            _caloriasActuales = caloriasGuardadas;
            _comidasDeHoy.clear();
            _comidasDeHoy.addAll(listaComidasGuardadas);
          });
        }
      } catch (e) {
        debugPrint("Error leyendo Firestore: $e");
      } finally {
        if (mounted) setState(() => _cargandoDatos = false);
      }
    } else {
      if (mounted) setState(() => _cargandoDatos = false);
    }
  }

  /// Traduce el multiplicador numérico de actividad física a una etiqueta legible.
  String _mapearActividad(String valor) {
    switch (valor) {
      case '1.2':
        return 'Sedentario';
      case '1.375':
        return 'Ligero';
      case '1.55':
        return 'Moderado';
      case '1.725':
        return 'Activo';
      case '1.9':
        return 'Muy Activo';
      default:
        return valor;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoDatos) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: (_indiceActual == 0 || _indiceActual == 2)
          ? Colors.white
          : (_limiteSuperado
                ? const Color(0xFFE53935)
                : const Color(0xFF43A047)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _obtenerPantallaActual(),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Gestiona la visualización según la pestaña activa en la barra de navegación.
  Widget _obtenerPantallaActual() {
    switch (_indiceActual) {
      case 0:
        return _buildHistorial();
      case 1:
        return _buildDashboard();
      case 2:
        return _buildPerfil();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildHistorial() {
    return KeyedSubtree(
      key: const ValueKey(0),
      child: PantallaHistorial(
        onDatosModificados: () {
          _cargarDatosUsuario();
        },
      ),
    );
  }

  Widget _buildDashboard() {
    return KeyedSubtree(
      key: const ValueKey(1),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildTextosEstado(),
          const SizedBox(height: 30),
          _buildAroProgreso(),
          const SizedBox(height: 30),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildTablaComidas(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfil() {
    return KeyedSubtree(
      key: const ValueKey(2),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            'Mi Perfil',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blueAccent,
                          child: Icon(
                            Icons.person,
                            size: 35,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nombreUsuario,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _correoUsuario,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información personal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFilaDato('Fecha de nacimiento', _fechaNacimiento),
                        const Divider(),
                        _buildFilaDato('Peso', '${_pesoKg.toInt()} kg'),
                        const Divider(),
                        _buildFilaDato('Estatura', '${_alturaCm.toInt()} cm'),
                        const Divider(),
                        _buildFilaDato('Género', _genero),
                        const Divider(),
                        _buildFilaDato('Nivel de actividad', _nivelActividad),
                        const Divider(),
                        _buildFilaDatoInteractiva(
                          'Tasa Metabólica Basal (TMB)',
                          '${_tmb.toInt()} kcal',
                          () {
                            String formulaAmigable = _genero == 'Masculino'
                                ? '88.4 + (13.4 × ${_pesoKg.toInt()} kg) + (4.8 × ${_alturaCm.toInt()} cm) - (5.7 × $_edad años)'
                                : '447.6 + (9.2 × ${_pesoKg.toInt()} kg) + (3.1 × ${_alturaCm.toInt()} cm) - (4.3 × $_edad años)';
                            _mostrarExplicacionCalculo(
                              'Tasa Metabólica Basal',
                              'Calorías diarias que tu cuerpo requiere exclusivamente para mantener sus funciones vitales en reposo.\n\nCálculo (Harris-Benedict):\n$formulaAmigable\n\nTotal = ${_tmb.toInt()} kcal.',
                            );
                          },
                        ),
                        const Divider(),
                        _buildFilaDatoInteractiva(
                          'Calorías de Mantenimiento',
                          '${_caloriasMantenimiento.toInt()} kcal',
                          () {
                            _mostrarExplicacionCalculo(
                              'Calorías de Mantenimiento',
                              'Calorías diarias requeridas para mantener tu peso actual, ajustadas a tu estilo de vida.\n\nCálculo:\nTMB (${_tmb.toInt()} kcal) × Nivel de actividad ($_nivelActividad: $_factorActividad).',
                            );
                          },
                        ),
                        const Divider(),
                        _buildFilaDato(
                          'Meta calórica (Ingresada)',
                          '${_caloriasMeta.toInt()} kcal',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PantallaProgreso(),
                          ),
                        );
                      },
                      child: const Text(
                        'Ver Progreso',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PantallaDatosPersonales(),
                          ),
                        );
                      },
                      child: const Text(
                        'Editar Perfil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PantallaConfiguracionNotificaciones(),
                          ),
                        );
                      },
                      child: const Text(
                        'Configurar Notificaciones',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PantallaLogin(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una fila simple de datos para la sección de perfil.
  Widget _buildFilaDato(String etiqueta, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(color: Colors.black54, fontSize: 15),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Construye una fila interactiva con icono informativo para métricas avanzadas.
  Widget _buildFilaDatoInteractiva(
    String etiqueta,
    String valor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  etiqueta,
                  style: const TextStyle(color: Colors.black54, fontSize: 15),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blueAccent,
                ),
              ],
            ),
            Text(
              valor,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra un diálogo flotante explicativo sobre fórmulas de cálculo (TMB/Mantenimiento).
  void _mostrarExplicacionCalculo(String titulo, String explicacion) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            explicacion,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Entendido',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Construye los textos de estado superior en el Dashboard principal.
  Widget _buildTextosEstado() {
    return Column(
      children: [
        Text(
          _limiteSuperado ? 'Límite superado' : 'Vas muy bien',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _limiteSuperado
              ? 'Has superado tu meta calórica'
              : 'Sigue con tus hábitos saludables',
          style: const TextStyle(fontSize: 18, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Construye el indicador circular de progreso calórico diario.
  Widget _buildAroProgreso() {
    final progreso = (_caloriasActuales / _caloriasMeta).clamp(0.0, 1.0);

    final double anchoPantalla = MediaQuery.of(context).size.width;
    final double tamanoAro = anchoPantalla * 0.55;

    return SizedBox(
      width: tamanoAro,
      height: tamanoAro,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progreso,
            strokeWidth: 16,
            backgroundColor: Colors.black12,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _caloriasActuales.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '/ ${_caloriasMeta.toInt()} kcal',
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la tabla resumen de comidas registradas hoy en el Dashboard.
  Widget _buildTablaComidas() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Comidas de hoy',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildFilaTabla('Hora', 'Comida', 'Calorías', esEncabezado: true),
          const SizedBox(height: 4),
          const Divider(color: Colors.black26, thickness: 2),
          Expanded(
            child: _comidasDeHoy.isEmpty
                ? const Center(
                    child: Text(
                      'Aún no has registrado comidas',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _comidasDeHoy.length,
                    itemBuilder: (context, index) {
                      final comida = _comidasDeHoy[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: _buildFilaTabla(
                          comida['hora']!,
                          comida['comida']!,
                          comida['calorias']!,
                          esCaloriaAzul: true,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          _buildBotonRegistrar(),
        ],
      ),
    );
  }

  /// Construye una fila individual para la tabla de comidas del día.
  Widget _buildFilaTabla(
    String hora,
    String comida,
    String calorias, {
    bool esEncabezado = false,
    bool esCaloriaAzul = false,
  }) {
    final estiloBase = TextStyle(
      fontSize: 14,
      color: esEncabezado ? Colors.black54 : Colors.black,
      fontWeight: FontWeight.bold,
    );
    return Row(
      children: [
        SizedBox(width: 70, child: Text(hora, style: estiloBase)),
        Expanded(
          child: Text(comida, style: estiloBase, textAlign: TextAlign.left),
        ),
        Text(
          calorias,
          style: esCaloriaAzul
              ? const TextStyle(
                  color: Color(0xFF1E88E5),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                )
              : estiloBase,
        ),
      ],
    );
  }

  /// Construye el botón principal de acción para registrar una nueva comida.
  Widget _buildBotonRegistrar() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _limiteSuperado
              ? const Color(0xFFE53935)
              : Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  PantallaRegistroAlimentos(
                    onComidaAgregada: (datosComida) {
                      final ahora = DateTime.now();
                      final horaFormateada =
                          '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';

                      final int kcal = datosComida['calorias_totales'] as int;
                      final String nombreVisual =
                          datosComida['nombre_visual'] as String;

                      setState(() {
                        _caloriasActuales += kcal;
                        _comidasDeHoy.add({
                          'hora': horaFormateada,
                          'comida': nombreVisual,
                          'calorias': '$kcal kcal',
                        });
                      });
                      _guardarComidaEnFirestore(datosComida, horaFormateada);
                    },
                  ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          );
        },
        child: const Text(
          'Registrar comida',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Construye la barra de navegación inferior de la aplicación.
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _indiceActual,
      selectedItemColor: _indiceActual == 1 && _limiteSuperado
          ? const Color(0xFFE53935)
          : Theme.of(context).colorScheme.primary,
      onTap: (index) => setState(() => _indiceActual = index),
      items: const [
        BottomNavigationBarItem(
          label: 'Historial',
          icon: Icon(Icons.find_in_page_outlined),
        ),
        BottomNavigationBarItem(
          label: 'Inicio',
          icon: Icon(Icons.home_outlined),
        ),
        BottomNavigationBarItem(
          label: 'Perfil',
          icon: Icon(Icons.person_outlined),
        ),
      ],
    );
  }
}
