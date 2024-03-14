import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class Particle {
  Offset position;
  Particle(this.position);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ParticleTrail(),
    );
  }
}

class ParticleTrail extends StatefulWidget {
  const ParticleTrail({super.key});

  @override
  State<ParticleTrail> createState() => _ParticleTrailState();
}

class _ParticleTrailState extends State<ParticleTrail> with TickerProviderStateMixin {
  List<Particle> particlesFixed = [];
  List<Particle> particles = [];
  final int numParticles = 98;
  Offset? mousePosition;
  double noiseScale = 0.01 / 2;
  late Ticker ticker;

  // double _noise(double x, double y, double z) {
  //   return (sin(x) + cos(y) + tan(z)) * 0.1;
  // }

  bool _onScreen(Offset pos) {
    return pos.dx >= 0 &&
        pos.dx <= (window.physicalSize.width / window.devicePixelRatio) &&
        pos.dy >= 0 &&
        pos.dy <= (window.physicalSize.height / window.devicePixelRatio);
  }

  double _noise(double x, double y, double z) {
    // Generate noise values for each corner of the unit cube
    int X = x.floor() & 255;
    int Y = y.floor() & 255;
    int Z = z.floor() & 255;

    x -= x.floor();
    y -= y.floor();
    z -= z.floor();

    double u = fade(x);
    double v = fade(y);
    double w = fade(z);
    //handle 255
    int A = p[X % 256] + Y, AA = p[A % 256] + Z, AB = p[(A + 1) % 256] + Z;
    int B = p[(X + 1) % 256] + Y, BA = p[B % 256] + Z, BB = p[(B + 1) % 256] + Z;

    return lerp(
        w,
        lerp(v, lerp(u, grad(p[AA % 256], x, y, z), grad(p[BA % 256], x - 1, y, z)),
            lerp(u, grad(p[AB % 256], x, y - 1, z), grad(p[BB % 256], x - 1, y - 1, z))),
        lerp(v, lerp(u, grad(p[(AA + 1) % 256], x, y, z - 1), grad(p[(BA + 1) % 256], x - 1, y, z - 1)),
            lerp(u, grad(p[(AB + 1) % 256], x, y - 1, z - 1), grad(p[(BB + 1) % 256], x - 1, y - 1, z - 1))));
  }

  double fade(double t) {
    return t * t * t * (t * (t * 6 - 15) + 10);
  }

  double lerp(double t, double a, double b) {
    return a + t * (b - a);
  }

  double grad(int hash, double x, double y, double z) {
    int h = hash & 15;
    double u = h < 8 ? x : y,
        v = h < 4
            ? y
            : h == 12 || h == 14
                ? x
                : z;
    return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
  }

// Permutation table
  List<int> p = [];

  void main() {
    // Initialize permutation table
    for (int i = 0; i < 256; i++) {
      p.add(i);
    }
    p.shuffle(); // Shuffle the permutation table
  }

  @override
  void initState() {
    super.initState();
    final width = (window.physicalSize.width / window.devicePixelRatio);
    final height = (window.physicalSize.height / window.devicePixelRatio);
    for (double i = 0; i < width; i += 120) {
      for (double y = 0; y < height; y += 102) {
        final dx = Random().nextDouble() * (window.physicalSize.width / window.devicePixelRatio);
        final dy = Random().nextDouble() * (window.physicalSize.height / window.devicePixelRatio);
        particlesFixed.add(Particle(Offset(
          dx,
          dy,
        )));
        particles.add(Particle(Offset(
          dx,
          dy,
        )));
      }
    }

    main();
    ticker = createTicker((elapsed) {
      setState(() {
        for (int i = 0; i < particles.length; i++) {
          Particle p = particles[i];
          Particle pF = particlesFixed[i];
          double n = _noise(
              p.position.dx * noiseScale, p.position.dy * noiseScale, elapsed.inMilliseconds * noiseScale * noiseScale);
          double a = 2 * pi * n;

          p.position += Offset(cos(a), sin(a));
          pF.position += Offset(cos(a), sin(a));
          if (!_onScreen(p.position)) {
            final newPosition = Offset(Random().nextDouble() * (window.physicalSize.width / window.devicePixelRatio),
                Random().nextDouble() * (window.physicalSize.height / window.devicePixelRatio));
            p.position = newPosition;
            pF.position = newPosition;
          }
        }
      });
    });
    ticker.start();
  }

  int i = 144;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withRed(20).withBlue(20),
      body: GestureDetector(
        onTap: () async {
          particles.clear();
          particlesFixed.clear();
          final width = (window.physicalSize.width / window.devicePixelRatio);
          final height = (window.physicalSize.height / window.devicePixelRatio);
          for (double i = 0; i < width; i += 120) {
            for (double y = 0; y < height; y += 102) {
              final dx = Random().nextDouble() * (window.physicalSize.width / window.devicePixelRatio);
              final dy = Random().nextDouble() * (window.physicalSize.height / window.devicePixelRatio);
              particlesFixed.add(Particle(Offset(
                dx,
                dy,
              )));
              particles.add(Particle(Offset(
                dx,
                dy,
              )));
            }
          }

          main();
        },
        onPanUpdate: (event) {
          // setState(() {
          mousePosition = event.globalPosition;
          // });
        },
        child: CustomPaint(
          painter: ParticlePainter(particles, particlesFixed, mousePosition),
          size: MediaQuery.of(context).size,
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final List<Particle> particlesFixed;
  final Offset? mousePosition;

  ParticlePainter(this.particles, this.particlesFixed, this.mousePosition);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < particles.length; i++) {
      final Paint paint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2;
      canvas.drawPoints(PointMode.points, [particles[i].position], paint);

      if (mousePosition != null) {
        final distance = (particles[i].position - mousePosition!).distance;
        // final thisDistance = (particlesFixed[i].position - mousePosition!).distance;
        // if (thisDistance > 200) {
        //   particles[i].position = Offset(
        //     particles[i].position.dx + (particlesFixed[i].position.dx - particles[i].position.dx),
        //     particles[i].position.dy + (particlesFixed[i].position.dy - particles[i].position.dy),
        //   );
        // }

        if (distance < 200 && distance > 0) {
          final angle = (particles[i].position - mousePosition!).direction;

          particles[i].position = Offset(
            particles[i].position.dx + cos(angle) * 6,
            particles[i].position.dy + sin(angle) * 6,
          );
        }
      }

      for (int j = 0; j < particles.length; j++) {
        final dist = (particles[i].position - particles[j].position).distance.abs();
        canvas.drawLine(
          particles[i].position,
          particles[j].position,
          paint
            ..strokeWidth = 1
            ..color = Colors.white.withOpacity(dist <= 200 ? 1 - (dist / 200) : 0.00),
        );
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return true;
  }
}
