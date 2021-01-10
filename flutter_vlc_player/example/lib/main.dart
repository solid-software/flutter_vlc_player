import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player_example/multiple_tab.dart';
import 'package:flutter_vlc_player_example/single_tab.dart';

void main() {
  runApp(
    MaterialApp(
      home: App(),
    ),
  );
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text('Vlc Player Example'),
            bottom: TabBar(
              tabs: [
                Tab(text: 'Single'),
                Tab(text: 'Multiple'),
              ],
            ),
          ),
          body: TabBarView(
            physics: NeverScrollableScrollPhysics(),
            children: [
              SingleTab(),
              MultipleTab(),
            ],
          ),
        ),
      ),
    );
  }
}
