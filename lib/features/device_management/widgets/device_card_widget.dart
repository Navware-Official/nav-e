import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/bloc/bluetooth/bluetooth_bloc.dart';
import 'package:nav_e/core/domain/entities/device.dart';
import 'package:nav_e/features/device_management/bloc/devices_bloc.dart';

class DeviceCard extends StatelessWidget {
  final Device device;

  const DeviceCard({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
      BlocProvider.of<BluetoothBloc>(context).add(CheckConnectionStatus(device));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 15,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      BlocBuilder<BluetoothBloc, ApplicationBluetoothState>(
                        builder: (context, state) {
                          if (state is BluetoothConnetionStatusAquired) {
                            return Icon(
                              _getDeviceIcon(),
                              size: 35,
                              color: _getConnectionColor(state.status.toString()),
                            );
                          } else {
                            return Icon(
                        _getDeviceIcon(),
                        size: 35,
                              color: Colors.grey,
                            );
                          }
                        }
                      )
                    ],
                  )
                ),
                Expanded(
                  flex: 70,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      if (device.model != null) ...[
                        SizedBox(height: 4),
                        Text(
                          device.model!,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                      SizedBox(height: 2),
                      Text(
                        device.remoteId,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  )
                ),
                Expanded(
                  flex: 15,
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert),
                    onSelected: (value) => _handleMenuAction(context, value),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusIcon(Icons.battery_unknown, "Battery", Colors.grey),
                      _buildStatusIcon(Icons.settings, "Settings", Colors.blue),
                      _buildStatusIcon(Icons.sync, "Sync", Colors.green),
                    ],
                  )
                ),
                SizedBox(height: 50),
                Expanded(
                  flex: 60,
                  child: BlocBuilder<BluetoothBloc, ApplicationBluetoothState>(
                    builder: (context, state) {
                      if (state is AquiringBluetoothConnetionStatus) {
                        var awaitingColor = Colors.grey;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: awaitingColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: awaitingColor.withValues(alpha: 0.3)),
                              ),
                                child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: Center(child: CircularProgressIndicator()),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "Checking connection...",
                                    style: TextStyle(
                                      color: awaitingColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else if (state is BluetoothConnetionStatusAquired) {
                        var connectionStatus = state.status.toString();
                        var connectionColor = _getConnectionColor(connectionStatus);

                        return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                            GestureDetector(
                              onTap: () {
                                BlocProvider.of<BluetoothBloc>(context).add(ToggleConnection(device));
                              },
                              child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                                color: connectionColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: connectionColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                      color: connectionColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                                    connectionStatus,
                              style: TextStyle(
                                      color: connectionColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                            )
                    ],
                        );
                      }
                      

                    return Expanded(child: Text(
                        "Error: Something went wrong. Unable to load Device!", 
                        textAlign: TextAlign.center, 
                        style: TextStyle(fontSize: 24, color: Colors.redAccent))
                      );
                    }
                  )
                ),
              ],
            )
          ],
        ),
      )
    );
  }

  Widget _buildStatusIcon(IconData icon, String tooltip, Color color) {
    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 24, color: color),
    );
  }

  IconData _getDeviceIcon() {
    // You can customize this based on device type/model
    if (device.name.toLowerCase().contains('gps')) {
      return Icons.gps_fixed;
    } else if (device.name.toLowerCase().contains('bluetooth')) {
      return Icons.bluetooth;
    } else if (device.name.toLowerCase().contains('tracker')) {
      return Icons.track_changes;
    }
    return Icons.device_unknown;
  }

  Color _getConnectionColor(String connectionStatus) {
    if (connectionStatus == "Connected") {
      return Colors.green;
    } else if (connectionStatus == "Disconnected") {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        _showEditDialog(context);
        break;
      case 'delete':
        _showDeleteDialog(context);
        break;
    }
  }

  void _showEditDialog(BuildContext context) {
    TextEditingController textFieldController = TextEditingController(text: device.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change device name'),
        content: TextField(
          controller: textFieldController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: device.name
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('CANCEL'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          ElevatedButton(
            onPressed: () {
              var renamedDevice = device.copyWith(name: textFieldController.text);
              BlocProvider.of<DevicesBloc>(context).add(UpdateDevice(renamedDevice));
              Navigator.pop(context);
            },
            child: Text('Rename')
          )
        ],
      )
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Device'),
        content: Text('Are you sure you want to delete "${device.name}"?'),
        actions: <Widget>[
          TextButton(
            child: Text('CANCEL'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          ElevatedButton(
            onPressed: () {
              var deletedDevice = device.id;
              BlocProvider.of<DevicesBloc>(context).add(DeleteDevice(deletedDevice!));
              Navigator.pop(context);
            },
            child: Text('Delete')
          )
        ],
      ),
    );
  }
}