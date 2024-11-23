import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'game.dart';


class ApiService {
  static const String baseUrl = 'raibcdev.pythonanywhere.com';

  static Future<dynamic> request(String type, String command, [Map<String, dynamic>? data]) async {
    var url = Uri.https(baseUrl, command);

    http.Response response;

    try {
      if (type == 'post' && data != null) {
        response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data),
        );
      } else if (type == 'put' && data != null) {
        response = await http.put(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data),
        );
      } else if (type == 'delete') {
        response = await http.delete(url);
      } else {
        response = await http.get(url);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body); 
      } else {
        print('Erro na requisição: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro na requisição: $e');
      return null;
    }
  }

  Future<dynamic> getScores() async {
    var response = await request('get', '/score/list');
    if (response is List) {
      return response; 
    } else {
      print('Erro: Resposta não é uma lista');
      return [];
    }
  }

  Future<void> newGame(String name, int pontos) async {
    var games = await getScores();
    int newId = games.length + 1;

    Map<String, dynamic> data = {
      'id': newId,
      'nome': name,
      'pontos': pontos,
    };

    await request('post', '/score', data);
  }
  
  Future<void> updateScore(Map<String, dynamic> newData) async {
    await request('put', '/score', newData);
  }

  Future<dynamic> searchScore(String gameId) async {
    return await request('get', '/score/$gameId');
  }

  Future<void> deleteScore(String gameId) async {
    var response = await request('delete', '/score/$gameId');
    if (response.body.result == true) {
      print('Score deletado com sucesso!');
    } else {
      print('Erro ao deletar score.');
    }
  }
}