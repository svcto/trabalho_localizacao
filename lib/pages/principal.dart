import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maps_launcher/maps_launcher.dart';
import '../dao/registro_dao.dart';
import '../entity/registro.dart';
import 'package:intl/intl.dart';

class Principal extends StatefulWidget{
  Principal({Key? key}) : super(key: key);

  _PrincipalState createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {
  Position? _localizacaoAtual;
  final _controller = TextEditingController();

  String get _textoLocalizacao =>
      _localizacaoAtual == null ? '' :
      'Latitude: ${_localizacaoAtual!
          .latitude}  |  Longetude: ${_localizacaoAtual!.longitude}';


  final _registros = <Registro>[];
  var _carregando = false;
  final _dao = RegistroDao();

  @override
  void initState() {
    // super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registro de Registros')),
      body: _criarBody(),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Registrar Registro',
        child: const Icon(Icons.add),
        onPressed: _obterLocalizacaoAtual,
      ),
    );
  }

  Widget _criarBody() {
    if (_carregando) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: AlignmentDirectional.center,
            child: CircularProgressIndicator(),
          ),
          Align(
            alignment: AlignmentDirectional.center,
            child: Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Carregando seus registros de registro',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme
                      .of(context)
                      .primaryColor,
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (_registros.isEmpty) {
      return Center(
        child: Text(
          'Nenhum registro de registro encontrado',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme
                .of(context)
                .primaryColor,
          ),
        ),
      );
    }
    return ListView.builder(
        itemCount: _registros.length,
        itemBuilder: (BuildContext context, int index) {
          final registro = _registros[index];
          return ListTile(
            title: Text(
              '${registro.id} - ${registro.dataRegistro}',

            ),
            subtitle: Text(registro.localizacao == null
                ? 'Registro sem localizacao'
                : 'Localizacao - ${registro.localizacao}',

            ),
          );
        });
  }

  void _obterLocalizacaoAtual() async {
    bool servicoHabilitado = await servicoAtivo();
    if (!servicoHabilitado) {
      return;
    }
    bool permitido = await this.permitido();
    if (!permitido) {
      return;
    }

    _localizacaoAtual = await Geolocator.getCurrentPosition();

    String _textoLocalizacao = 'Latitude: ${_localizacaoAtual!
        .latitude}, Longitude: ${_localizacaoAtual!.longitude}';

    DateTime dataHoraAtual = DateTime.now();
    String textoDataHoraAtual = DateFormat('dd/MM/yyyy HH:mm:ss').format(
        dataHoraAtual);

    Registro novo = Registro(
        id: null,
        localizacao: _textoLocalizacao,
        dataRegistro: dataHoraAtual
    );
    await _dao.salvar(novo);


    _atualizarLista();

    setState(() {

    });
  }



  void _abrirNoMapaExterno() {
    if (_controller.text
        .trim()
        .isEmpty) {
      return;
    }
    MapsLauncher.launchQuery(_controller.text);
  }

  void _abrirCoordenadasNoMapaExterno() {
    if (_localizacaoAtual == null) {
      return;
    }
    MapsLauncher.launchCoordinates(
        _localizacaoAtual!.latitude, _localizacaoAtual!.longitude);
  }

  Future<bool> servicoAtivo() async {
    bool ativo = await Geolocator.isLocationServiceEnabled();
    if (!ativo) {
      await _mostrarMensagemDialog(
          'Para utilizar esse recurso, você deverá ativar o serviço de localização!!');
      Geolocator.openLocationSettings();
      return false;
    }
    return true;
  }

  Future<bool> permitido() async {
    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        _mostrarMensagem( 'Não será possível utilizar o recurso por falta de permissão!!');
        return false;
      }
    }
    if (permissao == LocationPermission.deniedForever) {
      await _mostrarMensagemDialog(
          'Para utilizar esse recurso, você deverá acessar as configurações '
              'do appe permitir a utilização do serviço de localização');
      Geolocator.openAppSettings();
      return false;
    }
    return true;
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)));
  }

  Future<void> _mostrarMensagemDialog(String mensagem) async {
    await showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: Text('Atenção'),
            content: Text(mensagem),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  void _atualizarLista() async {
    setState(() {
      _carregando = true;
    });
    final registros = await _dao.getLista();
    setState(() {
      _registros.clear();
      _carregando = false;
      if (registros.isNotEmpty) {
        _registros.addAll(registros);
      }
    });
  }
}