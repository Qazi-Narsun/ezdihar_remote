import 'dart:convert';

import 'package:flutter/services.dart';

/// One building type (A, B or C) from `assets/data/building_details.json`.
/// Every building of a type shares the same details.
class BuildingType {
  const BuildingType({
    required this.type,
    required this.buildingCount,
    required this.floors,
    required this.apartmentsPerBuilding,
    required this.apartmentTypes,
    required this.totalArea,
  });

  final String type;
  final int buildingCount;
  final int floors;
  final int apartmentsPerBuilding;
  final List<String> apartmentTypes;

  /// Total area in square metres.
  final double totalArea;

  /// Ids such as A01..A05, derived from [type] and [buildingCount].
  List<String> get buildingIds =>
      [for (var i = 1; i <= buildingCount; i++) '$type${i.toString().padLeft(2, '0')}'];

  factory BuildingType.fromJson(Map<String, dynamic> json) {
    // `floors` is either a plain count or a list with one entry per floor.
    final floors = json['floors'];
    return BuildingType(
      type: json['type'] as String,
      buildingCount: json['buildingCount'] as int,
      floors: floors is List ? floors.length : floors as int,
      apartmentsPerBuilding: json['apartmentsPerBuilding'] as int,
      apartmentTypes: List<String>.from(json['apartmentTypes'] as List),
      totalArea: ((json['totalArea'] as Map)['value'] as num).toDouble(),
    );
  }

  static const _asset = 'assets/data/building_details.json';

  static Future<List<BuildingType>> loadAll() async {
    final json = jsonDecode(await rootBundle.loadString(_asset)) as Map<String, dynamic>;
    return [
      for (final t in json['buildingTypes'] as List)
        BuildingType.fromJson(t as Map<String, dynamic>),
    ];
  }
}
