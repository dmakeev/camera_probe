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
  late RTCVideoRenderer renderer;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  @override
  initState() {
    super.initState();

    navigator.mediaDevices.getUserMedia({'audio': true, 'video': true}).then((stream) {
      stream.getTracks().forEach((track) => track.stop());
    }).catchError((error, st) {
      print('NO CAMERA PERMISSIONS?: $error');
      print(error);
      print(st);
    });

    // Init video renderer
    widget.renderer = RTCVideoRenderer();
    widget.renderer.initialize();

    // Check the device list periodically
    Timer.periodic(const Duration(seconds: 3), (timer) {
      navigator.mediaDevices.enumerateDevices().then((deviceList) {
        // Print all devices
        // deviceList.forEach((device) => print(device.kind));
        // Get only video input devioces
        deviceList.retainWhere((device) => device.kind == 'videoinput');
        // Print all filtered video devices
        // deviceList.forEach((device) => print(device.kind));
        // Check if the device list is changed
        final oldDevices = widget.cameraList.map((d) => d.deviceId).toList();
        oldDevices.sort();
        final newDevices = deviceList.map((d) => d.deviceId).toList();
        newDevices.sort();
        final equal = oldDevices.equals(newDevices);
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

    navigator.mediaDevices.getUserMedia(mediaConstraints).then((stream) {
      final track = stream.getTracks().first;
      print(
          'Setting video track: id: ${track.id},  kind: ${track.kind}, enabled: ${track.enabled} , muted: ${track.muted}');
      widget.stream = stream;
      widget.renderer.srcObject = stream;
      widget.renderer.setSrcObject(stream: stream, trackId: track.id);

      setState(() {});
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
            const SizedBox(height: 24),
            SizedBox(
                width: 320,
                height: 240,
                child: RTCVideoView(
                  widget.renderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  filterQuality: FilterQuality.none,
                  placeholderBuilder: (BuildContext context) {
                    return Container(
                      color: Colors.grey,
                      child: const Center(
                        child: Text('Waiting for the video...'),
                      ),
                    );
                  },
                )),
            if (widget.stream != null) ...[
              const SizedBox(height: 24),
              MediaInfo(videoTrack: widget.stream!.getVideoTracks().first)
            ],
          ],
        ),
      ),
    );
  }
}
