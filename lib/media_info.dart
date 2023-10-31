import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

// ignore: must_be_immutable
class MediaInfo extends StatefulWidget {
  MediaInfo({super.key, required this.videoTrack});

  MediaStreamTrack videoTrack;
  String _mediaInfo = '';
  Image? _screenshot;
  Timer? _timer;

  @override
  State<MediaInfo> createState() => _MediaInfoState();
}

class _MediaInfoState extends State<MediaInfo> {
  @override
  initState() {
    super.initState();

    _getInfo();
    // Check the media stats periodically
    widget._timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _getInfo();
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    widget._timer?.cancel();
  }

  _getInfo() {
    final trackSettings = widget.videoTrack.getSettings();
    print(widget.videoTrack);
    // Rprint(widget.videoTrack.);
    print(trackSettings);
    widget._mediaInfo = """
          width: ${trackSettings['width']}
          height: ${trackSettings['height']}
          frameRate: ${trackSettings['frameRate']}
          resizeMode: ${trackSettings['resizeMode']}
        """;
    widget.videoTrack.captureFrame().then((frame) {
      setState(() {
        widget._screenshot = Image.memory(frame.asUint8List());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(
        widget._mediaInfo,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 24),
      if (widget._screenshot != null) SizedBox(width: 160, child: widget._screenshot!)
    ]);
  }
}
