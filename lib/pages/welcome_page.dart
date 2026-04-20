import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isAnimated = false;
  bool _showText = false;
  double _rotation = 0.0;
  Timer? _timer; 

  @override
  void initState() {
    super.initState();

  
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isAnimated = true;
          _rotation = 2 * math.pi;
        });
      }
    });

  
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _showText = true;
        });
      }
    });


    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color ivoryColor = Color(0xFFFFF8E1);
    const Color darkCoffee = Color(0xFF3E2723);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
    
          gradient: RadialGradient(
            center: Alignment.center,
            radius: _isAnimated ? 1.2 : 0.01,
            colors: [
              darkCoffee,
              isDarkMode(context) ? const Color(0xFF1A120B) : ivoryColor,
            ],
            stops: const [0.5, 1.0],
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
         
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: _rotation),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeInOutBack,
                builder: (context, double angle, child) {
                  return Transform.rotate(angle: angle, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: darkCoffee,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.coffee_rounded,
                    size: 70,
                    color: ivoryColor,
                  ),
                ),
              ),

          
              AnimatedSize(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutQuart,
                child: _showText
                    ? Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 600),
                          opacity: _showText ? 1.0 : 0.0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 2,
                                ),
                              ),
                              ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFB76212), 
                                        Color(0xFFC88C0C), 
                                      ],
                                    ).createShader(bounds),
                                child: Text(
                                  "StarBud Coffee",
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 40,
                                    height: 1.0,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
