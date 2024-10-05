import 'package:flutter/material.dart';
import 'game.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatelessWidget {
  TextEditingController _controllerQtd = new TextEditingController();
  int qtd = 0;
  
  @override  
  void _showToast(BuildContext context) {
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
                  qtd = int.parse(_controllerQtd.text);

                  if(qtd >= 7 && qtd <= 13){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GameScreen(qtd: this.qtd)),
                    );
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

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nim Game')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Play'),
              onPressed: () {
                _showToast(context);
              },
            ),
          ],
        ),
      ),
    );

  }
}