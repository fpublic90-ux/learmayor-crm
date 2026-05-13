import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'app/globals.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/employee_provider.dart';
import 'core/providers/intern_provider.dart';
import 'core/providers/attendance_provider.dart';
import 'core/providers/company_provider.dart';
import 'core/providers/report_provider.dart';

void main() async {
  // Ensuring the Flutter engine is ready before calling any async methods
  WidgetsFlutterBinding.ensureInitialized();
  
  final authProvider = AuthProvider();

  // Setting up native mobile system UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  
  // Lock to portrait mode for a focused mobile experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProxyProvider<AuthProvider, EmployeeProvider>(
          create: (_) => EmployeeProvider(),
          update: (_, auth, employee) => employee!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, InternProvider>(
          create: (_) => InternProvider(),
          update: (_, auth, intern) => intern!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AttendanceProvider>(
          create: (_) => AttendanceProvider(),
          update: (_, auth, attendance) => attendance!..updateToken(auth.token),
        ),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ReportProvider>(
          create: (_) => ReportProvider(),
          update: (_, auth, report) => report!..updateToken(auth.token),
        ),
      ],
      child: const LearnyorHRMApp(),
    ),
  );
}

class LearnyorHRMApp extends StatefulWidget {
  const LearnyorHRMApp({super.key});

  @override
  State<LearnyorHRMApp> createState() => _LearnyorHRMAppState();
}

class _LearnyorHRMAppState extends State<LearnyorHRMApp> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Executive Warmup: Trigger server wake-up on cold boot
    Future.microtask(() {
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).warmup();
      }
    });
    // Use the already created authProvider from the context
    _router = AppRouter.getRouter(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Learnyor HRM',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      scaffoldMessengerKey: Globals.scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
    );
  }
}
