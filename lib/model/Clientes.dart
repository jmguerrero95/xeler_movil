class Clientes {
  const Clientes({required this.id, required this.name});

  final int id;
  final String name;

  factory Clientes.fromJson(Map<String, dynamic> json) {
    return Clientes(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}
