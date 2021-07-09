
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class Recipe extends ParseObject {
  Recipe() : super("Recipe");
  Recipe.clone() : this();

  @override
  clone(Map map) => Recipe.clone()..fromJson(map);

  String get name => get<String>("Name");

  set name(String name) => set<String>("Name", name);

}
