import 'package:flutter/material.dart';


/// Final page... Wheeew!
/// AboutPage gives user info on how to use the app and its creators
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Aquifer')),
      body: Container(
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Aquifer - Hydration Reminder App',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  'This app helps you stay hydrated by reminding you to drink water every hour inorder to stay hydrated. \n You can also watch your hydration level via the water animation!',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Created with ❤️ by YMIT students. \n P.S: The Aquifer Team',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}