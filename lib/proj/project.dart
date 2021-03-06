import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyProj extends StatefulWidget {
  MyProj({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyProj();
}

class _MyProj extends State<MyProj> {
  String _selectedItem;
  String _currentItem;
  DateTime _currentTime;
  Position _currentLocation;
  DocumentReference _documentRef;

  List<DropdownMenuItem<String>> _dropDownMenuItems;
  @override
  void initState() {
    super.initState();
    _currentItem = 'initial';
    _currentTime = DateTime.now();
    _initialSelectItem();
  }

  Future _initialSelectItem() async {
    var snapshot =
        await Firestore.instance.collection("consumetype").getDocuments();
    _dropDownMenuItems = snapshot.documents
        .map((f) => DropdownMenuItem<String>(
              child: Text(f['name']),
              value: f.documentID,
            ))
        .toList();
    if (this.mounted)
      setState(() {
        _selectedItem = _dropDownMenuItems[0].value;
        _currentItem = _dropDownMenuItems[0].value;
      });
  }

  void changedDropDownItem(String selected) {
    if (this.mounted)
      setState(() {
        _selectedItem = selected;
      });
  }

  Future _onPress() async {
    _getLocation();
    if (_currentItem != _selectedItem) {
      if (this.mounted)
        setState(() {
          _currentItem = _selectedItem;
          _currentTime = DateTime.now();
        });
      if (_documentRef != null) {
        Firestore.instance.runTransaction((transaction) async {
          DocumentSnapshot freshSnap = await transaction.get(_documentRef);
          await transaction
              .update(freshSnap.reference, {'endtime': _currentTime});
        });
      }
      if (_currentLocation != null)
        Firestore.instance.collection('consumerecords').add({
          'name': _currentItem,
          'starttime': _currentTime,
          'location': {
            'latitude': _currentLocation.latitude,
            'longitude': _currentLocation.longitude,
          },
        }).then((docRef) => _documentRef = docRef);
    } else
      _currentItem = _selectedItem;
  }

  Future _getLocation() async {
    _currentLocation =
        await Geolocator().getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('项目'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _currentLocation == null
                ? Text('empty')
                : Container(
                    child: Column(
                      children: <Widget>[
                        Text(_currentLocation.latitude.toString()),
                        Text(_currentLocation.longitude.toString()),
                      ],
                    ),
                  ),
            Text(_currentTime.toString()),
            Text(_currentItem),
            Text("请选择你的项目: "),
            Container(
              padding: EdgeInsets.all(16.0),
            ),
            _dropDownMenuItems == null
                ? Container(
                    child: Text('Loading...'),
                  )
                : DropdownButton(
                    value: _selectedItem,
                    items: _dropDownMenuItems,
                    onChanged: changedDropDownItem,
                  ),
            RaisedButton(
              onPressed: _onPress,
              child: Text('添加'),
            )
          ],
        ),
      ),
    );
  }
}
