import 'package:flutter/material.dart';

// =========================================================================
// 1. PANTALLA PRINCIPAL: HOME / INICIO
// =========================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int objetivoDiario = 2200;
  int caloriasConsumidas = 1758; // Valor base del prototipo

  // Lista dinámica de las comidas del usuario
  final List<Map<String, String>> misComidas = [
    {
      'hora': '08:00',
      'nombre': 'Desayuno: Avena',
      'kcal': '450 kcal',
    },
    {
      'hora': '13:00',
      'nombre': 'Almuerzo: Pollo',
      'kcal': '620 kcal',
    },
    {
      'hora': '20:00',
      'nombre': 'Cena: Ensalada',
      'kcal': '688 kcal',
    },
  ];

  // Posiciona por defecto la pestaña en "Inicio"
  int _currentIndex = 1;

  // =========================================================================
  // AGREGAR NUEVA COMIDA
  // =========================================================================

  void agregarNuevaComida(String nombre, int kcal) {
    setState(() {
      caloriasConsumidas += kcal;

      final ahora = DateTime.now();

      final horaFormateada =
          '${ahora.hour.toString().padLeft(2, '0')}:'
          '${ahora.minute.toString().padLeft(2, '0')}';

      misComidas.add({
        'hora': horaFormateada,
        'nombre': nombre,
        'kcal': '$kcal kcal',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool superaMeta = caloriasConsumidas > objetivoDiario;

    // Configuración visual según el estado calórico
    final Color colorFondo = superaMeta
        ? const Color(0xFFD32F2F)
        : const Color(0xFF2E7D32);

    final String tituloPrincipal = superaMeta
        ? 'Has superado tu meta calórica'
        : '¡Vas muy bien!';

    final String subtitulo = superaMeta
        ? 'Hoy consumiste más calorías de las establecidas.'
        : 'Sigue con tus hábitos saludables.';

    // Cálculo del porcentaje del círculo de progreso
    double porcentajeProgreso = caloriasConsumidas / objetivoDiario;

    if (porcentajeProgreso > 1.0) {
      porcentajeProgreso = 1.0;
    }

    return Scaffold(
      backgroundColor: colorFondo,

      // =====================================================================
      // CUERPO
      // =====================================================================

      body: SafeArea(
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // SECCIÓN SUPERIOR
            // -----------------------------------------------------------------

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                children: [
                  Text(
                    tituloPrincipal,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    subtitulo,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // -----------------------------------------------------------
                  // CÍRCULO DE PROGRESO
                  // -----------------------------------------------------------

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 210,
                        height: 210,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 16,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.25),
                          ),
                        ),
                      ),

                      SizedBox(
                        width: 210,
                        height: 210,
                        child: CircularProgressIndicator(
                          value: porcentajeProgreso,
                          strokeWidth: 16,
                          valueColor:
                          const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$caloriasConsumidas / $objetivoDiario',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            'kcal',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // -----------------------------------------------------------------
            // SECCIÓN INFERIOR
            // -----------------------------------------------------------------

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  16.0,
                  4.0,
                  16.0,
                  16.0,
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  padding: const EdgeInsets.all(22),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comidas de hoy',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // -------------------------------------------------------
                      // ENCABEZADOS DE LA TABLA
                      // -------------------------------------------------------

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: const [
                          SizedBox(
                            width: 70,
                            child: Text(
                              'Hora',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                                fontSize: 18,
                              ),
                            ),
                          ),

                          Expanded(
                            child: Text(
                              'Comida',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),

                          Text(
                            'Calorías',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      const Divider(
                        color: Colors.black26,
                        thickness: 2,
                      ),

                      // -------------------------------------------------------
                      // LISTA DE COMIDAS
                      // -------------------------------------------------------

                      Expanded(
                        child: ListView.builder(
                          itemCount: misComidas.length,
                          itemBuilder: (context, index) {
                            final comida = misComidas[index];

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14.0,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 70,
                                    child: Text(
                                      comida['hora']!,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  Expanded(
                                    child: Text(
                                      comida['nombre']!,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),

                                  Text(
                                    comida['kcal']!,
                                    style: const TextStyle(
                                      color: Color(0xFF1E88E5),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // -------------------------------------------------------
                      // BOTÓN REGISTRAR COMIDA
                      // -------------------------------------------------------

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFF4FC3F7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RegistrarComidaScreen(
                                      onComidaAgregada:
                                      agregarNuevaComida,
                                    ),
                              ),
                            );
                          },
                          child: const Text(
                            'Registrar comida',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // =====================================================================
      // BARRA DE NAVEGACIÓN
      // =====================================================================

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 16,
        unselectedFontSize: 14,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.description, size: 28),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 28),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 28),
            label: 'Perfil',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// =========================================================================
// 2. PANTALLA: REGISTRAR COMIDA
// =========================================================================

class RegistrarComidaScreen extends StatelessWidget {
  final Function(String, int) onComidaAgregada;

  const RegistrarComidaScreen({
    super.key,
    required this.onComidaAgregada,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> alimentosDisponibles = [
      {
        'nombre': 'Frijol',
        'kcal': 95,
      },
      {
        'nombre': 'Pescado',
        'kcal': 165,
      },
      {
        'nombre': 'Arroz Blanco',
        'kcal': 206,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,

      // =====================================================================
      // APP BAR
      // =====================================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          'Registrar Comida',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),

        centerTitle: true,
      ),

      // =====================================================================
      // CUERPO
      // =====================================================================

      body: Padding(
        padding: const EdgeInsets.all(20.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------------------
            // BUSCAR ALIMENTO
            // -----------------------------------------------------------------

            const Text(
              'Buscar Alimento',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar',
                hintStyle: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),

                prefixIcon: const Icon(
                  Icons.search,
                  size: 26,
                ),

                suffixIcon: const Icon(
                  Icons.close,
                  size: 24,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                contentPadding:
                const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // BOTÓN BUSCAR
            // -----------------------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF00B0FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  'Buscar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // -----------------------------------------------------------------
            // CREAR ALIMENTO PERSONALIZADO
            // -----------------------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Colors.blue,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  'Crear Alimento Personalizado',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // -----------------------------------------------------------------
            // RESULTADOS
            // -----------------------------------------------------------------

            const Text(
              'Resultados de Búsqueda',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // LISTA DE ALIMENTOS
            // -----------------------------------------------------------------

            Expanded(
              child: ListView.builder(
                itemCount: alimentosDisponibles.length,
                itemBuilder: (context, index) {
                  final alimento =
                  alimentosDisponibles[index];

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),

                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius:
                      BorderRadius.circular(12),
                    ),

                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        // -----------------------------------------------------
                        // INFORMACIÓN DEL ALIMENTO
                        // -----------------------------------------------------

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                alimento['nombre'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                '${alimento['kcal']} kcal por unidad',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // -----------------------------------------------------
                        // CANTIDAD Y BOTÓN AÑADIR
                        // -----------------------------------------------------

                        Row(
                          children: [
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),

                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 1.5,
                                ),
                              ),

                              child: const Text(
                                'Cantidad',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            ElevatedButton(
                              style:
                              ElevatedButton.styleFrom(
                                backgroundColor:
                                const Color(0xFF00B0FF),
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                padding:
                                const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),

                              onPressed: () {
                                onComidaAgregada(
                                  alimento['nombre'],
                                  alimento['kcal'],
                                );

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${alimento['nombre']} añadido correctamente',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );

                                Navigator.pop(context);
                              },

                              child: const Text(
                                'Añadir',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // =====================================================================
      // BARRA DE NAVEGACIÓN
      // =====================================================================

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 16,
        unselectedFontSize: 14,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.description, size: 28),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 28),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 28),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}