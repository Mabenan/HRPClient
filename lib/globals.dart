
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hrp/data/ingredient.dart';
import 'package:hrp/data/market.dart';
import 'package:hrp/data/price.dart';
import 'package:hrp/data/product.dart';
import 'package:hrp/data/receipt.dart';
import 'package:hrp/data/recipe.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:rxdart/rxdart.dart';


final navigatorKey = GlobalKey<NavigatorState>();


final _floatActHandlStream = BehaviorSubject<Future<Null> Function()>();
final _titleStream = BehaviorSubject<String>();
Stream<Future<Null> Function()> get floatActHandlStream => _floatActHandlStream.stream;
Stream<String> get titleStream => _titleStream.stream;

setActualFloatingActionHandler(Future<Null> Function() action){
  _floatActHandlStream.add(action);
}

setTitle(String title){
  _titleStream.add(title);
}

class WindowsParseConnectivityProvider extends ParseConnectivityProvider {

  WindowsParseConnectivityProvider() : super(){
    _connectivityStream = Stream.value(ParseConnectivityResult.wifi);
  }

  @override
  Future<ParseConnectivityResult> checkConnectivity() async{
    return ParseConnectivityResult.wifi;
  }

  Stream<ParseConnectivityResult> _connectivityStream;

  @override
  // TODO: implement connectivityStream
  Stream<ParseConnectivityResult> get connectivityStream => _connectivityStream;

}

initParse() async {
  Map<String, ParseObjectConstructor> subclassMap = {
    "Recipe" : () => Recipe(),
    "Receipt" : () => Receipt(),
    "Product" : () => Product(),
    "Price" : () => Price(),
    "Ingredient": () => Ingredient(),
    "Market" : () => Market(),
  };
  Future<ParseResponse> resp;
  if (const bool.fromEnvironment("DEBUG_SERVER")) {
    Parse server = await Parse().initialize("ABCDEFG",
        kIsWeb || !Platform.isAndroid ? "http://localhost:13371/" : "http://10.0.2.2:13371/",
        appName: "hrp",
        appVersion: "Version 1",
        appPackageName: "com.mabenan.hrp",
        coreStore: await CoreStoreSharedPrefsImp.getInstance(),
        debug: true,
        autoSendSessionId: true,
        registeredSubClassMap: subclassMap,
        connectivityProvider: !kIsWeb && Platform.isWindows ? WindowsParseConnectivityProvider() : null,
        liveQueryUrl:
        kIsWeb || !Platform.isAndroid ? "http://localhost:13371/" : "http://10.0.2.2:13371/");
    resp = server.healthCheck();
  } else {
    Parse server = await Parse().initialize(
        "VZVLcsw29sjuF0QHui7v", "http://node:13391/",
        appName: "hrp",
        appVersion: "Version 1",
        appPackageName: "com.mabenan.hrp",
        coreStore: await CoreStoreSharedPrefsImp.getInstance(),
        debug: false,
        autoSendSessionId: true,
        registeredSubClassMap: subclassMap,
        liveQueryUrl: "http://node:13371/");
    resp = server.healthCheck();
    var resp2 = await resp;
    if (!resp2.success) {
      server = await Parse().initialize(
          "VZVLcsw29sjuF0QHui7v", "https://audiobook.mabenan.de/",
          appName: "hrp",
          appVersion: "Version 1",
          appPackageName: "com.mabenan.hrp",
          coreStore: await CoreStoreSharedPrefsImp.getInstance(),
          debug: false,
          autoSendSessionId: true,
          registeredSubClassMap: subclassMap,
          liveQueryUrl: "https://hrp.mabenan.de/");
      resp = server.healthCheck();
    }
  }
}
