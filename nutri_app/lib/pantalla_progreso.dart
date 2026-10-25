import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PantallaProgreso extends StatefulWidget {
  const PantallaProgreso({super.key});

  @override
  State<PantallaProgreso> createState() => _PantallaProgresoState();
}

class _PantallaProgresoState extends State<PantallaProgreso> {
  // Estados y variables locales de control
  bool _primeraCarga = true;
  bool _cargandoDatos = false;
  bool _esSemana = true;
  int _metaCalorias = 2000;
  int _offsetTemporal = 0;

  // Estadísticas y datos para la gráfica
  List<Map<String, dynamic>> _datosGrafica = [];
  double _promedioPeriodo = 0;
  int _diasEnMeta = 0;
  double _picoMaximo = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatosProgreso();
  }

  /// Carga los datos de progreso desde Firestore según el período seleccionado (semana o mes).
  Future<void> _cargarDatosProgreso() async {
    setState(() => _cargandoDatos = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (_primeraCarga) {
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
        if (userDoc.exists && userDoc.data()?['meta_calorias'] != null) {
          _metaCalorias = (userDoc.data()?['meta_calorias'] as num).toInt();
        }
      }

      DateTime fechaInicio;
      DateTime fechaFin;
      final hoy = DateTime.now();

      if (_esSemana) {
        final referencia = hoy.add(Duration(days: _offsetTemporal * 7));
        fechaInicio = referencia.subtract(
          Duration(days: referencia.weekday - 1),
        );
        fechaFin = fechaInicio.add(const Duration(days: 6));
      } else {
        fechaInicio = DateTime(hoy.year, hoy.month + _offsetTemporal, 1);
        fechaFin = DateTime(fechaInicio.year, fechaInicio.month + 1, 0);
      }

      String inicioStr = DateFormat('yyyy-MM-dd').format(fechaInicio);
      String finStr = DateFormat('yyyy-MM-dd').format(fechaFin);

      final historialSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('historial_diario')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: inicioStr)
          .where(FieldPath.documentId, isLessThanOrEqualTo: finStr)
          .get();

      Map<String, double> mapaCalorias = {};
      for (var doc in historialSnapshot.docs) {
        final double total = (doc.data()['calorias_totales'] ?? 0).toDouble();
        mapaCalorias[doc.id] = total;
      }

      if (_esSemana) {
        _procesarDatosSemana(mapaCalorias, fechaInicio);
      } else {
        _procesarDatosMes(mapaCalorias, fechaInicio, fechaFin);
      }
    } catch (e) {
      debugPrint("Error cargando progreso: $e");
    } finally {
      if (mounted) {
        setState(() {
          _cargandoDatos = false;
          _primeraCarga = false;
        });
      }
    }
  }

  /// Procesa los datos diarios para la vista semanal.
  void _procesarDatosSemana(Map<String, double> mapaCalorias, DateTime lunes) {
    List<Map<String, dynamic>> temp = [];
    double sumaTotal = 0;
    int conteoDiasConDatos = 0;
    int metaCumplida = 0;
    double maximoEncontrado = 0;

    for (int i = 0; i < 7; i++) {
      final dia = lunes.add(Duration(days: i));
      final fechaStr = DateFormat('yyyy-MM-dd').format(dia);

      String etiqueta = '';
      try {
        etiqueta = DateFormat(
          'E',
          'es_ES',
        ).format(dia).substring(0, 3).toUpperCase();
      } catch (_) {
        etiqueta = DateFormat('E').format(dia).substring(0, 3).toUpperCase();
      }

      final calorias = mapaCalorias[fechaStr] ?? 0.0;
      if (calorias > 0) {
        sumaTotal += calorias;
        conteoDiasConDatos++;
        if (calorias <= _metaCalorias) metaCumplida++;
        if (calorias > maximoEncontrado) maximoEncontrado = calorias;
      }

      temp.add({
        'etiqueta': etiqueta,
        'fechaCompleta': DateFormat('dd/MM/yyyy').format(dia),
        'valor': calorias,
      });
    }

    _datosGrafica = temp;
    _promedioPeriodo = conteoDiasConDatos > 0
        ? (sumaTotal / conteoDiasConDatos)
        : 0;
    _diasEnMeta = metaCumplida;
    _picoMaximo = maximoEncontrado;
  }

  /// Procesa los datos agrupados por semanas para la vista mensual.
  void _procesarDatosMes(
    Map<String, double> mapaCalorias,
    DateTime inicioMes,
    DateTime finMes,
  ) {
    List<Map<String, dynamic>> temp = [];
    double sumaTotalMes = 0;
    int semanasConDatos = 0;
    int metasSemanales = 0;
    double maximoEncontrado = 0;

    int diasEnMes = finMes.day;

    for (int i = 0; i < 4; i++) {
      int diaInicio = i * 7 + 1;
      int diaFin = (i == 3) ? diasEnMes : diaInicio + 6;

      double sumaSemana = 0;
      int diasConDatos = 0;

      for (int d = diaInicio; d <= diaFin; d++) {
        final dia = DateTime(inicioMes.year, inicioMes.month, d);
        final fechaStr = DateFormat('yyyy-MM-dd').format(dia);
        if (mapaCalorias.containsKey(fechaStr)) {
          sumaSemana += mapaCalorias[fechaStr]!;
          diasConDatos++;
        }
      }

      double promedioSemana = diasConDatos > 0
          ? (sumaSemana / diasConDatos)
          : 0.0;

      temp.add({
        'etiqueta': 'Sem ${i + 1}',
        'fechaCompleta': 'Días $diaInicio al $diaFin',
        'valor': promedioSemana,
      });

      if (promedioSemana > 0) {
        sumaTotalMes += promedioSemana;
        semanasConDatos++;
        if (promedioSemana <= _metaCalorias) metasSemanales++;
        if (promedioSemana > maximoEncontrado) {
          maximoEncontrado = promedioSemana;
        }
      }
    }

    _datosGrafica = temp;
    _promedioPeriodo = semanasConDatos > 0
        ? (sumaTotalMes / semanasConDatos)
        : 0;
    _diasEnMeta = metasSemanales;
    _picoMaximo = maximoEncontrado;
  }

  /// Genera el texto descriptivo del rango temporal actual.
  String _obtenerTituloRango() {
    final hoy = DateTime.now();
    if (_esSemana) {
      final referencia = hoy.add(Duration(days: _offsetTemporal * 7));
      final lunes = referencia.subtract(Duration(days: referencia.weekday - 1));
      final domingo = lunes.add(const Duration(days: 6));
      return '${DateFormat('dd MMM', 'es_ES').format(lunes)} - ${DateFormat('dd MMM', 'es_ES').format(domingo)}';
    } else {
      final referencia = DateTime(hoy.year, hoy.month + _offsetTemporal, 1);
      return DateFormat('MMMM yyyy', 'es_ES').format(referencia).toUpperCase();
    }
  }

  /// Despliega el selector de fecha para navegar directamente a una semana o mes.
  Future<void> _seleccionarFechaCalendario(BuildContext context) async {
    final hoy = DateTime.now();
    if (_esSemana) {
      final DateTime? seleccionada = await showDatePicker(
        context: context,
        initialDate: hoy.add(Duration(days: _offsetTemporal * 7)),
        firstDate: DateTime(2023),
        lastDate: hoy,
      );
      if (seleccionada != null) {
        final lunesActual = hoy.subtract(Duration(days: hoy.weekday - 1));
        final lunesSeleccionado = seleccionada.subtract(
          Duration(days: seleccionada.weekday - 1),
        );

        setState(() {
          _offsetTemporal =
              lunesSeleccionado.difference(lunesActual).inDays ~/ 7;
        });
        _cargarDatosProgreso();
      }
    } else {
      final DateTime? seleccionada = await showDatePicker(
        context: context,
        initialDate: DateTime(hoy.year, hoy.month + _offsetTemporal, 1),
        firstDate: DateTime(2023),
        lastDate: hoy,
        helpText: 'Selecciona cualquier día del mes',
      );
      if (seleccionada != null) {
        setState(() {
          _offsetTemporal =
              (seleccionada.year - hoy.year) * 12 +
              (seleccionada.month - hoy.month);
        });
        _cargarDatosProgreso();
      }
    }
  }

  @override
  Widget build(context) {
    final theme = Theme.of(context);

    const Color colorDentroMeta = Color(0xFF2ECC71);
    const Color colorExcedido = Color(0xFFFF6B6B);
    final Color colorBorde = Colors.grey.shade300;

    final double topeGrafica = _metaCalorias > 0
        ? (_metaCalorias * 1.5)
        : 3500.0;
    const double alturaMax = 130.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _primeraCarga
              ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 10),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.black87,
                              size: 22,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Text(
                          'Progreso',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorBorde),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (_esSemana) return;
                                        setState(() {
                                          _esSemana = true;
                                          _offsetTemporal = 0;
                                        });
                                        _cargarDatosProgreso();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _esSemana
                                              ? theme.colorScheme.primary
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          'Semana',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _esSemana
                                                ? Colors.white
                                                : Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (!_esSemana) return;
                                        setState(() {
                                          _esSemana = false;
                                          _offsetTemporal = 0;
                                        });
                                        _cargarDatosProgreso();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: !_esSemana
                                              ? theme.colorScheme.primary
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          'Mes',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: !_esSemana
                                                ? Colors.white
                                                : Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              height: 280,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: colorBorde),
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _esSemana
                                            ? 'Consumo diario'
                                            : 'Promedio semanal',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              bottom:
                                                  24 +
                                                  (alturaMax *
                                                      (_metaCalorias /
                                                              topeGrafica)
                                                          .clamp(0.0, 1.0)),
                                              left: 0,
                                              right: 0,
                                              child: Container(
                                                height: 1.5,
                                                color: const Color.fromARGB(
                                                  62,
                                                  255,
                                                  120,
                                                  120,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: _datosGrafica.map((
                                                item,
                                              ) {
                                                final double valor =
                                                    item['valor'];
                                                final double proporcion =
                                                    (valor / topeGrafica).clamp(
                                                      0.0,
                                                      1.0,
                                                    );
                                                final double alturaBarra =
                                                    alturaMax * proporcion;

                                                final bool excedido =
                                                    valor > _metaCalorias &&
                                                    valor > 0;
                                                final Color colorBarra =
                                                    excedido
                                                    ? colorExcedido
                                                    : colorDentroMeta;

                                                return InkWell(
                                                  onTap: () {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).hideCurrentSnackBar();
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          '${item['fechaCompleta']}: ${valor.toInt()} kcal',
                                                        ),
                                                        duration:
                                                            const Duration(
                                                              seconds: 2,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 4.0,
                                                        ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        Container(
                                                          color: Colors.white,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 2.0,
                                                              ),
                                                          child: FittedBox(
                                                            child: Text(
                                                              valor > 0
                                                                  ? valor
                                                                        .toInt()
                                                                        .toString()
                                                                  : '0',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: Colors
                                                                        .grey,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Container(
                                                          width: 24,
                                                          height:
                                                              alturaBarra < 4
                                                              ? 4
                                                              : alturaBarra,
                                                          decoration: BoxDecoration(
                                                            color: colorBarra,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          item['etiqueta'],
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .black54,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_cargandoDatos)
                                    Container(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorBorde),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      setState(() => _offsetTemporal--);
                                      _cargarDatosProgreso();
                                    },
                                    icon: const Icon(
                                      Icons.chevron_left,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        _seleccionarFechaCalendario(context),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_month,
                                          size: 18,
                                          color: Colors.blueGrey,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _obtenerTituloRango(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _offsetTemporal < 0
                                        ? () {
                                            setState(() => _offsetTemporal++);
                                            _cargarDatosProgreso();
                                          }
                                        : null,
                                    icon: Icon(
                                      Icons.chevron_right,
                                      color: _offsetTemporal < 0
                                          ? Colors.black87
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: colorBorde),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      const Text(
                                        'Promedio',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${_promedioPeriodo.toInt()} kcal',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    height: 35,
                                    width: 1,
                                    color: colorBorde,
                                  ),
                                  Column(
                                    children: [
                                      const Text(
                                        'En Meta',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '$_diasEnMeta / ${_esSemana ? 7 : 4}',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    height: 35,
                                    width: 1,
                                    color: colorBorde,
                                  ),
                                  Column(
                                    children: [
                                      const Text(
                                        'Mayor Consumo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${_picoMaximo.toInt()} kcal',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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
