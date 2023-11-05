import 'dart:async';
import 'dart:io';

import 'package:downloadpad_sandbox/download_dialog.dart';
import 'package:downloadpad_sandbox/downloadpad.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:path_provider/path_provider.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({Key? key}) : super(key: key);

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  String image = "";
  bool isOkVisible = false;
  late StreamSubscription<List<int>> streamSubscription;
  double? progress = 0;
  String status = "0%";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "Downloader",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                String url =
                    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
                Directory path = await getApplicationDocumentsDirectory();
                String dir = path.path;
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (BuildContext context) {
                    return DownloadDialog(url: url, path: dir,

                    ); // Example progress value
                  },
                );
              },
              style: ButtonStyle(
                  backgroundColor: MaterialStateColor.resolveWith(
                      (states) => Colors.green)),
              child: const Text(
                "Download",
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<String> getPath() async {
    Directory _path = await getApplicationDocumentsDirectory();
    String _localPath = _path.path + Platform.pathSeparator + 'Attachments';
    final savedDir = Directory(_localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
    var path = _localPath;

    return path;
  }

  String getFileExt(String? fileUrl) {
    int lastDotIndex = fileUrl!.lastIndexOf('.');
    if (lastDotIndex != -1) {
      String ext = fileUrl.substring(lastDotIndex + 1).toLowerCase();
      return (ext == "pptx" || ext == "ppt") ? "pdf" : ext;
    } else {
      return ''; // No file extension found
    }
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

    File downloadedFile = File('$dir/$url');
    if (await downloadedFile.exists()) {
      Navigator.of(context).pop();
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
            filePath = '$dir/$url';

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

  void startDownload() async {
    // String url = "https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885__480.jpg";
    String url = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
    Directory path = await getApplicationDocumentsDirectory();
    String dir = path.path;
    DownloadPad.downloadFile(url, "my_file", dir);
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
