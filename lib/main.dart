import 'package:cgpa_tracker/screens/add_course_screen.dart';
import 'package:cgpa_tracker/screens/google_sheets_sync_screen.dart';
import 'package:cgpa_tracker/screens/homepage.dart';
import 'package:cgpa_tracker/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CGPATracker());
}


class CGPATracker extends StatefulWidget {
  const CGPATracker({super.key});
  
  @override
  State<CGPATracker> createState() => _CGPATrackerState();
}

class _CGPATrackerState extends State<CGPATracker> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = const [
    Homepage(),
    AddCourseScreen(),
    GoogleSheetsSyncScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CGPA Tracker',
      theme: ThemeData(
        primaryColor: AppTheme.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryColor,
          primary: AppTheme.primaryColor,
          secondary: AppTheme.accentColor,
          surface: AppTheme.surfaceColor,
          error: AppTheme.errorColor,
        ),
        scaffoldBackgroundColor: AppTheme.background,
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppTheme.dividerColor,
          thickness: 1,
        ),
      ),
      home: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calculate),
              label: 'Calculate',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.backup),
              label: 'Backup',
            ),
          ],
        ),
      ),
    );
  }
}