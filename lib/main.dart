import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/screens/add_course_screen.dart';
import '/screens/google_sheets_sync_screen.dart';
import '/screens/homepage.dart';
import '../provider/academic_records_provider.dart';
import '/theme.dart';

void main() {
  runApp(const Markify());
}

class Markify extends StatefulWidget {
  const Markify({super.key});

  @override
  State<Markify> createState() => _MarkifyState();
}

class _MarkifyState extends State<Markify> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    Homepage(),
    AddCourseScreen(),
    GoogleSheetsSyncScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => AcademicRecordsProvider(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Markify',
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
                  icon: SizedBox.shrink(),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: SizedBox.shrink(),
                  label: 'Calculate',
                ),
                BottomNavigationBarItem(
                  icon: SizedBox.shrink(),
                  label: 'Backup',
                ),
              ],
            ),
          ),
        ));
  }
}
