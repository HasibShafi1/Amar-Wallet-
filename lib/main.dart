import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amarwallet/core/constants/theme.dart';
import 'package:amarwallet/features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AmarWalletApp(),
    ),
  );
}

class AmarWalletApp extends StatelessWidget {
  const AmarWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amar Wallet',
      debugShowCheckedModeBanner: false,
      theme: AmarTheme.lightTheme,
      home: const DashboardScreen(),
    );
  }
}
