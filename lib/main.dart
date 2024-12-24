import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Water Reminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const NotificationPage(),
    );
  }
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final List<int> _timeOptions = [5, 10, 15, 20];
  final List<String> _unitOptions = ['Seconds', 'Minutes', 'Hours'];

  int _selectedTime = 5;
  String _selectedUnit = 'Seconds';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _requestNotificationPermission();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      final result = await Permission.notification.request();
      if (!result.isGranted) {
        _showSnackBar('Please enable notification permissions in settings.');
      }
    }
  }

  int _calculateDuration() {
    switch (_selectedUnit) {
      case 'Minutes':
        return _selectedTime * 60;
      case 'Hours':
        return _selectedTime * 3600;
      default:
        return _selectedTime;
    }
  }

  void _scheduleNotification() {
    _cancelNotification();

    if (_selectedTime <= 0 || _selectedUnit.isEmpty) {
      _showSnackBar('Please select a valid time and unit.');
      return;
    }

    final durationInSeconds = _calculateDuration();
    _showSnackBar(
        'Notification scheduled every $_selectedTime $_selectedUnit.');

    _timer = Timer.periodic(Duration(seconds: durationInSeconds), (timer) {
      _showNotification();
    });
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'water_notification_channel',
      'Water Reminder',
      channelDescription: 'Reminders to drink water.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Time to Hydrate!',
      'Drink a glass of water to stay healthy!',
      notificationDetails,
    );
  }

  void _cancelNotification() {
    if (_timer != null) {
      _timer!.cancel();
      _showSnackBar('Scheduled notifications canceled.');
    }
  }

  void _confirmCancelNotification() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Notifications'),
          content:
              const Text('Do you want to cancel all scheduled notifications?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelNotification();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Reminder'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Set a Reminder to Stay Hydrated!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Dropdown for selecting the time unit
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<String>(
                  value: _selectedUnit,
                  items: _unitOptions.map((unit) {
                    return DropdownMenuItem<String>(
                      value: unit,
                      child: Text(unit),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUnit = value!;
                    });
                  },
                ),
                const SizedBox(width: 20),

                // Dropdown for selecting the time value
                DropdownButton<int>(
                  value: _selectedTime,
                  items: _timeOptions.map((time) {
                    return DropdownMenuItem<int>(
                      value: time,
                      child: Text('$time'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTime = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Button to schedule the notification
            ElevatedButton(
              onPressed: _scheduleNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'Schedule Notifications',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),

            // Button to cancel the scheduled notifications
            OutlinedButton(
              onPressed: _confirmCancelNotification,
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'Cancel Notifications',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
