import 'dart:convert';
import 'dart:io';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:xeler_impresora/paginas/testprint.dart';

class CrearFacturaPage extends StatefulWidget {
  int id;
  String name;
  CrearFacturaPage({Key key, @required this.id,@required this.name}) : super(key:key);

  @override
  _CrearFacturaState createState() => _CrearFacturaState(id,name);
}

class _CrearFacturaState extends State<CrearFacturaPage> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  int id;
  String name;
  bool _isLoading = false;
  var userData;
  String pathImage;
  String _mySelection = 'COP';
  bool _connected = false;
  final formato = new NumberFormat("#,###");
  var valor;
  var inicio;
  var fin;
  var creada;
  var elId;
  TestPrint testPrint;

  _CrearFacturaState(this.id,this.name);
  var controller = new MoneyMaskedTextController(precision: 0,decimalSeparator: '',thousandSeparator: '.');
  TextEditingController valorController = TextEditingController();
  TextEditingController primerosController = TextEditingController();
  TextEditingController ultimosController = TextEditingController();

 
  @override
  void initState() {
    super.initState();
    _getUserInfo();
    initSavetoPath();
    initPlatformState();
    testPrint= TestPrint();
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

  @override
  Widget build(BuildContext context){
    return Padding(
      padding: EdgeInsets.all(0),
      child: Material(
        child: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppBar(
                centerTitle: true,
                title: Text('Crear Factura'),
              ),
              /* Container(
  
  padding: EdgeInsets.only(left: 16, right: 16, top: 16),
     
  decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10)),

  // dropdown below..
  child: DropdownButton<String>(
      value: _mySelection,
      icon: Icon(Icons.arrow_drop_down),
      iconSize: 42,
      underline: SizedBox(),
      onChanged: (String newValue) {
        setState(() {
          _mySelection = newValue;
        });
      },
      items: <String>[
        'COP',
        'USD',
        'EUR'
      ].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList()),
      
), */
              Padding(
                padding: EdgeInsets.only(left: 16, right: 16, top: 16),
                child: Padding(
                padding: const EdgeInsets.all(0.0),
                child:Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
      DropdownButton<String>(
      underline: Container(
          height: 1.0,
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.transparent, width: 1.0))
          ),
        ),
  items: <String>['COP', 'USD', 'EUR'].map((String value) {
    return new DropdownMenuItem<String>(
      child: SizedBox(
      width: 70.0,
      child: Text(value, textAlign: TextAlign.center),
      
    ),
      value: value,
      
    );
  }).toList(),
  onChanged: (newVal) {
            setState(() {
              _mySelection = newVal;
            });
  },
  value: _mySelection,
),
      Flexible(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Valor',
                    hintText: 'Ingresa el valor',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                  // ignore: deprecated_member_use
                  WhitelistingTextInputFormatter.digitsOnly],
        ),
      ),
    ],
  ),
              ),
              ),
              /* Padding(
                padding: EdgeInsets.only(left: 16, right: 16, top: 16),
                child: TextFormField(
                  //controller: valorController,
                  controller: controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Valor',
                    hintText: 'Ingresa el valor',
                    icon: Icon(Icons.monetization_on),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                  WhitelistingTextInputFormatter.digitsOnly],
                ),
              ) ,*/
              Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: <Widget>[
    new Flexible(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: new TextField(
          maxLength: 4,
          controller: primerosController,
            decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '3 primeros digitos',
                hintText: 'Ingresa los 3 primeros digitos del wallet',
                icon: Icon(Icons.monetization_on),
                isDense: true,
                contentPadding: EdgeInsets.all(10)
            )
        ),
      ),
    ),
    new Flexible(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: new TextField(
          maxLength: 4,
          controller: ultimosController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: '3 ultimos digitos',
                hintText: 'Ingresa los 3 ultimos digitos del wallet',
                icon: Icon(Icons.monetization_on),
                isDense: true,
                contentPadding: EdgeInsets.all(10)
            )
        ),
      ),
    ),
  ],
),
              Padding(
                padding: EdgeInsets.only(left: 16, right: 16, top: 16),
                //padding: EdgeInsets.symmetric(vertical: 16.0),
                child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: double.infinity),
                    child: RaisedButton(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  onPressed: _isLoading ? null : _crearFactura,
                                  padding: EdgeInsets.all(22),
                                  color: Color.fromARGB(255,118, 104, 254),
                                  child: _isLoading ? Center( child:CircularProgressIndicator()) : 
                                  Text(_isLoading ? 'Creando...' : 'Crear', 
                                  style: TextStyle(color: Colors.white)),
                                ),
                )
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showNewVersionAvailableDialog(msg) {
  final alert = AlertDialog(
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

  void _crearFactura() async{
    /* if(!_connected){
      _showNewVersionAvailableDialog('Impresora no conectada');
      return;
    } */
    setState(() {
       _isLoading = true;
    });

    var data = {
       // 'valor' : valorController.text,
        'valor' : controller.text,
        'wallet_inicio': primerosController.text,
        'wallet_fin': ultimosController.text,
        'cliente_id': id,
        'currency': _mySelection
    };

    

    var res = await CallApi().postData(data, 'crearFactura');
    var body = json.decode(res.body);
    //print(body);
    if(res.statusCode == 200){
      
      elId = body['factura_id'].toString();
      //print(body['valor_letras']);
      
      testPrint.sample2(pathImage, userData['direccion'],elId);
      setState(() {
        _isLoading = false;
        
      });
      controller.clear();
      valorController.clear();
      primerosController.clear();
      ultimosController.clear();
      /* Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => DetallesCliente(id: body['id'],name: body['name'],))); */
    }else{
      //_showMsg(body['message']);
    }



  


  }

  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return new File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

}

