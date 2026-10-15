import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every floor outline has the same fill, so selected floors highlight alike', () {
    final fills = <String>{};
    for (var i = 1; i <= 7; i++) {
      final svg = File('assets/images/building/floor_outline_$i.svg').readAsStringSync();
      fills.add(RegExp(r'fill="[^"]+" fill-opacity="[^"]+"').firstMatch(svg)!.group(0)!);
    }
    expect(fills, {'fill="#F28D43" fill-opacity="0.03"'});
  });
}
