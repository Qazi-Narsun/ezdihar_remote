import 'package:flutter_test/flutter_test.dart';

import 'package:ezdihar_remote/data/building_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads building, floor and apartment data for every type', () async {
    final types = {for (final t in await BuildingType.loadAll()) t.type: t};
    expect(types.keys, ['A', 'B', 'C']);

    for (final t in types.values) {
      expect(t.floorDetails, hasLength(t.floors), reason: 'type ${t.type}');
      expect(t.floorDetails.first.code, 'GF');
      expect(t.floorDetails.last.code, '6F');
      expect(t.apartments.keys.toSet(), t.apartmentTypes.toSet(), reason: 'type ${t.type}');
      for (final f in t.floorDetails) {
        expect(t.apartmentTypes, containsAll(f.apartmentTypes), reason: '${t.type} ${f.code}');
      }
    }

    final a = types['A']!;
    expect(a.floorDetails[1].apartments, 7);
    expect(a.floorDetails[6].apartmentTypes, ['1BR', '2BR', '3BR']);
    expect(a.apartments['4BR']!.area, 195);
    expect(a.apartments['4BR']!.available, isTrue);

    // Sheet quirk kept as is: type C's ground floor has no apartments.
    final cGround = types['C']!.floorDetails.first;
    expect(cGround.apartments, 0);
    expect(cGround.apartmentTypes, isEmpty);
  });
}
