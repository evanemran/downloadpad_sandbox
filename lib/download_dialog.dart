import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class DownloadDialog extends StatefulWidget {
  const DownloadDialog({super.key, required this.url, required this.path});

  final String url;
  final String path;

  @override
  State<DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<DownloadDialog> {

  bool isOkVisible = false;
  late StreamSubscription<List<int>> streamSubscription;
  double? progress = 0;
  String status = "0%";
  double _width = 0;
  double _height = 0;
  double _vPosition = 0;
  double _hPosition = 0;
  final BorderRadiusGeometry _borderRadius = BorderRadius.circular(100);
  final Color _color = Colors.green;

  @override
  void initState() {
    downloadFile(widget.url, widget.path);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: AlertDialog(
        content: Wrap(
          children: [
            Center(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      "Downloading Attachment",
                      style:
                      TextStyle(color: Colors.blueAccent, fontSize: 20),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child:
                        progress==1 ?
                        Transform.translate(
                          offset: Offset(_hPosition, _vPosition),
                          child: Center(child: AnimatedContainer(

                            width: _width,
                            height: _height,
                            decoration: BoxDecoration(
                              color: _color,
                              borderRadius: _borderRadius,
                            ),
                            // Define how long the animation should take.
                            duration: const Duration(seconds: 3),
                            curve: Curves.bounceOut,
                            child: Row(children: [Expanded(child: Text("Complete!", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center,))],),
                          ),),)
                            : Text(
                          status,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                          color: Colors.black12,
                          value: 1,
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                          color: Colors.green,
                          value: progress,
                        ),
                      ),
                    ],
                  ),
                  // CircularProgressIndicator()
                ],
              ),
            )
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.red),
              )),
          TextButton(
              onPressed: () {
                if (isOkVisible) {
                  Navigator.of(context).pop();
                }
                else {
                  showToast("Please wait to complete download!");
                }
              },
              child: Text(
                "View",
                style: TextStyle(color: isOkVisible ? Colors.black : Colors.black12),
              ))
        ],
      ),
    );
  }

  String getFileExt(String? fileUrl) {
    int lastDotIndex = fileUrl!.lastIndexOf('.');
    if (lastDotIndex != -1) {
      String ext = fileUrl.substring(lastDotIndex + 1).toLowerCase();
      return ext;
    } else {
      return ''; // No file extension found
    }
  }

  String getFileNameFromUrl(String url) {
    List<String> segments = Uri.parse(url).pathSegments;
    String lastSegment = segments.last;
    String fileName = lastSegment.split('.').first;
    return fileName;
  }

  String removeFileExtension(String filePath) {
    // Find the last dot in the file path
    int lastDotIndex = filePath.lastIndexOf('.');

    if (lastDotIndex != -1) {
      // Remove the existing extension and append the new extension
      String newFilePath = filePath.substring(0, lastDotIndex);
      return newFilePath;
    } else {
      // No existing extension found, simply append the new extension
      return filePath;
    }
  }

  void downloadFile(String url, String path) async {
    var dir = path;
    File file;
    String filePath = "";
    String name = "${getFileNameFromUrl(url)}.${getFileExt(url)}";

    File downloadedFile = File('$dir/$name');
    if (await downloadedFile.exists()) {
      // Navigator.of(context).pop();
      showToast("File Already Exists!");
    } else {
      bool isNetworkAvailable = await InternetConnectionChecker().hasConnection;

      if (isNetworkAvailable) {
        try {
          Map<String, String> headers = {
            'Connection': 'Keep-Alive',
            'Keep-Alive': 'timeout=5'
          };
          var request = Request('GET', Uri.parse(url));
          request.headers.addAll(headers);
          StreamedResponse response = await Client().send(request);
          if (response.statusCode == 200) {
            final contentLength = response.contentLength;

            List<int> bytes = [];
            filePath = '$dir/$name';

            streamSubscription = response.stream.listen(
                  (newBytes) {
                bytes.addAll(newBytes);
                final downloadedLength = bytes.length;
                setState(() {
                  progress = downloadedLength.toDouble() / (contentLength ?? 1);
                  status = "${((progress ?? 0) * 100).toStringAsFixed(0)}%";
                });
              },
              onDone: () async {
                    _width = 120;
                    _height = 120;
                file = File(filePath);
                await file.writeAsBytes(bytes);
                setState(() {
                  progress = 1;
                  status = "100%";
                  isOkVisible = true;
                });
              },
              onError: (error) {
                Navigator.of(context).pop();
                showToast("Download Cancelled!");
              },
              cancelOnError: true,
            );
          } else {
            filePath = 'Error code: ' + response.statusCode.toString();
            Navigator.of(context).pop();

            showToast("Download Failed!");
          }
        } catch (ex) {
          filePath = 'Can not fetch url';
          Navigator.of(context).pop();

          showToast("Can not fetch url");
        }
      } else {
        Navigator.of(context).pop();
        showToast("Please connect to internet!");
      }
    }
  }

  void showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16.0);
  }
}
