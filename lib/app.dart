import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ncba_news/app_sections/feed.dart';
import 'app_screens/add_news.dart';
import 'app_screens/profile.dart';
import 'app_sections/admin.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isAdmin = false;
  bool _searchBarExpanded = false;
  int currentPageIndex = 0;
  bool _loading = true;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  void _checkAdminStatus() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Check if the user has admin custom claim
        final idTokenResult = await user.getIdTokenResult();
        print(idTokenResult);
        setState(() {
          _isAdmin = idTokenResult.claims?['admin'] ?? false;
          _pages = _buildPages();
        });
      }
    } catch (e) {
      print("Error checking admin status: $e");
    } finally {
      setState(() {
        _loading = false; // Set loading state to false once done checking admin status
      });
    }
  }

  List<Widget> _buildPages() {
    List<Widget> pages = [
      const Feed(),
      const Text('Saved'),
      const Text('Categories'),
    ];

    if (_isAdmin) {
      pages.add(const AdminTabSection());
    }

    return pages;
  }

  void _signOut() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: SafeArea(
          child: Container(
            color: Theme.of(context).appBarTheme.backgroundColor, // Set background color to avoid black overlay
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onTap: () {
                        setState(() {
                          _searchBarExpanded = true;
                        });
                      },
                      onTapOutside: (event) {
                        setState(() {
                          _searchBarExpanded = false;
                        });
                      },
                      onSubmitted: (value) {
                        setState(() {
                          _searchBarExpanded = false;
                        });
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        hintText: 'Search',
                        suffixIcon: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.search),
                        ),
                        suffixIconConstraints: const BoxConstraints.tightFor(width: 50.0),
                        filled: true,
                        fillColor: Colors.grey[200], // Ensure the fill color is set
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  _searchBarExpanded
                      ? Container()
                      : Row(
                    children: [
                      const SizedBox(width: 5.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const Profile()));
                              },
                              icon: const Icon(Icons.account_circle_outlined),
                            ),
                            IconButton(
                              onPressed: _signOut,
                              icon: const Icon(Icons.logout),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _pages.elementAt(currentPageIndex),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddNews()));
        },
        tooltip: 'Add News',
        label: const Text("Add News"),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        icon: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentPageIndex,
        onTap: (index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        unselectedIconTheme: const IconThemeData(color: Colors.grey),
        selectedItemColor: Colors.black,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.feed_outlined),
            activeIcon: Icon(Icons.feed),
            label: 'Feed',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline_rounded),
            activeIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list),
            activeIcon: Icon(Icons.list),
            label: 'Categories',
          ),
          if (_isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
        ],
      ),
    );
  }
}
