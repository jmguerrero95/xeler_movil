import 'dart:convert';
import "package:blue_thermal_printer/blue_thermal_printer.dart";
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:xeler_impresora/impresora/convert_to_letters.dart';

class TestPrint {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  final formato = new NumberFormat("#,###");

  sample2(String pathImage,String direccion,String elId) async {
    var res = await http.get('https://impresora.xeler.io/api/obtenerFactura/'+elId);
    var body = json.decode(res.body);   
    
    bluetooth.isConnected.then((isConnected) {
      if (isConnected) {
        bluetooth.printImage(pathImage);   //path of your image/logo
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printCustom("Fecha: " +body['created_at'],1, 0);
        bluetooth.printCustom('Punto: '+ direccion,1,0);
        bluetooth.printCustom('No: XE-00000'+elId,2,0);
        bluetooth.printNewLine();
        bluetooth.printCustom(body['name'],2,1, charset: "iso-8859-1");
        bluetooth.printCustom('Valor: '+'\$ '+formato.format(int.parse(body['valor'])),2,1);
        bluetooth.printCustom('('+body['valor_letras']+' ' + body['currency']+')', 1, 1);
        bluetooth.printNewLine();
        bluetooth.printCustom('PRIMEROS 3 CARACTERES DE LA WALLET Y ULTIMOS 3   CARACTERES DE LA WALLET', 1, 1);
        bluetooth.printCustom('('+body['wallet_inicio']+') '+ '('+body['wallet_fin']+')', 2, 1);
        bluetooth.printNewLine();
        bluetooth.printCustom('Confirmo que los digitos o caracteres mencionados dentro de los parentesis mas arriba de este comprobante  coinciden con los iniciales y finales de mi monedero o wallet, y que soy el Beneficiario  final de la transaccion, a su vez entiendo que las transacciones en criptomonedas son irreversibles.', 1, 0, charset: "windows-1250");
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printCustom('Firma: _________________________________________', 1, 0);
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printCustom('Recibe: _______________________________________', 1, 0);
        bluetooth.printNewLine();
        bluetooth.printCustom(">>>   Gracias   <<<",2,1);
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printNewLine();
      }
    });
  }

  sample(String pathImage,String direccion) async {
    //SIZE
    // 0- normal size text
    // 1- only bold text
    // 2- bold with medium text
    // 3- bold with large text
    //ALIGN
    // 0- ESC_ALIGN_LEFT
    // 1- ESC_ALIGN_CENTER
    // 2- ESC_ALIGN_RIGHT
    

    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd H:mm:ss');
    final String timestamp = formatter.format(now);
    bluetooth.isConnected.then((isConnected) {
      print('impresora');
    print(isConnected);
      if (isConnected) {
        bluetooth.printImage(pathImage);
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printCustom("Fecha: " +timestamp,1, 0);
        bluetooth.printCustom('Punto: '+direccion,1,0);
        bluetooth.printCustom('No: 45345345',2,0);
        bluetooth.printNewLine();
        bluetooth.printCustom('Marcos Pinto nuevo 4',2,1);
        bluetooth.printCustom('Valor: '+'\$ 2.800.000',2,1);
        bluetooth.printCustom('('+NumberUtility.toWord('2800000', NumStrLanguage.English)+')', 1, 1);
        bluetooth.printNewLine();
        bluetooth.printCustom('PRIMEROS 3 CARACTERES DE LA WALLET Y ULTIMOS 3   CARACTERES DE LA WALLET', 1, 1);
        bluetooth.printCustom('(3ze) (254)', 2, 1);
        bluetooth.printNewLine();
        String testString = " čĆžŽšŠ-H-ščđ dígitos";
        bluetooth.printCustom(testString, 1, 1, charset: "windows-852");
        bluetooth.printCustom('Confirmo que los dígitos o caracteres mencionados dentro de los paréntesis más arriba de este comprobante  coinciden con los iniciales y finales de mi monedero o wallet, y que soy el Beneficiario  final de la transaccion, a su vez entiendo que las transacciones en criptomonedas son irreversibles.', 1, 0, charset: "windows-852");
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printCustom('Firma: _________________________________________', 1, 0);
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printCustom('Recibe: _______________________________________', 1, 0);
        bluetooth.printNewLine();
        bluetooth.printCustom(">>>   Gracias   <<<",2,1);
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printNewLine();
      }
    });
  }
}