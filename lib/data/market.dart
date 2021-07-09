import 'package:flutter/src/services/text_input.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class Market extends ParseObject {


  Market() : super("Market");
  Market.clone() : this();

  @override
  clone(Map map) => Market.clone()..fromJson(map);

  String get name => get<String>("Name");

  set name(String name) => set<String>("Name", name);

  String get interpretation => get<String>("Interpretation");

  set interpretation(String interpretation) =>
      set<String>("Interpretation", interpretation);
}