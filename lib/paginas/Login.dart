import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/paginas/Inicio.dart';

class LogIn extends StatefulWidget {
  @override
  _LogInState createState() => _LogInState();
}

class _LogInState extends State<LogIn> {


  bool _isLoading = false;


  TextEditingController mailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  ScaffoldState scaffoldState;
  _showMsg(msg) { //
    final snackBar = SnackBar(
      content: Text(msg),
      action: SnackBarAction(
        label: 'Cerrar',
        onPressed: () {
          // Some code to undo the change!
        },
      ),
    );
    Scaffold.of(context).showSnackBar(snackBar);
  }
 @override
  Widget build(BuildContext context) {
      final logo = Hero(
      tag: 'hero',
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 48.0,
        child: Image.asset('assets/images/512xeler.png'),
      ),
    );

    final email = TextFormField(
      cursorColor: Color.fromARGB(255, 36, 38, 80),
      keyboardType: TextInputType.emailAddress,
      controller: mailController,
      autofocus: false,
      style: TextStyle(color: Color(0xFF000000)),
      decoration: InputDecoration(
        hintText: 'Usuario',
        fillColor: Colors.white, 
        filled: true,
        contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
      ),
    );

    final password = TextFormField(
      autofocus: false,
      obscureText: true,
      controller: passwordController,
      style: TextStyle(color: Color(0xFF000000)),
      decoration: InputDecoration(
        hintText: 'Contraseña',
        fillColor: Colors.white, 
        filled: true,
        contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.0)
        ),
        
      ),
    );

    final loginButton = Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: RaisedButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        onPressed: _isLoading ? null : _login,
        padding: EdgeInsets.all(12),
        color: Color.fromARGB(255,118, 104, 254),
        child: Text(_isLoading? 'Iniciando...' : 'Iniciar Sesión', 
        style: TextStyle(color: Colors.white)),
      ),
    );

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 36, 38, 80),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(left: 24.0, right: 24.0),
          children: <Widget>[
            logo,
            SizedBox(height: 48.0),
            email,
            SizedBox(height: 8.0),
            password,
            SizedBox(height: 24.0),
            loginButton
          ],
        ),
      ),
    );
  



  }

  void _login() async{
    
    setState(() {
       _isLoading = true;
    });

    var data = {
        'username' : mailController.text, 
        'password' : passwordController.text
    };

    var res = await CallApi().postData(data, 'login');
    var body = json.decode(res.body);
    //print(body);
    if(body['success']){
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      localStorage.setString('token', body['token']);
      localStorage.setString('user', json.encode(body['user']));
      Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => Inicio()));
    }else{
      _showMsg(body['message']);
    }


    setState(() {
       _isLoading = false;
    });

  


  }
  
}