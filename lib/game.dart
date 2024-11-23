import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'api_python.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:restart_app/restart_app.dart';


class GameScreen extends StatefulWidget {
  late int qtd; 
  late String player; 

  GameScreen({required this.qtd, required this.player}); 
  late int qtd_original = this.qtd;
  late String currentGame = 'null';

  @override
  _GameScreenState createState() => _GameScreenState();
  
}

class _GameScreenState extends State<GameScreen> {

  // Mastrar de quem é a vez
  bool isPlayerTurn = true;
  String _turn = "Vez de ";

  // Mostrar resultado final do jogo
  String _result = "";
  int _codWinner = 0;

  // Controlar pontos
  int? _userPoints = 0;
  int? _aiPoints = 0;

  // Quantidade de botões
  int qtdButtons = 3;

  // Número de partidas
  int _nMatches = 1;

  // Persistencia de dados
  late SharedPreferences prefs;

  // Controller do input de quantidade
  TextEditingController _controllerQtd = new TextEditingController();
  
  // Controlar visibilidade do botão para ir para a próxima partida
  bool _endGame = false;

  // Partidas anteriores do jogador
  List<TableRow> _playerGames = [];

  // Instancia da api
  ApiService api = new ApiService();

  @override
  void initState(){
    super.initState();
    loadPreferences();
    _turn = "Vez de " + widget.player;
    newGame();

    searchGames(widget.player);
  }

