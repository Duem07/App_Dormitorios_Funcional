import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart'; // 
import 'login_screen.dart';
import 'Estudiantes/screens/home_screen.dart';
import 'Administrador/Preceptor/screens/dashboard_preceptor_screen.dart';
import 'Administrador/Monitor/screens/dashboard_monitor_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const GestionDormitoriosApp(),
    ),
  );
}

class GestionDormitoriosApp extends StatelessWidget {
  const GestionDormitoriosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HVU - ULV',

      themeMode: themeProvider.themeMode,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,

      initialRoute: '/',

      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/home_preceptor': (context) => const DashboardPreceptorScreen(),
        '/home_monitor': (context) => const DashboardMonitorScreen(),
      },
    );
  }
}
