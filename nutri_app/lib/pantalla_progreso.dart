
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgresoScreen extends StatefulWidget {
  final String userId;

  const ProgresoScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProgresoScreen> createState() => _ProgresoScreenState();
}

class _ProgresoScreenState extends State<ProgresoScreen> {
  bool esSemana = true;
  double metaCaloricaUsuario = 2200.0; // Meta diaria base por defecto

  @override
  void initState() {
    super.initState();
    _obtenerMetaUsuario();
  }

  /// Obtiene la meta calórica real guardada en el perfil del usuario en Firestore
  Future<void> _obtenerMetaUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()?['meta_calorica'] != null) {
        setState(() {
          metaCaloricaUsuario =
              (doc.data()!['meta_calorica'] as num).toDouble();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid =
        FirebaseAuth.instance.currentUser?.uid ?? widget.userId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Progreso',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Selector de Tiempo Estilo Boceto
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        esSemana = true;
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: esSemana
                              ? const Color(0xFF54B5FF)
                              : Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(7),
                            bottomLeft: Radius.circular(7),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Semana',
                          style: TextStyle(
                            color: esSemana ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        esSemana = false;
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: !esSemana
                              ? const Color(0xFF54B5FF)
                              : Colors.white,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(7),
                            bottomRight: Radius.circular(7),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Mes',
                          style: TextStyle(
                            color: !esSemana ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),

            // 2. Gráfica Inteligente con Escala Dinámica, Ejes Gruesos y Números Grandes
            SizedBox(
              height: 220,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(currentUid)
                    .collection('historial_diario')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  // Mapeamos los datos de la base de datos
                  Map<String, double> mapaCalorias = {};
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      final datos = doc.data() as Map<String, dynamic>;
                      mapaCalorias[doc.id] =
                          (datos['calorias_totales'] ?? 0).toDouble();
                    }
                  }

                  List<BarChartGroupData> gruposBarras = [];
                  List<String> etiquetasX = [];
                  DateTime ahora = DateTime.now();

                  // Variables de control de escala del plano cartesiano
                  double maximoEjeY = esSemana ? 5000.0 : 25000.0;

                  if (esSemana) {
                    // MODO SEMANA: Vista Diaria (Meta: Meta Diaria)
                    int diaActualSemana = ahora.weekday;
                    DateTime lunesDeEstaSemana = ahora.subtract(
                      Duration(days: diaActualSemana - 1),
                    );
                    etiquetasX = [
                      'Lun',
                      'Mar',
                      'Mié',
                      'Jue',
                      'Vie',
                      'Sáb',
                      'Dom'
                    ];

                    for (int i = 0; i < 7; i++) {
                      DateTime fechaDia =
                      lunesDeEstaSemana.add(Duration(days: i));
                      String fechaKey =
                          "${fechaDia.year}-${fechaDia.month.toString().padLeft(2, '0')}-${fechaDia.day.toString().padLeft(2, '0')}";

                      double caloriasConsumidas =
                          mapaCalorias[fechaKey] ?? 0.0;
                      Color colorBarra = caloriasConsumidas >
                          metaCaloricaUsuario
                          ? const Color(0xFFFF4D4D)
                          : const Color(0xFF2ECC71);

                      // Topear visualmente a 5000 máximo
                      double valorGrafica = caloriasConsumidas > 5000.0
                          ? 5000.0
                          : caloriasConsumidas;

                      gruposBarras.add(
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: valorGrafica,
                              color: colorBarra,
                              width: 16,
                              borderRadius: BorderRadius.circular(2),
                            )
                          ],
                        ),
                      );
                    }
                  } else {
                    // MODO MES: Suma Semanal Acumulada (Meta: Meta x 7)
                    etiquetasX = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
                    double metaSemanalAcumulada = metaCaloricaUsuario * 7;

                    for (int s = 3; s >= 0; s--) {
                      double sumaCaloriasSemana = 0;

                      for (int d = 0; d < 7; d++) {
                        int diasDeDiferencia = (s * 7) + d;
                        DateTime fechaDia = ahora.subtract(
                          Duration(days: diasDeDiferencia),
                        );
                        String fechaKey =
                            "${fechaDia.year}-${fechaDia.month.toString().padLeft(2, '0')}-${fechaDia.day.toString().padLeft(2, '0')}";

                        if (mapaCalorias.containsKey(fechaKey)) {
                          sumaCaloriasSemana += mapaCalorias[fechaKey]!;
                        }
                      }

                      Color colorBarra = sumaCaloriasSemana >
                          metaSemanalAcumulada
                          ? const Color(0xFFFF4D4D)
                          : const Color(0xFF2ECC71);

                      // Tope visual en la vista mensual a 25000 kcal
                      double valorGraficaMes =
                      sumaCaloriasSemana > 25000.0
                          ? 25000.0
                          : sumaCaloriasSemana;

                      gruposBarras.add(
                        BarChartGroupData(
                          x: 3 - s,
                          barRods: [
                            BarChartRodData(
                              toY: valorGraficaMes,
                              color: colorBarra,
                              width: 24,
                              borderRadius: BorderRadius.circular(3),
                            )
                          ],
                        ),
                      );
                    }
                  }

                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maximoEjeY,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < etiquetasX.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    etiquetasX[index],
                                    // Aumentado a tamaño 14, más oscuro y en negrita
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.bold,
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
                            reservedSize: 50, // Más espacio para que no se corten los números
                            getTitlesWidget: (value, meta) {
                              if (esSemana) {
                                if (value == 0 ||
                                    value == 1000 ||
                                    value == 2000 ||
                                    value == 3000 ||
                                    value == 4000 ||
                                    value == 5000) {
                                  return Text(
                                    value.toInt().toString(),
                                    // Aumentado a tamaño 14 y en negrita
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.bold,
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
                                    value.toInt().toString(),
                                    // Tamaño 12 para el modo mes para que quepa bien el texto largo
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          // Ejes cartesianos más marcados (Grosor 3.0) y oscuros
                          left: BorderSide(
                            color: Colors.black87,
                            width: 3.0,
                          ),
                          bottom: BorderSide(
                            color: Colors.black87,
                            width: 3.0,
                          ),
                        ),
                      ),
                      barGroups: gruposBarras,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 25),

            // 3. Título del Rango de Fechas (Corregido y Limpio sin errores)
            const Text(
              'Rango de fechas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    esSemana ? 'Última semana' : 'Último mes',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 4. Botón Volver al Perfil
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF54B5FF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Volver al perfil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // 5. Barra de Navegación Inferior Completa
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: 2,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 1) {
              Navigator.pop(context); // Regresa al Dashboard (Inicio)
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined, size: 26),
              label: 'Historial',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 26),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 26),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
