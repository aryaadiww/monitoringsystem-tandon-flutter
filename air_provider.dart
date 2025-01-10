// lib/airProvider.dart
import 'package:flutter/material.dart';

class AirProvider with ChangeNotifier {
  double _ketinggianAir = 0.0;
  double _kekeruhanAir = 0.0;

  double get ketinggianAir => _ketinggianAir;
  double get kekeruhanAir => _kekeruhanAir;

  void updateAirData(double ketinggian, double kekeruhan) {
    _ketinggianAir = ketinggian;
    _kekeruhanAir = kekeruhan;
    notifyListeners();
  }
}