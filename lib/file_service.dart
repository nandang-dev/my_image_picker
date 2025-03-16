import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

typedef OnUploadProgressCallback = void Function(int sentBytes, int totalBytes);

class FileServiceUtil {
  // static String baseUrl = ;
  static Future<String> fileUploadMultipart({
    required File file,
    required String url,
    String? description,
    String field = "media",
    String? token,
    String descriptionField = "description",
    Map<String, String>? header,
    required bool useDescriptionFieldAsQuery,
    Map<String, String> queryParam = const {},
    OnUploadProgressCallback? onUploadProgress,
  }) async {
    Uri uri = Uri.parse(url).replace(queryParameters: queryParam);

    var request = http.MultipartRequest("POST", uri);

    request.files.add(await http.MultipartFile.fromPath(field, file.path));

    if (useDescriptionFieldAsQuery && description != null) {
      request.fields[descriptionField] = description;
    }

    // Tambahkan header jika ada
    if (token != null && token.isNotEmpty) {
      request.headers[HttpHeaders.authorizationHeader] = token;
    }

    if (header != null) {
      request.headers.addAll(header);
    }

    //add header content type
    request.headers[HttpHeaders.contentTypeHeader] = "multipart/form-data";

    debugPrint("Uploading to: ${request.url}");
    debugPrint("Headers: ${request.headers}");
    debugPrint("Fields: ${request.fields}");
    debugPrint("Files: ${request.files.map((f) => f.filename).toList()}");

    var response = await request.send();

    if (response.statusCode ~/ 100 != 2) {
      throw Exception(
          'Error uploading file, Status code: ${response.statusCode}');
    } else {
      return await response.stream.bytesToString();
    }
  }

  static Future<String> readResponseAsString(HttpClientResponse response) {
    var completer = Completer<String>();
    var contents = StringBuffer();
    response.transform(utf8.decoder).listen((String data) {
      contents.write(data);
    }, onDone: () => completer.complete(contents.toString()));
    return completer.future;
  }
}
