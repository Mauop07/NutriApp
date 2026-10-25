import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

import 'notification_service.dart';

class PantallaConfiguracionNotificaciones extends StatefulWidget {
  const PantallaConfiguracionNotificaciones({super.key});

  @override
  State<PantallaConfiguracionNotificaciones> createState() =>
      _PantallaConfiguracionNotificacionesState();
}

class _PantallaConfiguracionNotificacionesState
    extends State<PantallaConfiguracionNotificaciones> {
  List<Map<String, dynamic>> _alarmas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _inicializarNotificaciones();
  }

  /// Solicita permisos críticos y carga los recordatorios configurados.
  Future<void> _inicializarNotificaciones() async {
    await NotificationService().solicitarPermisos();
    await _cargarAlarmas();
  }

  /// Lee las alarmas desde SharedPreferences o inyecta las predeterminadas.
  Future<void> _cargarAlarmas() async {
    final prefs = await SharedPreferences.getInstance();
    final String? alarmasGuardadas = prefs.getString('mis_alarmas');

    if (alarmasGuardadas != null) {
      final List<dynamic> decodificado = jsonDecode(alarmasGuardadas);
      _alarmas = decodificado.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      _alarmas = [
        {
          'id': 101,
          'titulo': 'Desayuno',
          'hora': 8,
          'minuto': 0,
          'activa': true,
        },
        {
          'id': 102,
          'titulo': 'Almuerzo',
          'hora': 12,
          'minuto': 0,
          'activa': true,
        },
        {'id': 103, 'titulo': 'Cena', 'hora': 18, 'minuto': 0, 'activa': true},
      ];
      await _guardarYProgramarAlarmas();
    }

    setState(() => _cargando = false);
  }

  /// Ordena la lista de alarmas cronológicamente por hora y minuto.
  void _ordenarAlarmas() {
    _alarmas.sort((a, b) {
      final tiempoA = (a['hora'] * 60) + a['minuto'];
      final tiempoB = (b['hora'] * 60) + b['minuto'];
      return tiempoA.compareTo(tiempoB);
    });
  }

  /// Guarda los cambios en almacenamiento local y reprograma las alertas en el sistema.
  Future<void> _guardarYProgramarAlarmas() async {
    _ordenarAlarmas();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mis_alarmas', jsonEncode(_alarmas));

    for (var alarma in _alarmas) {
      if (alarma['activa']) {
        await NotificationService().programarNotificacionDiaria(
          id: alarma['id'],
          title: '¡Hora de tu ${alarma['titulo']}!',
          body: 'No olvides registrar tu comida en la app.',
          hour: alarma['hora'],
          minute: alarma['minuto'],
        );
      } else {
        await NotificationService().cancelarNotificacion(alarma['id']);
      }
    }
  }

  /// Alterna el estado activo/inactivo de un recordatorio específico.
  Future<void> _toggleAlarma(int index, bool valor) async {
    setState(() {
      _alarmas[index]['activa'] = valor;
    });
    await _guardarYProgramarAlarmas();
  }

  /// Muestra diálogo de confirmación y elimina un recordatorio.
  Future<void> _eliminarAlarma(int index) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar alarma'),
          content: Text(
            '¿Seguro que deseas eliminar el recordatorio de "${_alarmas[index]['titulo']}"?',
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
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontSize: 16),
                    ),
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
                    child: const Text(
                      'Eliminar',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final idCancelar = _alarmas[index]['id'];
    await NotificationService().cancelarNotificacion(idCancelar);

    setState(() {
      _alarmas.removeAt(index);
    });
    await _guardarYProgramarAlarmas();
  }

  /// Despliega el selector de hora estilo Cupertino (iOS).
  Future<TimeOfDay?> _mostrarSelectorCupertino(TimeOfDay tiempoInicial) async {
    TimeOfDay? tiempoElegido = tiempoInicial;

    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 280,
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onPressed: () {
                      tiempoElegido = null;
                      Navigator.pop(context);
                    },
                  ),
                  CupertinoButton(
                    child: Text(
                      'Aceptar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: false,
                  initialDateTime: DateTime(
                    2023,
                    1,
                    1,
                    tiempoInicial.hour,
                    tiempoInicial.minute,
                  ),
                  onDateTimeChanged: (DateTime nuevaHora) {
                    tiempoElegido = TimeOfDay(
                      hour: nuevaHora.hour,
                      minute: nuevaHora.minute,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    return tiempoElegido;
  }

  /// Edita la hora configurada de una alarma existente.
  Future<void> _editarHora(int index) async {
    final horaActual = _alarmas[index]['hora'];
    final minutoActual = _alarmas[index]['minuto'];

    final TimeOfDay? horaSeleccionada = await _mostrarSelectorCupertino(
      TimeOfDay(hour: horaActual, minute: minutoActual),
    );

    if (horaSeleccionada != null) {
      setState(() {
        _alarmas[index]['hora'] = horaSeleccionada.hour;
        _alarmas[index]['minuto'] = horaSeleccionada.minute;
        _alarmas[index]['activa'] = true;
      });
      await _guardarYProgramarAlarmas();
    }
  }

  /// Agrega un nuevo recordatorio personalizado al listado.
  Future<void> _agregarAlarma() async {
    final TimeOfDay? horaSeleccionada = await _mostrarSelectorCupertino(
      TimeOfDay.now(),
    );

    if (horaSeleccionada == null || !mounted) return;

    final TextEditingController nombreController = TextEditingController();
    final String? nombreSeleccionado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombre del recordatorio'),
        content: TextField(
          controller: nombreController,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ej. Merienda'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (nombreController.text.trim().isNotEmpty) {
                Navigator.pop(context, nombreController.text.trim());
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nombreSeleccionado != null && nombreSeleccionado.isNotEmpty) {
      setState(() {
        _alarmas.add({
          'id': DateTime.now().millisecondsSinceEpoch.remainder(100000),
          'titulo': nombreSeleccionado,
          'hora': horaSeleccionada.hour,
          'minuto': horaSeleccionada.minute,
          'activa': true,
        });
      });
      await _guardarYProgramarAlarmas();
    }
  }

  /// Formatea la hora numérica a formato de lectura local (ej. 8:00 AM).
  String _formatearHora(int hora, int minuto) {
    final TimeOfDay tiempo = TimeOfDay(hour: hora, minute: minuto);
    // ignore: use_build_context_synchronously
    return tiempo.format(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            color: Colors.black,
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.red),
            onPressed: () => NotificationService().dispararPruebaInstantanea(),
          ),
        ],
      ),
      body: _cargando
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _alarmas.length,
              itemBuilder: (context, index) {
                final alarma = _alarmas[index];
                return Card(
                  color: Colors.grey[100],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      alarma['titulo'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      _formatearHora(alarma['hora'], alarma['minuto']),
                      style: TextStyle(
                        fontSize: 16,
                        color: alarma['activa']
                            ? theme.colorScheme.primary
                            : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: alarma['activa'],
                          activeThumbColor: theme.colorScheme.primary,
                          onChanged: (valor) => _toggleAlarma(index, valor),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _eliminarAlarma(index),
                        ),
                      ],
                    ),
                    onTap: () => _editarHora(index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: _agregarAlarma,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nueva Alarma',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
