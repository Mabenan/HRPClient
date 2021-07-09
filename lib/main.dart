import 'package:hrp/login.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hrp/markets.dart';
import 'package:hrp/priceAdjustDetail.dart';
import 'package:hrp/pricesToAdjust.dart';
import 'package:hrp/receipts.dart';
import 'package:hrp/recipes.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'globals.dart' as globals;
import 'package:rxdart/rxdart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();
  runApp(MyApp());
}

Future<void> init() async {
  await globals.initParse();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HRP',
      theme:
          ThemeData(brightness: Brightness.dark, primarySwatch: Colors.orange),
      home: PageWrapper(),
      navigatorKey: globals.navigatorKey,
    );
  }
}

class PageWrapper extends StatefulWidget {
  PageWrapper({Key key}) : super(key: key);
  @override
  _PageWrapperState createState() => _PageWrapperState();
}

class _PageWrapperState extends State<PageWrapper> {
  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: "login",
      onGenerateRoute: routes,
    );
  }

  MaterialPageRoute routes(RouteSettings settings) {
    WidgetBuilder builder;
    switch (settings.name) {
      case "main":
        builder = (BuildContext _) => MyHomePage();
        break;
      case "login":
        builder = (BuildContext _) => LoginWidget();
        break;
    }
    return MaterialPageRoute(builder: builder, settings: settings);
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);
  final String title = "HRP";

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class NavObs extends NavigatorObserver {
  final GlobalKey<NavigatorState> subRoute = GlobalKey();
  final _canPopStream = BehaviorSubject<bool>();

  Stream<bool> get canPopStream => _canPopStream.stream;
  NavObs();

  @override
  void didPop(Route route, Route previousRoute) {
    super.didPop(route, previousRoute);
    route.changedExternalState(); // ignore: invalid_use_of_protected_member
    _canPopStream.add(navigator.canPop());
  }

  @override
  void didPush(Route route, Route previousRoute) {
    super.didPush(route, previousRoute);
    _canPopStream.add(navigator.canPop());
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final obServer = NavObs();

  double leadingWidth = 48.0;

  _MyHomePageState() : super(){
    obServer.canPopStream.listen((event) {
      setState(() {
        if(event) {
          this.leadingWidth = 48.0 * 2;
        }else{
          setState(() {
            this.leadingWidth = 48.0;
          });

        }
      });

    });
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () =>
          Future.value(Navigator.of(obServer.subRoute.currentContext).canPop()),
      child: Scaffold(
        drawer: Drawer(
          child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Text('Menu'),
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
              ),
              ListTile(
                title: Text('Recipe'),
                onTap: () {
                  Navigator.of(obServer.subRoute.currentContext)
                      .pushNamedAndRemoveUntil("main/recipes", (route) => false);
                },
              ),
              ListTile(
                title: Text('Receipe'),
                onTap: () {
                  Navigator.of(obServer.subRoute.currentContext)
                      .pushNamedAndRemoveUntil("main/receipes", (route) => false);
                },
              ),
              ListTile(
                title: Text('Market'),
                onTap: () {
                  Navigator.of(obServer.subRoute.currentContext)
                      .pushNamedAndRemoveUntil("main/markets", (route) => false);
                },
              ),
            ],
          ),
        ),
        appBar: AppBar(
          leadingWidth: leadingWidth,
          leading: Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(obServer.subRoute.currentContext).openDrawer(),
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              ),
              StreamBuilder<bool>(
                  stream: obServer.canPopStream,
                  initialData: false,
                  builder: (BuildContext cntx, AsyncSnapshot<bool> snap) {
                    if (snap.data) {
                      return ConstrainedBox(
                        constraints: BoxConstraints.tightFor(width: 40.0),
                        child: BackButton(
                          onPressed: () => {
                            Navigator.of(obServer.subRoute.currentContext)
                                .maybePop(true)
                          },
                        ),
                      );
                    } else {
                      return Container();
                    }
                  }),
            ],
          ),
          title: StreamBuilder<String>(
            stream: globals.titleStream,
            initialData: "HRP",
            builder: (context, snapshot) {
              return Text(snapshot.data);
            },
          ),
          actions: [
            IconButton(
              onPressed: () => {
                ParseUser.currentUser().then((user) => {
                      user.logout(),
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => LoginWidget()))
                    })
              },
              icon: Icon(
                Icons.logout,
                size: 26.0,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Navigator(
                key: obServer.subRoute,
                initialRoute: "main/recipes",
                onGenerateRoute: routes,
                observers: [obServer],
              ),
            ),
          ],
        ),
        floatingActionButton: StreamBuilder<Future<Null> Function()>(
          stream: globals.floatActHandlStream,
          initialData: null,
          builder: (context, snapshot) {
            if (snapshot.data != null) {
              return FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () => snapshot.data(),
              );
            } else {
              return Container();
            }
          },
        ),
      ),
    );
  }

  MaterialPageRoute routes(RouteSettings settings) {
    WidgetBuilder builder;
    switch (settings.name) {
      case "main/recipes":
        builder = (BuildContext _) => RecipesWidget();
        break;
      case "main/receipes":
        builder = (BuildContext _) => ReceiptsWidget();
        break;
      case "main/markets":
        builder = (BuildContext _) => MarketsWidget();
        break;
      case "sub/market":
        builder = (BuildContext _) => MarketDetailWidget(market: (settings.arguments as MarketDetailArgument).market);
        break;
      case "sub/pricesToAdjust":
        builder = (BuildContext _) => PriceToAdjust(
            receipt:
                (settings.arguments as PriceToAdjustRouteArguments).receipt);
        break;
      case "sub/priceAdjustDetail":
        builder = (BuildContext _) => PriceAdjustDetail(
          price:
          (settings.arguments as PriceAdjustDetailArguments).price
        );
        break;
    }
    return MaterialPageRoute(builder: builder, settings: settings);
  }
}
