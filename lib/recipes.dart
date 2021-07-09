import 'package:flutter/material.dart';
import 'package:hrp/data/recipe.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'globals.dart' as globals;

class RecipesWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => RecipesWidgetState();
}

class RecipesWidgetState extends State<RecipesWidget> {
  final QueryBuilder<Recipe> query =
      (QueryBuilder<Recipe>(Recipe())..orderByAscending("Name"));
  final LiveQuery liveQuery = LiveQuery(autoSendSessionId: true);
  Subscription<Recipe> sub;
  List<Recipe> _recipes = List<Recipe>.empty(growable: true);

  RecipesWidgetState() : super() {
    this.init();
  }

  init() async {
    sub = await liveQuery.client.subscribe(query);
    sub.on(LiveQueryEvent.create, (value) {
      getData();
    });
    sub.on(LiveQueryEvent.delete, (Recipe value) {
      getData();
    });
    sub.on(LiveQueryEvent.update, (Recipe value) {
      getData();
    });
  }

  @override
  Widget build(BuildContext context) {
    globals.setTitle("Recipes");
    globals.setActualFloatingActionHandler(() async {
      var recipe = new Recipe();
      recipe.name = "Test Recipe";
      setState(() {
        _recipes.add(recipe);
      });
      recipe.save();
    });
    if(_recipes.length == 0){
      getData();
    }
    return Container(
      child: _recipes.length != 0
          ? getList(context)
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  getList(BuildContext context) {
    return RefreshIndicator(
        child: ListView.builder(
          itemCount: _recipes.length,
          itemBuilder: (BuildContext context, int index) {
            return buildChilds(context, _recipes.elementAt(index));
          },
        ),
        onRefresh: getData);
  }

  Future<void> getData() async {
    print("refresh");
    var result = (await query.query());
    setState(() {
      _recipes = List<Recipe>.from(result.results.map((e) => e as Recipe));
    });
  }

  buildChilds(BuildContext context, Recipe elementAt) {
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
