import 'package:highlight/languages/typescript.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:hrp/data/market.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'globals.dart' as globals;
import 'package:flutter_highlight/themes/androidstudio.dart';

class MarketsWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MarketsWidgetState();
}

class MarketsWidgetState extends State<MarketsWidget> {
  final QueryBuilder<Market> query =
      (QueryBuilder<Market>(Market())..orderByAscending("Name"));
  final LiveQuery liveQuery = LiveQuery(autoSendSessionId: true);
  Subscription<Market> sub;
  List<Market> _markets = List<Market>.empty(growable: true);

  final TextEditingController _createMarketName = TextEditingController();

  MarketsWidgetState() : super() {
    this.init();
  }

  init() async {
    sub = await liveQuery.client.subscribe(query);
    sub.on(LiveQueryEvent.create, (value) {
      getData();
    });
    sub.on(LiveQueryEvent.delete, (Market value) {
      getData();
    });
    sub.on(LiveQueryEvent.update, (Market value) {
      getData();
    });
  }

  @override
  Widget build(BuildContext context) {
    globals.setTitle("Markets");
    globals.setActualFloatingActionHandler(() async {
      if (await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Create Market'),
          content: TextField(
            controller: _createMarketName,
            decoration: InputDecoration(hintText: "Name of Market"),
            autocorrect: false,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                if (_createMarketName.text != "") {
                  Navigator.pop(context, true);
                }
              },
            ),
          ],
        ),
      )) {
        Market market = new Market();
        market.name = _createMarketName.text;
        market = (await market.save()).result;
        setState(() {
          _markets.add(market);
        });
      }
    });
    if (_markets.length == 0) {
      getData();
    }
    return Container(
      child: _markets.length != 0
          ? getList(context)
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  getList(BuildContext context) {
    return RefreshIndicator(
        child: ListView.builder(
          itemCount: _markets.length,
          itemBuilder: (BuildContext context, int index) {
            return buildChilds(context, _markets.elementAt(index));
          },
        ),
        onRefresh: getData);
  }

  Future<void> getData() async {
    print("refresh");
    var result = (await query.query());
    setState(() {
      _markets = List<Market>.from(result.results.map((e) => e as Market));
    });
  }

  buildChilds(BuildContext context, Market elementAt) {
    if (elementAt.objectId != null) {
      return GestureDetector(
        child: Card(
          child: ListTile(
            title: Text(elementAt.name),
          ),
        ),
        onTap: () => Navigator.of(context).pushNamed("sub/market",
            arguments: MarketDetailArgument(market: elementAt)),
      );
    } else {
      return Card(
        child: ListTile(
          title: CircularProgressIndicator(),
        ),
      );
    }
  }
}

class MarketDetailArgument {
  final Market market;

  MarketDetailArgument({this.market});
}

class MarketDetailWidget extends StatefulWidget {
  final Market market;

  MarketDetailWidget({key, this.market}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MarketDetailState(market: market);
}

class _MarketDetailState extends State<MarketDetailWidget> {
  final Market market;

  final CodeController _interpretationController;

  _MarketDetailState({this.market})
      : _interpretationController = CodeController(text: market.interpretation, language: typescript, theme: androidstudioTheme),
        super();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.only(left: 20, right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(market.name,
                style: Theme.of(context).primaryTextTheme.headline2),
            CodeField(
              controller: _interpretationController,
            ),
          ],
        ),
      ),
    );
  }
}
