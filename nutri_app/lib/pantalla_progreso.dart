import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// ============================================================================
// PANTALLA: PROGRESO Y GRÁFICAS DE CONSUMO CALÓRICO
// ============================================================================
class PantallaProgreso extends StatefulWidget {
  const PantallaProgreso({super.key});

  @override
  State<PantallaProgreso> createState() => _PantallaProgresoState();
}

class _PantallaProgresoState extends State<PantallaProgreso> {
  // --------------------------------------------------------------------------
  // Estados y variables locales de control
  // --------------------------------------------------------------------------
  bool _primeraCarga = true;
  bool _cargandoDatos = false;
  bool _esSemana = true; // Controla el selector: true (Semana), false (Mes)
  int _metaCalorias = 2000;
  int _offsetTemporal = 0; // Desplazamiento en semanas o meses (0 = actual)

  // --------------------------------------------------------------------------
  // Estadísticas y datos procesados para la gráfica
  // --------------------------------------------------------------------------
  List<Map<String, dynamic>> _datosGrafica = [];
  double _promedioPeriodo = 0;
  int _diasEnMeta =
      0; // Se usa para contar días (Semana) o semanas (Mes) en meta
  double _picoMaximo = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatosProgreso();
  }

  /// Carga la meta calórica del usuario y descarga el historial desde Firestore
  /// filtrando estrictamente por el rango de fechas seleccionado.
  Future<void> _cargarDatosProgreso() async {
    setState(() => _cargandoDatos = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Obtener la meta calórica (con Timeout)
      if (_primeraCarga) {
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get()
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => throw Exception('Offline'),
            );

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

      // 3. Consultar historial optimizado (con Timeout)
      final historialSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('historial_diario')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: inicioStr)
          .where(FieldPath.documentId, isLessThanOrEqualTo: finStr)
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Offline'),
          );

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
      debugPrint("Cargando gráfica offline o sin registros: $e");
      // Inicializar vacía si falla la conexión y la caché para que no rompa la UI
      if (_esSemana) {
        _procesarDatosSemana({}, DateTime.now());
      } else {
        _procesarDatosMes({}, DateTime.now(), DateTime.now());
      }
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

  /// Procesa los datos sumando los 7 días de cada semana para la vista mensual.
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

      // Sumamos todas las calorías de los días correspondientes a esta semana
      for (int d = diaInicio; d <= diaFin; d++) {
        final dia = DateTime(inicioMes.year, inicioMes.month, d);
        final fechaStr = DateFormat('yyyy-MM-dd').format(dia);
        if (mapaCalorias.containsKey(fechaStr)) {
          sumaSemana += mapaCalorias[fechaStr]!;
        }
      }

      temp.add({
        'etiqueta': 'Sem ${i + 1}',
        'fechaCompleta': 'Días $diaInicio al $diaFin',
        'valor': sumaSemana, // Usamos el total acumulado, no el promedio
      });

      if (sumaSemana > 0) {
        sumaTotalMes += sumaSemana;
        semanasConDatos++;
        // Evaluamos si el consumo total de la semana superó la meta semanal (Meta diaria x 7)
        if (sumaSemana <= (_metaCalorias * 7)) metasSemanales++;
        if (sumaSemana > maximoEncontrado) {
          maximoEncontrado = sumaSemana;
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

  /// Genera el texto descriptivo del rango temporal actual (Ej. "20 OCT - 26 OCT").
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

  /// Despliega el selector de fecha para navegar directamente a una fecha específica.
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color colorDentroMeta = Color(0xFF2ECC71);
    const Color colorExcedido = Color(0xFFFF6B6B);
    final Color colorBorde = Colors.grey.shade300;

    // Escala máxima del eje Y: 5000 para vista diaria, 25000 para acumulados semanales (Mes)
    double maximoEjeY = _esSemana ? 5000.0 : 25000.0;

    // Conversión de datos procesados a la estructura requerida por fl_chart
    List<BarChartGroupData> gruposBarras = [];
    List<String> etiquetasX = [];

    for (int i = 0; i < _datosGrafica.length; i++) {
      final item = _datosGrafica[i];
      double valor = item['valor'];
      etiquetasX.add(item['etiqueta']);

      // En la vista mensual, la meta se multiplica por 7 días
      double metaEvaluada = _esSemana
          ? _metaCalorias.toDouble()
          : (_metaCalorias * 7).toDouble();
      bool excedido = valor > metaEvaluada && valor > 0;
      Color colorBarra = excedido ? colorExcedido : colorDentroMeta;

      // Topear la altura visual de la barra para que no rompa el gráfico
      double valorGrafica = valor > maximoEjeY ? maximoEjeY : valor;

      gruposBarras.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: valorGrafica,
              color: colorBarra,
              width: _esSemana ? 16 : 24,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

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

                    // 1. Cabecera con botón de retroceso
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
                            // 2. Selector Semana / Mes
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

                            // 3. Gráfica Profesional Integrada con fl_chart
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
                                            : 'Consumo semanal',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      Expanded(
                                        child: BarChart(
                                          BarChartData(
                                            alignment:
                                                BarChartAlignment.spaceAround,
                                            maxY: maximoEjeY,
                                            barTouchData: BarTouchData(
                                              enabled: true,
                                              touchTooltipData: BarTouchTooltipData(
                                                getTooltipItem:
                                                    (
                                                      group,
                                                      groupIndex,
                                                      rod,
                                                      rodIndex,
                                                    ) {
                                                      final item =
                                                          _datosGrafica[group.x
                                                              .toInt()];
                                                      return BarTooltipItem(
                                                        '${item['fechaCompleta']}\n${rod.toY.toInt()} kcal',
                                                        const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      );
                                                    },
                                              ),
                                            ),
                                            titlesData: FlTitlesData(
                                              show: true,
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget:
                                                      (
                                                        double value,
                                                        TitleMeta meta,
                                                      ) {
                                                        int index = value
                                                            .toInt();
                                                        if (index >= 0 &&
                                                            index <
                                                                etiquetasX
                                                                    .length) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  top: 8.0,
                                                                ),
                                                            child: Text(
                                                              etiquetasX[index],
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .black54,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                        return const Text('');
                                                      },
                                                ),
                                              ),
                                              leftTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 45,
                                                  getTitlesWidget: (value, meta) {
                                                    if (_esSemana) {
                                                      if (value == 0 ||
                                                          value == 1000 ||
                                                          value == 2000 ||
                                                          value == 3000 ||
                                                          value == 4000 ||
                                                          value == 5000) {
                                                        return Text(
                                                          value
                                                              .toInt()
                                                              .toString(),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .black54,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        );
                                                      }
                                                    } else {
                                                      if (value == 0 ||
                                                          value == 5000 ||
                                                          value == 10000 ||
                                                          value == 15000 ||
                                                          value == 20000 ||
                                                          value == 25000) {
                                                        return Text(
                                                          value
                                                              .toInt()
                                                              .toString(),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 10,
                                                                color: Colors
                                                                    .black54,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        );
                                                      }
                                                    }
                                                    return const Text('');
                                                  },
                                                ),
                                              ),
                                              topTitles: const AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: false,
                                                ),
                                              ),
                                              rightTitles: const AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: false,
                                                ),
                                              ),
                                            ),
                                            gridData: const FlGridData(
                                              show: false,
                                            ),
                                            borderData: FlBorderData(
                                              show: true,
                                              border: const Border(
                                                left: BorderSide(
                                                  color: Colors.black87,
                                                  width: 2.0,
                                                ),
                                                bottom: BorderSide(
                                                  color: Colors.black87,
                                                  width: 2.0,
                                                ),
                                              ),
                                            ),
                                            barGroups: gruposBarras,
                                          ),
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

                            // 4. Selector de Rango de Fecha Interactivo
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
                                        : null, // Deshabilita la flecha si estamos en la semana/mes actual
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

                            // 5. Tarjetas de Resumen Estadístico
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
                            const SizedBox(height: 20),
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
