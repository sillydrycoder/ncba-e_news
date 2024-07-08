import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:ncba_news/app_sections/feed.dart';
import 'app_screens/add_news.dart';
import 'app_screens/profile.dart';
import 'app_sections/admin.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isAdmin = false;
  bool _searchBarToggled = false;
  int currentPageIndex = 0;
  bool _loading = true;
  late List<Widget> _pages;
  late AnimationController _iconAnimationController;
  int screenIndex = 0;
  late bool showNavigationDrawer;

  void handleScreenChanged(int selectedScreen) {
    setState(() {
      screenIndex = selectedScreen;
    });
  }

  void openDrawer() {
    scaffoldKey.currentState!.openDrawer();
  }

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    super.dispose();
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
        _loading =
            false; // Set loading state to false once done checking admin status
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

  void _toggleSearchBar() {
    setState(() {
      _searchBarToggled = !_searchBarToggled;
      if (_searchBarToggled) {
        _iconAnimationController.forward();
      } else {
        _iconAnimationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        elevation: 5,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        centerTitle: true,

        leading: DrawerButton(
          onPressed: openDrawer,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/ncba_logo.png',
              height: 30,
            ),
            const SizedBox(width: 10),
            const Text('NCBA&E News'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: _searchBarToggled
                ? TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      prefix: const Text("Search: "),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        onPressed: () {
                          setState(() {
                            _searchBarToggled = false;
                          });
                        },
                      ),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(9),
                    ),
                  )
                : Row(
                    children: [
                      IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.filter_alt_outlined)),
                      Expanded(child: Container()),
                      IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.chat_outlined)),
                      IconButton(
                          onPressed: () {},
                          icon: const Badge(
                            label: Text("10"),
                            child: Icon(Icons.notifications_outlined),
                          )),
                    ],
                  ),
          ),
        ),
        actions: [
          IconButton(
            icon: AnimatedIcon(
              icon: AnimatedIcons.search_ellipsis,
              progress: _iconAnimationController,
            ),
            onPressed: _toggleSearchBar,
          ),
        ],
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _pages.elementAt(currentPageIndex),
      ),
      drawer: Drawer(
        width: 260,
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(topRight: Radius.circular(20)),
                color: Theme.of(context).primaryColor,
              ),
              onDetailsPressed: () {

              },
                accountName: const Text("Muhammad Ali"),
                accountEmail: const Text("muhammad_ali@workmail.com")
            ),
            ListTile(
              selectedTileColor: Colors.grey[300],
              shape: const RoundedRectangleBorder(
              ),
              title: const Text("Home"),
              leading: const Icon(Icons.home),
              selected: screenIndex == 0,
              onTap: () {
                handleScreenChanged(0);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 5),
            ListTile(
              selectedTileColor: Colors.grey[300],
              shape: const RoundedRectangleBorder(),
              title: const Text("Publishing Portal"),
              leading: const Icon(Icons.newspaper),
              selected: false,
              onTap: () {
                handleScreenChanged(0);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 5),
            ListTile(
              selectedTileColor: Colors.grey[300],
              shape: const RoundedRectangleBorder(
              ),
              title: const Text("Saved"),
              leading: const Icon(Icons.bookmark_border),
              selected: false,
              onTap: () {
                handleScreenChanged(0);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 5),
            ListTile(
              selectedTileColor: Colors.grey[300],
              shape: const RoundedRectangleBorder(
              ),
              title: const Text("Sign Out"),
              leading: const Icon(Icons.logout_outlined),
              selected: false,
              onTap: () {
                _signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
