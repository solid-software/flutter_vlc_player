import 'package:flutter/material.dart';

import 'multiple_tab.dart';
import 'single_tab.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text('Vlc Player Example'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Single'),
                Tab(text: 'Multiple'),
              ],
            ),
          ),
          body: const TabBarView(
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
