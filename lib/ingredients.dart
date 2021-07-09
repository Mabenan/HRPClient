import 'package:flutter/material.dart';
import 'package:hrp/data/ingredient.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'globals.dart' as globals;

class IngredientsWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => IngredientsWidgetState();
}

class IngredientsWidgetState extends State<IngredientsWidget> {
  final QueryBuilder<Ingredient> query =
      (QueryBuilder<Ingredient>(Ingredient())..orderByAscending("Name"));
  final LiveQuery liveQuery = LiveQuery(autoSendSessionId: true);
  Subscription<Ingredient> sub;
  List<Ingredient> _ingredients = List<Ingredient>.empty(growable: true);

  IngredientsWidgetState() : super() {
    this.init();
  }

  init() async {
    sub = await liveQuery.client.subscribe(query);
    sub.on(LiveQueryEvent.create, (value) {
      getData();
    });
    sub.on(LiveQueryEvent.delete, (Ingredient value) {
      getData();
    });
    sub.on(LiveQueryEvent.update, (Ingredient value) {
      getData();
    });
  }

  @override
  Widget build(BuildContext context) {
    globals.setActualFloatingActionHandler(() async {
      var ingredient = new Ingredient();
      setState(() {
        _ingredients.add(ingredient);
      });
      ingredient.save();
    });
    if(_ingredients.length == 0){
      getData();
    }
    return Container(
      child: _ingredients.length != 0
          ? getList(context)
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  getList(BuildContext context) {
    return RefreshIndicator(
        child: ListView.builder(
          itemCount: _ingredients.length,
          itemBuilder: (BuildContext context, int index) {
            return buildChilds(context, _ingredients.elementAt(index));
          },
        ),
        onRefresh: getData);
  }

  Future<void> getData() async {
    print("refresh");
    var result = (await query.query());
    setState(() {
      _ingredients = List<Ingredient>.from(result.results.map((e) => e as Ingredient));
    });
  }

  buildChilds(BuildContext context, Ingredient elementAt) {
    if(elementAt.objectId != null) {
      return Card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(elementAt.name),
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
