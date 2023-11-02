import 'package:flutter/material.dart';
import 'camerascreen/camera_screen.dart';
import 'view.dart';
import 'maps.dart';

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() {
    return _CameraAppState();
  }
}

class _CameraAppState extends State {
  int _currentIndex = 0;
  final List<Widget> _children = [CameraScreen(), MapSample(),View()];
  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
          body: _children[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex:
                _currentIndex, // this will be set when a new tab is tapped
            backgroundColor: Colors.green[600],
            selectedItemColor: Colors.white,
            onTap: onTabTapped,
            items: [
              BottomNavigationBarItem(
                icon: new Icon(Icons.search),
                title:
                    new Text('Spot', style: TextStyle(fontFamily: "Righteous")),
              ),
              BottomNavigationBarItem(
                icon: new Icon(Icons.directions_car),
                title: new Text('Drive',
                    style: TextStyle(fontFamily: "Righteous")),
              ),
              BottomNavigationBarItem(
                icon: new Icon(Icons.pin_drop),
                title: new Text('View',
                    style: TextStyle(fontFamily: "Righteous")),
              ),
            ],
          ),
        ),
        debugShowCheckedModeBanner: false);
  }
}

void main() => runApp(CameraApp());
