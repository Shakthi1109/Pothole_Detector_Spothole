import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'dart:async';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserLocation {
  final double latitude;
  final double longitude;
  UserLocation({this.latitude, this.longitude});
  factory UserLocation.fromJson(dynamic json) {
    return UserLocation(
        latitude: json['lat'] as double, longitude: json['long'] as double);
  }
}

class View extends StatefulWidget {
  @override
  State<View> createState() => ViewState();
}

const kGoogleApiKey = "AIzaSyB_MtrznQkOlUtyVrTWwLSPezdq2Vd0jNc";

GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

class ViewState extends State<View> {
  Completer<GoogleMapController> _controller = Completer();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  final myController = TextEditingController();
  var location = loc.Location();
  UserLocation _currentLocation;
  int _count = 0;

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

  Future<http.Response> fetchPost() async {
    final response =
        await http.get('https://server.v16.now.sh/api/location/getholes');
    print(response.body);
    var x = jsonDecode(response.body)['holes'] as List;
    List<UserLocation> locList =
        x.map((doc) => UserLocation.fromJson(doc)).toList();
    locList.forEach((e) => _add(e.latitude, e.longitude));
    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON.
      print('Success');
//      JSONObject json = (JSONObject) JSONSerializer.toJSON(data);
//      double latPin = json.getDouble( "lat" );
//      double longPin = json.getDouble( "long" );
//
//      print(latPin);
//      print(longPin);

    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to load post');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPost();
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
