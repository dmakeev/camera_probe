import 'dart:async';

import 'package:camera_prober/media_info.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

// ignore: must_be_immutable
class CameraPage extends StatefulWidget {
  CameraPage({super.key});
  String? selectedCameraId;
  List<MediaDeviceInfo> cameraList = [];
  MediaStream? stream;
  RTCVideoRenderer renderer = RTCVideoRenderer();

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  @override
  initState() {
    super.initState();

    // Init video renderer
    widget.renderer.initialize();

    navigator.mediaDevices.getUserMedia({'audio': true, 'video': true}).then((stream) {
      stream.getTracks().forEach((track) => track.stop());
    }).catchError((error, st) {
      print('NO CAMERA PERMISSIONS?: $error');
      print(error);
      print(st);
    });

    final eq = const ListEquality().equals;
    // Check the device list periodically
    Timer.periodic(const Duration(seconds: 3), (timer) {
      navigator.mediaDevices.enumerateDevices().then((deviceList) {
        // deviceList.forEach((device) => print(device.kind));
        // Get only video input devioces
        deviceList.retainWhere((device) => device.kind == 'videoinput');
        // print('>>> 3');
        //print(deviceList);
        // Check if the device list is changed
        final equal = eq(widget.cameraList.map((d) => d.deviceId).toList(), deviceList.map((d) => d.deviceId).toList());
        if (!equal) {
          setState(() {
            widget.selectedCameraId = null;
            widget.cameraList = deviceList;
          });
        }
      });
    });
  }

  void _setVideoInput() {
    final mediaConstraints = <String, dynamic>{
      'audio': false,
      'video': {
        'deviceId': widget.selectedCameraId,
      }
    };

    Helper.openCamera(mediaConstraints).then((stream) {
      setState(() {
        widget.stream = stream;
        widget.renderer.srcObject = stream;
      });
    }).catchError((error, st) {
      print('GETTING VIDEO ERROR: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('How much is the fish'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            if (widget.cameraList.isNotEmpty)
              DropdownButton<String>(
                value: widget.selectedCameraId,
                icon: const Icon(Icons.arrow_downward),
                onChanged: (String? value) {
                  // This is called when the user selects an item.
                  setState(() {
                    widget.stream?.getTracks().forEach((track) => track.stop());
                    widget.stream = null;
                    widget.selectedCameraId = value;
                    _setVideoInput();
                  });
                },
                items: widget.cameraList.map<DropdownMenuItem<String>>((MediaDeviceInfo device) {
                  return DropdownMenuItem<String>(
                    value: device.deviceId,
                    child: Text(device.label),
                  );
                }).toList(),
              )
            else
              Text(
                'Camera list is loading...',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            if (widget.stream != null) ...[
              const SizedBox(height: 24),
              SizedBox(width: 320, height: 240, child: RTCVideoView(widget.renderer)),
              const SizedBox(height: 24),
              MediaInfo(videoTrack: widget.stream!.getVideoTracks().first)
            ],
          ],
        ),
      ),
    );
  }
}
