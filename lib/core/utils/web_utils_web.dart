import 'dart:html' as html;
import 'dart:convert';

void downloadCsv(String csvString, String filename) {
  final bytes = utf8.encode(csvString);
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();

  html.Url.revokeObjectUrl(url);
}
