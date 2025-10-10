class Resumen {
  const Resumen({
    required this.id,
    required this.valor,
    required this.cliente,
    required this.primeros,
    required this.ultimos,
    required this.creado,
  });

  final int id;
  final String valor;
  final String cliente;
  final String primeros;
  final String ultimos;
  final String creado;

  factory Resumen.fromJson(Map<String, dynamic> json) {
    return Resumen(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      valor: json['valor']?.toString() ?? '0',
      cliente: json['cliente']?.toString() ?? '',
      primeros: json['wallet_inicio']?.toString() ?? '',
      ultimos: json['wallet_fin']?.toString() ?? '',
      creado: json['created_at']?.toString() ?? '',
    );
  }
}
