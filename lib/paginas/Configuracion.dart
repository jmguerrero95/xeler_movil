import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/paginas/Login.dart';
//import 'package:xeler_impresora/paginas/Seleccion.dart';

import 'Cambiar.dart';
import 'Seleccion2.dart';

const TextStyle whiteBoldText = TextStyle(
  fontWeight: FontWeight.bold,
  color: Colors.black,
);

class ConfiguracionPage extends StatefulWidget {
  ConfiguracionPage({Key key, this.title}) : super(key: key);
  final String title;
  

  @override
  _ConfiguracionState createState() => _ConfiguracionState();
  
}

class _ConfiguracionState extends State<ConfiguracionPage>{
  var userData;
  String elDispositivo;
  final TextStyle whiteText = TextStyle(
    color: Colors.white,
  );
  final TextStyle greyTExt = TextStyle(
    color: Colors.grey.shade400,
  );

  /* void getStringValuesSF() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  //Return String
  var stringValue = prefs.getString('dispositivo');
  setState((){
    elDispositivo = stringValue;
  });
  //return stringValue;
} */

  @override
  void initState(){
    _getUserInfo();
   // getStringValuesSF();
    super.initState();
  }

  void _getUserInfo() async {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var userJson = localStorage.getString('user'); 
      var user = json.decode(userJson);
      var stringValue = user['dispositivo'].toString();
      if(stringValue != null){
        setState(() => {
            userData = user,
            elDispositivo = stringValue
        });
        /* setState(() {
          userData = user;
          elDispositivo = stringValue;
        }); */
      }
      //print(userData['dispositivo']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                  Image.asset(
                 'assets/images/512xeler.png',
                  fit: BoxFit.contain,
                  height: 32,
              ),
            ],
        ),
      ),
      body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                ListTile(
                  title: Text(
                    "Impresora Seleccionada",
                    style: whiteBoldText,
                  ),
                  subtitle: Text(
                    elDispositivo != null ? elDispositivo : 'Ninguna',
                    style: greyTExt,
                  ),
                  trailing: Icon(
                    Icons.keyboard_arrow_right,
                    color: Colors.grey.shade400,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SeleccionPage2()));
                  },
                ),
                Divider(
                  color: Colors.black,
                  height: 5,
                ),
                ListTile(
                  title: Text(
                    "Cambiar Contraseña",
                    style: whiteBoldText,
                  ),
                  trailing: Icon(
                    Icons.keyboard_arrow_right,
                    color: Colors.grey.shade400,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => CambiarPage()));
                  },
                ),
                /* Divider(
                  color: Colors.black,
                  height: 5,
                ),
                ListTile(
                  title: Text(
                    "Impresora Seleccionada",
                    style: whiteBoldText,
                  ),
                  subtitle: Text(
                    /* elDispositivo != null ? elDispositivo :  */'Ninguna',
                    style: greyTExt,
                  ),
                  trailing: Icon(
                    Icons.keyboard_arrow_right,
                    color: Colors.grey.shade400,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SeleccionPage2()));
                  },
                ), */
                Divider(
                  color: Colors.black,
                  height: 5,
                ),
              ],
            ),
          ),
    );

    


  }

  void logout() async{
      // logout from the server ... 
      var res = await CallApi().getData('logout');
      var body = json.decode(res.body);
      if(body['success']){
         SharedPreferences localStorage = await SharedPreferences.getInstance();
         localStorage.remove('user');
         localStorage.remove('token');
          Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => LogIn()));
      }
     
  }

}

