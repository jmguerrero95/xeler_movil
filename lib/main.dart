import 'dart:convert';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xeler_impresora/paginas/Inicio.dart';
import 'package:xeler_impresora/paginas/Login.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  bool _isLoggedIn = false;
  bool _connected = false;
  var userData;
  int _tipo;
  String _dispositivo,_direccion;
  //var myDevice = BluetoothDevice;
  

  @override
  void initState() {
    _checkIfLoggedIn();
    super.initState();
  }

  void _checkIfLoggedIn() async {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var token = localStorage.getString('token');
      var userJson = localStorage.getString('user'); 
      var user = json.decode(userJson);
      var stringValue = user['dispositivo'].toString();
      var stringValue2 = user['address'].toString();
      var stringValue3 = user['tipo'];
      if(token != null){
        setState(() => {
            _isLoggedIn = true,
            userData = user,
            _dispositivo = stringValue,
            _direccion = stringValue2,
            _tipo = stringValue3
        });
         /* setState(() {
            _isLoggedIn = true;
            userData = user;
            _dispositivo = stringValue;
            _direccion = stringValue2;
            _tipo = stringValue3;
         }); */
      }

      if(_direccion != null){

          final myDevice = BluetoothDevice.fromMap({
            'name': _dispositivo,
            'address': _direccion,
            'type': _tipo
        });

        bluetooth.isConnected.then((isConnected) {
          
            if (!isConnected) {
              
              bluetooth.connect(myDevice).catchError((error) {
                setState(() {
                  _connected = false;
                  });
              });
            }
          });
      }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [                             
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate
      ],
      supportedLocales: [
        const Locale('es'),
      ],
      theme: new ThemeData(
          primaryColor: Color.fromARGB(255, 36, 38, 80), 
          fontFamily: 'Raleway'
      ),
      home: Scaffold(
        //body: Inicio(),
        body: _isLoggedIn ? Inicio() :  LogIn(),
      ),
      
    );
  }
}
