import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/estacion.dart';

void main() => runApp(const SMATApp());

class SMATApp extends StatelessWidget {
  const SMATApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMAT Monitoreo',
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Estacion>> futureEstaciones;

  @override
  void initState() {
    super.initState();
    // Carga inicial de datos al abrir la app [cite: 105]
    futureEstaciones = ApiService().fetchEstaciones();
  }

  // Lógica de Refresco para el Reto [cite: 145, 146]
  void _refreshData() {
    setState(() {
      futureEstaciones = ApiService().fetchEstaciones();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMAT - Monitoreo Móvil'), // [cite: 110]
      ),
      body: FutureBuilder<List<Estacion>>( // [cite: 111]
        future: futureEstaciones,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // [cite: 115]
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error de conexión')); // [cite: 117]
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay estaciones registradas.'));
          } else {
            return ListView.builder( // [cite: 119]
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final est = snapshot.data![index];
                return ListTile(
                  leading: const Icon(Icons.satellite_alt), // [cite: 124]
                  title: Text(est.nombre), // [cite: 125]
                  subtitle: Text(est.ubicacion), // [cite: 126]
                );
              },
            );
          }
        },
      ),
      // --- IMPLEMENTACIÓN DEL RETO: BOTÓN FLOTANTE [cite: 144] ---
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}