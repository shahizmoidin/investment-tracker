import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:payment_reminder/src/screens/calander_screen.dart';
import 'package:payment_reminder/src/screens/payment_history.dart';

import 'package:payment_reminder/providers/auth_provider.dart';
import 'package:payment_reminder/src/screens/payment_screen.dart';
import 'package:payment_reminder/src/services/auth_wrapper.dart';
import 'package:payment_reminder/src/services/notification_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  NotificationService notificationService = NotificationService();
  await notificationService.init();
  notificationService.scheduleWeeklyMondayNotification(
      0, 'Payment Reminder', 'Make payment of ₹300 today!');

  runApp(MyApp(notificationService: notificationService));
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;

  MyApp({required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Payment Reminder',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: AuthWrapper(notificationService: notificationService),
        routes: {
          '/add-payment': (context) =>
              AddPaymentScreen(notificationService: notificationService),
          '/payment-history': (context) => PaymentHistoryScreen(),
          '/calendar': (context) => CalendarScreen(),
        },
      ),
    );
  }
}
