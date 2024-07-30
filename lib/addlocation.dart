import 'package:flutter/material.dart';
import 'package:flutter_application_1/homepage.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({super.key});

  @override
  State<AddLocationPage> createState() => _AddLocationState();
}

class _AddLocationState extends State<AddLocationPage> {
  TextEditingController input1 = TextEditingController();
  TextEditingController input2 = TextEditingController();

  TextEditingController typeController = TextEditingController(); // เพิ่ม TextEditingController สำหรับประเภทสนาม
  List<String> selectedTypes = [];
  List<Map<String, dynamic>> fieldTypes = [];
  int? locationId; // เก็บ location_id ที่เพิ่งเพิ่ม

  Future<void> fetchType() async {
    final response = await http.get(Uri.parse('http://192.168.1.41/test5/get_ShowDataType.php'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        fieldTypes = List<Map<String, dynamic>>.from(data);
      });
    } else {
      print('Failed to load field types. Status code: ${response.statusCode}');
      throw Exception('Failed to load field types');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchType();
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ข้อผิดพลาด'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('ตกลง'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('เลือกประเภทสนาม'),
          content: SingleChildScrollView(
            child: ListBody(
              children: fieldTypes.map((type) {
                return CheckboxListTile(
                  title: Text(type['type_name']),
                  value: selectedTypes.contains(type['type_name']),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedTypes.add(type['type_name']);
                      } else {
                        selectedTypes.remove(type['type_name']);
                      }
                    });
                    Navigator.of(context).pop();
                    _showTypeDialog(); // เปิดใหม่เพื่อรีเฟรช
                  },
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('ตกลง'),
              onPressed: () {
                Navigator.of(context).pop();
                typeController.text = selectedTypes.join(', '); // แสดงประเภทที่เลือก
              },
            ),
          ],
        );
      },
    );
  }

  Widget buttonAddLocation(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: ElevatedButton(
        child: Text("เพิ่มสถานที่", style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          primary: Color.fromARGB(255, 255, 0, 0),
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        onPressed: () {
          if (input1.text.isEmpty || input2.text.isEmpty) {
            showErrorDialog(context, 'กรุณากรอกข้อมูล');
          } else {
            _showLoadingDialog(context); // แสดงป๊อบอัพขณะส่งข้อมูล
            functionAddLocation();
          }
        },
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('กำลังตรวจสอบข้อมูลกรุณารอสักครู่'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(),
            ],
          ),
        );
      },
    );
  }

  Future<void> functionAddLocation() async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://192.168.1.41/test5/get_AddLocation.php"),
    );

    request.fields['location_name'] = input1.text;
    request.fields['location_time'] = input2.text;
    request.fields['types_id'] = json.encode(selectedTypes.map((type) {
      final typeMap = fieldTypes.firstWhere((element) => element['type_name'] == type);
      return typeMap['type_id'];
    }).toList());

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        locationId = jsonResponse['location_id']; // เก็บ location_id ที่เพิ่งเพิ่ม

        // เริ่มการตรวจสอบสถานะการอนุมัติ
        Timer.periodic(Duration(seconds: 5), (timer) {
          checkApprovalStatus(timer);
        });
      } else {
        print("Request failed with status: ${response.statusCode}");
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  Future<void> checkApprovalStatus(Timer timer) async {
    var response = await http.get(
      Uri.parse("http://192.168.1.41/test5/check_approval_status.php?location_id=$locationId"),
    );

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      var status = responseData['status'];

      if (status == 'approved') {
        timer.cancel();
        Navigator.of(context).pop(); // ปิดป๊อบอัพ
        _showApprovalDialog(context, "เพิ่มสถานที่สำเร็จ");
      } else if (status == 'rejected') {
        timer.cancel();
        Navigator.of(context).pop(); // ปิดป๊อบอัพ
        _showApprovalDialog(context, "การอนุมัติไม่สำเร็จ");
      }
    }
  }

  void _showApprovalDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('ตกลง'),
              onPressed: () {
                Navigator.of(context).pop();
                if (message == "เพิ่มสถานที่สำเร็จ") {
                  setState(() {
                    input1.clear();
                    input2.clear();
                    typeController.clear();
                    selectedTypes.clear();
                    fetchType();
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 222, 222, 222),
      appBar: AppBar(
        title: Text("เพิ่มสถานที่"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: const Color.fromARGB(255, 255, 255, 255)),
          onPressed: () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => Homepage()));
          },
        ),
        backgroundColor: Color.fromARGB(255, 255, 0, 0),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: TextFormField(
                controller: input1,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                  hintText: 'ชื่อสถานที่',
                  fillColor: const Color.fromARGB(255, 255, 255, 255),
                  filled: true,
                  hintStyle: TextStyle(color: Color.fromARGB(255, 102, 102, 102)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  prefixIcon: Icon(Icons.add, color: Color.fromARGB(255, 255, 0, 0)),
                ),
                style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: TextFormField(
                controller: input2,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                  hintText: 'เวลาเปิด - ปิด',
                  fillColor: Color.fromARGB(255, 255, 255, 255),
                  filled: true,
                  hintStyle: TextStyle(color: Color.fromARGB(255, 102, 102, 102)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  prefixIcon: Icon(Icons.add, color: Color.fromARGB(255, 255, 0, 0)),
                ),
                style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: TextFormField(
                controller: typeController,
                readOnly: true,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                  hintText: 'เลือกประเภทสนาม',
                  fillColor: Color.fromARGB(255, 255, 255, 255),
                  filled: true,
                  hintStyle: TextStyle(color: Color.fromARGB(255, 102, 102, 102)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  prefixIcon: Icon(Icons.add, color: Color.fromARGB(255, 255, 0, 0)),
                ),
                onTap: _showTypeDialog,
                style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              ),
            ),
            buttonAddLocation(context),
            SizedBox(height: 20)
          ],
        ),
      ),
    );
  }
}
