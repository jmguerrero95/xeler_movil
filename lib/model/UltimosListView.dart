class UltimosClientes {
  int id;
  String name;
  
  UltimosClientes(this.id, this.name);

  UltimosClientes.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }
}