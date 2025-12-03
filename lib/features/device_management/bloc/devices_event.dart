part of 'devices_bloc.dart';

sealed class DevicesEvent extends Equatable {
  const DevicesEvent();

  @override
  List<Object> get props => [];
}

class LoadDevices extends DevicesEvent {}

class AddDevice extends DevicesEvent {
  final Device device;
  
  const AddDevice(this.device);
  
  @override
  List<Object> get props => [device];
}

class UpdateDevice extends DevicesEvent {
  final Device device;
  
  const UpdateDevice(this.device);
  
  @override
  List<Object> get props => [device];
}

class DeleteDevice extends DevicesEvent {
  final int deviceId;
  
  const DeleteDevice(this.deviceId);
  
  @override
  List<Object> get props => [deviceId];
}

class SearchDevices extends DevicesEvent {
  final String query;
  
  const SearchDevices(this.query);
  
  @override
  List<Object> get props => [query];
}

class LoadAddDevicesPage extends DevicesEvent {}