import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/api/api_client.dart';

void main() {
  test(
    'alamat API selalu berakhir dengan garis miring; kosong tetap kosong',
    () {
      expect(
        withTrailingSlash('http://10.0.0.2:8001/api/v1'),
        'http://10.0.0.2:8001/api/v1/',
      );
      expect(
        withTrailingSlash('http://10.0.0.2:8001/api/v1/'),
        'http://10.0.0.2:8001/api/v1/',
      );
      expect(withTrailingSlash(''), '');
    },
  );
}
