import 'package:hrp/data/product.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class Price extends ParseObject {
  Price() : super("Price");
  Price.clone() : this();

  @override
  clone(Map map) => Price.clone()..fromJson(map);

  bool get needsManualIntervention => get<bool>("NeedsManualIntervention");

  set needsManualIntervention(bool needsManualIntervention) =>
      set<bool>("NeedsManualIntervention", needsManualIntervention);
  String get name => get<String>("Name");

  set name(String name) => set<String>("Name", name);

  double get costs => get<double>("Costs", defaultValue: 0.0);

  set costs(double price) => set<double>("Costs", price);

  Product get product => get<Product>("Product", defaultValue: new Product());

  set product(Product product) => set<Product>("Product", product);
}
