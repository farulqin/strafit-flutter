import 'package:flutter/material.dart';
import 'app/app_theme.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const StraFitApp());
}

class StraFitApp extends StatelessWidget {
  const StraFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StraFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginPage(),
    );
  }
}
