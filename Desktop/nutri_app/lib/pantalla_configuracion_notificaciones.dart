import 'package:flutter/material.dart';
import 'notification_service.dart';

class PantallaConfiguracionNotificaciones extends StatefulWidget {
  const PantallaConfiguracionNotificaciones({Key? key}) : super(key: key);

  @override
  _PantallaConfiguracionNotificacionesState createState() =>
      _PantallaConfiguracionNotificacionesState();
}

class _PantallaConfiguracionNotificacionesState
    extends State<PantallaConfiguracionNotificaciones> {
  bool _activas = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Notificaciones'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Recordatorios de comidas'),
            subtitle: const Text('Activa las alertas para registrar tus alimentos a tiempo.'),
            value: _activas,
            onChanged: (valor) {
              setState(() {
                _activas = valor;
              });
              if (valor) {
                NotificationService().showNotification(
                  title: '¡Notificaciones activadas!',
                  body: 'Te avisaremos cuando debas registrar tus alimentos.',
                );
              }
            },
          ),
        ],
      ),
    );
  }
}