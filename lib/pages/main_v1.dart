/// PREVIOUS APP VERSION
/// 
/// NOW REDUNANT!


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';

/// App Entry Point
/// - Launches the Aquifer app
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized
  await initNotifications(); // Initialize local notifications
  tz.initializeTimeZones(); // Initialize timezone data
  runApp(const AquiferApp());
}

class AquiferApp extends StatelessWidget {
  const AquiferApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aquifer - Hydration reminder app',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ReminderHome(), // Home screen of the app
    );
  }
}

/// Methods and variables that create the notification popup

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// List to hold reminders
List<Reminder> reminders = [];

Future<void> initNotifications() async {
  /// Initializes the local notifications plugin
  /// This method sets up the Android initialization settings for the notifications.

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Request notification permissions for Android 13+
  if (flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >() !=
      null) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'water_channel',
            'Aquifer Water Reminder',
            importance: Importance.max,
          ),
        );
  }
}

class Reminder {
  int id;
  DateTime startTime;

  Reminder(this.id, this.startTime);

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
  };

  static Reminder fromJson(Map<String, dynamic> json) =>
      Reminder(json['id'], DateTime.parse(json['startTime']));
}

class ReminderHome extends StatefulWidget {
  const ReminderHome({super.key});

  @override
  ReminderHomeState createState() => ReminderHomeState();
}

/// State class for ReminderHome
/// This class manages the state of the reminder home screen,
/// including initializing notifications, scheduling reminders,
/// and handling user interactions such as adding, restarting, and deleting reminders.
/// It also manages the loading and saving of reminders using SharedPreferences.
///
/// It builds the UI for displaying reminders and allows users to interact with them.
class ReminderHomeState extends State<ReminderHome> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      // Delay initialization to ensure the widget is built
      await loadReminders();
    });
  }

  /// Methods that handle reminders

  Future<void> scheduleReminder(DateTime time, int id) async {
    /// Schedules a reminder notification
    /// Args:
    ///   - time: The time when the reminder should be triggered.
    ///   - id: The unique identifier for the reminder.
    /// Returns: void

    for (int i = 0; i < 4; i++) {
      final scheduledTZTime = tz.TZDateTime.now(tz.local)
          .add(Duration(seconds: 20 * i)) // Schedule every 20 seconds
          .add(Duration(milliseconds: 500)); // Add a small buffer
      // final tz.TZDateTime scheduledTZTime = tz.TZDateTime.from(
      //   scheduledTime,
      //   tz.local,
      // );
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id + i,
        'Drink Water',
        'Stay hydrated!',
        scheduledTZTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_channel',
            'Aquifer Water Reminder',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  void addReminder() async {
    /// Create a new reminder
    ///
    /// Args: None
    ///
    /// Returns: void

    DateTime now = DateTime.now(); // Current time
    int id = Random().nextInt((pow(2, 31) - 1).toInt()); // unique id
    Reminder reminder = Reminder(id, now);

    reminders.add(reminder);
    await scheduleReminder(now, id);
    await saveReminders();
    setState(() {});
  }

  void restartReminder(int index) async {
    DateTime newTime = DateTime.now();
    reminders[index].startTime = newTime;
    await scheduleReminder(newTime, reminders[index].id);
    await saveReminders();
    setState(() {});
  }

  void deleteReminder(int index) async {
    for (int i = 0; i < 4; i++) {
      flutterLocalNotificationsPlugin.cancel(reminders[index].id + i);
    }
    reminders.removeAt(index);
    await saveReminders();
    setState(() {});
  }

  Future<void> saveReminders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> jsonReminders = reminders
        .map((r) => jsonEncode(r.toJson()))
        .toList();
    await prefs.setStringList('reminders', jsonReminders);
  }

  Future<void> loadReminders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? jsonList = prefs.getStringList('reminders');
    reminders =
        jsonList?.map((r) => Reminder.fromJson(jsonDecode(r))).toList() ?? [];
    setState(() {});
  }

  /// Widget tree
  ///
  /// Comprises a base container widget in a scaffold
  /// The container holds decoration and child widgets.
  /// The child holds a Column of children and footer widgets
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.lightBlue[100],
          image: DecorationImage(
            image: const AssetImage("assets/images/water_bg_3.png"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.lightBlue.withValues(alpha: 0.3),
              BlendMode.dstATop,
            ),
          ),
        ),
        child: Column(
          children: [
            Center(child: Image.asset("assets/images/new_logo.png")),
            const SizedBox(height: 40), // Fix dimension issue
            const Text(
              // Also fix the text widget dimension/position issue
              'Aquifer - Hydration Reminder App',
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            ElevatedButton(
              onPressed: addReminder,
              child: const Text("Add Reminder"),
            ),
            const Align(alignment: Alignment.bottomCenter),

            // List of Reminders
            Expanded(
              child: SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          'Every 20 seconds from: ${DateFormat('hh:mm a').format(reminder.startTime)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.repeat),
                              onPressed: () => restartReminder(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => deleteReminder(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Add footer with credits here
            const Text(
              "Made with () by YMIT Students",
              style: TextStyle(
                fontSize: 15,
                color: Color.fromARGB(255, 207, 157, 5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
