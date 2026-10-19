import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================================
// 1. PANTALLA: REGISTRAR COMIDA (Conectada a Firestore)
// ============================================================================
class PantallaRegistroAlimentos extends StatefulWidget {
  final Function(String, int) onComidaAgregada;

  const PantallaRegistroAlimentos({super.key, required this.onComidaAgregada});

  @override
  State<PantallaRegistroAlimentos> createState() =>
      _PantallaRegistroAlimentosState();
}

class _PantallaRegistroAlimentosState extends State<PantallaRegistroAlimentos> {
  final TextEditingController _buscarController = TextEditingController();

  List<Map<String, dynamic>> _catalogoCompleto = [];
  List<Map<String, dynamic>> _resultados = [];
  final Map<String, int> _cantidades = {};
  final Map<String, int> _unidadesSeleccionadas = {};

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarAlimentosDeFirestore();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  // --- CONEXIÓN A FIREBASE ---
  Future<void> _cargarAlimentosDeFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      // 1. Cargar catálogo general (excluyendo los personalizados viejos si aún existen)
      final snapshotGeneral = await FirebaseFirestore.instance
          .collection('catalogo_alimentos')
          .get();

      final listaGeneral = snapshotGeneral.docs
          .where((doc) => doc.data()['categoria'] != 'Personalizado')
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .toList();

      // 2. Cargar alimentos personalizados de la subcolección del usuario
      List<Map<String, dynamic>> listaPersonalizada = [];
      if (user != null) {
        final snapshotPersonalizado = await FirebaseFirestore.instance
            .collection('usuarios') // Coleccion principal de usuarios
            .doc(user.uid) // Documento del usuario actual
            .collection(
              'alimentos_personalizados',
            ) // Subcoleccion de alimentos personalizados
            .get();

        listaPersonalizada = snapshotPersonalizado.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      }

