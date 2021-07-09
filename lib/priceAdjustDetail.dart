import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrp/data/price.dart';
import 'package:hrp/data/product.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:rxdart/rxdart.dart';
import 'package:searchfield/searchfield.dart';

class PriceAdjustDetailArguments {
  final Price price;

  PriceAdjustDetailArguments({this.price});
}

class PriceAdjustDetail extends StatefulWidget {
  final Price price;

  PriceAdjustDetail({key, this.price}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PriceAdjustDetailState(this.price);
}

class _PriceAdjustDetailState extends State<PriceAdjustDetail> {
  final Price price;

  final TextEditingController _priceCostsController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _productSearchController =
      TextEditingController();

  final BehaviorSubject<bool> _showCreateProduct = BehaviorSubject<bool>();

  _PriceAdjustDetailState(this.price) {
    Product()
        .getObject(
            price.product.objectId)
        .then((value) {
      setState(() {
        _productController.text = value.result.name;
      });
    });
    _priceCostsController.text = price.costs.toString();
    _priceCostsController.addListener(() {
      price.costs = double.tryParse(_priceCostsController.text);
    });
    _productSearchController.addListener(() async {
      if (_productSearchController.text != null &&
          _productSearchController.text != "") {
        var prodResp = await (QueryBuilder<Product>(Product())
              ..whereEqualTo("Name", _productSearchController.text))
            .query();
        if (prodResp.success && prodResp.result != null) {
          Product prod = prodResp.result.first as Product;
          setProduct(prod);
          _showCreateProduct.add(false);
        } else {
          _showCreateProduct.add(true);
        }
      } else {
        _showCreateProduct.add(false);
      }
    });
  }

  void setProduct(Product prod) {
    price.product = prod;
    _productController.text = prod.name;
    (prod).save();
  }

  List<Widget> buildProductChoose(BuildContext context) {
    return <Widget>[
      TextField(
        controller: _productController,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Product',
          hintText: '',
        ),
        enabled: false,
        textInputAction: TextInputAction.next,
      ),
      FutureBuilder<ParseResponse>(
        future: () async {
          await Product().getObject(price
              .product.objectId);
          return await ((QueryBuilder(Product())
                ..whereRelatedTo("PossibleProducts", "Price", price.objectId))
              .query());
        }(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.success && snapshot.data.results != null) {
              var valuesQuery = snapshot.data.results.map((value) {
                if (value.objectId !=
                    price
                        .product.objectId) {
                  return new DropdownMenuItem<Product>(
                    value: value,
                    child: new Text(value.name),
                  );
                }
              }).where((element) => element != null);
              List<DropdownMenuItem<Product>> values =
                  List.empty(growable: true);
              if (price.product.objectId != "") {
                values = [
                  new DropdownMenuItem<Product>(
                    value: price.product,
                    child: new Text(price.product.name),
                  ),
                  ...(valuesQuery.toList())
                ];
              } else {
                values = valuesQuery.toList();
              }
              return DropdownButtonFormField<Product>(
                value: price.product,
                items: values,
                onChanged: (_) {
                  setState(() {
                    _productController.text = _.name;
                    price.product = _;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Most possible Products for Price: ",
                  hintText: 'Please first try to find fitting product here',
                ),
              );
            } else {
              return Container();
            }
          } else {
            return Container();
          }
        },
      ),
      FutureBuilder<ParseResponse>(
        future: (QueryBuilder<Product>(Product())
              ..whereDoesNotMatchKeyInQuery(
                  "objectId",
                  "objectId",
                  (QueryBuilder(Product())
                    ..whereRelatedTo(
                        "PossibleProducts", "Price", price.objectId))))
            .query(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.success) {
              return Row(
                children: [
                  Expanded(
                    child: SearchField(
                      suggestions: snapshot.data.results != null
                          ? List.from(snapshot.data.results.map((e) {
                              return (e as Product).name;
                            }))
                          : [],
                      validator: (state) {
                        return null;
                      },
                      searchInputDecoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Product',
                        hintText: 'Please select or create an product',
                      ),
                      controller: _productSearchController,
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  StreamBuilder<bool>(
                    stream: _showCreateProduct.stream,
                    initialData: false,
                    builder: (context, snapshot) {
                      if (snapshot.data) {
                        return Container(
                          width: 100,
                          child: ElevatedButton(
                            onPressed: () async {
                              var prod = new Product();
                              prod.name = _productSearchController.text;
                              prod = (await prod.save()).result;
                              setProduct(prod);
                              _showCreateProduct.add(false);
                            },
                            child: Text("Create"),
                          ),
                        );
                      } else {
                        return Container(
                          width: 100,
                        );
                      }
                    },
                  ),
                ],
              );
            } else {
              return Container();
            }
          } else {
            return Container();
          }
        },
      ),
      Container(
        width: 100,
        child: ElevatedButton(
          onPressed: () async {
            await price.save();
            Navigator.pop(context);
          },
          child: Text("Save"),
        ),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.only(left: 20, right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(price.name,
                style: Theme.of(context).primaryTextTheme.headline2),
            TextField(
              controller: _priceCostsController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Price',
                hintText: 'Enter the price with 2 decimal',
              ),
              textInputAction: TextInputAction.next,
            ),
          ]..addAll(buildProductChoose(context)),
        ),
      ),
    );
  }
}
