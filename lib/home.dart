import 'dart:math';

import 'package:bluetooth_basic/action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String isSupport = "No";
  String status = "Off";
  List<ScanResult> scanList = [];
  List<BluetoothDevice> _connectedDevices = [];

  // Chan bam nhieu lan
  bool isProcess = false;

  @override
  void initState() {
    super.initState();

    FlutterBluePlus.systemDevices.then((devices) {
      _connectedDevices = devices;
      setState(() {});
    });

    FlutterBluePlus.isSupported.then((value) {
      isSupport = value ? "Yes" : "No";
      if (mounted) {
        setState(() {});
      }
    });

    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.on) {
        status = "On";
      } else {
        status = "Off";
      }
      setState(() {});
    });

    FlutterBluePlus.onScanResults.listen(
      (results) {
        scanList = results;
        // if (results.isNotEmpty) {
        //   ScanResult r = results.last; // the most recently found device
        //   print(
        //       '${r.device.remoteId}: "${r.advertisementData.advName}" found!');
        // }
        setState(() {});
      },
      onError: (e) => print(e),
    );
  }

  List<Widget> _buildConnectedDeviceTiles() {
    return _connectedDevices.map((d) => Item_Bluetooth(d)).toList();
  }

  List<Widget> _buildScanResultTiles() {
    List<Widget> results = [];

    for (ScanResult r in scanList) {
      String name = r.device.platformName.toUpperCase() ?? "";
      // print("_handleResult: ${name}");

      if (name.isNotEmpty) {
        // log('${r.device.platformName} found! rssi: ${r.rssi} id: ${r.device.remoteId}');
        results.add(Item_Bluetooth(
          r.device,
        ));
      }
    }

    return results;
  }

  Row Item_Bluetooth(BluetoothDevice device) {
    String name = device.platformName.toUpperCase() ?? "";
    String id = device.remoteId.str;
    return Row(
      children: [
        Icon(
          Icons.bluetooth,
          color: Colors.black,
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 14.0,
                ),
              ),
              Text(
                id,
                style: TextStyle(
                  fontSize: 14.0,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 10), // Khoảng cách giữa văn bản và nút
        Container(
          child: TextButton(
            onPressed: () async {
              if (isProcess) return;
              isProcess = true;

              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ActionBluetooth(device: device),
              ));

              isProcess = false;
            },
            style: TextButton.styleFrom(
              backgroundColor: Color.fromARGB(
                  68, 158, 158, 158), // Đặt màu nền của nút là màu xám
            ),
            child: Text(
              'Kết Nối',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BlueTooth"),
        actions: [
          IconButton(
              onPressed: () async {
                // start scan
                await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
              },
              icon: Icon(Icons.bluetooth))
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Text("Hỗ trợ: "),
                SizedBox(
                  width: 10,
                ),
                Text(isSupport)
              ],
            ),
            Row(
              children: [
                Text("Trạng thái: "),
                SizedBox(
                  width: 10,
                ),
                Text(status)
              ],
            ),
            Text("Danh sách quét: "),
            SizedBox(
              height: 10,
            ),
            Expanded(
                child: SingleChildScrollView(
              child: Column(
                children: [..._buildScanResultTiles()],
              ),
            ))
          ],
        ),
      ),
    );
  }
}
