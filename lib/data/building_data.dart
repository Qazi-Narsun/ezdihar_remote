import 'dart:convert';

import 'package:flutter/services.dart';

double _area(Object? json) => ((json as Map)['value'] as num).toDouble();

/// One floor of a building type from `assets/data/floor_details.json`.
class FloorDetails {
  const FloorDetails({
    required this.code,
    required this.apartments,
    required this.apartmentTypes,
    required this.area,
  });

  /// Sheet code: "GF" for the ground floor, then "1F".."6F".
  final String code;
  final int apartments;

  /// Apartment type ids on this floor (empty when it has no apartments).
  final List<String> apartmentTypes;

  /// Floor area in square metres.
  final double area;

  bool get isGround => code == 'GF';

  /// Floor number: 0 for the ground floor, n for "nF".
  int get level => isGround ? 0 : int.parse(code.replaceAll(RegExp(r'\D'), ''));

  factory FloorDetails.fromJson(Map<String, dynamic> json) => FloorDetails(
        code: json['floor'] as String,
        apartments: json['apartments'] as int,
        apartmentTypes: List<String>.from(json['apartmentTypes'] as List),
        area: _area(json['area']),
      );
}

/// One apartment type (e.g. "2BR") of a building type from
/// `assets/data/apartment_details.json`. The sheet has one area per type.
class ApartmentDetails {
  const ApartmentDetails({required this.unitType, required this.area, required this.available});

  final String unitType;

  /// Area in square metres.
  final double area;
  final bool available;

  factory ApartmentDetails.fromJson(Map<String, dynamic> json) => ApartmentDetails(
        unitType: json['unitType'] as String,
        area: _area(json['area']),
        available: json['available'] as bool,
      );
}

/// One building type (A, B or C) from `assets/data/building_details.json`,
/// with its floors and apartment types. Every building of a type shares the
/// same details.
class BuildingType {
  const BuildingType({
    required this.type,
    required this.buildingCount,
    required this.floors,
    required this.apartmentsPerBuilding,
    required this.apartmentTypes,
    required this.totalArea,
    this.floorDetails = const [],
    this.apartments = const {},
  });

  final String type;
  final int buildingCount;
  final int floors;
  final int apartmentsPerBuilding;
  final List<String> apartmentTypes;

  /// Total area in square metres.
  final double totalArea;

  /// Floors bottom to top (ground floor first).
  final List<FloorDetails> floorDetails;

  /// Apartment details by type id (e.g. "2BR").
  final Map<String, ApartmentDetails> apartments;

  /// Ids such as A01..A05, derived from [type] and [buildingCount].
  List<String> get buildingIds =>
      [for (var i = 1; i <= buildingCount; i++) '$type${i.toString().padLeft(2, '0')}'];

  factory BuildingType.fromJson(
    Map<String, dynamic> json, {
    List<FloorDetails> floorDetails = const [],
    Map<String, ApartmentDetails> apartments = const {},
  }) {
    // `floors` is either a plain count or a list with one entry per floor.
    final floors = json['floors'];
    return BuildingType(
      type: json['type'] as String,
      buildingCount: json['buildingCount'] as int,
      floors: floors is List ? floors.length : floors as int,
      apartmentsPerBuilding: json['apartmentsPerBuilding'] as int,
      apartmentTypes: List<String>.from(json['apartmentTypes'] as List),
      totalArea: _area(json['totalArea']),
      floorDetails: floorDetails,
      apartments: apartments,
    );
  }

  static const _buildingsAsset = 'assets/data/building_details.json';
  static const _floorsAsset = 'assets/data/floor_details.json';
  static const _apartmentsAsset = 'assets/data/apartment_details.json';

  /// The `buildingTypes` entries of a data file, keyed by type letter.
  static Future<Map<String, Map<String, dynamic>>> _byType(String asset) async {
    final json = jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>;
    return {
      for (final t in (json['buildingTypes'] as List).cast<Map<String, dynamic>>())
        t['type'] as String: t,
    };
  }

  static Future<List<BuildingType>> loadAll() async {
    final [buildings, floors, apartments] =
        await Future.wait([_buildingsAsset, _floorsAsset, _apartmentsAsset].map(_byType));
    return [
      for (final MapEntry(key: type, value: json) in buildings.entries)
        BuildingType.fromJson(
          json,
          floorDetails: [
            for (final f in (floors[type]?['floors'] as List? ?? const []))
              FloorDetails.fromJson(f as Map<String, dynamic>),
          ]..sort((a, b) => a.level.compareTo(b.level)),
          apartments: {
            for (final a in (apartments[type]?['apartments'] as List? ?? const []))
              (a as Map<String, dynamic>)['unitType'] as String: ApartmentDetails.fromJson(a),
          },
        ),
    ];
  }
}
