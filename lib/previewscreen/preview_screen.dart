import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:location/location.dart';
import 'package:http/http.dart';

class PreviewImageScreen extends StatefulWidget {
  final String imagePath;
  PreviewImageScreen({this.imagePath});

  @override
  _PreviewImageScreenState createState() => _PreviewImageScreenState();
}

class UserLocation {
  final double latitude;
  final double longitude;
  UserLocation({this.latitude, this.longitude});
}

class _PreviewImageScreenState extends State<PreviewImageScreen> {
  final myController = TextEditingController();
  @override
  // void dispose() {
  //   // Clean up the controller when the widget is disposed.
  //   myController.dispose();
  //   super.dispose();
  // }

  UserLocation _currentLocation;
  var location = Location();
  final String url = "https://server.v16.now.sh/api/location/create";
  Future<UserLocation> getLocation() async {
    try {
      var userLocation = await location.getLocation();
      _currentLocation = UserLocation(
          latitude: userLocation.latitude, longitude: userLocation.longitude);
    } on Exception catch (e) {
      print('Could not get location: ${e.toString()}');
    }
    print(_currentLocation.latitude.toString() +
        ',' +
        _currentLocation.longitude.toString());
    return _currentLocation;
  }

  _makePostRequest(UserLocation userLocation) async {
    Map<String, String> headers = {"Content-type": "application/json"};
    String json =
        '{lat: "${userLocation.latitude}", long: "${userLocation.longitude}"}';
    // make POST request
    Response response = await post(url, headers: headers, body: json);
    // check the status code for the result
    int statusCode = response.statusCode;
    print(statusCode);
    if (statusCode == 400) {
      Fluttertoast.showToast(
          msg: "Request can't be Sent!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIos: 1,
          backgroundColor: Colors.grey,
          textColor: Colors.white,
          fontSize: 16.0);
    }
    //print(statusCode);
    // this API passes back the id of the new item added to the body
    //String body = response.body;
  }

  Future loadModel() async {
    String ress = await Tflite.loadModel(
        model: "assets/model.tflite",
        labels: "assets/labels.txt",
        numThreads: 1 // defaults to 1
        );
    print(ress);
  }

  void runModel(filepath) async {
    var recognitions = await Tflite.runModelOnImage(
      path: filepath, // required
      numResults: 2,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    print(recognitions[0]["label"]);
    if (recognitions[0]["label"].toString() == "0 Potholes") {
      getLocation().then((loc) {
        _makePostRequest(loc);
      });

      Fluttertoast.showToast(
          msg: "Sent",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIos: 2,
          backgroundColor: Colors.grey,
          textColor: Colors.white,
          fontSize: 16.0);
    } else if (recognitions[0]["label"].toString() == "1 Not Potholes") {
      Fluttertoast.showToast(
          msg: "Retry",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIos: 1,
          backgroundColor: Colors.grey,
          textColor: Colors.white,
          fontSize: 16.0);
    } else {
      Fluttertoast.showToast(
          msg: "Error",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIos: 1,
          backgroundColor: Colors.grey,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  FocusNode myFocusNode = new FocusNode();
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview'),
        backgroundColor: Colors.green[600],
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
                flex: 3,
                child: Image.file(File(widget.imagePath), fit: BoxFit.cover)),
            Flexible(
                //flex: 1,
                child: Center(
              child: ListView(children: <Widget>[
                Container(
                  padding: EdgeInsets.all(20.0),
                  child: TextFormField(
                      focusNode: myFocusNode,
                      controller: myController,
                      decoration: new InputDecoration(
                          labelText: "Enter Description",
                          fillColor: Colors.white,
                          labelStyle: TextStyle(color: Colors.green),
                          focusedBorder: new OutlineInputBorder(
                              borderSide: new BorderSide(color: Colors.green),
                              borderRadius: new BorderRadius.circular(20.0)),
                          contentPadding: const EdgeInsets.all(20.0),
                          border: new OutlineInputBorder(
                            borderRadius: new BorderRadius.circular(20.0),
                            borderSide: new BorderSide(color: Colors.green),
                          ))),
                ),
                Container(
                  padding:
                      EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
                  child: ButtonTheme(
                    height: 55.0,
                    child: RaisedButton(
                      color: Colors.green[300],
                      textColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0)),
                      onPressed: () {
                        runModel(widget.imagePath);
                        print(myController.text);
                        //TODO: feed img model.
                      },
                      child: Text('Report Pothole'),
                    ),
                  ),
                )
              ]),
            )),
          ],
        ),
      ),
    );
  }
}
