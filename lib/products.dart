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
      var receipe = new Receipe();
      setState(() {
        _receipes.add(receipe);
      });
      receipe.save();
    });
    if(_receipes.length == 0){
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
    if(elementAt.objectId != null) {
      return Card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(elementAt.get("Processed").toString()),
          ],
        ),
      );
    }else{
      return Card(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}

class Receipe extends ParseObject {
  Receipe() : super("Receipe");
  Receipe.clone() : this();

  @override
  clone(Map map) => Receipe.clone()..fromJson(map);

}
