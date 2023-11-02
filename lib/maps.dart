import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'dart:async';
import 'package:android_intent/android_intent.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:sensors/sensors.dart';
import 'package:http/http.dart';

class UserLocation {
  final double latitude;
  final double longitude;
  UserLocation({this.latitude, this.longitude});
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

const kGoogleApiKey = "AIzaSyB_MtrznQkOlUtyVrTWwLSPezdq2Vd0jNc";

GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  final myController = TextEditingController();
  var location = loc.Location();
  UserLocation _currentLocation;
  int _count = 0, yStore = 0;
  StreamSubscription stream;
  bool isTracking = false;

  void _add(lat, long) async {
    _count = _count + 1;
    var markerIdVal = _count.toString();
    final MarkerId markerId = MarkerId(markerIdVal);
    // creating a new MARKER
    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(lat, long),
      infoWindow: InfoWindow(
          title: markerIdVal, snippet: 'This is Position Number $markerIdVal'),
      onTap: () {
        //_onMarkerTapped(markerId);
      },
    );
    setState(() {
      // adding a new marker to map
      markers[markerId] = marker;
    });
    final GoogleMapController controller = await _controller.future;
    CameraPosition currentLoc =
        CameraPosition(target: LatLng(lat, long), zoom: 14);
    controller.animateCamera(CameraUpdate.newCameraPosition(currentLoc));
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    UserLocation currLoc = await getLocation();
    _add(currLoc.latitude, currLoc.longitude);
    CameraPosition currentLoc = CameraPosition(
        target: LatLng(currLoc.latitude, currLoc.longitude),
        zoom: 19.151926040649414);
    controller.animateCamera(CameraUpdate.newCameraPosition(currentLoc));
  }

  Future<UserLocation> getLocation() async {
    try {
      var userLocation = await location.getLocation();
      _currentLocation = UserLocation(
          latitude: userLocation.latitude, longitude: userLocation.longitude);
    } on Exception catch (e) {
      print('Could not get location: ${e.toString()}');
    }
    return _currentLocation;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(21.5, 81.5),
    zoom: 4.5,
  );

  Future<Null> displayPrediction(Prediction p) async {
    if (p != null) {
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId);

      var placeId = p.placeId;
      double lat = detail.result.geometry.location.lat;
      double lng = detail.result.geometry.location.lng;

      _add(lat, lng);
    }
  }

  void _drive() async {
    String origin =
        "${markers[MarkerId("1")].position.latitude.toString()},${markers[MarkerId("1")].position.longitude.toString()}"; // lat,long like 123.34,68.56
    String destination =
        "${markers[MarkerId("2")].position.latitude.toString()},${markers[MarkerId("2")].position.longitude.toString()}";
    final AndroidIntent intent = new AndroidIntent(
        action: 'action_view',
        data: Uri.encodeFull("https://www.google.com/maps/dir/?api=1&origin=" +
            origin +
            "&destination=" +
            destination +
            "&travelmode=driving&dir_action=navigate"),
        package: 'com.google.android.apps.maps');
    int val = 0;
    bool flag = false;
    bool upflag = false;
    bool flag2 = false;
    setState(() {
      isTracking = true;
    });
    StreamSubscription events =
        userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      int yVal = event.y.round();
      if (yVal <= -5) {
        val = yVal;
        flag = true;
        new Future.delayed(Duration(milliseconds: 1000), () {
          flag = false;
        });
      }
      if (flag) {
        if (yVal >= (val + 2).abs()) {
          //print('going down');
          flag = false;
          upflag = true;
          new Future.delayed(Duration(milliseconds: 1500), () {
            upflag = false;
          });
        }
      }

      if (upflag) {
        int yVal2 = event.y.round();
        if (yVal2 >= 5) {
          val = yVal2;
          flag2 = true;
          new Future.delayed(Duration(milliseconds: 1000), () {
            flag2 = false;
          });
        }
        if (flag2) {
          if (yVal2 <= (val - 2) * -1) {
            print('pothole detected');
            onPotholeDetect();
            flag2 = false;
            upflag = false;
          }
        }
      }
    });
    setState(() {
      stream = events;
      isTracking = true;
    });
    intent.launch();
  }

  void onPotholeDetect() async {
    loc.LocationData detectedLocation = await location.getLocation();
    Map<String, String> headers = {"Content-type": "application/json"};
    String json =
        '{"lat": "${detectedLocation.latitude.toString()}", "long": "${detectedLocation.longitude.toString()}"}';
    // make POST request
    Response response = await post(
        "https://server.v16.now.sh/api/location/create",
        headers: headers,
        body: json);
    // check the status code for the result
    int statusCode = response.statusCode;
    //print(json);
    print(statusCode);
    //print(statusCode);
    // this API passes back the id of the new item added to the body
  }

  void killPotholeTracker() {
    stream.cancel();
    setState(() {
      isTracking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: Stack(
          alignment: AlignmentDirectional.topCenter,
          children: <Widget>[
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _kGooglePlex,
              markers: Set<Marker>.of(markers.values),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
          ],
        ),
        floatingActionButton: Stack(
          children: <Widget>[
            Align(
                alignment: Alignment.bottomCenter,
                child: Transform.scale(
                  scale: 1.1,
                  child: isTracking
                      ? FloatingActionButton(
                          onPressed: killPotholeTracker,
                          child: Icon(Icons.close),
                          backgroundColor: Colors.teal)
                      : FloatingActionButton(
                          onPressed: _drive,
                          child: Icon(Icons.directions_car),
                          backgroundColor: Colors.teal),
                )),
            Align(
              alignment: Alignment.bottomLeft,
              child: SpeedDial(
                animatedIcon: AnimatedIcons.menu_close,
                children: [
                  SpeedDialChild(
                      child: Icon(Icons.my_location),
                      label: "Current Location",
                      onTap: _goToTheLake),
                  SpeedDialChild(
                      child: Icon(Icons.cancel),
                      label: "Clear markers",
                      backgroundColor: Colors.teal,
                      onTap: () {
                        setState(() {
                          markers = <MarkerId, Marker>{};
                          _count = 0;
                        });
                      }),
                  SpeedDialChild(
                      child: Icon(Icons.near_me),
                      label: "Destination",
                      backgroundColor: Colors.red[600],
                      onTap: () async {
                        // show input autocomplete with selected mode
                        // then get the Prediction selected
                        Prediction p = await PlacesAutocomplete.show(
                            context: context, apiKey: kGoogleApiKey);
                        await displayPrediction(p);
                      }),
                  SpeedDialChild(
                      child: Icon(Icons.navigation),
                      label: "Source",
                      backgroundColor: Colors.green[400],
                      onTap: () async {
                        // show input autocomplete with selected mode
                        // then get the Prediction selected
                        Prediction p = await PlacesAutocomplete.show(
                            context: context, apiKey: kGoogleApiKey);
                        displayPrediction(p);
                      })
                ],
              ),
            ),
          ],
        ));
  }
}
