import 'dart:convert';
import 'dart:async'; // Necesario para usar TimeoutException
import 'package:http/http.dart' as http;
import '../models/estacion.dart';
import 'auth_service.dart'; 

class ApiService {
  // TIP: Si usas emulador Android, recuerda que 127.0.0.1 es 10.0.2.2
  final String baseUrl = "http://127.0.0.1:8000";

  // --- MEJORA LABORATORIO 7.1: Manejo de errores y Timeouts ---

  Future<List<Estacion>> fetchEstaciones() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/estaciones/'))
          .timeout(const Duration(seconds: 5)); // Evita que la app espere por siempre

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Estacion.fromJson(data)).toList();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('El servidor SMAT tardó demasiado en responder.');
    } catch (e) {
      throw Exception('Error de conexión: Verifica si el servidor está encendido.');
    }
  }

  Future<bool> crearEstacion(String nombre, String ubicacion) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/estaciones/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', 
        },
        body: jsonEncode({
          'nombre': nombre,
          'ubicacion': ubicacion,
          'valor': 0, // Agregamos el valor inicial por defecto
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> eliminarEstacion(int id) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/estaciones/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> editarEstacion(int id, String nombre, String ubicacion) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/estaciones/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nombre': nombre,
          'ubicacion': ubicacion,
        }),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}