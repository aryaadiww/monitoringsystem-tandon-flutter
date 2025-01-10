import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RiwayatLaporan extends StatefulWidget {
  @override
  _RiwayatLaporanState createState() => _RiwayatLaporanState();
}

class _RiwayatLaporanState extends State<RiwayatLaporan> {
  List<Map<String, dynamic>> laporanList = [];
  String kodeAlat = '';
  String iP = '192.168.8.214';


  @override
  void initState() {
    super.initState();
    _loadLaporan();
  }

  Future<void> _loadLaporan() async {
    final prefs = await SharedPreferences.getInstance();
    kodeAlat = prefs.getString('kode_alat') ?? '';

    final response = await http.post(
      Uri.parse('http://$iP/toserba/android/dataLaporanRusak.php'), // Ganti dengan IP Anda
      body: {
        'kode_alat': kodeAlat,
      },
    );

    final data = json.decode(response.body);
    if (data['success']) {
      setState(() {
        laporanList = List<Map<String, dynamic>>.from(data['data']);
      });
    } else {
      print(data['message']);
    }
  }

  Future<void> _deleteLaporan(String id) async {
    final response = await http.post(
      Uri.parse('http://$iP/toserba/android/deleteLaporan.php'), // Ganti dengan IP Anda
      body: {
        'id': id,
      },
    );

    final data = json.decode(response.body);
    if (data['success']) {
      _showDialog('Berhasil', 'Laporan berhasil dihapus', () {
        _loadLaporan(); // Refresh daftar laporan setelah penghapusan
      });
    } else {
      _showDialog('Gagal', 'Gagal menghapus laporan: ${data['message']}');
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus laporan ini?'),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Hapus'),
              onPressed: () {
                _deleteLaporan(id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDialog(String title, String message, [VoidCallback? onConfirm]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                if (onConfirm != null) {
                  onConfirm();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Laporan',
        style: TextStyle(
          color: Colors.white
        ),),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        itemCount: laporanList.length,
        itemBuilder: (context, index) {
          final laporan = laporanList[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(laporan['jenis_kerusakan']),
              subtitle: Text('${laporan['tanggal']} - ${laporan['deskripsi']}'),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDelete(laporan['id_laporan'].toString()), // Ganti dengan ID yang sesuai
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setelan'),
        ],
        currentIndex: 0, // Tidak ada yang aktif
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
}
