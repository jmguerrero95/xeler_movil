class Resumen{
  int id;
  String valor;
  String cliente;
  String primeros;
  String ultimos;
  String creado;
  Resumen(this.id, this.valor,this.cliente,this.primeros,this.ultimos,this.creado);

  Resumen.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    valor = json['valor'];
    cliente = json['cliente'];
    primeros = json['wallet_inicio'];
    ultimos = json['wallet_fin'];
    creado = json['created_at'];
  }
}