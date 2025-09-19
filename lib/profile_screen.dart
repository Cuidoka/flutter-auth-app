// lib/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:auth_flutter_app/services/api_service.dart';
import 'package:auth_flutter_app/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userData;
  String _errorMessage = ''; // Variável específica para erros

  // --- MUDANÇA 1: Variável de estado para controlar o loader ---
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // --- MUDANÇA 2: Lógica atualizada com try/catch/finally ---
  Future<void> _fetchUserData() async {
    try {
      final data = await _apiService.getMe();
      setState(() {
        _userData = data['user'];
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      // Se o erro for de sessão expirada, deslogamos o usuário
      if (e.toString().contains('Sua sessão expirou')) {
        _logout();
      }
    } finally {
      // Este bloco SEMPRE será executado, não importa se deu erro ou sucesso
      setState(() {
        _isLoading = false; // Esconde o loader
      });
    }
  }

  void _logout() {
    _apiService.logout();
    // Usamos `pushAndRemoveUntil` para limpar o histórico de navegação
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      // --- MUDANÇA 3: UI condicional baseada no _isLoading ---
      body: Center(
        child: _isLoading
            // SE _isLoading for true, mostre o loader
            ? const CircularProgressIndicator()
            // SENÃO, mostre o conteúdo
            : _userData != null
                // Se temos dados do usuário, mostre-os
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Bem-vindo, ${_userData!['name']}!',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Text('ID do usuário: ${_userData!['userId']}'),
                    ],
                  )
                // Se não temos dados (deu erro), mostre a mensagem de erro
                : Text(
                    'Falha ao carregar perfil:\n$_errorMessage',
                    style: const TextStyle(fontSize: 18, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
      ),
    );
  }
}