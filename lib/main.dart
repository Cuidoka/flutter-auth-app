// lib/main.dart

import 'package:flutter/material.dart';
import 'package:auth_flutter_app/login_screen.dart';
import 'package:auth_flutter_app/home_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // <-- Peça nova importada

void main() async {
  // Isso garante que o Flutter está pronto antes de rodar o app
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    const storage = FlutterSecureStorage();
    // Apenas mudamos a chave que procuramos para 'accessToken'
    final token = await storage.read(key: 'accessToken'); 
    
    if (token != null) {
      _isLoggedIn = true;
    }
    setState(() {
      _isLoading = false;
    });
}

  @override
  Widget build(BuildContext context) {
    // Mostra uma tela de "carregando" enquanto verificamos o token
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Flutter Auth',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Se estiver logado, vai para HomeScreen, senão, para LoginScreen
      home: _isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}