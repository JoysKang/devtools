import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/json_format_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    JsonFormatPage(),
    Center(child: Text('开发中...')),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧导航栏
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          labelType: NavigationRailLabelType.all,
          destinations: const <NavigationRailDestination>[
            NavigationRailDestination(
              icon: Icon(Icons.home),
              label: Text('首页'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.format_align_center),
              label: Text('JSON格式化'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.build),
              label: Text('开发中...'),
            ),
          ],
        ),

        // 右侧内容区
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: Container(
            color: Colors.white,
            child: _pages[_selectedIndex],
          ),
        ),
      ],
    );
  }
}
