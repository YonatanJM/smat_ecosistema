import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/estacion.dart';
import 'login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Estacion>> estacionesFuture;

  @override
  void initState() {
    super.initState();
    _refreshEstaciones();
  }

  // Modificado para retornar el Future y poder usarlo en el RefreshIndicator
  Future<void> _refreshEstaciones() async {
    setState(() {
      estacionesFuture = ApiService().fetchEstaciones();
    });
    await estacionesFuture;
  }

  void _confirmarEliminacion(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar Estación?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              bool ok = await ApiService().eliminarEstacion(id);
              if (ok && mounted) {
                Navigator.pop(context);
                _refreshEstaciones();
              }
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _abrirDialogoEdicion(Estacion estacion) {
    final nombreCtrl = TextEditingController(text: estacion.nombre);
    final ubicacionCtrl = TextEditingController(text: estacion.ubicacion);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Estación"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(controller: ubicacionCtrl, decoration: const InputDecoration(labelText: "Ubicación")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              bool ok = await ApiService().editarEstacion(estacion.id, nombreCtrl.text, ubicacionCtrl.text);
              if (ok && mounted) {
                Navigator.pop(context);
                _refreshEstaciones();
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estaciones SMAT'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshEstaciones),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      // --- RETO IMPLEMENTADO: Gesto de deslizar para actualizar ---
      body: RefreshIndicator(
        onRefresh: _refreshEstaciones,
        child: FutureBuilder<List<Estacion>>(
          future: estacionesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // Con AlwaysScrollableScrollPhysics permitimos el gesto incluso si está vacío
              return const Center(
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: 500, 
                    child: Center(child: Text('No hay estaciones registradas.')),
                  ),
                ),
              );
            }

            return ListView.builder(
              // Crucial para que el RefreshIndicator funcione siempre
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final estacion = snapshot.data![index];

                // Lógica de alerta: Rojo >= 50, Verde < 50
                final Color colorAlerta = (estacion.valor ?? 0) < 50 ? Colors.green : Colors.red;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorAlerta.withOpacity(0.2),
                    child: Icon(Icons.sensors, color: colorAlerta),
                  ),
                  title: Text(estacion.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${estacion.ubicacion}\nValor: ${estacion.valor ?? 0}"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _abrirDialogoEdicion(estacion),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmarEliminacion(estacion.id),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}