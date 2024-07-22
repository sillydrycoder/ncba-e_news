import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ncba_news/app_screens/publishing_portal.dart';
import 'package:ncba_news/app_sections/categories.dart';
import 'package:ncba_news/app_screens/saved.dart';
import 'app_screens/news_editor.dart';
import 'app_screens/signin.dart';
import 'app_sections/feed.dart';
import 'app_sections/profile.dart';
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
  String _searchQuery = '';
  late List<Widget> _pages;
  late AnimationController _iconAnimationController;
  final TextEditingController _searchController = TextEditingController();

  void handleScreenChanged(int selectedScreen) {
    setState(() {
      currentPageIndex = selectedScreen;
    });
    Navigator.of(context).pop(); // Close the drawer
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
        setState(() {
          _isAdmin = idTokenResult.claims?['admin'] ?? false;
          _pages = _buildPages();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error checking admin status: $e");
      }
    } finally {
      setState(() {
        _loading =
            false; // Set loading state to false once done checking admin status
      });
    }
  }

  _getPageLabel(int index) {
    switch (index) {
      case 0:
        return const Text(
          "Home",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        );
      case 1:
        return const Text(
          "Saved",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        );
      case 2:
        return const Text(
          "Categories",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        );
      case 3:
        return const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        );
      case 4:
        return const Text(
          "Publishing Portal",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        );
      case 5:
        return const Text(
          "Admin",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        );
      default:
        return const Text(
          "Unknown",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        );
    }
  }

  List<Widget> _buildPages() {
    List<Widget> pages = [
      Feed(searchQuery: _searchQuery),
      const Saved(),
      const Categories(),
      const Profile(),
      const PublishingPortal(),
      const AdminTabSection(),
    ];

    if (_isAdmin) {
      pages.add(const AdminTabSection());
    }

    return pages;
  }

  void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut().then((value) => {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const SignIn()),
              (route) => false,
            )
          });
    } catch (e) {
      // Handle sign-out errors if necessary
      if (kDebugMode) {
        print('Error signing out: $e');
      }
    }
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
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
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
                ? TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          setState(() {
                            _searchQuery = _searchController.text;
                          });
                        },
                      ),
                      prefix: const Text("Search: "),
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        onPressed: () {
                          setState(() {
                            _searchBarToggled = false;
                          });
                        },
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.all(9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  )
                : Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 30),
                    child: PopupMenuButton(
                      itemBuilder: (context) {
                        return [
                          const PopupMenuItem(
                            value: 0,
                            child: Text("Home"),
                          ),
                          const PopupMenuItem(
                            value: 1,
                            child: Text("Saved"),
                          ),
                          const PopupMenuItem(
                            value: 2,
                            child: Text("Categories"),
                          ),
                          const PopupMenuItem(
                            value: 3,
                            child: Text("Profile"),
                          ),
                          const PopupMenuItem(
                            value: 4,
                            child: Text("Publishing Portal"),
                          ),
                          if (_isAdmin)
                            const PopupMenuItem(
                              value: 5,
                              child: Text("Admin"),
                            ),
                        ];
                      },
                      onSelected: (int value) {
                        setState(() {
                          currentPageIndex = value;
                        });
                      },
                      child: _getPageLabel(currentPageIndex),
                    ),
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
      drawer: NavigationDrawer(
        onDestinationSelected: (int index) {
          handleScreenChanged(index);
        },
        selectedIndex: currentPageIndex,
        elevation: 1,
        tilePadding: const EdgeInsets.all(10),
        children: [
          const NavigationDrawerDestination(
            icon: Icon(Icons.home_outlined),
            label: Text("Home"),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.bookmark_outline),
            label: Text("Saved"),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.category_outlined),
            label: Text("Categories"),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.person_outline),
            label: Text("Profile"),
          ),
          const NavigationDrawerDestination(
              icon: Icon(Icons.publish_outlined),
              label: Text("Publishing Portal")),
          if (_isAdmin)
            const NavigationDrawerDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              label: Text("Admin"),
            ),
          const Divider(
            indent: 10,
            endIndent: 10,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _signOut();
                },
                label: const Text("Sign Out"),
                icon: const Icon(Icons.logout_outlined),
              )
            ],
          )
        ],
      ),
      floatingActionButton: currentPageIndex == 4
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NewsEditor()));
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
