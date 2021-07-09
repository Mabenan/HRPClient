import 'dart:io' as io;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hrp/data/market.dart';
import 'package:hrp/data/price.dart';
import 'package:hrp/data/receipt.dart';
import 'package:hrp/pricesToAdjust.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:rxdart/rxdart.dart';
import 'package:searchfield/searchfield.dart';
import 'globals.dart' as globals;

class ReceiptsWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ReceiptsWidgetState();
}

class ReceiptsWidgetState extends State<ReceiptsWidget> {
  final QueryBuilder<Receipt> query =
      (QueryBuilder<Receipt>(Receipt())..orderByAscending("Name"));
  final LiveQuery liveQuery = LiveQuery(autoSendSessionId: true);
  Subscription<Receipt> sub;
  List<Receipt> _receipts;

  ReceiptsWidgetState() : super() {
    this.init();
  }

  init() async {
    sub = await liveQuery.client.subscribe(query);
    sub.on(LiveQueryEvent.create, (value) {
      getData();
    });
    sub.on(LiveQueryEvent.delete, (Receipt value) {
      getData();
    });
    sub.on(LiveQueryEvent.update, (Receipt value) {
      getData();
    });
    _marketSearchController.addListener(() async {
      if (_marketSearchController.text != null &&
          _marketSearchController.text != "") {
        var prodResp = await (QueryBuilder<Market>(Market())
              ..whereEqualTo("Name", _marketSearchController.text))
            .query();
        if (prodResp.success && prodResp.result != null) {
          Market prod = prodResp.result.first as Market;
          _market.add(prod);
          _showCreateMarket.add(false);
        } else {
          _showCreateMarket.add(true);
        }
      } else {
        _showCreateMarket.add(false);
      }

      if (name.text != "" && _market.value != null && file != null) {
        _canCreate.add(true);
      } else {
        _canCreate.add(false);
      }
    });
    name.addListener(() {
      if (name.text != "" && _market.value != null && file != null) {
        _canCreate.add(true);
      } else {
        _canCreate.add(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    globals.setTitle("Receipts");
    globals.setActualFloatingActionHandler(() async {
      showDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel:
              MaterialLocalizations.of(context).modalBarrierDismissLabel,
          barrierColor: Colors.black45,
          builder: buildCreateDialog);
    });
    if (_receipts == null) {
      getData();
    }
    return Container(
      child: _receipts != null
          ? _receipts.length == 0
              ? Container()
              : getList(context)
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  getList(BuildContext context) {
    return RefreshIndicator(
        child: ListView.builder(
          itemCount: _receipts.length,
          itemBuilder: (BuildContext context, int index) {
            return buildChilds(context, _receipts.elementAt(index));
          },
        ),
        onRefresh: getData);
  }

  Future<void> getData() async {
    print("refresh");
    var result = (await query.query());
    setState(() {
      _receipts = result.results != null
          ? List<Receipt>.from(result.results.map((e) => e as Receipt))
          : List<Receipt>.empty(growable: true);
    });
  }

  buildChilds(BuildContext context, Receipt elementAt) {
    if (elementAt.objectId != null) {
      return GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, "sub/pricesToAdjust",
              arguments: new PriceToAdjustRouteArguments(receipt: elementAt));
        },
        child: Card(
          child: ListTile(
              title: Text(elementAt.name),
              trailing: FutureBuilder<ParseResponse>(
                future: (QueryBuilder(Price())
                      ..whereRelatedTo("Prices", "Receipt", elementAt.objectId))
                    .query(),
                builder: (context, snapshot) {
                  if (snapshot.data != null) {
                    if (snapshot.data.success) {
                      if (snapshot.data.results != null) {
                        return snapshot.data.results
                                    .where((element) => (element as Price)
                                        .needsManualIntervention)
                                    .length ==
                                0
                            ? Icon(Icons.check)
                            : Icon(Icons.error_outline);
                      } else {
                        return Icon(Icons.check);
                      }
                    } else {
                      return CircularProgressIndicator();
                    }
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              )),
        ),
      );
    } else {
      return Card(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }

  TextEditingController name = TextEditingController();
  final TextEditingController _marketSearchController = TextEditingController();
  final BehaviorSubject<bool> _showCreateMarket = BehaviorSubject<bool>();
  final BehaviorSubject<Market> _market = BehaviorSubject<Market>();
  final BehaviorSubject<bool> _canCreate = BehaviorSubject<bool>();
  ParseFileBase file;
  Widget buildCreateDialog(BuildContext cntxt) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(cntxt).size.width - 10,
        height: MediaQuery.of(cntxt).size.height - 80,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [Spacer(), CloseButton()],
            ),
            SizedBox(
              height: 20,
            ),
            TextField(
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Name',
                  hintText: 'Enter a name for the receipt'),
              controller: name,
            ),
            SizedBox(
              height: 20,
            ),
            FutureBuilder<ParseResponse>(
              future: (QueryBuilder<Market>(Market())).query(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data.success) {
                    return Row(
                      children: [
                        Expanded(
                          child: SearchField(
                            suggestions: snapshot.data.results != null
                                ? List.from(snapshot.data.results.map((e) {
                                    return (e as Market).name;
                                  }))
                                : [],
                            validator: (state) {
                              return null;
                            },
                            searchInputDecoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Market',
                              hintText: 'Please select or create an market',
                            ),
                            controller: _marketSearchController,
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        StreamBuilder<bool>(
                          stream: _showCreateMarket.stream,
                          initialData: false,
                          builder: (context, snapshot) {
                            if (snapshot.data) {
                              return Container(
                                width: 100,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    var prod = new Market();
                                    prod.name = _marketSearchController.text;
                                    prod = (await prod.save()).result;
                                    _market.add(prod);
                                    _showCreateMarket.add(false);
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
            SizedBox(
              height: 20,
            ),
            Container(
              height: 50,
              width: 250,
              decoration: BoxDecoration(
                  color: Colors.blue, borderRadius: BorderRadius.circular(20)),
              child: TextButton(
                onPressed: () async {
                  if (kIsWeb || io.Platform.isWindows) {
                    final typeGroup =
                        XTypeGroup(label: 'images', extensions: ['jpg', 'png']);
                    final result =
                        await openFile(acceptedTypeGroups: [typeGroup]);
                    if (result != null) {
                      if (kIsWeb) {
                        var bytes = await result.readAsBytes();
                        setState(() {
                          file = ParseWebFile(bytes, name: result.name);
                        });
                      } else {
                        setState(() {
                          file = ParseFile(new io.File(result.path));
                        });
                      }
                      if (name.text != "" &&
                          _market.value != null &&
                          file != null) {
                        _canCreate.add(true);
                      } else {
                        _canCreate.add(false);
                      }
                    } else {
                      // User canceled the picker
                    }
                  } else {
                    final image = await ImagePicker()
                        .getImage(source: ImageSource.camera);
                    if (image != null) {
                      setState(() {
                        file = ParseFile(new io.File(image.path));
                      });
                      if (name.text != "" &&
                          _market.value != null &&
                          file != null) {
                        _canCreate.add(true);
                      } else {
                        _canCreate.add(false);
                      }
                    } else {
                      // User canceled the picker
                    }
                  }
                },
                child: Text(
                  'Upload',
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            StreamBuilder(
                stream: _canCreate.stream,
                initialData: false,
                builder: (context, snapshot) {
                  return Container(
                    height: 50,
                    width: 250,
                    decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20)),
                    child: TextButton(
                      onPressed: snapshot.data
                          ? () {
                              Receipt receipt = new Receipt();
                              receipt.name = name.text;
                              receipt.image = file;
                              receipt.market = _market.value;
                              setState(() {
                                _receipts.add(receipt);
                              });
                              receipt.save();
                              Navigator.pop(cntxt, true);
                            }
                          : null,
                      child: Text(
                        snapshot.data ? 'Submit' : 'Please Fill Fields',
                      ),
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }
}
