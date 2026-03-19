import 'package:spendly/screens/auth/sign_in_screen.dart';
import 'package:spendly/screens/auth/sign_up_screen.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    tabController = TabController(initialIndex: 0, length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Dynamic Background Elements
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  height: 300,
                  width: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00B2E7).withOpacity(0.15),
                  ),
                ),
              ),
              Positioned(
                top: 100,
                left: -50,
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF8D6C).withOpacity(0.1),
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    // App Logo or Branding Item
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logos/app_icon.png', // Fallback to app icon
                          height: 80,
                          width: 80,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.account_balance_wallet_rounded,
                                  size: 60, color: Color(0xFF00B2E7)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Daily Bachat',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Tab Bar Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TabBar(
                          controller: tabController,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          labelColor: const Color(0xFF00B2E7),
                          unselectedLabelColor: Colors.grey.shade500,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Sign In'),
                            Tab(text: 'Sign Up'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Forms Section
                    Expanded(
                      child: TabBarView(
                        controller: tabController,
                        children: [
                          SignInScreen(),
                          SignUpScreen(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
