import 'dart:html';

import 'package:flutter/material.dart';
import 'home.dart';
import 'package:shared_preferences/shared_preferences.dart';


class GameScreen extends StatefulWidget {
  late int qtd; // Accept qtd as a parameterx

  GameScreen({required this.qtd}); // Constructor
  late int qtd_original = this.qtd;

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

  void removeSticks(int qtd) {
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
        return;
      }
      
      isPlayerTurn = !isPlayerTurn;
      _turn = isPlayerTurn ? 'Sua Vez' : 'Vez da IA'; // Switch turns
    });
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

                      prefs.setInt('userPoints', 0);
                      prefs.setInt('aiPoints', 0);
                    });

                    Navigator.of(context).pop(); 
                  }else{
                    print('digite uma quantidade entre 7 e 13');
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