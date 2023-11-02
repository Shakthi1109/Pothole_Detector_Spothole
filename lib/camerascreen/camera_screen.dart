import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../previewscreen/preview_screen.dart';
import 'package:file_picker/file_picker.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() {
    return _CameraScreenState();
  }
}

class _CameraScreenState extends State {
  CameraController controller;
  List cameras;
  int selectedCameraIdx;
  String imagePath;
  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;

      if (cameras.length > 0) {
        setState(() {
          selectedCameraIdx = 0;
        });

        _initCameraController(cameras[selectedCameraIdx]).then((void v) {});
      } else {
        print("No camera available");
      }
    }).catchError((err) {
      print('Error: $err.code\nError Message: $err.message');
    });
  }

  Future _initCameraController(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }

    controller = CameraController(cameraDescription, ResolutionPreset.high);

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (controller.value.hasError) {
        print('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  BoxDecoration myBoxDecoration() {
    return BoxDecoration(
      border: Border.all(
        width: 15,
        color: Colors.green[600],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: new IconButton(
            icon: new Icon(Icons.search),
            onPressed: () {},
          ),
          title: const Text(
            'Spothole',
            style: TextStyle(fontSize: 30, fontFamily: "Righteous"),
          ),
          backgroundColor: Colors.green[600],
        ),
        body: Container(
          //decoration: myBoxDecoration(),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: _cameraPreviewWidget(),
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Stack(
          children: <Widget>[
            Align(
              alignment: FractionalOffset(0.1, 0.99),
              child: new FloatingActionButton(
                  heroTag: "Switch",
                  child: _cameraTogglesRowWidget(),
                  backgroundColor: Colors.green[600],
                  onPressed: () {
                    _onSwitchCamera();
                  }),
            ),
            Align(
                alignment: FractionalOffset(0.5, 0.99),
                child: SizedBox(
                  width: 75.0,
                  height: 75.0,
                  child: new FloatingActionButton(
                      heroTag: "Capture",
                      child: Icon(Icons.camera, size: 60),
                      backgroundColor: Colors.green[600],
                      onPressed: () {
                        _onCapturePressed(context);
                      }),
                )),
            Align(
              alignment: FractionalOffset(0.9, 0.99),
              child: new FloatingActionButton(
                  heroTag: "File Pick",
                  child: Icon(Icons.add, size: 30),
                  backgroundColor: Colors.green[600],
                  onPressed: () {
                    _onFilePressed(context);
                  }),
            ),
          ],
        ));
  }

  /// Display Camera preview.
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Loading',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: CameraPreview(controller),
    );
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).
  Widget _cameraTogglesRowWidget() {
    if (cameras == null || cameras.isEmpty) {
      return Icon(Icons.sync_disabled, size: 40);
    } else
      return Icon(Icons.sync, size: 40);
  }

  void _onSwitchCamera() {
    selectedCameraIdx =
        selectedCameraIdx < cameras.length - 1 ? selectedCameraIdx + 1 : 0;
    CameraDescription selectedCamera = cameras[selectedCameraIdx];
    _initCameraController(selectedCamera);
  }

  void _onFilePressed(context) async {
    String path = await FilePicker.getFilePath(type: FileType.IMAGE);
    print(path);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewImageScreen(imagePath: path),
      ),
    );
  }

  void _onCapturePressed(context) async {
    // Take the Picture in a try / catch block. If anything goes wrong,
    // catch the error.
    try {
      // Attempt to take a picture and log where it's been saved
      final path = join(
        // In this example, store the picture in the temp directory. Find
        // the temp directory using the `path_provider` plugin.
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.png',
      );
      print(path);
      await controller.takePicture(path);

      // If the picture was taken, display it on a new screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewImageScreen(imagePath: path),
        ),
      );
    } catch (e) {
      // If an error occurs, log the error to the console.
      print(e);
    }
  }

  void _showCameraException(CameraException e) {
    String errorText = 'Error: ${e.code}\nError Message: ${e.description}';
    print(errorText);

    print('Error: ${e.code}\n${e.description}');
  }
}
