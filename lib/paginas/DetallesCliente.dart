import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/model/Facturas.dart';
import 'package:xeler_impresora/paginas/CrearFactura.dart';
import 'package:xeler_impresora/paginas/testprint.dart';

class DetallesCliente extends StatefulWidget {
  final int id;
  final String name;
  DetallesCliente({Key key, @required this.id,@required this.name}) : super(key:key);

  @override
  _DetallesClienteState createState() => _DetallesClienteState(id,name);
}
class _DetallesClienteState extends State<DetallesCliente> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
int id;
String name;
_DetallesClienteState(this.id,this.name);
String pathImage;
bool _connected = false;
TestPrint testPrint;
var userData;
final noSimbolInUSFormat = new NumberFormat.currency(locale: "es_CO",
      symbol: "\$");
final formato = new NumberFormat("#,###");

List<Facturas> _ultimos = List<Facturas>();

  Future<List<Facturas>> fetchNotes() async {
    
    //await Future.delayed(Duration(seconds: 2));
    var response = await CallApi().getData('obtenerFacturasCliente/'+id.toString());
    
    var notes = List<Facturas>();
    print(json.decode(response.body));
    if (response.statusCode == 200) {
      var notesJson = json.decode(response.body);
      for (var noteJson in notesJson) {
        notes.add(Facturas.fromJson(noteJson));
      }
    }
    return notes;
  }

  @override
  void initState() {
    initSavetoPath();
    initPlatformState();
    _getUserInfo();
    testPrint= TestPrint();
    fetchNotes().then((value) {
      setState(() {
        _ultimos.addAll(value);
      });
    });
    super.initState();
  }

  void _getUserInfo() async {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var userJson = localStorage.getString('user'); 
      var user = json.decode(userJson);
      //print(user);
      setState(() {
        userData = user;
      _connected = localStorage.getBool("connected");
      });

  }

  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return new File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  Future<void> initPlatformState() async {
    //String platformVersion;
    bool isConnected=await bluetooth.isConnected;
    //List<BluetoothDevice> devices = [];
    /* try {
      //devices = await bluetooth.getBondedDevices();
    } on PlatformException {
      //platformVersion = 'Error recuperando version.';
    } */

    bluetooth.onStateChanged().listen((state) {
      
      switch (state) {
        
        case BlueThermalPrinter.CONNECTED:
          setState(() {
            _connected = true;
          });
          break;
        
        case BlueThermalPrinter.DISCONNECTED:
          setState(() {
            _connected = false;
          });
          break;
        default:
          print(state);
          break;
      }
    });

    if (!mounted) return;
    /* setState(() {
      _devices = devices;
      //_platformVersion = platformVersion;
    }); */

    if(isConnected) {
      setState(() {
        _connected=true;
      });
    }
  }

  initSavetoPath()async{
    
    final filename = '192xeler.png';
    var bytes = await rootBundle.load("assets/images/192xeler.png");
    String dir = (await getApplicationDocumentsDirectory()).path;
    writeToFile(bytes,'$dir/$filename');
    setState(() {
      pathImage='$dir/$filename';
    });
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
        child:Padding(
            padding: const EdgeInsets.only(top: 0.0, left: 0.0, right: 0.0),
          child: Column(
            children: <Widget>[
              ProfileHeader(
                title: name,
                //subtitle: "Cliente",
                actions: <Widget>[
                  MaterialButton(
                    color: Colors.deepPurpleAccent,
                    shape: CircleBorder(),
                    elevation: 0,
                    child: Icon(Icons.add,color: Colors.white,),
                    onPressed: () {
                      Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => CrearFacturaPage(id:id,name:name)));
                    },
                  )
                ],
              ),
              const SizedBox(height: 10.0),
              Container(
              width: double.infinity,
              height: 690,
              margin: EdgeInsets.only(top: 15),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 0.0, left: 20),
                        child: Text(
                          'Ultimas 5 Facturas',
                          style: TextStyle(fontSize: 18.0),
                        ),
                      )
                    ],
                  ),
      Expanded(
        
          child: _ultimos.isNotEmpty ?
          ListView.builder(
        itemBuilder: (context, index) {
          return Card(
          elevation: 8.0,
          //margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(color: Color.fromARGB(255, 36, 38, 80)),
            child: ListTile(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          title: Text('Valor: '+formato.format(int.parse(_ultimos[index].valor))+' COP'
            
            ,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Row(
            children: <Widget>[
              Expanded(
                flex: 4,
                child: Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Text('Wallet destino: '+_ultimos[index].primeros+' / ' +_ultimos[index].ultimos,
                        style: TextStyle(color: Colors.white))),
              )
            ],
          ),
          onTap: () {
            testPrint.sample2(pathImage, userData['direccion'],_ultimos[index].id.toString());
          },
          
        )
          ),
          );
        },
        itemCount: _ultimos.length)
        : Text("El cliente "+name+" no tiene facturas",
                style: TextStyle(fontSize: 18.0)
                  )
      )
       
      ],
  )
          )]),
        )
      ));
  }
}


class ProfileHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;

  const ProfileHeader(
      {Key key,
      @required this.title,
      this.subtitle,
      this.actions})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Ink(
          height: 80,
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 36, 38, 80),
          ),
        ),
        if (actions != null)
          Container(
            width: double.infinity,
            height: 60,
            padding: const EdgeInsets.only(bottom: 0.0, right: 0.0),
            alignment: Alignment.bottomRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: actions,
            ),
          ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 30),
          child: Column(
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              ),
            ],
          ),
        )
      ],
    );
  }
  
}