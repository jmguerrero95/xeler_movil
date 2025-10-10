class UltimosClientes {
  const UltimosClientes({required this.id, required this.name});

  final int id;
  final String name;

  factory UltimosClientes.fromJson(Map<String, dynamic> json) {
    return UltimosClientes(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}
