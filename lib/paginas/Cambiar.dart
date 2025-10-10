import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:xeler_impresora/api/api.dart';

class CambiarPage extends StatefulWidget {
  @override
  _CambiarPageState createState() => _CambiarPageState();
}

class _CambiarPageState extends State<CambiarPage> {

  bool _isLoading = false;
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController passwordNuevoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Cambiar Contraseña'),
      ),
      //Appbar
      body: SingleChildScrollView(
        child: Card(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: TextField(
                  obscureText: true,
                  controller: oldPasswordController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Contraseña Anterior',
                    labelText:  'Contraseña Anterior'
                  )
                ),
              ),
              //Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(25.0, 0.0, 25.0, 25.0),
                child: TextField(
                  obscureText: true,
                  controller: passwordController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Contraseña Nueva',
                    labelText:  'Contraseña Nueva'
                  )
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(25.0, 0.0, 25.0, 25.0),
                child: TextField(
                  obscureText: true,
                  controller: passwordNuevoController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Repite Contraseña Nueva',
                    labelText:  'Repite Contraseña Nueva'
                  )
                ),
              ),
              Divider(),
              Padding(
                padding: EdgeInsets.fromLTRB(25.0, 0.0, 25.0, 25.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                                  child: RaisedButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    onPressed: _isLoading ? null : _cambiar,
                    padding: EdgeInsets.all(12),
                    color: Color.fromARGB(255,118, 104, 254),
                    child: _isLoading ? Center( child:CircularProgressIndicator()) : 
                    Text(_isLoading? 'Cambiando...' : 'Cambiar', 
                    style: TextStyle(color: Colors.white)),
                  ),
                ),
              )
            ]
          ),
        )
      ),
    );
  }

  void _showNewVersionAvailableDialog(msg,titulo) {
  final alert = AlertDialog(
    title: Text(titulo),
    content: Text(msg),
    actions: [FlatButton(child: Text("OK"), onPressed: () {
      Navigator.of(context).pop();
     // Navigator.pop();
    })],
  );

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

  void _cambiar() async{
    
    setState(() {
       _isLoading = true;
    });

    var data = {
        'old_password' : oldPasswordController.text, 
        'password' : passwordController.text,
        'nueva' : passwordNuevoController.text
    };

    var res = await CallApi().postData(data, 'configuracion2');
    var body = json.decode(res.body);
    //print(body);
    if(body['success']){
      _showNewVersionAvailableDialog(body['mensaje'],body['titulo']);
      oldPasswordController.clear();
      passwordNuevoController.clear();
      passwordController.clear();
    }else{
      _showNewVersionAvailableDialog(body['mensaje'],body['titulo']);
    }


    setState(() {
       _isLoading = false;
    });

  


  }


}