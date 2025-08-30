import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/custom_app_bar.dart';
import '../components/login_modal_screen.dart';
import '../config/api_config.dart';


class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>{
  


  @override
  Widget build(BuildContext context) {
 
    return Scaffold(
      appBar: CustomAppBar(
        appBarType: AppBarType.main,
        leading: Padding(
          // IconButton의 기본 여백과 비슷한 값을 줍니다.
          padding: const EdgeInsets.only(left: 20.0, top: 2),
          child: const Text(
            'Crewer',
            style: TextStyle(
              color: Color(0xFFFF002B),
              fontWeight: FontWeight.w600,
              fontSize: 27,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Row(
        children: [
         TextButton(onPressed: () {
          final route = '/groupfeeds/';
          context.push(route);
         }, child: Text("그룹피드")),
         TextButton(onPressed: () {
            final route = '/feeds/';
            context.push(route);
         }, child: Text("인기피드")),
         
        ],
      ),
    );
  }
}