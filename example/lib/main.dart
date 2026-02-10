import 'package:f_multi_select_dropdown/f_multi_select_dropdown.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi Select Drop Down Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MultiSelectDropDown(),
    );
  }
}

class MultiSelectDropDown extends StatefulWidget {
  const MultiSelectDropDown({super.key});

  @override
  State<MultiSelectDropDown> createState() => _MultiSelectDropDownState();
}

class _MultiSelectDropDownState extends State<MultiSelectDropDown> {
  final List<String> countries = [
    'India',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'Japan',
    'Singapore',
    'UAE',
  ];


  List<String> dataList = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MultiSelectDropdownServer(
                chipBackgroundColor: Colors.teal,
                items: countries,
                selectedItems: dataList,
                getLabel: (e) => e,
                compareFn: (a, b) => a == b,
                onChanged: (items) {
                  setState(() => dataList = items);
                },
                onSearch: (query) async {
                  final q = query.toLowerCase();

                  final results = countries.where((e) => e.toLowerCase().contains(q)).toList();

                  return results;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
