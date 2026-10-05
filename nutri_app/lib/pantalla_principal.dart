import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pantalla_datos_personales.dart';
import 'main.dart';

/// Pantalla principal (Dashboard). Gestiona la navegación inferior
/// y muestra el resumen calórico diario, el progreso y la vista de perfil.
class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _indiceActual = 1;

  // Estado del Dashboard
  double _caloriasActuales = 0.0;
  double _caloriasMeta = 2000.0;
  bool _cargandoDatos = true;

  // Datos del Perfil
  String _nombreUsuario = 'Usuario';
  String _correoUsuario = '';
  String _fechaNacimiento = '-';
  double _pesoKg = 0.0;
  double _alturaCm = 0.0;
  String _genero = '-';
  String _nivelActividad = '-';

  bool get _limiteSuperado => _caloriasActuales > _caloriasMeta;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  /// Recupera la información del usuario autenticado desde Firestore.
  Future<void> _cargarDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        _correoUsuario = user.email ?? 'Sin correo';
      });

      try {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

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
            _pesoKg = (data['peso_kg'] ?? 0).toDouble();
            _alturaCm = (data['altura_cm'] ?? 0).toDouble();
            _genero = data['genero'] ?? '-';
            _nivelActividad = actividadTexto;
          });
        }
      } catch (e) {
        debugPrint("Error leyendo Firestore: $e");
      } finally {
        setState(() {
          _cargandoDatos = false;
        });
      }
    } else {
      setState(() {
        _cargandoDatos = false;
      });
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
      backgroundColor: _indiceActual == 2
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

  // ==========================================
  // NAVEGACIÓN DE VISTAS
  // ==========================================

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
    return const Center(
      key: ValueKey(0),
      child: Text(
        'Historial de Comidas\n(Próximamente)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return KeyedSubtree(
      key: const ValueKey(1),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _buildTextosEstado(),
                          const SizedBox(height: 48),
                          _buildAroProgreso(),
                          const Spacer(),
                          const SizedBox(height: 40),
                          _buildTablaComidas(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildBotonRegistrar(),
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
                  // Tarjeta de Identificación
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

                  // Tarjeta de Datos Fisiológicos
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
                        _buildFilaDato(
                          'Meta calórica',
                          '${_caloriasMeta.toInt()} kcal',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Acciones de Cuenta
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sección de Progreso próximamente'),
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

  // ==========================================
  // WIDGETS DEL DASHBOARD
  // ==========================================

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

  Widget _buildAroProgreso() {
    final progreso = (_caloriasActuales / _caloriasMeta).clamp(0.0, 1.0);

    return SizedBox(
      width: 220,
      height: 220,
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

  Widget _buildTablaComidas() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comidas de hoy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildFilaTabla('Hora', 'Comida', 'Calorías', esEncabezado: true),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                'Sin registros (Placeholder)',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilaTabla(
    String hora,
    String comida,
    String calorias, {
    bool esEncabezado = false,
  }) {
    final estilo = TextStyle(
      fontWeight: esEncabezado ? FontWeight.bold : FontWeight.normal,
    );

    return Row(
      children: [
        Expanded(child: Text(hora, style: estilo)),
        Expanded(child: Text(comida, style: estilo)),
        Expanded(
          child: Text(calorias, style: estilo, textAlign: TextAlign.right),
        ),
      ],
    );
  }

  Widget _buildBotonRegistrar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
        ),
        onPressed: () {
          setState(() {
            _caloriasActuales += 250;
          });
        },
        child: Text(
          'Registrar comida',
          style: TextStyle(
            color: _limiteSuperado
                ? const Color(0xFFE53935)
                : Theme.of(context).colorScheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _indiceActual,
      selectedItemColor: _indiceActual == 1 && _limiteSuperado
          ? const Color(0xFFE53935)
          : Theme.of(context).colorScheme.primary,
      onTap: (index) {
        setState(() {
          _indiceActual = index;
        });
      },
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
