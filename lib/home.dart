import 'package:flutter/material.dart';
import 'game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
                    showAlert(context, 'Número inválido', 'Digite uma quantidade inteira entre 7 e 13', 2);
                  }
                }catch(e){
                  showAlert(context, 'Número inválido', 'Digite uma quantidade inteira entre 7 e 13', 2);
                }
              }
            )
          ],
        );
      }
    );
  }

  void showAlert(BuildContext context, String title, String text, int time){
    
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

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nim Game'),
        centerTitle: true
      ),
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