import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Importación para AuthService
import 'login_screen.dart';           // Importación para LoginScreen

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estaciones SMAT'), // Título solicitado en el reto
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // 1. Llama al servicio para eliminar el jwt_token de SharedPreferences
              await AuthService().logout();

              // 2. Reinicia la navegación al Login y borra todo el historial
              // Usamos context.mounted para evitar errores si el widget ya no existe
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false, // Esta línea resetea la aplicación
                );
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Bienvenido al Dashboard de SMAT'),
      ),
    );
  }
}