import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amarwallet/core/constants/theme.dart';
import 'package:amarwallet/core/providers/settings_provider.dart';
import 'package:amarwallet/features/dashboard/presentation/screens/main_layout.dart';
import 'package:amarwallet/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  
  runApp(
    const ProviderScope(
      child: AmarWalletApp(),
    ),
  );
}

class AmarWalletApp extends ConsumerWidget {
  const AmarWalletApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Amar Wallet',
      debugShowCheckedModeBanner: false,
      theme: AmarTheme.lightTheme,
      darkTheme: AmarTheme.darkTheme,
      themeMode: themeMode,
      home: const MainLayout(),
    );
  }
}
