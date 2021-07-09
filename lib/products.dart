import 'package:flutter/material.dart';
import 'package:hrp/data/product.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'globals.dart' as globals;

class ProductsWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ProductsWidgetState();
}

class ProductsWidgetState extends State<ProductsWidget> {
  final QueryBuilder<Product> query =
      (QueryBuilder<Product>(Product())..orderByAscending("Name"));
  final LiveQuery liveQuery = LiveQuery(autoSendSessionId: true);
  Subscription<Product> sub;
  List<Product> _products = List<Product>.empty(growable: true);

  ProductsWidgetState() : super() {
    this.init();
  }

  init() async {
    sub = await liveQuery.client.subscribe(query);
    sub.on(LiveQueryEvent.create, (value) {
      getData();
    });
    sub.on(LiveQueryEvent.delete, (Product value) {
      getData();
    });
    sub.on(LiveQueryEvent.update, (Product value) {
      getData();
    });
  }

  @override
  Widget build(BuildContext context) {
    globals.setTitle("Products");
    globals.setActualFloatingActionHandler(() async {
      var product = new Product();
      setState(() {
        _products.add(product);
      });
      product.save();
    });
    if(_products.length == 0){
      getData();
    }
    return Container(
      child: _products.length != 0
          ? getList(context)
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  getList(BuildContext context) {
    return RefreshIndicator(
        child: ListView.builder(
          itemCount: _products.length,
          itemBuilder: (BuildContext context, int index) {
            return buildChilds(context, _products.elementAt(index));
          },
        ),
        onRefresh: getData);
  }

  Future<void> getData() async {
    print("refresh");
    var result = (await query.query());
    setState(() {
      _products = List<Product>.from(result.results.map((e) => e as Product));
    });
  }

  buildChilds(BuildContext context, Product elementAt) {
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
