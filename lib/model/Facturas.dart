class Facturas {
  const Facturas({
    required this.id,
    required this.facturaNumber,
    required this.valor,
    required this.primeros,
    required this.ultimos,
    required this.creado,
  });

  final int id;
  final String facturaNumber;
  final String valor;
  final String primeros;
  final String ultimos;
  final String creado;

  factory Facturas.fromJson(Map<String, dynamic> json) {
    return Facturas(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      facturaNumber: json['factura_id']?.toString() ?? '',
      valor: json['valor']?.toString() ?? '0',
      primeros: json['wallet_inicio']?.toString() ?? '',
      ultimos: json['wallet_fin']?.toString() ?? '',
      creado: json['created_at']?.toString() ?? '',
    );
  }
}
