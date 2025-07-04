import 'dart:async';

import 'package:flutter/material.dart';


/// BigCard Widget to hold the current hydration profile of the user
///
/// NOTE OF DISCLOSURE: This code/animation was pulled and edits were made to it using co-pilot. Source: https://github.com/bilalidress/Flutter_Water_Animation/ No registered copyright License as at 04/07/2025
class BigCard extends StatefulWidget {
  const BigCard({super.key, required this.pair, required this.waterLevel});

  final String pair; // Holds the current hydration state of the user
  final double waterLevel; // Current water level (0-100%)

  @override
  State<BigCard> createState() => _BigCardState();
}

class _BigCardState extends State<BigCard> with TickerProviderStateMixin {
  late AnimationController firstController;
  late Animation<double> firstAnimation;

  late AnimationController secondController;
  late Animation<double> secondAnimation;

  late AnimationController thirdController;
  late Animation<double> thirdAnimation;

  late AnimationController fourthController;
  late Animation<double> fourthAnimation;

  @override
  void initState() {
    super.initState();

    firstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    firstAnimation =
        Tween<double>(begin: 1.9, end: 2.1).animate(
            CurvedAnimation(parent: firstController, curve: Curves.easeInOut),
          )
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              firstController.reverse();
            } else if (status == AnimationStatus.dismissed) {
              firstController.forward();
            }
          });

    secondController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    secondAnimation =
        Tween<double>(begin: 1.8, end: 2.4).animate(
            CurvedAnimation(parent: secondController, curve: Curves.easeInOut),
          )
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              secondController.reverse();
            } else if (status == AnimationStatus.dismissed) {
              secondController.forward();
            }
          });

    thirdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    thirdAnimation =
        Tween<double>(begin: 1.8, end: 2.4).animate(
            CurvedAnimation(parent: thirdController, curve: Curves.easeInOut),
          )
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              thirdController.reverse();
            } else if (status == AnimationStatus.dismissed) {
              thirdController.forward();
            }
          });

    fourthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    fourthAnimation =
        Tween<double>(begin: 1.9, end: 2.1).animate(
            CurvedAnimation(parent: fourthController, curve: Curves.easeInOut),
          )
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              fourthController.reverse();
            } else if (status == AnimationStatus.dismissed) {
              fourthController.forward();
            }
          });

    Timer(const Duration(seconds: 2), () {
      firstController.forward();
    });

    Timer(const Duration(milliseconds: 1600), () {
      secondController.forward();
    });

    Timer(const Duration(milliseconds: 800), () {
      thirdController.forward();
    });

    fourthController.forward();
  }

  @override
  void dispose() {
    firstController.dispose();
    secondController.dispose();
    thirdController.dispose();
    fourthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Center(
      child: SizedBox(
        width: size.width * 0.5, // Half the screen size
        height: size.height * 0.25, // one-fourth the screen size
        child: Card(
          color: const Color(0xff2B2C56),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    widget.pair,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 50.0,
                      wordSpacing: 3,
                      color: Colors.white.withOpacity(.7),
                    ),
                  ),
                ),
                CustomPaint(
                  painter: MyPainter(
                    firstAnimation.value,
                    secondAnimation.value,
                    thirdAnimation.value,
                    fourthAnimation.value,
                    widget.waterLevel, // Pass the water level
                  ),
                  child: SizedBox(height: size.height, width: size.width),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  final double firstValue;
  final double secondValue;
  final double thirdValue;
  final double fourthValue;
  final double waterLevel; // Water level percentage (0-100)

  MyPainter(
    this.firstValue,
    this.secondValue,
    this.thirdValue,
    this.fourthValue,
    this.waterLevel,
  );

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = const Color(0xff3B6ABA).withOpacity(.8)
      ..style = PaintingStyle.fill;

    // Calculate water height based on water level percentage
    double waterHeight = size.height * (waterLevel / 100.0);
    double waterTop = size.height - waterHeight;

    // Adjust animation values based on water level
    double adjustedFirst = waterTop / firstValue;
    double adjustedSecond = waterTop / secondValue;
    double adjustedThird = waterTop / thirdValue;
    double adjustedFourth = waterTop / fourthValue;

    var path = Path()
      ..moveTo(0, adjustedFirst)
      ..cubicTo(
        size.width * .4,
        adjustedSecond,
        size.width * .7,
        adjustedThird,
        size.width,
        adjustedFourth,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is MyPainter) {
      return oldDelegate.firstValue != firstValue ||
          oldDelegate.secondValue != secondValue ||
          oldDelegate.thirdValue != thirdValue ||
          oldDelegate.fourthValue != fourthValue ||
          oldDelegate.waterLevel != waterLevel;
    }
    return true;
  }
}
