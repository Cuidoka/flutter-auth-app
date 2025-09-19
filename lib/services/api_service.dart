// lib/services/api_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final String _baseUrl = 'http://localhost:3000/api/auth';
  final _storage = const FlutterSecureStorage();

  // --- FUNÇÕES AUXILIARES PARA GERENCIAR TOKENS ---

  // Salva ambos os tokens
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);
  }

  // Lê o accessToken
  Future<String?> _getAccessToken() async {
    return await _storage.read(key: 'accessToken');
  }

  // Lê o refreshToken
  Future<String?> _getRefreshToken() async {
    return await _storage.read(key: 'refreshToken');
  }

  // Apaga todos os tokens
  Future<void> _deleteAllTokens() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
  }


  // --- LÓGICA DE LOGIN E LOGOUT ATUALIZADA ---

  Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, String>{'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Agora salvamos os dois tokens que o backend nos enviou
      await _saveTokens(data['accessToken'], data['refreshToken']);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message']);
    }
  }

  Future<void> logout() async {
    // Pega o refresh token para invalidá-lo no backend
    final refreshToken = await _getRefreshToken();
    if (refreshToken != null) {
        await http.post(
            Uri.parse('$_baseUrl/logout'),
            headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(<String, String>{'refreshToken': refreshToken}),
        );
    }
    // Deleta os tokens do celular independentemente da resposta do servidor
    await _deleteAllTokens();
  }


  // --- A MÁGICA DA RENOVAÇÃO AUTOMÁTICA ---

  // Função que tenta renovar o token
  Future<String?> _refreshToken() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null) {
      throw Exception('Refresh token não encontrado, por favor faça login novamente.');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/refresh'),
      headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, String>{'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newAccessToken = data['accessToken'];
      await _storage.write(key: 'accessToken', value: newAccessToken);
      print("Token de acesso renovado com sucesso!");
      return newAccessToken;
    } else {
      // Se a renovação falhar, o refresh token é inválido. Deslogamos o usuário.
      await logout();
      throw Exception('Sua sessão expirou. Por favor, faça login novamente.');
    }
  }

  // getMe agora com a lógica de "tentar de novo"
  Future<Map<String, dynamic>> getMe() async {
    String? accessToken = await _getAccessToken();

    if (accessToken == null) {
      throw Exception('Access token não encontrado.');
    }

    var response = await http.get(
      Uri.parse('$_baseUrl/me'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    // SE o token expirou (erro 401 ou 403)...
    if (response.statusCode == 401 || response.statusCode == 403) {
      print("Access Token expirado. Tentando renovar...");
      try {
        // Tentamos renovar o token
        final newAccessToken = await _refreshToken();
        
        // Se a renovação funcionou, tentamos a chamada original DE NOVO
        print("Retentando a chamada para /me com o novo token...");
        response = await http.get(
          Uri.parse('$_baseUrl/me'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $newAccessToken', // Usando o novo token
          },
        );
      } catch (e) {
        // Se a renovação falhou, propagamos o erro para a UI (que vai deslogar o user)
        rethrow;
      }
    }

    // Se depois de tudo a resposta ainda não for 200, é um erro.
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message']);
    }
  }
}