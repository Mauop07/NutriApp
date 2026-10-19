import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PantallaHistorial extends StatefulWidget {
  final VoidCallback? onDatosModificados;

  const PantallaHistorial({super.key, this.onDatosModificados});

  @override
  State<PantallaHistorial> createState() => _PantallaHistorialState();
}

class _PantallaHistorialState extends State<PantallaHistorial> {
  // ==========================================
  // ESTADO Y VARIABLES LOCALES
  // ==========================================
  DateTime _fechaSeleccionada = DateTime.now();
  int _tabActual = 0; // 0: Día, 1: Semana, 2: Mes
  bool _cargando = false;
  bool _modoEdicion = false;

  List<Map<String, dynamic>> _comidas = [];
  List<Map<String, dynamic>> _resumenDias = [];
  double _totalCalorias = 0.0;

  final List<String> _meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ==========================================
  // UTILIDADES Y FORMATO
  // ==========================================
  String _formatoFechaBD(DateTime fecha) {
    return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
  }

  String _formatoTextoFecha() {
    if (_tabActual == 0) {
      return '${_fechaSeleccionada.day} de ${_meses[_fechaSeleccionada.month - 1]} de ${_fechaSeleccionada.year}';
    } else if (_tabActual == 1) {
      final inicio = _fechaSeleccionada.subtract(
        Duration(days: _fechaSeleccionada.weekday - 1),
      );
      final fin = inicio.add(const Duration(days: 6));
      final mesCortoInicio = _meses[inicio.month - 1].substring(0, 3);
      final mesCortoFin = _meses[fin.month - 1].substring(0, 3);
      if (inicio.month == fin.month) {
        return '${inicio.day} - ${fin.day} $mesCortoInicio ${inicio.year}';
      }
      return '${inicio.day} $mesCortoInicio - ${fin.day} $mesCortoFin ${fin.year}';
    } else {
      final mes = _meses[_fechaSeleccionada.month - 1];
      return '${mes[0].toUpperCase()}${mes.substring(1)} ${_fechaSeleccionada.year}';
    }
  }

  String _obtenerTextoTotal() {
    if (_tabActual == 0) return 'Total del día';
    if (_tabActual == 1) return 'Total de la semana';
    return 'Total del mes';
  }

  void _cambiarFecha(int direccion) {
    setState(() {
      if (_tabActual == 0) {
        _fechaSeleccionada = _fechaSeleccionada.add(Duration(days: direccion));
      } else if (_tabActual == 1) {
        _fechaSeleccionada = _fechaSeleccionada.add(
          Duration(days: direccion * 7),
        );
      } else {
        _fechaSeleccionada = DateTime(
          _fechaSeleccionada.year,
          _fechaSeleccionada.month + direccion,
          _fechaSeleccionada.day,
        );
      }
    });
    _cargarDatos();
  }

