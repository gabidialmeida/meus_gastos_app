import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gastos_app/presentation/screens/home_screen.dart';
import 'package:gastos_app/presentation/widgets/notification_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o handler de notificações
  try {
    await NotificationHandler.initialize();
  } catch (e) {
    log("Erro na inicialização: $e");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenciador de Gastos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}