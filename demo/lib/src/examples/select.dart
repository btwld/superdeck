import 'package:flutter/material.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  runApp(const MyApp());
}

// Simple fruit data class for type safety
class Fruit {
  const Fruit({required this.value, required this.label, required this.emoji});

  final String value;
  final String label;
  final String emoji;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Simple Select',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Choose from a dropdown list',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 24),
              SimpleSelectExample(),
            ],
          ),
        ),
      ),
    );
  }
}

class SimpleSelectExample extends StatefulWidget {
  const SimpleSelectExample({super.key});

  @override
  State<SimpleSelectExample> createState() => _SimpleSelectExampleState();
}

class _SimpleSelectExampleState extends State<SimpleSelectExample> {
  String? _selectedValue;

  // Available fruits
  static const fruits = [
    Fruit(value: 'apple', label: 'Apple', emoji: '🍎'),
    Fruit(value: 'banana', label: 'Banana', emoji: '🍌'),
    Fruit(value: 'orange', label: 'Orange', emoji: '🍊'),
  ];

  // Get selected fruit label for display
  String? get _selectedLabel {
    if (_selectedValue == null) return null;
    return fruits.firstWhere((f) => f.value == _selectedValue).label;
  }

  Widget _buildOption(Fruit fruit) {
    return NakedSelect.Option(
      value: fruit.value,
      builder: (context, state, _) {
        final backgroundColor = state.when<Color?>(
          selected: Colors.blue.shade50,
          hovered: Colors.grey.shade100,
          orElse: null,
        );

        final textStyle = TextStyle(
          color: state.isSelected ? Colors.blue : Colors.black,
          fontWeight: state.isSelected ? FontWeight.w600 : FontWeight.normal,
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: backgroundColor,
          child: Row(
            spacing: 8,
            children: [
              Text(fruit.emoji),
              Text(fruit.label, style: textStyle),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: NakedSelect<String>(
        value: _selectedValue,
        onChanged: (value) => setState(() => _selectedValue = value),
        builder: (context, state, _) {
          final focused = state.isFocused;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: focused ? Colors.blue : Colors.grey.shade300,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedLabel ?? 'Choose fruit...',
                    style: TextStyle(
                      color:
                          _selectedValue != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.expand_more, size: 20, color: Colors.grey),
              ],
            ),
          );
        },
        overlayBuilder: (context, info) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: info.anchorRect.width),
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: fruits.map(_buildOption).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
