import 'dart:convert';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:xeler_impresora/impresora/convert_to_letters.dart';

class TestPrint {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  final NumberFormat formato = NumberFormat('#,###');

  Future<void> sample2(String pathImage, String direccion, String elId) async {
    final res = await http.get(
      Uri.parse('https://impresora.xeler.io/api/obtenerFactura/$elId'),
    );
    if (res.statusCode != 200) {
      return;
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;

    final isConnected = await bluetooth.isConnected;
    if (isConnected == true) {
      try {
        await bluetooth.printImage(pathImage);
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
        await bluetooth.printCustom('Fecha: ${body['created_at']}', 1, 0);
        await bluetooth.printCustom('Punto: $direccion', 1, 0);
        await bluetooth.printCustom('No: XE-00000$elId', 2, 0);
        await bluetooth.printNewLine();
        await bluetooth.printCustom(
          body['name'].toString(),
          2,
          1,
          charset: 'iso-8859-1',
        );
        final valor = int.tryParse(body['valor']?.toString() ?? '0') ?? 0;
        final currency = body['currency']?.toString() ?? 'COP';
        final valorLetras = body['valor_letras']?.toString() ?? '';
        await bluetooth.printCustom('Valor: $currency ${formato.format(valor)}', 2, 1);
        await bluetooth.printCustom(
          '($valorLetras $currency)',
          1,
          1,
        );
        await bluetooth.printNewLine();
        await bluetooth.printCustom(
          'PRIMEROS 3 CARACTERES DE LA WALLET Y ULTIMOS 3   CARACTERES DE LA WALLET',
          1,
          1,
        );
        await bluetooth.printCustom('(${body['wallet_inicio']}) (${body['wallet_fin']})', 2, 1);
        await bluetooth.printNewLine();
        await bluetooth.printCustom(
          'Confirmo que los digitos o caracteres mencionados dentro de los parentesis mas arriba de este comprobante  coinciden con los iniciales y finales de mi monedero o wallet, y que soy el Beneficiario  final de la transaccion, a su vez entiendo que las transacciones en criptomonedas son irreversibles.',
          1,
          0,
          charset: 'windows-1250',
        );
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
        await bluetooth.printCustom('Firma: _________________________________________', 1, 0);
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
        await bluetooth.printCustom('Recibe: _______________________________________', 1, 0);
        await bluetooth.printNewLine();
        await bluetooth.printCustom('>>>   Gracias   <<<', 2, 1);
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
      } catch (error, stackTrace) {
        debugPrint('Error al imprimir factura: $error');
        debugPrint('$stackTrace');
      }
    }
  }

  Future<void> sample(String pathImage, String direccion) async {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd H:mm:ss');
    final String timestamp = formatter.format(now);
    final isConnected = await bluetooth.isConnected;
    if (isConnected == true) {
      try {
        await bluetooth.printImage(pathImage);
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
        await bluetooth.printCustom('Fecha: $timestamp', 1, 0);
        await bluetooth.printCustom('Punto: $direccion', 1, 0);
        await bluetooth.printCustom('No: 45345345', 2, 0);
        await bluetooth.printNewLine();
        await bluetooth.printCustom('Marcos Pinto nuevo 4', 2, 1);
        await bluetooth.printCustom('Valor: COP 2.800.000', 2, 1);
        await bluetooth.printCustom(
          "(${NumberUtility.toWord('2800000', NumStrLanguage.English)})",
          1,
          1,
        );
        await bluetooth.printNewLine();
        await bluetooth.printCustom(
          'PRIMEROS 3 CARACTERES DE LA WALLET Y ULTIMOS 3   CARACTERES DE LA WALLET',
          1,
          1,
        );
        await bluetooth.printCustom('(3ze) (254)', 2, 1);
        await bluetooth.printNewLine();
        const testString = ' čĆžŽšŠ-H-ščđ dígitos';
        await bluetooth.printCustom(testString, 1, 1, charset: 'windows-852');
        await bluetooth.printCustom(
          'Confirmo que los dígitos o caracteres mencionados dentro de los paréntesis más arriba de este comprobante  coinciden con los iniciales y finales de mi monedero o wallet, y que soy el Beneficiario  final de la transaccion, a su vez entiendo que las transacciones en criptomonedas son irreversibles.',
          1,
          0,
          charset: 'windows-852',
        );
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
        await bluetooth.printCustom('Firma: _________________________________________', 1, 0);
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
        await bluetooth.printCustom('Recibe: _______________________________________', 1, 0);
        await bluetooth.printNewLine();
        await bluetooth.printCustom('>>>   Gracias   <<<', 2, 1);
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
      } catch (error, stackTrace) {
        debugPrint('Error al imprimir prueba: $error');
        debugPrint('$stackTrace');
      }
    }
  }
}
