import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Home Resource Planning'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    initParse();
  }

  void initParse() async {
    if (kDebugMode) {
      await Parse().initialize(
          "o7rRXnAte1Zjy4E2wRG9", "https://hrpdev.mabenan.de",
          coreStore: await CoreStoreSharedPrefsImp.getInstance());
    } else {
      await Parse().initialize(
          "CSTPHLACNVVJWUPWYWSIIVGHJE", "https://hrp.mabenan.de",
          coreStore: await CoreStoreSharedPrefsImp.getInstance());
    }
    var healthCheck = await Parse().healthCheck();
    if (healthCheck.success) {
      developer.log("connected to ${ParseCoreData().appName}");
    } else {
      developer.log("can't connect to ${ParseCoreData().serverUrl}",
          error: new Error());
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(onPressed: () => {print("Test")}, child: Text('YEAH')),
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            new TextButton(onPressed: () => {}, child: Text('Test Nav'))
          ],
        ),
      ),
    );
  }
}
