import 'dart:async';

// local packages
import 'package:aquifer_app/widgets/water_animation.dart' show BigCard;
import 'package:aquifer_app/pages/about_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show Brightness, FontWeight, SystemChrome, SystemUiOverlayStyle;

// Pub.dev packages
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();
  runApp(const AquiferApp());

  // Required to draw water animation. Also pulled from the Flutter_Water_Animation repo
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
}

/// Root App Widget
class AquiferApp extends StatelessWidget {
  const AquiferApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Provider package will be utilized for state management
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

/// Methods and variables for handling notifs
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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

/// App state class to manage reminder and notifications
class AquiferAppState extends ChangeNotifier {
  // Holds methods and variables which other widgets must check for state
  var current = 'on'; // Current state of reminders
  var drinkInterval = 1; // Default drink interval in hours
  double _waterLevel = 100.0; // Current water level (0-100%)
  Timer?
  _dehydrationTimer; // Countdown till next drink i.e 1 hour NOTE: The value is variable to debug changes
  bool _isDehydrated = false; // Current hydration state
  DateTime?
  _lastUpdateTime; // Track when water level was last updated to ensure app closes dont affct the correct hydration value
  bool _hasNotifiedForCurrentDehydration =
      false; // Track if we've already notified for current dehydration inorder to ensure reminder isnt sent twice for one _waterLevel drop or _isDehydrated true

  /// Define getter methods/vraibles for waterLevel and isDehydrated
  /// This aligns with best coding practices to ensure data encapsulation
  /// Plus It allows usgae of _isDehydrated for several purposes without additional logic
  double get waterLevel => _waterLevel;
  bool get isDehydrated => _isDehydrated;
  String get hydrationStatus => _isDehydrated ? 'Dehydrated' : 'Hydrated';

  // Load previous app state, if app is closed/restarted
  AquiferAppState() {
    _loadState();
  }

  // Load saved state from SharedPreferences
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load basic settings/user preferences
      current = prefs.getString('reminder_status') ?? 'on';
      drinkInterval = prefs.getInt('drink_interval') ?? 1;

      // Load water level and last update time
      _waterLevel = prefs.getDouble('water_level') ?? 100.0;
      final lastUpdateTimeString = prefs.getString('last_update_time');

      if (lastUpdateTimeString != null) {
        _lastUpdateTime = DateTime.parse(lastUpdateTimeString);

        // Calculate how much time has passed since last update
        final now = DateTime.now();
        final timeDifference = now.difference(_lastUpdateTime!);

        // Calculate water level decrease based on time passed
        if (timeDifference.inMinutes > 0 && current == 'on') {
          final decreaseRate = 100.0 / (drinkInterval * 60); // Per minute
          final totalDecrease = decreaseRate * timeDifference.inMinutes;
          _waterLevel = (_waterLevel - totalDecrease).clamp(0.0, 100.0);
        }
      }

      // Update dehydration status
      _isDehydrated = _waterLevel <= 0;
      _hasNotifiedForCurrentDehydration =
          prefs.getBool('has_notified') ?? false;

      // Start dehydration count-down
      _startDehydrationTimer();

      // Start timer if reminders are on
      if (current == 'on') {
        _startDehydrationTimer();
      }

