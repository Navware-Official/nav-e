part of 'devices_bloc.dart';

sealed class DevicesEvent {
  const DevicesEvent();

  List<Object> get props => [];
}

class LoadDevices extends DevicesEvent{}

class LoadAddDevicesPage extends DevicesEvent{}

// TODO: Create the rest of the events for full on functionality