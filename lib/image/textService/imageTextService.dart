import 'package:googleapis/vision/v1.dart';

class ImageTextService {
  Set<String> getNamesCandidates(AnnotateImageResponse r) {
    Set<String> validName = new Set();

    r.textAnnotations.forEach((txt) {
      String text = txt.description;

      if (isValidName(text)){
        validName.add(text);
      }

    });

    return validName;
  }

  bool isValidName(String text) {

    if (text.split(' ').length > 5 || text.length < 2) {
     return false;
    }

    Set<String> set = RegExp(".*[0-9]|/|».*").allMatches(text).map((match) => match.groupCount > 0 ? match[0] : "").toSet();
    return set.length == 0;
  }
}