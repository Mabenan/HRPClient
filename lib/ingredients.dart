import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'globals.dart' as globals;

class PricesWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => PricesWidgetState();
}

class PricesWidgetState extends State<PricesWidget> {
  final QueryBuilder<Price> query =
      (QueryBuilder<Price>(Price())..orderByAscending("Name"));
  final LiveQuery liveQuery = LiveQuery(autoSendSessionId: true);
  Subscription<Price> sub;
  List<Price> _prices = List<Price>.empty(growable: true);

  PricesWidgetState() : super() {
    this.init();
  }

  init() async {
    sub = await liveQuery.client.subscribe(query);
    sub.on(LiveQueryEvent.create, (value) {
      getData();
    });
    sub.on(LiveQueryEvent.delete, (Price value) {
      getData();
    });
    sub.on(LiveQueryEvent.update, (Price value) {
      getData();
    });
  }

  @override
  Widget build(BuildContext context) {
    globals.setActualFloatingActionHandler(() async {
      var price = new Price();
      setState(() {
        _prices.add(price);
      });
      price.save();
    });
    if(_prices.length == 0){
      getData();
    }
    return Container(
      child: _prices.length != 0
          ? getList(context)
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  getList(BuildContext context) {
    return RefreshIndicator(
        child: ListView.builder(
          itemCount: _prices.length,
          itemBuilder: (BuildContext context, int index) {
            return buildChilds(context, _prices.elementAt(index));
          },
        ),
        onRefresh: getData);
  }

  Future<void> getData() async {
    print("refresh");
    var result = (await query.query());
    setState(() {
      _prices = List<Price>.from(result.results.map((e) => e as Price));
    });
  }

  buildChilds(BuildContext context, Price elementAt) {
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

class Price extends ParseObject {
  Price() : super("Price");
  Price.clone() : this();

  @override
  clone(Map map) => Price.clone()..fromJson(map);

}
