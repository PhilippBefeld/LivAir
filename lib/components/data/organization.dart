import 'package:mvp/components/data/asset.dart';

class Organization{

  String name;
  String? label;
  String id;
  int locationCount;
  Asset2 mainLocation;
  int deviceCount;
  List<Asset2> assetList;

  Organization({
    required this.name,
    this.label,
    required this.deviceCount,
    required this.id,
    required this.locationCount,
    required this.mainLocation,
    required this.assetList
  });
}