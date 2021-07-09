

import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class Ingredient extends ParseObject {
  Ingredient() : super("Ingredient");
  Ingredient.clone() : this();

  @override
  clone(Map map) => Ingredient.clone()..fromJson(map);
  String get name => get<String>("Name");

  set name(String name) => set<String>("Name", name);

}