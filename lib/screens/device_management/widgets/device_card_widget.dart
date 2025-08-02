import 'package:flutter/material.dart';

class DeviceCard extends StatelessWidget {
  final String deviceName; 

  const DeviceCard({
    super.key,
    required this.deviceName
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [Icon(Icons.assistant_navigation, size: 35,)], // icon
                  )
                ),
                Expanded(
                  flex: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [Text(deviceName, style: TextStyle(fontSize: 18),)], // title
                  )
                ),
                Expanded(
                  flex: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [Icon(Icons.more_vert)], // title
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Icon(Icons.battery_unknown, size: 30),
                      Icon(Icons.settings, size: 30),
                      Icon(Icons.sync, size: 30),
                    ],
                  )
                ),
                SizedBox(
                  height: 50,
                ),
                Expanded(
                  flex: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Status: Connected")
                    ],
                  )
                ),
              ],
            )
          ],
        )
      )
    );
  }
}