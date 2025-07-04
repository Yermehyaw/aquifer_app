import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// App entry point
void main() {
  runApp(AquiferApp());
}

class AquiferApp extends StatelessWidget {
  const AquiferApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          AquiferAppState(), // Provide the app state to the widget tree
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Aquifer - Hydration reminder app',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const ReminderHome(), // Home screen of the app
      ),
    );
  }
}

/// App state class to manage reminder and notifications
class AquiferAppState extends ChangeNotifier {
  // Holds methods and variables which other widgets must check for state
  var current = 'on'; // Current state of reminders
  var drinkInterval = 1; // Default drink interval

  void toggleReminder() {
    /// Switches notifs on/off
    ///
    /// Args: None
    ///
    /// Returns: void
    print('Toggling reminders');
    print('Reminders are turned $current');
    notifyListeners(); // Notify listeners about the change
  }

  void confirmDrink() {
    /// Confirms the user is hydrated and restarts the drinking schedule
    ///
    /// args: None
    ///
    /// Returns: Void
    print(
      'You are now Hydrated! Dont stop, Next drink in {appState.drinkInterval}',
    );
  }
}

/// App Homepage class
class ReminderHome extends StatelessWidget {
  const ReminderHome({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AquiferAppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Aquifer - Hydration Reminder')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('Welcome to Aquifer!'),

          ElevatedButton(
            onPressed: () =>
                appState.toggleReminder(), // Logic to switch on reminders
            child: Row(
              children: [const Icon(Icons.repeat), const Text('Reminders')],
            ),
          ),

          ElevatedButton(
            onPressed: () => appState
                .confirmDrink(), // Logic for user to confirm they are hydrated and restarts reminder
            child: const Text('Confirm Water Intake'),
          ),
        ],
      ),
    );
  }
}
