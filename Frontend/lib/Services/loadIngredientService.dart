import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';

Future<bool> temp() async{
  final dio = Dio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String fridgeURL = (ip!.startsWith('10.0.2')) ?
  'http://10.0.2.2:8000/api/fridge/1(n)' :
  'http://192.168.119.150:8000/api/fridge/1(n)';



  return true;
}