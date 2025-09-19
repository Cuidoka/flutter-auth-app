import 'package:flutter/material.dart';
import 'package:auth_flutter_app/login_screen.dart';
import 'package:auth_flutter_app/services/api_service.dart';
import 'package:auth_flutter_app/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  String _welcomeMessage = 'Carregando dados...';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _logout() {
    _apiService.logout();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sessão encerrada com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final responseBody = await _apiService.getMe();
      setState(() {
        _welcomeMessage = responseBody['message'];
      });
    } catch (e) {
      setState(() {
        _welcomeMessage = 'Falha ao carregar dados protegidos. ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área Protegida'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center( // <-- Comece a substituir daqui
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _welcomeMessage,
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              child: const Text('Ver meu perfil'),
            ),
          ],
        ),
      ),
    );
  }
}