      // 3. Combinar ambas listas
      if (mounted) {
        setState(() {
          _catalogoCompleto = [...listaGeneral, ...listaPersonalizada];
          _resultados = List.from(_catalogoCompleto);
          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint("Error descargando catálogo: $e");
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _buscarAlimento() {
    final String consulta = _buscarController.text.trim().toLowerCase();

    // Ocultar teclado automáticamente al buscar
    FocusScope.of(context).unfocus();

    setState(() {
      if (consulta.isEmpty) {
        _resultados = List.from(_catalogoCompleto);
      } else {
        _resultados = _catalogoCompleto.where((alimento) {
          final String nombre = (alimento['nombre'] ?? '')
              .toString()
              .toLowerCase();
          return nombre.contains(consulta);
        }).toList();
      }
    });
  }

  void _limpiarBusqueda() {
    _buscarController.clear();
    _buscarAlimento();
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

    final String nombre = nuevoAlimento['nombre'].toString();

    final List<Map<String, dynamic>> unidades =
        (nuevoAlimento['unidades'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    // Verificar en la lista local si ya existe
    final bool yaExiste = _catalogoCompleto.any(
      (alimento) =>
          (alimento['nombre'] ?? '').toString().toLowerCase() ==
          nombre.toLowerCase(),
    );

    if (yaExiste) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ya existe un alimento llamado "$nombre".')),
      );
      return;
    }

    // --- GUARDAR EN FIREBASE ---
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String docId = nombre
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[áéíóú]'), 'a');

      final dataParaGuardar = {
        'nombre': nombre,
        'unidades': unidades,
        'categoria': 'Personalizado',
        'creadoPor': user.uid, // Firma del usuario
      };

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('alimentos_personalizados')
          .doc(docId)
          .set(dataParaGuardar);

      dataParaGuardar['id'] = docId;

      setState(() {
        _catalogoCompleto.add(dataParaGuardar);
        _cantidades[nombre] = 1;
        _unidadesSeleccionadas[nombre] = 0;
        _buscarController.text = nombre;
        _buscarAlimento(); // Refresca los resultados
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$nombre" se guardó en la base de datos.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  Future<void> _configurarCantidad(Map<String, dynamic> alimento) async {
    final String nombre = alimento['nombre'].toString();
    final List<Map<String, dynamic>> unidades = (alimento['unidades'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final Map<String, int>? resultado = await showDialog<Map<String, int>>(
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
    final String nombre = alimento['nombre'].toString();
    final List unidades = alimento['unidades'] as List;
    final int cantidad = _cantidades[nombre] ?? 1;
    final int indiceUnidad = _unidadesSeleccionadas[nombre] ?? 0;

    final Map unidad = unidades[indiceUnidad] as Map;
    final int kcalPorUnidad = int.tryParse(unidad['kcal'].toString()) ?? 0;
    final int kcalTotal = kcalPorUnidad * cantidad;
    final String nombreUnidad = unidad['unidad'].toString();

    final String nombreRegistrado = cantidad == 1
        ? '$nombre ($nombreUnidad)'
        : '$nombre ($cantidad x $nombreUnidad)';

    // Enviar datos al Dashboard
    widget.onComidaAgregada(nombreRegistrado, kcalTotal);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$nombre añadido: $kcalTotal kcal.')),
    );
    Navigator.pop(context); // Regresar al Dashboard
  }

  @override
  Widget build(BuildContext context) {
    final colorPrincipal = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
      body: _cargando
          ? Center(child: CircularProgressIndicator(color: colorPrincipal))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: _buscarController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _buscarAlimento(),
                    style: const TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                      hintText: 'Buscar alimento...',
                      prefixIcon: const Icon(Icons.search, size: 26),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 24),
                        tooltip: 'Limpiar búsqueda',
                        onPressed: _limpiarBusqueda,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrincipal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _buscarAlimento,
                      child: const Text(
                        'Buscar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorPrincipal, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _abrirCrearAlimento,
                      child: Text(
                        'Crear Alimento Personalizado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorPrincipal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Resultados de Búsqueda',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _resultados.isEmpty
                        ? const Center(
                            child: Text(
                              'No se encontraron alimentos.\nPuedes crear uno personalizado.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black54,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _resultados.length,
                            itemBuilder: (context, index) {
                              final alimento = _resultados[index];
                              final String nombre = alimento['nombre']
                                  .toString();
                              final List unidades =
                                  alimento['unidades'] as List;
                              final int cantidad = _cantidades[nombre] ?? 1;
                              final int indice =
                                  _unidadesSeleccionadas[nombre] ?? 0;

                              final Map unidad = unidades[indice] as Map;
                              final String kcalStr = unidad['kcal'].toString();
                              final String nombreUnidad = unidad['unidad']
                                  .toString();

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorPrincipal.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nombre,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$kcalStr kcal $nombreUnidad',
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
                                      onPressed: () =>
                                          _configurarCantidad(alimento),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        side: BorderSide(
                                          color: Colors.grey.shade400,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Cantidad',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            '$cantidad',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _anadirAlimento(alimento),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorPrincipal,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        minimumSize: Size.zero,
                                      ),
                                      child: const Text(
                                        'Añadir',
                                        style: TextStyle(
                                          fontSize: 16,
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
    );
  }
}

// ============================================================================
// 2. PANTALLA: CREAR ALIMENTO PERSONALIZADO
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

    final List<Map<String, dynamic>> unidadesValidas = [];
    for (int i = 0; i < _unidades.length; i++) {
      final String unidad = _unidades[i].unidadController.text.trim();
      final int? kcal = int.tryParse(
        _unidades[i].caloriasController.text.trim(),
      );
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final colorPrincipal = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Personalizado',
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
              style: const TextStyle(fontSize: 18),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintStyle: const TextStyle(fontSize: 18),
                hintText: 'Escribe el nombre del alimento',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
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
                    'Unidad/cantidad',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Kcal',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
                        style: const TextStyle(fontSize: 17),
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
                        style: const TextStyle(fontSize: 17),
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
                  backgroundColor: colorPrincipal.withOpacity(0.1),
                  foregroundColor: colorPrincipal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _agregarUnidad,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Agregar otra unidad',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrincipal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _guardarAlimento,
                child: const Text(
                  'Guardar alimento',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
// DIÁLOGO DE CANTIDAD
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

class _DialogoCantidadAlimentoState extends State<_DialogoCantidadAlimento> {
  late final TextEditingController _cantidadController;
  late int _unidadElegida;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController(
      text: '${widget.cantidadInicial}',
    );
    _unidadElegida = widget.unidadInicial
        .clamp(0, widget.unidades.length - 1)
        .toInt();
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

    Navigator.of(
      context,
    ).pop<Map<String, int>>({'cantidad': cantidad, 'unidad': _unidadElegida});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Cantidad de ${widget.nombre}',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Elige una unidad y escribe la cantidad.',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _unidadElegida,
            isExpanded: true,
            decoration: const InputDecoration(
              labelStyle: TextStyle(fontSize: 19),
              labelText: 'Unidad',
              border: OutlineInputBorder(),
            ),
            items: List.generate(widget.unidades.length, (index) {
              final unidad = widget.unidades[index];
              return DropdownMenuItem<int>(
                value: index,
                child: Text(
                  '${unidad['unidad']} — ${unidad['kcal']} kcal',
                  style: const TextStyle(fontSize: 17),
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
            style: const TextStyle(fontSize: 19),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _guardar(),
            decoration: const InputDecoration(
              labelStyle: TextStyle(fontSize: 19),
              labelText: 'Cantidad',
              hintText: 'Ej. 2',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
        ),
        ElevatedButton(
          onPressed: _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: Size.zero,
          ),
          child: const Text(
            'Guardar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
