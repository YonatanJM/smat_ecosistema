import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Requerido para consultar las lecturas reales
import 'dart:convert';
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
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final estacion = snapshot.data![index];

                final Color colorAlerta = (estacion.valor ?? 0) < 50 ? Colors.green : Colors.red;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorAlerta.withOpacity(0.2),
                    child: Icon(Icons.sensors, color: colorAlerta),
                  ),
                  title: Text(estacion.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${estacion.ubicacion}\nValor: ${estacion.valor ?? 0}"),
                  isThreeLine: true,
                  
                  // ====== INTEGRACIÓN DEL CLIC (COMPONENTE 3) ======
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VistaDetalleLecturas(
                          nombreEstacion: estacion.nombre,
                        ),
                      ),
                    );
                  },
                  
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

// =========================================================================
// NUEVA VISTA: HISTORIAL DE LECTURAS EN TIEMPO REAL CON ALERTA DINÁMICA
// =========================================================================
class VistaDetalleLecturas extends StatefulWidget {
  final String nombreEstacion;
  const VistaDetalleLecturas({super.key, required this.nombreEstacion});

  @override
  State<VistaDetalleLecturas> createState() => _VistaDetalleLecturasState();
}

class _VistaDetalleLecturasState extends State<VistaDetalleLecturas> {
  List<dynamic> _lecturas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _obtenerLecturasServidor();
  }

  // Función limpia para traer las mediciones inyectadas por el IoT
  Future<void> _obtenerLecturasServidor() async {
    setState(() {
      _cargando = true;
    });
    try {
      // Petición directa a tu backend local corriendo en Chrome
      final response = await http.get(Uri.parse('http://localhost:8000/lecturas/'));
      if (response.statusCode == 200) {
        setState(() {
          _lecturas = json.decode(response.body);
          _cargando = false;
        });
      } else {
        setState(() { _cargando = false; });
      }
    } catch (e) {
      debugPrint("Error conectando a la API: $e");
      setState(() { _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monitoreo: ${widget.nombreEstacion}'),
        actions: [
          // Botón para refrescar y ver cómo aumenta la lista sola
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _obtenerLecturasServidor,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _lecturas.isEmpty
              ? const Center(child: Text("No hay lecturas de telemetría aún."))
              : RefreshIndicator(
                  onRefresh: _obtenerLecturasServidor,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _lecturas.length,
                    // Mostramos las lecturas más recientes primero arriba
                    itemBuilder: (context, index) {
                      final lectura = _lecturas[_lecturas.length - 1 - index];
                      final double valor = double.tryParse(lectura['valor'].toString()) ?? 0.0;

                      // VALIDACIÓN DEL RETO: Si supera los 70.0 cm activa el modo alerta
                      bool esAlerta = valor > 70.0;

                      return Card(
                        // Fondo rojo suave para peligro, blanco para nivel normal
                        color: esAlerta ? Colors.red.shade50 : Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                        elevation: esAlerta ? 3 : 1,
                        child: ListTile(
                          leading: Icon(
                            esAlerta ? Icons.warning_amber_rounded : Icons.water,
                            color: esAlerta ? Colors.red : Colors.blue,
                            size: 30,
                          ),
                          title: Text(
                            "Nivel del agua: $valor cm",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: esAlerta ? Colors.red.shade900 : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            esAlerta 
                                ? "ESTADO: ¡ALERTA DE DESBORDE CRÍTICO!\nFrecuencia: Transmisión rápida (2s)" 
                                : "ESTADO: SEGURO / NORMAL\nFrecuencia: Transmisión estándar (10s)",
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}