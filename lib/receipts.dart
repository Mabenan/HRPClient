import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'globals.dart' as globals;

class ReceipesWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ReceipesWidgetState();
}

class ReceipesWidgetState extends State<ReceipesWidget> {
  final QueryBuilder<Receipe> query =
      (QueryBuilder<Receipe>(Receipe())..orderByAscending("Name"));
  final LiveQuery liveQuery = LiveQuery(autoSendSessionId: true);
  Subscription<Receipe> sub;
  List<Receipe> _receipes = List<Receipe>.empty(growable: true);

  ReceipesWidgetState() : super() {
    this.init();
  }

  init() async {
    sub = await liveQuery.client.subscribe(query);
    sub.on(LiveQueryEvent.create, (value) {
      getData();
    });
    sub.on(LiveQueryEvent.delete, (Receipe value) {
      getData();
    });
    sub.on(LiveQueryEvent.update, (Receipe value) {
      getData();
    });
  }

  @override
  Widget build(BuildContext context) {
    globals.setActualFloatingActionHandler(() async {
      showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel:
              MaterialLocalizations.of(context).modalBarrierDismissLabel,
          barrierColor: Colors.black45,
          transitionDuration: const Duration(milliseconds: 200),
          pageBuilder: buildCreateDialog);
    });
    if (_receipes.length == 0) {
      getData();
    }
    return Container(
      child: _receipes.length != 0
          ? getList(context)
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  getList(BuildContext context) {
    return RefreshIndicator(
        child: ListView.builder(
          itemCount: _receipes.length,
          itemBuilder: (BuildContext context, int index) {
            return buildChilds(context, _receipes.elementAt(index));
          },
        ),
        onRefresh: getData);
  }

  Future<void> getData() async {
    print("refresh");
    var result = (await query.query());
    setState(() {
      _receipes = List<Receipe>.from(result.results.map((e) => e as Receipe));
    });
  }

  buildChilds(BuildContext context, Receipe elementAt) {
    if (elementAt.objectId != null) {
      return Card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(elementAt.get("Processed").toString()),
          ],
        ),
      );
    } else {
      return Card(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }

  Widget buildCreateDialog(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {

    TextEditingController name = TextEditingController();
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width - 10,
        height: MediaQuery.of(context).size.height -  80,
        padding: EdgeInsets.all(20),
        color: Colors.white,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Name',
                  hintText: 'Enter a name for the receipe'),
              controller: name,
            ),
            Container(
              height: 50,
              width: 250,
              decoration: BoxDecoration(
                  color: Colors.blue, borderRadius: BorderRadius.circular(20)),
              child: TextButton(
                onPressed: () {
                  Receipe receipe = new Receipe();
                  receipe.name = name.text;
                  setState(() {
                    _receipes.add(receipe);
                  });
                  receipe.save();
                },
                child: Text(
                  'Submit',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
              ),
            ),
          ],
        ),
      ),
    );

  }
}

class Receipe extends ParseObject {
  Receipe() : super("Receipe");
  Receipe.clone() : this();

  @override
  clone(Map map) => Receipe.clone()..fromJson(map);
  String get name => get<String>("Name");

  set name(String name) => set<String>("Name", name);
}