      notifyListeners();
    } catch (e) {
      print('Error loading state: $e');
      _startDehydrationTimer();
    }
  }

  // Save current state to SharedPreferences
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reminder_status', current);
      await prefs.setInt('drink_interval', drinkInterval);
      await prefs.setDouble('water_level', _waterLevel);
      await prefs.setString(
        'last_update_time',
        DateTime.now().toIso8601String(),
      );
      await prefs.setBool('has_notified', _hasNotifiedForCurrentDehydration);
    } catch (e) {
      print('Error saving state: $e');
    }
  }

  void _startDehydrationTimer() {
    _dehydrationTimer?.cancel();
    _dehydrationTimer = Timer.periodic(
      const Duration(minutes: 1), // Check every minute for smooth animation
      (timer) {
        _decreaseWaterLevel();
      }, // *** POSSIBLY BUGGY ***
    );
  }

  void _decreaseWaterLevel() {
    // Prevent division by zero
    if (drinkInterval <= 0) return;

    // Store previous water level to check for zero crossing
    double previousWaterLevel = _waterLevel;

    // Decrease water level gradually over the drink interval
    double decreaseRate = 100.0 / (drinkInterval * 60); // Per minute
    _waterLevel = (_waterLevel - decreaseRate).clamp(0.0, 100.0);

    // Check if water level just reached zero (crossed from above 0 to 0)
    if (previousWaterLevel > 0 &&
        _waterLevel <= 0 &&
        !_hasNotifiedForCurrentDehydration) {
      _isDehydrated = true;
      _hasNotifiedForCurrentDehydration = true;
      _showDehydrationNotification();
      _saveState(); // Save state when dehydration occurs
    }

    // Save state periodically
    _saveState();
    notifyListeners();
  }

  void _showDehydrationNotification() async {
    try {
      await flutterLocalNotificationsPlugin.show(
        0,
        'Time to Drink Water!',
        'You\'re dehydrated! Please drink some water.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_channel',
            'Aquifer Water Reminder',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      print('Failed to show notification: $e');
    }
  }

  void toggleReminder() {
    /// Switches notifs on/off
    current = current == 'on' ? 'off' : 'on';

    if (current == 'on') {
      _startDehydrationTimer();
    } else {
      _dehydrationTimer?.cancel();
    }

    print('Reminders are turned $current');
    _saveState(); // Save state when reminder setting changes
    notifyListeners();
  }

  void confirmDrink() {
    /// Confirms the user is hydrated and restarts the drinking schedule
    _waterLevel = 100.0;
    _isDehydrated = false;
    _hasNotifiedForCurrentDehydration = false; // Reset notification flag
    _lastUpdateTime = DateTime.now(); // Reset the last update time
    _startDehydrationTimer();

    print(
      'You are now Hydrated! Next drink in ${drinkInterval.toString()} hour',
    );
    _saveState(); // Save state when drink is confirmed
    notifyListeners();
  }

  void setDrinkInterval(int hours) {
    drinkInterval = hours;
    _startDehydrationTimer(); // Restart timer with new interval
    _saveState(); // Save state when interval changes
    notifyListeners();
  }

  // Handle app lifecycle changes
  void onAppPaused() {
    _saveState(); // Save state when app is paused
  }

  void onAppResumed() {
    _loadState(); // Reload state when app is resumed
  }

  @override
  void dispose() {
    _dehydrationTimer?.cancel();
    super.dispose();
  }
}

/// App Homepage class
class ReminderHome extends StatefulWidget {
  const ReminderHome({super.key});

  @override
  State<ReminderHome> createState() => _ReminderHomeState();
}

class _ReminderHomeState extends State<ReminderHome> {
  var selectedIndex = 0; // Index of the selected half of page

  @override
  Widget build(BuildContext context) {
    Widget page; // Widget to hold the current page content
    switch (selectedIndex) {
      case 0:
        page = const ReminderHomePage(); // First half of the page
        break;
      case 1:
        page = const AboutPage(); // Second half of the page
        break;
      default:
        page = const ReminderHomePage(); // Default to first half
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          appBar: AppBar(title: const Text('Aquifer - Hydration Reminder')),
          body: Row(
            children: [
              SafeArea(
                // Holds a sidebar/navigation rail and ensures the navigation rail is within safe area
                child: NavigationRail(
                  // Navigation rail widget for navigation between hompge and about page
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      selectedIndex = index; // Update the selected index
                    });
                  },
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.water_drop),
                      label: Text('Reminders'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.info),
                      label: Text('About'),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.lightBlue[100],
                    image: DecorationImage(
                      image: const AssetImage("assets/images/water_bg_3.png"),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.lightBlue.withOpacity(0.3),
                        BlendMode.dstATop,
                      ),
                    ),
                  ),
                  child:
                      page, // Page content changes according to the page selected in the navigation rail/side bar i.e from Reminderpage to AboutPage and viceversa
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReminderHomePage extends StatelessWidget {
  const ReminderHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Call all the needed appState variables at once to reduce redundancies in method calls and state management
    var appState = context.watch<AquiferAppState>();
    var hydrationState = appState.hydrationStatus;
    var waterLevel = appState.waterLevel;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Welcome to Aquifer!',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 50.0,
              wordSpacing: 3,
            ),
          ),
          const Text(
            'Your Personal Hydration Reminder App',
            style: TextStyle(fontSize: 25),
          ),
          BigCard(pair: hydrationState, waterLevel: waterLevel),
          const SizedBox(height: 10),
          Text(
            'Hydration Level: ${waterLevel.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () => appState.toggleReminder(),
                icon: const Icon(Icons.notifications_active),
                label: Text('Reminders ${appState.current}'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => appState.confirmDrink(),
            child: const Text('Confirm Water Intake'),
          ),
        ],
      ),
    );
  }
}
