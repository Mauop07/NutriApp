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
  int caloriasConsumidas = 0; // Valor base del prototipo

  // Lista dinámica de las comidas del usuario
  final List<Map<String, String>> misComidas = [
    /*{'hora': '08:00', 'nombre': 'Avena', 'kcal': '450 kcal'},
    {'hora': '13:00', 'nombre': 'Pollo', 'kcal': '620 kcal'},
    {'hora': '20:00', 'nombre': 'Ensalada', 'kcal': '688 kcal'},
    */
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
                          valueColor: AlwaysStoppedAnimation<Color>(
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
                          valueColor: const AlwaysStoppedAnimation<Color>(
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
                              fontSize: 25,
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
                padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
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
                        '         Comidas de hoy',
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                      const Divider(color: Colors.black26, thickness: 2),

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
                            backgroundColor: const Color(0xFF4FC3F7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegistrarComidaScreen(
                                  onComidaAgregada: agregarNuevaComida,
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



class CatalogoNutriApp {
  static final List<Map<String, dynamic>> alimentos = [
    {
      'nombre': 'Frijol',
      'unidades': [
        {'unidad': 'por unidad', 'kcal': 95},
      ],
    },
    {
      'nombre': 'Pescado',
      'unidades': [
        {'unidad': 'por unidad', 'kcal': 165},
      ],
    },
    {
      'nombre': 'Arroz Blanco',
      'unidades': [
        {'unidad': 'por unidad', 'kcal': 206},
      ],
    },
  ];
}

// ============================================================================
// 2. PANTALLA: REGISTRAR COMIDA
// ============================================================================

class RegistrarComidaScreen extends StatefulWidget {
  final Function(String, int) onComidaAgregada;

  const RegistrarComidaScreen({
    super.key,
    required this.onComidaAgregada,
  });

  @override
  State<RegistrarComidaScreen> createState() => _RegistrarComidaScreenState();
}

class _RegistrarComidaScreenState extends State<RegistrarComidaScreen> {
  final TextEditingController _buscarController = TextEditingController();

  List<Map<String, dynamic>> _resultados = [];
  final Map<String, int> _cantidades = {};
  final Map<String, int> _unidadesSeleccionadas = {};

  @override
  void initState() {
    super.initState();
    _resultados = List<Map<String, dynamic>>.from(
      CatalogoNutriApp.alimentos,
    );
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  void _buscarAlimento() {
    final String consulta = _buscarController.text.trim().toLowerCase();

    setState(() {
      if (consulta.isEmpty) {
        _resultados = List<Map<String, dynamic>>.from(
          CatalogoNutriApp.alimentos,
        );
      } else {
        _resultados = CatalogoNutriApp.alimentos.where((alimento) {
          final String nombre =
          (alimento['nombre'] as String).toLowerCase();
          return nombre.contains(consulta);
        }).toList();
      }
    });
  }

  void _limpiarBusqueda() {
    _buscarController.clear();
    _buscarAlimento();
    FocusScope.of(context).unfocus();
  }

  Future<void> _abrirCrearAlimento() async {
    final Map<String, dynamic>? nuevoAlimento =
    await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const CrearAlimentoPersonalizadoScreen(),
      ),
    );

    if (nuevoAlimento == null || !mounted) return;

    final String nombre = nuevoAlimento['nombre'] as String;
    final List<Map<String, dynamic>> unidades =
    (nuevoAlimento['unidades'] as List).cast<Map<String, dynamic>>();

    final bool yaExiste = CatalogoNutriApp.alimentos.any(
          (alimento) =>
      (alimento['nombre'] as String).toLowerCase() == nombre.toLowerCase(),
    );

    if (yaExiste) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ya existe un alimento llamado "$nombre".')),
      );
      return;
    }

    setState(() {
      CatalogoNutriApp.alimentos.add({
        'nombre': nombre,
        'unidades': unidades,
      });
      _cantidades[nombre] = 1;
      _unidadesSeleccionadas[nombre] = 0;
      _buscarController.text = nombre;
      _resultados = CatalogoNutriApp.alimentos.where((alimento) {
        return (alimento['nombre'] as String)
            .toLowerCase()
            .contains(nombre.toLowerCase());
      }).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$nombre" se guardó correctamente.')),
    );
  }

  Future<void> _configurarCantidad(Map<String, dynamic> alimento) async {
    final String nombre = alimento['nombre'] as String;
    final List<Map<String, dynamic>> unidades =
    (alimento['unidades'] as List).cast<Map<String, dynamic>>();

    final Map<String, int>? resultado =
    await showDialog<Map<String, int>>(
      context: context,
      builder: (_) => _DialogoCantidadAlimento(
        nombre: nombre,
        unidades: unidades,
        cantidadInicial: _cantidades[nombre] ?? 1,
        unidadInicial: _unidadesSeleccionadas[nombre] ?? 0,
      ),
    );

    if (resultado == null || !mounted) return;

    setState(() {
      _cantidades[nombre] = resultado['cantidad']!;
      _unidadesSeleccionadas[nombre] = resultado['unidad']!;
    });
  }

  void _anadirAlimento(Map<String, dynamic> alimento) {
    final String nombre = alimento['nombre'] as String;
    final List<Map<String, dynamic>> unidades =
    (alimento['unidades'] as List).cast<Map<String, dynamic>>();
    final int cantidad = _cantidades[nombre] ?? 1;
    final int indiceUnidad = _unidadesSeleccionadas[nombre] ?? 0;
    final unidad = unidades[indiceUnidad];
    final int kcalPorUnidad = unidad['kcal'] as int;
    final int kcalTotal = kcalPorUnidad * cantidad;
    final String nombreRegistrado = cantidad == 1
        ? '$nombre (${unidad['unidad']})'
        : '$nombre ($cantidad x ${unidad['unidad']})';

    widget.onComidaAgregada(nombreRegistrado, kcalTotal);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$nombre añadido: $kcalTotal kcal.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Registrar Comida',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 27,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buscar Alimento',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _buscarController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _buscarAlimento(),
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                hintText: 'Buscar',
                prefixIcon: const Icon(Icons.search, size: 26),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, size: 24),
                  tooltip: 'Limpiar búsqueda',
                  onPressed: _limpiarBusqueda,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B0FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _buscarAlimento,
                child: const Text(
                  'Buscar',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _abrirCrearAlimento,
                child: const Text(
                  'Crear Alimento Personalizado',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Resultados de Búsqueda',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _resultados.isEmpty
                  ? const Center(
                child: Text(
                  'No se encontraron alimentos.\nPuedes crear uno personalizado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 19, color: Colors.black54),
                ),
              )
                  : ListView.builder(
                itemCount: _resultados.length,
                itemBuilder: (context, index) {
                  final alimento = _resultados[index];
                  final String nombre = alimento['nombre'] as String;
                  final List<Map<String, dynamic>> unidades =
                  (alimento['unidades'] as List)
                      .cast<Map<String, dynamic>>();
                  final int cantidad = _cantidades[nombre] ?? 1;
                  final int indice = _unidadesSeleccionadas[nombre] ?? 0;
                  final unidad = unidades[indice];

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${unidad['kcal']} kcal ${unidad['unidad']}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        OutlinedButton(
                          onPressed: () => _configurarCantidad(alimento),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Cantidad',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                '$cantidad',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        ElevatedButton(
                          onPressed: () => _anadirAlimento(alimento),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B0FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Añadir',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
        onTap: (index) {
          if (index == 1) Navigator.pop(context);
          if (index != 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Esta sección todavía no está implementada.'),
              ),
            );
          }
        },
      ),
    );
  }
}

// ============================================================================
// 3. PANTALLA: CREAR ALIMENTO PERSONALIZADO
// ============================================================================

class CrearAlimentoPersonalizadoScreen extends StatefulWidget {
  const CrearAlimentoPersonalizadoScreen({super.key});

  @override
  State<CrearAlimentoPersonalizadoScreen> createState() =>
      _CrearAlimentoPersonalizadoScreenState();
}

class _CrearAlimentoPersonalizadoScreenState
    extends State<CrearAlimentoPersonalizadoScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final List<_UnidadPersonalizada> _unidades = [_UnidadPersonalizada()];

  @override
  void dispose() {
    _nombreController.dispose();
    for (final unidad in _unidades) {
      unidad.dispose();
    }
    super.dispose();
  }

  void _agregarUnidad() {
    setState(() => _unidades.add(_UnidadPersonalizada()));
  }

  void _eliminarUnidad(int index) {
    if (_unidades.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe quedar al menos una unidad.')),
      );
      return;
    }

    final unidad = _unidades[index];
    setState(() {
      _unidades.removeAt(index);
    });

    // Espera a que Flutter retire los TextField de esa fila antes de
    // liberar sus controladores.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unidad.dispose();
    });
  }

  void _guardarAlimento() {
    final String nombre = _nombreController.text.trim();

    if (nombre.isEmpty) {
      _mostrarError('Escribe el nombre del alimento.');
      return;
    }

    final bool nombreDuplicado = CatalogoNutriApp.alimentos.any(
          (alimento) =>
      (alimento['nombre'] as String).toLowerCase() == nombre.toLowerCase(),
    );

    if (nombreDuplicado) {
      _mostrarError('Ese alimento ya existe. Escribe otro nombre.');
      return;
    }

    final List<Map<String, dynamic>> unidadesValidas = [];

    for (int i = 0; i < _unidades.length; i++) {
      final String unidad = _unidades[i].unidadController.text.trim();
      final int? kcal =
      int.tryParse(_unidades[i].caloriasController.text.trim());

      if (unidad.isEmpty || kcal == null || kcal < 0) {
        _mostrarError(
          'Completa la unidad y coloca calorías válidas en la fila ${i + 1}.',
        );
        return;
      }

      unidadesValidas.add({'unidad': unidad, 'kcal': kcal});
    }

    Navigator.pop<Map<String, dynamic>>(context, {
      'nombre': nombre,
      'unidades': unidadesValidas,
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Alimentos Personalizados',
          style: TextStyle(
            color: Colors.black,
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Nombre del alimento',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: _nombreController,

              // Tamaño del texto que escribe el usuario
              style: const TextStyle(fontSize: 18),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(

                // Tamaño del mensaje de ejemplo
                hintStyle: const TextStyle(fontSize: 18),
                hintText: 'Escribe el nombre del alimento',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unidades y calorías',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Unidad / cantidad',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Calorías (kcal)',
                    style: TextStyle(fontSize: 18.5, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 42),
              ],
            ),
            const SizedBox(height: 6),
            ...List.generate(_unidades.length, (index) {
              final unidad = _unidades[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: unidad.unidadController,
                        style: const TextStyle(fontSize: 19),
                        decoration: InputDecoration(
                          hintText: 'Ej. 100 g',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: unidad.caloriasController,
                        style: const TextStyle(fontSize: 19),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Ej. 115',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      child: IconButton(
                        tooltip: 'Eliminar unidad',
                        onPressed: () => _eliminarUnidad(index),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _agregarUnidad,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Agregar otra unidad',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _guardarAlimento,
                child: const Text(
                  'Guardar alimento',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnidadPersonalizada {
  final TextEditingController unidadController = TextEditingController();
  final TextEditingController caloriasController = TextEditingController();

  void dispose() {
    unidadController.dispose();
    caloriasController.dispose();
  }
}


// ============================================================================
// DIÁLOGO DE CANTIDAD: los controladores pertenecen al propio diálogo y se
// liberan en dispose(), cuando Flutter ya está retirando sus TextField.
// ============================================================================

class _DialogoCantidadAlimento extends StatefulWidget {
  final String nombre;
  final List<Map<String, dynamic>> unidades;
  final int cantidadInicial;
  final int unidadInicial;

  const _DialogoCantidadAlimento({
    required this.nombre,
    required this.unidades,
    required this.cantidadInicial,
    required this.unidadInicial,
  });

  @override
  State<_DialogoCantidadAlimento> createState() =>
      _DialogoCantidadAlimentoState();
}

class _DialogoCantidadAlimentoState
    extends State<_DialogoCantidadAlimento> {
  late final TextEditingController _cantidadController;
  late int _unidadElegida;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cantidadController =
        TextEditingController(text: '${widget.cantidadInicial}');
    _unidadElegida =
        widget.unidadInicial.clamp(0, widget.unidades.length - 1).toInt();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  void _guardar() {
    final int? cantidad = int.tryParse(_cantidadController.text.trim());
    if (cantidad == null || cantidad < 1 || cantidad > 999) {
      setState(() {
        _error = 'Ingresa una cantidad entre 1 y 999.';
      });
      return;
    }

    Navigator.of(context).pop<Map<String, int>>({
      'cantidad': cantidad,
      'unidad': _unidadElegida,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Cantidad de ${widget.nombre}',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Elige una unidad y escribe la cantidad.',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _unidadElegida,
            isExpanded: true,
            decoration: const InputDecoration(
              labelStyle: const TextStyle(fontSize: 21),
              labelText: 'Unidad',
              border: OutlineInputBorder(),
            ),
            items: List.generate(widget.unidades.length, (index) {
              final unidad = widget.unidades[index];
              return DropdownMenuItem<int>(
                value: index,
                child: Text(
                  '${unidad['unidad']} — ${unidad['kcal']} kcal',

                  // Agranda el texto de las opciones
                  style: const TextStyle(fontSize: 18.5),

                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _unidadElegida = value;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cantidadController,

            // Tamaño del número que escribe el usuario
            style: const TextStyle(fontSize: 19.5),

            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _guardar(),
            decoration: const InputDecoration(
              labelStyle: const TextStyle(fontSize: 21),
              labelText: 'Cantidad',
              hintText: 'Ej. 2',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(fontSize: 19),
          ),
        ),
        ElevatedButton(
          onPressed: _guardar,
          child: const Text(
            'Guardar',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
