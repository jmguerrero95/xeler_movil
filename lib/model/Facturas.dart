class Facturas {
  int id;
  String factura_number;
  String valor;
  String primeros;
  String ultimos;
  String creado;
  Facturas(this.id,this.factura_number, this.valor,this.primeros,this.ultimos,this.creado);

  Facturas.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    factura_number = json['factura_id'];
    valor = json['valor'];
    primeros = json['wallet_inicio'];
    ultimos = json['wallet_fin'];
    creado = json['created_at'];
  }
}