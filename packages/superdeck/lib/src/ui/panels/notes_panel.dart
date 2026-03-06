import 'package:flutter/widgets.dart';

class NotesPanel extends StatelessWidget {
  const NotesPanel({super.key, required this.notes});

  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    // Using Flutter widgets directly since this is a simple UI component
    return Container(
      margin: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 0),
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 35, 35, 35),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: notes.length,
        itemBuilder: (context, index) => Text(notes[index]),
        separatorBuilder: (context, index) => const SizedBox(height: 10),
      ),
    );
  }
}
