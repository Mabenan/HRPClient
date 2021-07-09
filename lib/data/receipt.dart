

import 'package:hrp/data/market.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class Receipt extends ParseObject {
  Receipt() : super("Receipt");
  Receipt.clone() : this();

  ParseFileBase get image => get<ParseFileBase>("Image");

  set image(ParseFileBase image) => set<ParseFileBase>("Image", image);

  Market get market => get<Market>("Market");

  set market(Market market) => set<Market>("Market", market);

  @override
  clone(Map map) => Receipt.clone()..fromJson(map);
  String get name => get<String>("Name");

  set name(String name) => set<String>("Name", name);
}
