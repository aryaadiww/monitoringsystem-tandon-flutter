import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'riwayatLaporan.dart';

class LaporanKerusakan extends StatefulWidget {
  @override
  _LaporanKerusakanState createState() => _LaporanKerusakanState();
}

class _LaporanKerusakanState extends State<LaporanKerusakan> {
  final _formKey = GlobalKey<FormState>();
  DateTime selectedDate = DateTime.now();
  String selectedKerusakan = 'Sensor Kekeruhan';
  String deskripsi = '';
  String kodeAlat = '';
  String iP = "192.168.8.214";
  
  // List opsi kerusakan
  final List<String> jenisKerusakan = [
    'Sensor Kekeruhan',
    'Sensor Ketinggian',
    'Putus Kabel',
    '',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    _loadKodeAlat();
  }

  Future<void> _loadKodeAlat() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      kodeAlat = prefs.getString('kode_alat') ?? '';
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _submitLaporan() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('http://$iP/toserba/android/laporankerusakan.php'),
          body: {
            'kode_alat': kodeAlat,
            'tanggal': DateFormat('yyyy-MM-dd').format(selectedDate),
            'jenis_kerusakan': selectedKerusakan,
            'deskripsi': deskripsi,
          },
        );

        final data = json.decode(response.body);
        if (data['success']) {
          _showDialog('Berhasil', 'Laporan berhasil dikirim', () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => RiwayatLaporan()),
            );
          });
        } else {
          _showDialog('Gagal', 'Gagal mengirim laporan: ${data['message']}');
        }
      } catch (e) {
        _showDialog('Kesalahan', 'Terjadi kesalahan: $e');
      }
    }
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
        title: Text('Laporan Kerusakan',
        style: TextStyle(
          color: Colors.white
        ),),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tanggal
              Text('Tanggal:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd MMMM yyyy').format(selectedDate)),
                      Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Jenis Kerusakan
              Text('Jenis Kerusakan:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: selectedKerusakan,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
                items: jenisKerusakan.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedKerusakan = newValue!;
                  });
                },
              ),
              SizedBox(height: 20),

              // Deskripsi
              Text('Deskripsi:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextFormField(
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan deskripsi kerusakan...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mohon isi deskripsi kerusakan';
                  }
                  return null;
                },
                onChanged: (value) {
                  deskripsi = value;
                },
              ),
              SizedBox(height: 30),

              // Tombol Submit
              Center(
                child: ElevatedButton(
                  onPressed: _submitLaporan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: Text(
                    'Kirim Laporan',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
