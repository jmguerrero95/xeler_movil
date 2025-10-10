import 'dart:convert';

import 'package:fancy_bottom_navigation/fancy_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/paginas/Clientes.dart';
import 'package:xeler_impresora/paginas/Configuracion.dart';
import 'package:xeler_impresora/paginas/Home.dart';
import 'package:xeler_impresora/paginas/Resumen.dart';
//import 'package:xeler_impresora/paginas/Seleccion.dart';

import 'Login.dart';

const TextStyle whiteBoldText = TextStyle(
  fontWeight: FontWeight.bold,
  color: Colors.black,
);

int _index = 0;
final List<Widget> _pages = [
  HomePage(),
  ClientesPage(),
  ResumenPage(),
  ConfiguracionPage(),
];



class Inicio extends StatefulWidget {
  
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Inicio> {
  final TextStyle whiteText = TextStyle(
    color: Colors.white,
  );
  final TextStyle greyTExt = TextStyle(
    color: Colors.grey.shade400,
  );
  var userData;
  int currentPage = 0;
  
  GlobalKey bottomNavigationKey = GlobalKey();

  @override
  void initState() {
    _getUserInfo();
    
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
  ]);
  }

  void _getUserInfo() async {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var userJson = localStorage.getString('user'); 
      var user = json.decode(userJson);
      setState(() {
        userData = user;
      });

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: FancyBottomNavigation(
        tabs: [
          TabData(
              iconData: Icons.home,
              title: "Inicio"),
          TabData(
              iconData: Icons.supervisor_account,
              title: "Clientes"),
          TabData(
              iconData: Icons.monetization_on,
              title: "Resumen"),
          TabData(
             iconData: Icons.settings,
             title: "Configuración")
        ],
        onTabChangedListener: (position){
          setState(() {
            _index = position;
          });
        },
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