class Estacion {
  final int id;
  final String nombre;
  final String ubicacion;
  final int? valor; 

  Estacion({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    this.valor, 
  });

  factory Estacion.fromJson(Map<String, dynamic> json) {
    return Estacion(
      id: json['id'],
      nombre: json['nombre'],
      ubicacion: json['ubicacion'],
      valor: json['valor'] is int ? json['valor'] : 0, 
    );
  }
}