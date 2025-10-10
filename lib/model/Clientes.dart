class Clientes {
  int id;
  String name;
  
  Clientes(this.id, this.name);

  Clientes.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }
}