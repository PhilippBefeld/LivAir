
class Device2{
  int lastSync;
  String location;
  String floor;
  String locationId;
  bool isOnline;
  int radon;
  String? label;
  String name;
  int deviceAdded;

  //besteht später aus DeviceID-Device Paaren
  Device2({
    required this.lastSync,
    required this.location,
    required this.floor,
    required this.locationId,
    required this.isOnline,
    required this.radon,
    this.label,
    required this.name,
    required this.deviceAdded
  });

  update(int? lastSync,String? location,String? floor,String? locationId,bool? isOnline,int? radon,String? label,String? name){
    if(lastSync != null)this.lastSync = lastSync!;
    if(location!= null)this.location = location!;
    if(floor!= null)this.floor = floor!;
    if(locationId!= null)this.locationId = locationId!;
    if(isOnline!= null)this.isOnline = isOnline!;
    if(radon!= null)this.radon = radon!;
    if(label!= null)this.label = label!;
    if(name!= null)this.name = name!;
  }
}