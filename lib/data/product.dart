
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class Product extends ParseObject {
  Product() : super("Product");
  Product.clone() : this();

  @override
  clone(Map map) => Product.clone()..fromJson(map);
  String get name => get<String>("Name", defaultValue: "");

  set name(String name) => set<String>("Name", name);



}
