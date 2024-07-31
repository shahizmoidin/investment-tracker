import 'package:flutter/material.dart';
import 'package:payment_reminder/providers/auth_provider.dart';
import 'package:payment_reminder/src/screens/admin/admin_dashboard_screen.dart';
import 'package:payment_reminder/src/screens/auth_screen.dart';
import 'package:payment_reminder/src/screens/dashboard_screen.dart';
import 'package:payment_reminder/src/services/notification_service.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  final NotificationService notificationService;

  AuthWrapper({required this.notificationService});

  @override
  Widget build(BuildContext context) {
    print("Building AuthWrapper");
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print("AuthWrapper Consumer: Current user is ${authProvider.user}");
        if (authProvider.user != null) {
          print("User is logged in: ${authProvider.user?.uid}");
          return FutureBuilder<String>(
            future: authProvider.getRoleFuture(),
            builder: (context, snapshot) {
              print("FutureBuilder State: ${snapshot.connectionState}");
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              } else if (snapshot.hasError) {
                print("FutureBuilder Error: ${snapshot.error}");
                return Scaffold(
                    body: Center(child: Text('Error: ${snapshot.error}')));
              } else if (snapshot.hasData) {
                final userRole = snapshot.data;
                print("FutureBuilder: User role is $userRole");
                if (userRole == 'admin') {
                  print("Navigating to AdminDashboardScreen");
                  return AdminDashboardScreen();
                } else {
                  print("Navigating to DashboardScreen");
                  return DashboardScreen(
                    notificationService: notificationService,
                  );
                }
              } else {
                print("FutureBuilder: No data");
                return Scaffold(
                    body: Center(child: Text('Error: No role data found')));
              }
            },
          );
        } else {
          print("Navigating to AuthScreen");
          return AuthScreen(notificationService: notificationService);
        }
      },
    );
  }
}
