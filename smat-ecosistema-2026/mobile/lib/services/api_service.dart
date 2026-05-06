import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/estacion.dart';
import 'auth_service.dart'; 

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000";
  // Método para obtener la lista de estaciones (Lectura)
  Future<List<Estacion>> fetchEstaciones() async {
    final response = await http.get(Uri.parse('$baseUrl/estaciones/'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Estacion.fromJson(data)).toList();
    } else {
      throw Exception('Error al conectar con el servidor SMAT');
    }
  }
  Future<bool> crearEstacion(String nombre, String ubicacion) async {
    // 1. Recuperamos el token guardado en SharedPreferences
    final token = await AuthService().getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/estaciones/'),
      headers: {
        'Content-Type': 'application/json',
        // 2. Adjuntamos el token en el Header para que FastAPI nos autorice[cite: 2]
        'Authorization': 'Bearer $token', 
      },
      // 3. Enviamos los datos en formato JSON[cite: 2]
      body: jsonEncode({
        'nombre': nombre,
        'ubicacion': ubicacion,
      }),
    );
    // Retorna true si la estación se creó con éxito (Status 200 o 201)[cite: 2]
    return response.statusCode == 200 || response.statusCode == 201;
  }
}