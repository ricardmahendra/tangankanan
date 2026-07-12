import 'package:flutter/material.dart';
import 'tabs/mitra_home_tab.dart';
import 'tabs/mitra_job_tab.dart';
import 'tabs/mitra_finance_tab.dart';
import '../profile/profile_page.dart'; // We can use/extend profile page or reuse logout

class MitraPage extends StatefulWidget {
  const MitraPage({super.key});

  @override
  State<MitraPage> createState() => _MitraPageState();
}

class _MitraPageState extends State<MitraPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MitraHomeTab(),
    MitraJobTab(),
    MitraFinanceTab(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Pekerjaan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Keuangan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
