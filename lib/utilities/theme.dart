import 'package:flutter/material.dart';
ThemeData customTheme = ThemeData(
  elevatedButtonTheme : const ElevatedButtonThemeData(
    style:ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(Color(0xFF164EB0)
    ),
      foregroundColor:WidgetStatePropertyAll(
        Color(0xEBF8EDED),
      ),
    ),
        ),
    
  inputDecorationTheme : InputDecorationTheme(
    border : OutlineInputBorder(borderRadius: BorderRadius.circular(30),
    ),

    ),
 textTheme : const TextTheme(titleLarge:TextStyle(
  fontSize: 22,
  fontWeight : FontWeight.bold,

  ),
 ),
scaffoldBackgroundColor: Colors.white,
dialogTheme: const DialogThemeData(
  surfaceTintColor : Colors.transparent,
),
bottomSheetTheme: const BottomSheetThemeData(
  surfaceTintColor : Colors.transparent,
  backgroundColor : Color.fromARGB(255, 10, 107, 94),
),
colorSchemeSeed: const Color(0xff1679ab)
);