import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static Future<void> initializeNotification() async {
    await AwesomeNotifications().initialize(
      'resource://drawable/logo',
      [
        NotificationChannel(
          channelKey: 'water_alerts',
          channelName: 'Water Alerts',
          channelDescription: 'Notifikasi untuk kondisi air',
          defaultColor: Colors.blue,
          ledColor: Colors.blue,
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
        )
      ],
    );

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  static Future<void> showWaterQualityNotification({
    required String title,
    required String body,
    required String notifKey,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'water_alerts',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        payload: {'notif_key': notifKey},
      ),
    );
  }

  static Future<void> checkWaterConditions(double kekeruhan, double ketinggian, String kodeAlat) async {
    final prefs = await SharedPreferences.getInstance();
    
    final ketinggianRendahKey = 'ketinggian_rendah_status_$kodeAlat';
    final ketinggianTinggiKey = 'ketinggian_tinggi_status_$kodeAlat';
    final kekeruhanKey = 'kekeruhan_status_$kodeAlat';

    if (ketinggian <= 6.0) {
      print('Memicu notifikasi air rendah: $ketinggian cm untuk kode alat $kodeAlat');
      final lastStatus = prefs.getString(ketinggianRendahKey);
      if (lastStatus == null) {
        await showWaterQualityNotification(
          title: 'Peringatan Air Rendah!',
          body: 'Ketinggian air: ${ketinggian.toStringAsFixed(1)} cm. Air terlalu rendah!',
          notifKey: ketinggianRendahKey,
        );
        await prefs.setString(ketinggianRendahKey, 'triggered');
      }
    } else if (ketinggian >= 12.0) {
      print('Memicu notifikasi air tinggi: $ketinggian cm untuk kode alat $kodeAlat');
      final lastStatus = prefs.getString(ketinggianTinggiKey);
      if (lastStatus == null) {
        await showWaterQualityNotification(
          title: 'Peringatan Air Tinggi!',
          body: 'Ketinggian air: ${ketinggian.toStringAsFixed(1)} cm. Air terlalu tinggi!',
          notifKey: ketinggianTinggiKey,
        );
        await prefs.setString(ketinggianTinggiKey, 'triggered');
      }
    } else {
      print('Ketinggian normal: $ketinggian cm untuk kode alat $kodeAlat');
      await prefs.remove(ketinggianRendahKey);
      await prefs.remove(ketinggianTinggiKey);
    }

    if (kekeruhan <= 200) {
      print('Memicu notifikasi air keruh: $kekeruhan NTU untuk kode alat $kodeAlat');
      final lastStatus = prefs.getString(kekeruhanKey);
      if (lastStatus == null) {
        await showWaterQualityNotification(
          title: 'Peringatan Air Keruh!',
          body: 'Nilai kekeruhan air: ${kekeruhan.toStringAsFixed(1)} NTU. Air terlalu keruh!',
          notifKey: kekeruhanKey,
        );
        await prefs.setString(kekeruhanKey, 'triggered');
      }
    } else {
      print('Kekeruhan normal: $kekeruhan NTU untuk kode alat $kodeAlat');
      await prefs.remove(kekeruhanKey);
    }
  }
}
