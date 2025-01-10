import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class KekeruhanAirScreen extends StatefulWidget {
  @override
  _KekeruhanAirScreenState createState() => _KekeruhanAirScreenState();
}

class _KekeruhanAirScreenState extends State<KekeruhanAirScreen> {
  double kekeruhan = 0.0;
  String keterangan = '';
  final double maxKekeruhan = 600.0; // Batas maksimum kekeruhan
  int currentIndex = 1;
  String kodeAlat = '';
  Timer? _timer;
  String iP = "192.168.8.214";

  @override
  void initState() {
    super.initState();
    _loadKodeAlat();
    _startRealtimeUpdates();
  }

  void _startRealtimeUpdates() {
    // Update setiap 1 detik
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _fetchKekeruhanData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadKodeAlat() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      kodeAlat = prefs.getString('kode_alat') ?? '';
    });
    _fetchKekeruhanData();
  }

  Future<void> _fetchKekeruhanData() async {
    try {
      print('Kode alat: $kodeAlat');
      
      if (kodeAlat.isEmpty) {
        throw Exception('Kode alat tidak tersedia');
      }

      final response = await http.get(
        Uri.parse("http://$iP/toserba/android/bacakekeruhan.php?kode_alat=$kodeAlat")
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            kekeruhan = data['data']['kekeruhan'] != null ? 
                double.parse(data['data']['kekeruhan'].toString()) : 0.0;
            keterangan = _getKeterangan(kekeruhan);
          });
        } else {
          throw Exception(data['message'] ?? 'Data tidak berhasil dimuat');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        kekeruhan = 0.0;
        keterangan = 'Error';
      });
    }
  }

  String _getKeterangan(double value) {
    if (value <= 200) {
      return 'Keruh';
    } else if (value <= 300) {
      return 'Agak Keruh';
    } else {
      return 'Bersih';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Keruh':
        return Color(0xFF795C32);
      case 'Agak Keruh':
        return Colors.yellow;
      case 'Bersih':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kekeruhan Air',
          style: TextStyle(
            color: Colors.white, // Ganti dengan warna yang diinginkan
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Menampilkan nilai kekeruhan dalam bentuk circular progress
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: kekeruhan / maxKekeruhan,
                    strokeWidth: 50,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(keterangan)),
                  ),
                ),
                // Container untuk menampilkan nilai kekeruhan di tengah
                Container(
                  width: 120,
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${kekeruhan.toStringAsFixed(1)} NTU',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 80),
            // Indikator status kekeruhan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusIndicator('Keruh', Color(0xFF795C32), keterangan == 'Keruh'),
                _buildStatusIndicator('Agak Keruh', Colors.yellow, keterangan == 'Agak Keruh'),
                _buildStatusIndicator('Bersih', Colors.cyan, keterangan == 'Bersih'),
              ],
            ),
          ],
        ),
      ),
      // Bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setelan'),
        ],
        currentIndex: 0,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/dashboard');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/setting');
          }
        },
      ),
    );
  }

  // Widget untuk menampilkan indikator status
  Widget _buildStatusIndicator(String label, Color color, bool isActive) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color : Colors.grey[300],
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 18.0),
        ),
      ],
    );
  }
}
