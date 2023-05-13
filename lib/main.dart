import 'package:flutter/material.dart';
import 'package:trabalho_localizacao/pages/principal.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Ponto - MD',
      theme: ThemeData(

        primarySwatch: Colors.blue,
      ),
      home: Principal(),
    );
  }
}
