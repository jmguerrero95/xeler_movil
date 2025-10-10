import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/paginas/testprint.dart';
//import 'package:plugin_device_information/plugin_device_information.dart';

class SeleccionPage2 extends StatefulWidget {
  @override
  _SeleccionPage2State createState() => _SeleccionPage2State();
}

class _SeleccionPage2State extends State<SeleccionPage2> {
  
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice _device;
  bool _connected = false;
  bool _conectada = false;
  var userData;
  //var stringValue;
  String _dispositivo;
  String _direccion;
  int _tipo;
  String pathImage;
  TestPrint testPrint;
  final TextStyle whiteText = TextStyle(
    color: Colors.white,
  );
  final TextStyle greyTExt = TextStyle(
    color: Colors.grey.shade400,
  );
  final TextStyle whiteBoldText = TextStyle(
  fontWeight: FontWeight.bold,
  color: Colors.black,
);
  

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initSavetoPath();
   // _getUserInfo();
    //laImpresora();
    testPrint= TestPrint();
  }

  initSavetoPath() async {
    final filename = '192xeler.png';
    var bytes = await rootBundle.load("assets/images/192xeler.png");
    String dir = (await getApplicationDocumentsDirectory()).path;
    writeToFile(bytes,'$dir/$filename');
    setState(() {
      pathImage='$dir/$filename';
    });
  }


  Future<void> initPlatformState() async {
    
    bool isConnected=await bluetooth.isConnected;
    print(isConnected);
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } on PlatformException {
      //platformVersion = 'Error recuperando version.';
    }

    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case 1:
          setState(() {
            _connected = true;
          });
          break;
        case 0:
          setState(() {
            _connected = false;
          });
          break;
        /* default:
          print(state);
          break; */
      }
    });

    if (!mounted) return;
    setState(() {
      _devices = devices;
      //_platformVersion = platformVersion;
    });

    if(isConnected) {
      setState(() {
        _connected=true;
      });
    }
  }


  void _getUserInfo() async {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var userJson = localStorage.getString('user'); 
      var user = json.decode(userJson);
      var stringValue = user['dispositivo'].toString();
      print(stringValue);
      if(stringValue != null){
        setState(() => {
            userData = user,
        //  _connected=true,
          _dispositivo = stringValue
        });
        /* setState(() {
          userData = user;
          _connected=true;
          _dispositivo = stringValue;
        }); */

        //initPlatformState();
      }

      

  }

  void _guardarImpresora() async{
    var data = {
        'dispositivo' : _dispositivo,
        'tipo': _tipo,
        'address': _direccion 
    };

    var res = await CallApi().postData(data, 'guardarImpresora');
    var body = json.decode(res.body);
    //print(body);
    if(body['success']){
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      localStorage.setString('user', json.encode(body['user']));
    }

  /* 
  
    dispositivo: MHT-P28A, tipo: 0, address: DC:0D:30:A2:60:21
   */
  }

  /* void laImpresora() async {
    final myDevice = BluetoothDevice.fromMap({
      'name': _dispositivo,
      'address': _direccion,
      'type': _tipo
    });
    
  } */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Seleccion'),
        ),
        body: Container(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(width: 4,),
                    Text(
                      'Dis:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 15,),

                    Expanded(
                      child: !_connected ? 
                        DropdownButton(
                        items: _getDeviceItems(),
                        hint: new Text("Selecciona un dispositivo"),
                        value: _device,
                        //value: dispositivo,
                        onChanged: (value) {
                          setState(() => {
                                _device = value,
                                _dispositivo = value.name,
                                _direccion = value.address,
                                _tipo = value.type
                                
                            });
                            
                        },
                        //value: _selectedText,
                      ) 
                      : Center(
        child: Text(_dispositivo.toString(),
                style: TextStyle(fontSize: 18.0)
                  )
              ),
                    ),
                  ],
                ),
                SizedBox(height: 10,),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    RaisedButton(
                      color: Colors.brown,
                      onPressed:(){
                        initPlatformState();
                      },
                      child: Text('Actualizar', style: TextStyle(color: Colors.white),),
                    ),
                    SizedBox(width: 20,),
                    RaisedButton(
                      color: _connected ? Colors.red:Colors.green,
                      onPressed:
                      _connected ? _disconnect : _connect,
                      child: Text(_connected ? 'Desconectar' : 'Conectar', style: TextStyle(color: Colors.white),),
                    ),
                  ],
                ),
                Column(
                  children: <Widget>[
                    
                Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 35.0, 0.0, 0.0), 
                  child: ListTile(
                  title: Text(
                    "Imprimir Prueba",
                    style: whiteBoldText,
                  ),
                  trailing: Icon(
                    Icons.print,
                    color: Colors.grey.shade400,
                  ),
                  onTap: () { 
                    if(_connected ){
                      testPrint.sample(pathImage,userData != null ? userData['direccion'] : '');
                    } else {
                      show('Ningun dispositivo conectado');
                    }
                  },
                )),
                Divider(
                  color: Colors.black,
                  height: 5,
                ),
                  ],
                ),
              ]),
          ),
        ),
    );
  }


  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devices.isEmpty) {
       items.add(DropdownMenuItem(
        child: Text('Ningún dispositivo encontrado'),
      )); 
    } else {
      _devices.forEach((device) {
        //print(device.type);
        items.add(DropdownMenuItem(
          child: Text(device.name),
          value: device,
        ));
      });
    }
    return items;
  }


  void _connect() {
    if (_device == null) {
      show('Ningun dispositivo seleccionado');
    } else {
      
      bluetooth.isConnected.then((isConnected) {
       
        if (!isConnected) {
          
          bluetooth.connect(_device).catchError((error) {
            setState(() {
               _connected = false;
               });
          });
        } 
        _guardarImpresora();
        //print(_connected);
      });
    }
  }


  void _disconnect() {
    bluetooth.disconnect();
    setState(() => _connected = true);
  }

//write to app path
  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return new File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  Future show(
      String message, {
        Duration duration: const Duration(seconds: 3),
      }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    Scaffold.of(context).showSnackBar(
      new SnackBar(
        content: new Text(
          message,
          style: new TextStyle(
            color: Colors.white,
          ),
        ),
        duration: duration,
      ),
    );
  }
}