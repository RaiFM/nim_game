import 'package:flutter/material.dart';
import 'home.dart';


class GameScreen extends StatefulWidget {
  late int qtd; // Accept qtd as a parameter

  GameScreen({required this.qtd}); // Constructor

  @override
  _GameScreenState createState() => _GameScreenState();
  
}

class _GameScreenState extends State<GameScreen> {
  bool isPlayerTurn = true;
  String _result = "";
  String _turn = "Sua vez";
  int qtdButtons = 3;

  void removeSticks(int qtd) {
    setState(() {
      widget.qtd -= qtd;

      if(widget.qtd == 1){
        String winner = isPlayerTurn ? "Você" : "IA";
        _result = winner + " venceu!";
        _turn = "";
        qtdButtons = 0;
        widget.qtd = 0;
        return;
      }
      
      isPlayerTurn = !isPlayerTurn;
      _turn = isPlayerTurn ? 'Sua Vez' : 'Vez da IA'; // Switch turns
    });
  }

  Row _buildStick(){
    List<IconButton> sticks = [];
    for (int i = 0; i < widget.qtd; i++) {
      sticks.add(
        IconButton(
          icon: Icon(Icons.remove),
          onPressed: () {

          },
        ),
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
      appBar: AppBar(title: Text('Nim Game')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _result,
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          ),
          _buildStick(),
          _buildButtons(),
          Text(_turn),
        ],
      ),
    );
  }
}