  // ==========================================
  // OPERACIONES DE BASE DE DATOS (FIREBASE)
  // ==========================================
  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _modoEdicion = false;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (_tabActual == 0) {
        // Carga diaria individual
        final fechaStr = _formatoFechaBD(_fechaSeleccionada);
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('historial_diario')
            .doc(fechaStr)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final listaRaw = data['comidas'] as List? ?? [];
          setState(() {
            _comidas = listaRaw
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            _totalCalorias = (data['calorias_totales'] ?? 0).toDouble();
          });
        } else {
          setState(() {
            _comidas = [];
            _totalCalorias = 0.0;
          });
        }
      } else {
        // Carga agrupada (Semanal/Mensual)
        DateTime inicio;
        DateTime fin;

        if (_tabActual == 1) {
          inicio = _fechaSeleccionada.subtract(
            Duration(days: _fechaSeleccionada.weekday - 1),
          );
          fin = inicio.add(const Duration(days: 6));
        } else {
          inicio = DateTime(
            _fechaSeleccionada.year,
            _fechaSeleccionada.month,
            1,
          );
          fin = DateTime(
            _fechaSeleccionada.year,
            _fechaSeleccionada.month + 1,
            0,
          );
        }

        final inicioStr = _formatoFechaBD(inicio);
        final finStr = _formatoFechaBD(fin);

        final query = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('historial_diario')
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: inicioStr)
            .where(FieldPath.documentId, isLessThanOrEqualTo: finStr)
            .get();

        double sumaTotal = 0;
        List<Map<String, dynamic>> resumen = [];

        for (var doc in query.docs) {
          final data = doc.data();
          final cals = (data['calorias_totales'] ?? 0).toDouble();
          if (cals > 0) {
            sumaTotal += cals;
            final partes = doc.id.split('-');
            final mesNombre = _meses[int.parse(partes[1]) - 1].substring(0, 3);

            resumen.add({
              'id': doc.id,
              'fechaVisual': '${partes[2]} de $mesNombre',
              'calorias': '${cals.toInt()} kcal',
            });
          }
        }

        resumen.sort((a, b) => a['id'].compareTo(b['id']));

        setState(() {
          _resumenDias = resumen;
          _totalCalorias = sumaTotal;
        });
      }
    } catch (e) {
      debugPrint("Error leyendo historial: $e");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _eliminarComida(Map<String, dynamic> comidaAEliminar) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final caloriasStr = comidaAEliminar['calorias'].toString().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final caloriasARestar = int.tryParse(caloriasStr) ?? 0;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar registro?'),
        content: Text(
          'Se eliminará "${comidaAEliminar['comida']}" y se restarán $caloriasARestar kcal de tu total.',
        ),
        actionsPadding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16,
          top: 8,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Eliminar', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    setState(() => _cargando = true);

    try {
      final fechaStr = _formatoFechaBD(_fechaSeleccionada);
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('historial_diario')
          .doc(fechaStr)
          .update({
            'comidas': FieldValue.arrayRemove([comidaAEliminar]),
            'calorias_totales': FieldValue.increment(-caloriasARestar),
          });

      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Registro eliminado')));

      await _cargarDatos();
      if (widget.onDatosModificados != null) widget.onDatosModificados!();
    } catch (e) {
      debugPrint("Error eliminando: $e");
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _editarComida(Map<String, dynamic> comidaActual) async {
    final TextEditingController horaCtrl = TextEditingController(
      text: comidaActual['hora'],
    );
    final TextEditingController nombreCtrl = TextEditingController(
      text: comidaActual['comida'],
    );
    final calActualesStr = comidaActual['calorias'].toString().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final TextEditingController calCtrl = TextEditingController(
      text: calActualesStr,
    );

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar registro'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: horaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Hora (Ej: 08:30)',
                  prefixIcon: Icon(Icons.access_time, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alimento',
                  prefixIcon: Icon(Icons.restaurant, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: calCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calorías',
                  prefixIcon: Icon(Icons.local_fire_department, size: 20),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16,
          top: 8,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Guardar', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    setState(() => _cargando = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final int calViejas = int.tryParse(calActualesStr) ?? 0;
      final int calNuevas = int.tryParse(calCtrl.text.trim()) ?? 0;
      final int diferenciaCalorias = calNuevas - calViejas;

      final nuevaComida = {
        'hora': horaCtrl.text.trim(),
        'comida': nombreCtrl.text.trim(),
        'calorias': '${calNuevas} kcal',
      };

      final int index = _comidas.indexOf(comidaActual);
      if (index != -1) _comidas[index] = nuevaComida;

      final nuevoTotal = _totalCalorias + diferenciaCalorias;
      final fechaStr = _formatoFechaBD(_fechaSeleccionada);

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('historial_diario')
          .doc(fechaStr)
          .update({'comidas': _comidas, 'calorias_totales': nuevoTotal});

      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Registro actualizado')));

      await _cargarDatos();
      if (widget.onDatosModificados != null) widget.onDatosModificados!();
    } catch (e) {
      debugPrint("Error editando: $e");
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ==========================================
  // CONSTRUCCIÓN DE LA INTERFAZ (UI)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final colorPrincipal = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        const SizedBox(height: 10),
        const Text(
          'Historial',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // --- Selector de Pestañas (Día/Semana/Mes) ---
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              _buildTab('Día', 0, colorPrincipal),
              _buildTab('Semana', 1, colorPrincipal),
              _buildTab('Mes', 2, colorPrincipal),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- Navegador de Fechas ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                size: 20,
                color: Colors.black87,
              ),
              onPressed: () => _cambiarFecha(-1),
            ),
            InkWell(
              onTap: () async {
                final fechaElegida = await showDatePicker(
                  context: context,
                  initialDate: _fechaSeleccionada,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );
                if (fechaElegida != null) {
                  setState(() => _fechaSeleccionada = fechaElegida);
                  _cargarDatos();
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month,
                    size: 18,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatoTextoFecha(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: Colors.black87,
              ),
              onPressed: () => _cambiarFecha(1),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // --- Lista de Registros ---
        Expanded(
          child: _cargando
              ? Center(child: CircularProgressIndicator(color: colorPrincipal))
              : (_tabActual == 0 ? _comidas.isEmpty : _resumenDias.isEmpty)
              ? Center(
                  child: Text(
                    _tabActual == 0
                        ? 'No registraste comidas en esta fecha.'
                        : 'No hay registros en este periodo.',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _tabActual == 0
                      ? _comidas.length
                      : _resumenDias.length,
                  itemBuilder: (context, index) {
                    if (_tabActual == 0) {
                      // Vista Diaria
                      final comida = _comidas[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 8.0,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: Text(
                                comida['hora'] ?? '',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                comida['comida'] ?? '',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ),

                            // Área de Calorías y Acciones (Edición)
                            SizedBox(
                              height: 40,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!_modoEdicion)
                                    Center(
                                      child: Text(
                                        comida['calorias'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),

                                  if (_modoEdicion) ...[
                                    InkWell(
                                      onTap: () => _editarComida(comida),
                                      borderRadius: BorderRadius.circular(20),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.0,
                                          vertical: 8.0,
                                        ),
                                        child: Icon(
                                          Icons.edit,
                                          size: 22,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => _eliminarComida(comida),
                                      borderRadius: BorderRadius.circular(20),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.0,
                                          vertical: 8.0,
                                        ),
                                        child: Icon(
                                          Icons.delete_outline,
                                          size: 24,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Vista Semanal / Mensual
                      final dia = _resumenDias[index];
                      return InkWell(
                        onTap: () {
                          final partes = dia['id'].toString().split('-');
                          setState(() {
                            _tabActual = 0;
                            _fechaSeleccionada = DateTime(
                              int.parse(partes[0]),
                              int.parse(partes[1]),
                              int.parse(partes[2]),
                            );
                          });
                          _cargarDatos();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 8.0,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(
                                  dia['fechaVisual'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Text(
                                  'Consumo diario',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              Text(
                                dia['calorias'] ?? '',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
        ),
        const SizedBox(height: 10),

        // --- Tarjeta de Total Acumulado ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorPrincipal.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _obtenerTextoTotal(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${_totalCalorias.toInt()} kcal',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- Botón de Edición Inferior ---
        Builder(
          builder: (context) {
            final bool sePuedeEditar = _tabActual == 0 && _comidas.isNotEmpty;
            return SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: sePuedeEditar
                        ? (_modoEdicion
                              ? Colors.red.withOpacity(0.6)
                              : colorPrincipal.withOpacity(0.6))
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  backgroundColor: sePuedeEditar
                      ? (_modoEdicion
                            ? Colors.red.withOpacity(0.05)
                            : colorPrincipal.withOpacity(0.05))
                      : Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: sePuedeEditar
                    ? () {
                        setState(() => _modoEdicion = !_modoEdicion);
                      }
                    : null,
                child: Text(
                  _modoEdicion ? 'Terminar edición' : 'Editar registros',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: sePuedeEditar
                        ? (_modoEdicion ? Colors.red : colorPrincipal)
                        : Colors.grey,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // ==========================================
  // WIDGETS AUXILIARES
  // ==========================================
  Widget _buildTab(String texto, int indice, Color colorPrimario) {
    final bool activo = _tabActual == indice;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (activo) {
            setState(() => _fechaSeleccionada = DateTime.now());
            _cargarDatos();
          } else {
            setState(() => _tabActual = indice);
            _cargarDatos();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: activo ? colorPrimario : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          margin: const EdgeInsets.all(4),
          alignment: Alignment.center,
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 15,
              fontWeight: activo ? FontWeight.bold : FontWeight.normal,
              color: activo ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
