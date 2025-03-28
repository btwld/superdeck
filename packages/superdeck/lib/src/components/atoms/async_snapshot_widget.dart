import 'package:flutter/material.dart';

class AsyncStreamWidget<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(T data) builder;

  const AsyncStreamWidget({
    super.key,
    required this.stream,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        return _buildSnapshot(snapshot, builder);
      },
    );
  }
}

Widget _buildSnapshot<T>(
  AsyncSnapshot<T> snapshot,
  Widget Function(T data) builder,
) {
  if (snapshot.hasData) {
    return builder(snapshot.requireData);
  } else if (snapshot.hasError) {
    return Center(child: Text('Error: ${snapshot.error}'));
  }

  return const Center(child: CircularProgressIndicator());
}