  void searchGames(String player) async {
    try {
      var games = await api.getScores(); 

      setState(() {
        _playerGames = games
            .map((game) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(game['nome']),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(game['pontos'].toString()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Partida ${game['id']}'),
                  ),
                ],
              );
            })
            .toList();
      });
    } catch (e) {
      print('Erro ao buscar jogos: $e');
    }
  }

  void loadPreferences() async{
    prefs = await SharedPreferences.getInstance();

    setState(() {

      if(prefs.getString('lastPlayer') == widget.player){
        _userPoints = prefs.getInt('userPoints') ?? 0;
        _aiPoints = prefs.getInt('aiPoints') ?? 0;
        widget.currentGame = prefs.getString('lastGame') ?? '';
      }else{
        prefs.setString('lastPlayer', widget.player);
        _userPoints = 0;
        _aiPoints = 0;
      }

      prefs.setInt('qtd_original', widget.qtd);
    });
  }

  Future<Map<String, dynamic>> getReferenceData(String reference) async{
    DocumentReference gameRef = FirebaseFirestore.instance.doc(reference);
    
    DocumentSnapshot snapshot = await gameRef.get();

    Map<String, dynamic> gameData = snapshot.data() != null ? snapshot.data() as Map<String, dynamic> : {};

    return gameData;
  }

  void showAlert(String title, String text, int time){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Show the dialog
        return AlertDialog(
          title: Text(title),
          content: Text(text),
        );
      },
    );

    // Close the dialog automatically after 3 seconds
    Future.delayed(Duration(seconds: time), () {
      Navigator.of(context).pop(); // Close the dialog
    });
  }

  Future<String> updateGame(Map<String, dynamic> newData) async{
    String result = '';
    try{
      // DocumentReference gameRef = FirebaseFirestore.instance.doc(reference);

      // await gameRef.update(newData);
      await api.updateScore(newData);
      result = 'Game ' + widget.currentGame + ' updated';

    }catch(e){
      result = e.toString();
    }
    
    searchGames(widget.player);
    return result;
  }
  
  Future<String> newGame() async{
    String result = '';

    try{
      api.newGame(widget.player, 0);
    //   CollectionReference collRef = FirebaseFirestore.instance.collection(reference);

    //     DocumentReference newGameRef = await collRef.add({
    //       'aiPoints': 0,
    //       'matches': 1,
    //       'userPoints': 0,
    //       'player': widget.player
    //     });

    //     String newGameId = newGameRef.id;

    //     widget.currentGame = newGameId;

      result = 'New game created';

    }catch(e){
      result = e.toString();
    }
    return result;
  }

  void removeSticks(int qtd) async{
    
    if(qtd <= widget.qtd){

      Map<String, dynamic> gameData = await api.searchScore('game/' + widget.currentGame);

      bool update = false;
      bool addGame = false;
      Map<String, dynamic> newData = {};

      setState(() {
        widget.qtd -= qtd;
        int points = 0;
        String winner = "";
        _codWinner = 0;

        if (widget.qtd <= 1) {
          if(widget.qtd == 1){
            if(isPlayerTurn){
              winner = widget.player;
              points = 1 + (_userPoints ?? 0); 
              _codWinner = 1;
            }else{
              winner = "IA";
              points = (_aiPoints ?? 0) + 1;
              _codWinner = 2;
            }
          }else if(widget.qtd == 0){
            if(isPlayerTurn){
              winner = "IA";
              points = 1 + (_aiPoints ?? 0); 
              _codWinner = 2;
            }else{
              winner = widget.player;
              points = (_userPoints ?? 0) + 1;
              _codWinner = 1;
            }
          }

          qtdButtons = 0;
          widget.qtd = 0;
          _turn = "";
          _result = winner + " venceu!";

          switch(_codWinner){
            case 1:
              _userPoints = points;
              prefs.setInt('userPoints', points);
            case 2:
              _aiPoints = points;
              prefs.setInt('aiPoints', points);
          }

          if(gameData.isEmpty){
            addGame = true;
          }else{
            newData = {
              // 'aiPoints': _aiPoints,
              // 'matches': _nMatches,
              'id': widget.currentGame,
              'pontos': _userPoints,
              'nome': widget.player
            };

            update = true;
          }

          _endGame = true;
          
          return;
        }
        
        isPlayerTurn = !isPlayerTurn;
        _turn = isPlayerTurn ? 'Vez de ' + widget.player : 'Vez da IA'; // Switch turns
      });

      if(addGame){
        await newGame();
      }else if(update){
        await updateGame(newData);
      }

      prefs.setString('lastGame', widget.currentGame);
    }else{
      showAlert('Número inválido', 'Selecione um número válido para ser retirado', 2);
    }
  }

  void reestart(context){
    final scaffold = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Deseja reiniciar o jogo?'),
          actions: [
            TextButton(
              child: Text('Sim'),
              onPressed: () async{
                Map<String, dynamic> newData = {
                  // 'aiPoints': 0,
                  // 'matches': 0,
                  'id': widget.currentGame,
                  'pontos': 0,
                  'nome': widget.player
                };

                await updateGame(newData);

                Navigator.of(context).pop(); 
                setState(() {
                  _nMatches = 1;
                  _userPoints = 0;
                  _aiPoints = 0;
                  _result = "";
                  _turn = "Vez de " + widget.player;
                  qtdButtons = 3;

                  widget.qtd = widget.qtd_original;

                  prefs.setInt('userPoints', 0);
                  prefs.setInt('aiPoints', 0);
                });
              }
            ),
            TextButton(
              child: Text('Não'),
              onPressed: () {
                Navigator.of(context).pop(); 
              }
            ),
          ],
        );
      }
    );
  }

  void startGame(context){
    final scaffold = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Iniciar um novo jogo?'),
          actions: [
            TextButton(
              child: Text('Sim'),
              onPressed: () {
                Navigator.of(context).pop();
                askQtd(context); 
              }
            ),
            TextButton(
              child: Text('Não'),
              onPressed: () {
                Navigator.of(context).pop(); 
              }
            ),
          ],
        );
      }
    );
  }

  void nextMatch(){
    setState(() {
      _result = "";
      _turn = "Vez de " + widget.player;
      qtdButtons = 3;
      _nMatches++;
      _endGame = false;
      widget.qtd = prefs.getInt('qtd_original') ?? 0;
    });
  }

  void askQtd(context){
    final scaffold = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Digite a quantidade de palitos'),
          content: TextField(
            controller: _controllerQtd,
            decoration: InputDecoration(
              labelText: 'Quantidade',
              hintText: '7 - 13'
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              child: Text('Iniciar'),
              onPressed: () async{
                try{    
                  int qtd = int.parse(_controllerQtd.text);

                  if(qtd >= 7 && qtd <= 13){

                    newGame();

                    setState(() {
                      _nMatches = 1;
                      _userPoints = 0;
                      _endGame = false;
                      _aiPoints = 0;
                      _result = "";
                      _turn = "Vez de " + widget.player;
                      qtdButtons = 3;
                      widget.qtd = qtd;

                      prefs.setInt('userPoints', 0);
                      prefs.setInt('aiPoints', 0);
                    });

                    Navigator.of(context).pop(); 
                  }else{
                    showAlert('Número inválido', 'Escolha uma quantidade inteira entre 7 e 13', 2);
                  }
                }catch(e){
                  showAlert('Número inválido', 'Escolha uma quantidade inteira entre 7 e 13', 2);
                }
              }
            )
          ],
        );
      }
    );
  }

  Row _buildStick(){
    List<SizedBox> sticks = [];
    for (int i = 0; i < widget.qtd; i++) {
      sticks.add(
        SizedBox(
        width: 100,
        height: 50,
        child: IconButton(
          icon: Image.asset('assets/stick.png'),
          onPressed: () {

            },
          ),
        )
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: sticks,
    );
    
  }
  
  Row _buildButtons(){
    List<TextButton> buttons = [];
    for (int i = 1; i <= qtdButtons; i++) {
      buttons.add(
        TextButton(
          onPressed: () {
            removeSticks(i);
          }, 
          child: Text(i.toString())
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: buttons
    );
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nim Game'),centerTitle: true),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            color: Colors.blueGrey,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      widget.player,
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _userPoints.toString(),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "Partida " + _nMatches.toString(),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'IA',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _aiPoints.toString(),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ), 
          Container(
            height: (_playerGames.length * 50),
            child: Row(
              children: [
                Expanded(
                  child:Table(
                    columnWidths: {
                      0: FlexColumnWidth(0.5),
                      1: FlexColumnWidth(0.5),
                      2: FlexColumnWidth(0.5),
                      3: FlexColumnWidth(0.5),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey[300]),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Jogador', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Pontos Usuário', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Pontos IA', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Partidas', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      ..._playerGames
                    ],
                  )
                ),
                SizedBox(
                  child: Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            reestart(context);
                          }, 
                          child: Text("Recomeçar")
                        ),
                        TextButton(
                          onPressed: () {
                            startGame(context);
                          }, 
                          child: Text("Novo Jogo")
                        ),
                      ]
                    ),
                )
              ],
            )
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_turn),
                Text(
                  _result,
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
                _buildStick(),
                _buildButtons(),
                Visibility(
                  visible: _endGame,
                  child: TextButton(
                      onPressed: () {
                        nextMatch();
                      },
                      child: Text('Proxima Partida'),
                    ),
                )
              ],
            )
            ),
        ]
      ),
    );
  }
}