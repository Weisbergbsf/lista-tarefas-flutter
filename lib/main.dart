import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _todoController = TextEditingController();
  String? _errorText;

  List _todoList = [];

  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedPos;

  @override
  void initState() {
    super.initState();

    _readData().then((data) => {
          setState(() {
            if (data != null) {
              _todoList = json.decode(data);
            }
          })
        });
  }

  void _addTodo() {
    String text = _todoController.text;

    if (text.isEmpty) {
      setState(() {
        _errorText = 'O nome não pode ser vazio!';
      });
      return;
    }

    Map<String, dynamic> newTodo = {};
    newTodo['title'] = text;
    _todoController.text = '';
    newTodo['ok'] = false;

    setState(() {
      _todoList.add(newTodo);
    });
    _saveData();
  }

  Future _onRefresh() async {
    // Para simular um request no servidor
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _todoList.sort((a, b) {
        if (a['ok'] && !b['ok']) {
          return 1;
        }
        if (!a['ok'] && b['ok']) {
          return -1;
        }
        return 0;
      });
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List de tarefas'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                  controller: _todoController,
                  onChanged: (value) {
                    if(value.length == 1) {
                      setState(() {
                        _errorText = null;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: "Nova tarefa",
                    labelStyle: const TextStyle(color: Colors.blueAccent),
                    errorText: _errorText,
                  ),
                )),
                ElevatedButton(
                  style: const ButtonStyle(
                      backgroundColor:
                          MaterialStatePropertyAll(Colors.blueAccent)),
                  onPressed: _addTodo,
                  child:
                      const Text('ADD', style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemCount: _todoList.length,
                itemBuilder: buildItem,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      //key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      key: UniqueKey(),
      background: Container(
        color: Colors.red,
        child: const Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        onChanged: (c) {
          setState(() {
            _todoList[index]['ok'] = c;
          });
          _saveData();
        },
        title: Text(_todoList[index]['title']),
        value: _todoList[index]['ok'],
        secondary: CircleAvatar(
          child: Icon(_todoList[index]['ok'] ? Icons.check : Icons.error),
        ),
      ),
      onDismissed: (direction) {
        _lastRemoved = Map.from(_todoList[index]);
        _lastRemovedPos = index;

        setState(() {
          _todoList.removeAt(index);
        });

        _saveData();

        ScaffoldMessenger.of(context).removeCurrentSnackBar();

        final snackBar = SnackBar(
          content: Text('Tarefa \"${_lastRemoved['title']}\" removida!'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () {
              setState(() {
                _todoList.insert(_lastRemovedPos, _lastRemoved);
              });
              _saveData();
            },
          ),
          duration: const Duration(seconds: 5),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
    );
  }

  Future<File> _getFile() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    print(appDocPath);
    return File('$appDocPath/data.json');
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);
    final file = await _getFile();

    return file.writeAsString(data);
  }

  Future<String?> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (error) {
      return null;
    }
  }
}
