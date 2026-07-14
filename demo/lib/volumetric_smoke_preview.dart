import 'package:flutter/material.dart';

import 'src/widgets/shader_showcase.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ShaderShowcase(
        effect: ShaderEffect.volumetricSmoke,
        showControls: false,
        speed: 0.8,
        intensity: 1,
        quality: 0.5,
      ),
    ),
  );
}
