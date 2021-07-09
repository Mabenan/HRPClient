import 'package:flutter/material.dart';
import 'package:hrp/data/market.dart';
import 'package:hrp/data/price.dart';
import 'package:hrp/data/receipt.dart';
import 'package:hrp/priceAdjustDetail.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'globals.dart' as globals;

class PriceToAdjustRouteArguments {
  PriceToAdjustRouteArguments({this.receipt});
  final Receipt receipt;
}

class PriceToAdjust extends StatefulWidget {
  final Receipt receipt;

  PriceToAdjust({this.receipt}) : super();
  @override
  State<StatefulWidget> createState() =>
      _PriceToAdjustState(receipt: this.receipt);
}

class _PriceToAdjustState extends State<PriceToAdjust> {
  final QueryBuilder<Price> query =
      (QueryBuilder<Price>(Price())..orderByAscending("Name"));
  final LiveQuery liveQuery = LiveQuery(autoSendSessionId: true);
  Subscription<Price> sub;
  List<Price> _prices = List<Price>.empty(growable: true);

  final Receipt receipt;

  _PriceToAdjustState({this.receipt}) : super() {
    this.init();
  }

  init() async {
    query.whereRelatedTo("Prices", "Receipt", receipt.objectId);
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
    globals.setTitle("Prices of Receipt: "+receipt.name);
    globals.setActualFloatingActionHandler(null);
    if (_prices.length == 0) {
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
    if (elementAt.objectId != null) {
      return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, "sub/priceAdjustDetail",
                arguments: new PriceAdjustDetailArguments(price: elementAt));
          },
          child: Card(
            child: ListTile(
                title: Text(elementAt.name),
                subtitle: Text(elementAt.costs.toStringAsFixed(2) + " €"),
                trailing: !elementAt.needsManualIntervention ? Icon(Icons.check) : Icon(Icons.error_outline),
            ),
          ));
    } else {
      return Card(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}