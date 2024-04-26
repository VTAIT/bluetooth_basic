import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ActionBluetooth extends StatefulWidget {
  const ActionBluetooth({super.key, required this.device});
  final BluetoothDevice device;
  @override
  State<ActionBluetooth> createState() => _ActionBluetoothState();
}

class _ActionBluetoothState extends State<ActionBluetooth> {
  String name = "";
  FocusNode _nodeFocus = FocusNode();
  List<String> logText = [];
  List<String> logArray = [];
  List<int> queue = [];
  bool isConnect = false;
  TextEditingController textController = TextEditingController();

  BluetoothDevice? device;
  StreamSubscription<BluetoothConnectionState>? listenerConnect;
  BluetoothCharacteristic? bluetoothcharacteristics;
  StreamSubscription<List<int>>? listenerHolder;

  Future<void> discoveredServiceList(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      if (services.isEmpty) {
        logText.add("Không có services nào !!!");
        logArray.add("");
        return;
      }

      // Lấy đặc trưng cuối cùng của dịch vụ cuối cùng (điều này có thể cần chỉnh sửa nếu có nhiều dịch vụ)
      var characteristics = services.last.characteristics;
      if (characteristics.isEmpty) {
        logText.add("Không có characteristics nào !!!");
        logArray.add("");
        return;
      }

      bluetoothcharacteristics = characteristics.last;

      listenerHolder =
          bluetoothcharacteristics?.onValueReceived.listen((value) {
        queue.addAll(value);
        String temp = String.fromCharCodes(value);
        if (temp.contains("#")) {
          String fullCmd = String.fromCharCodes(queue);
          logText.add(fullCmd);
          logArray.add(queue.toString());
          queue.clear();
          setState(() {});
        }
      });

      await bluetoothcharacteristics?.setNotifyValue(true);
      logText.add("Đang lắng nghe dữ liệu từ BlueTooth !!!");
      logArray.add("");
    } catch (e) {}
    setState(() {});
  }

  sendData(List<int> data) async {
    log("Data: ${data.toString()}");
    if (data.length <= 20) {
      // print("Sending small package");
      await bluetoothcharacteristics?.write(data);
    } else {
      // print("Sending chunked package of ${data.length} bytes");

      int chunk = 0;
      int nextRemaining = data.length;
      List<int> toSend;

      while (nextRemaining > 0) {
        toSend = data.sublist(chunk, chunk + math.min(20, nextRemaining));
        // print("Enviando chunk $toSend");
        await sendData(toSend);
        await Future.delayed(Duration(milliseconds: 20));
        nextRemaining -= 20;
        chunk += 20;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    device = widget.device;
    name = device!.platformName;
    listenerConnect =
        device!.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
        isConnect = false;
      } else if (state == BluetoothConnectionState.connected) {
        isConnect = true;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    listenerConnect?.cancel();
    listenerHolder?.cancel();
    if (isConnect) {
      device?.disconnect();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(Colors.transparent),
              ),
              onPressed: () async {
                try {
                  if (isConnect) {
                    await device?.disconnect();
                  } else {
                    await device?.connect();
                    await discoveredServiceList(device!);
                  }
                } catch (e) {
                  print(e);
                }
              },
              child: Container(
                  decoration: BoxDecoration(
                      color: isConnect ? Colors.green : Colors.black,
                      borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.all(8),
                  child: Text(
                    isConnect ? "Ngắt" : "Kết nối",
                    style: TextStyle(color: Colors.white),
                  ))),
          TextButton(
              onPressed: () {
                logText.clear();
                logArray.clear();
              },
              child: Text("Clear"))
        ],
      ),
      body: GestureDetector(
        onTap: () {
          _nodeFocus.unfocus();
        },
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text("Log: "),
                    SizedBox(
                      height: 3,
                    ),
                    Expanded(
                        child: Container(
                            width: MediaQuery.of(context).size.width,
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(border: Border.all()),
                            child: ListView.builder(
                              itemCount: logText.length,
                              itemBuilder: (context, index) {
                                String text = logText[index];
                                String array = logArray[index];
                                String data = "Text: $text\nArray: $array";
                                return Text(data);
                              },
                            ))),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: textController,
                      keyboardType: TextInputType.text,
                      focusNode: _nodeFocus,
                      decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.grey,
                          contentPadding: const EdgeInsets.all(5),
                          border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(5)),
                          hintText: "Nhập nội dung"),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  IconButton(
                      onPressed: () {
                        // String cmd = "*SS,1234567890,BLE2,112233,1,12345#";
                        if (textController.text.isNotEmpty) {
                          // sendData(cmd.codeUnits);
                          sendData(textController.text.codeUnits);
                        }
                        _nodeFocus.unfocus();
                      },
                      icon: Icon(
                        Icons.send,
                        color: Colors.blue,
                      ))
                ],
              ),
            ),
            SizedBox(
              height: 10,
            )
          ],
        ),
      ),
    );
  }
}
