import 'package:delpack/image/textService/imageTextService.dart';
import "package:test/test.dart";

void main() {
  test('isValidName - return valid name', () {
    final ImageTextService imageTextService = new ImageTextService();
    bool res = imageTextService.isValidName('team delpack');
    expect(res, true);

    res = imageTextService.isValidName('team delpack/');
    expect(res, false);

    res = imageTextService.isValidName('t');
    expect(res, false);

    res = imageTextService.isValidName('team');
    expect(res, true);

    res = imageTextService.isValidName('team»');
    expect(res, false);

    res = imageTextService.isValidName('        team            ');
    expect(res, true);
  });
}
