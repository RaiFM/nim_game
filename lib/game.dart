import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


class GameScreen extends StatefulWidget {
  late int qtd; // Accept qtd as a parameterx

  GameScreen({required this.qtd}); // Constructor
  late int qtd_original = this.qtd;
  late String currentGame = 'null';

  @override
  _GameScreenState createState() => _GameScreenState();
  
}

class _GameScreenState extends State<GameScreen> {
  bool isPlayerTurn = true;
  String _result = "";
  String _turn = "Sua vez";
  int? _userPoints = 0;
  int? _aiPoints = 0;
  int qtdButtons = 3;
  int _nMatches = 1;
  late SharedPreferences prefs;
  TextEditingController _controllerQtd = new TextEditingController();
  int _codWinner = 0;

  @override
  void initState(){
    super.initState();
    loadPreferences();
  }

  void loadPreferences() async{
    prefs = await SharedPreferences.getInstance();

    setState(() {
      _userPoints = prefs.getInt('userPoints') ?? 0;
      _aiPoints = prefs.getInt('aiPoints') ?? 0;
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

  void removeSticks(int qtd) async{
    
    if(qtd <= widget.qtd){

      Map<String, dynamic> gameData = await getReferenceData('game/' + widget.currentGame);

      bool update = false;
      bool newGame = false;
      Map<String, dynamic> newData = {};

      setState(() {
        widget.qtd -= qtd;
        int points = 0;
        String winner = "";
        _codWinner = 0;

        if (widget.qtd <= 1) {
          if(widget.qtd == 1){
            if(isPlayerTurn){
              winner = "Você";
              points = 1 + (_userPoints ?? 0); //!= null ? _userPoints : 1;
              _codWinner = 1;
            }else{
              winner = "IA";
              points = (_aiPoints ?? 0) + 1; //!= null ? _userPoints : 1;
              _codWinner = 2;
            }
          }else if(widget.qtd == 0){
            if(isPlayerTurn){
              winner = "IA";
              points = 1 + (_aiPoints ?? 0); 
              _codWinner = 2;
            }else{
              winner = "Você";
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
            newGame = true;
          }else{
            newData = {
              'aiPoints': _aiPoints,
              'matches': _nMatches,
              'userPoints': _userPoints
            };

            update = true;
          }
          
          return;
        }
        
        isPlayerTurn = !isPlayerTurn;
        _turn = isPlayerTurn ? 'Sua Vez' : 'Vez da IA'; // Switch turns
      });

      if(newGame){
        CollectionReference collRef = FirebaseFirestore.instance.collection('game/');

        DocumentReference newGameRef = await collRef.add({
          'aiPoints': _aiPoints,
          'matches': _nMatches,
          'userPoints': _userPoints
        });

        String newGameId = newGameRef.id;

        widget.currentGame = newGameId;
        print('New game ' + newGameId);

      }else if(update){
        
        DocumentReference gameRef = FirebaseFirestore.instance.doc('game/' + widget.currentGame);

        await gameRef.update(newData);
        print('Game ' + widget.currentGame + ' updated');
      }
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
      _turn = "Sua vez";
      qtdButtons = 3;
      _nMatches++;
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
              onPressed: () {
                try{    
                  int qtd = int.parse(_controllerQtd.text);

                  if(qtd >= 7 && qtd <= 13){
                    setState(() {
                      _nMatches = 1;
                      _userPoints = 0;
                      _aiPoints = 0;
                      _result = "";
                      _turn = "Sua vez";
                      qtdButtons = 3;
                      widget.qtd = qtd;
                      widget.currentGame = 'null';

                      prefs.setInt('userPoints', 0);
                      prefs.setInt('aiPoints', 0);
                    });

                    Navigator.of(context).pop(); 
                  }else{
                    showAlert('Número inválido', 'Escolha uma quantidade inteira entre 7 e 13', 2);
                  }
                }catch(e){
                  print('digite uma quantidade válida');
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
                      'Você',
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
                      "Jogo " + _nMatches.toString(),
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
          ), Expanded(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        reestart(context);
                      },
                      child: Text('Recomeçar'),
                    ),
                    TextButton(
                      onPressed: () {
                        nextMatch();
                      },
                      child: Text('Proxima Partida'),
                    ),
                  ],
                ),
              ],
            )
            ),
        ]
      ),
    );
  }
}