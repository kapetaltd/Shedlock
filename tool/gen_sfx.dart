// Generates Shedlock's sound effects as small 8-bit-style WAV files.
// All sounds are synthesised here (square waves + noise), so they are
// original and royalty-free.
//
//   dart run tool/gen_sfx.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const rate = 22050;

/// One synthesised segment.
class Tone {
  const Tone(this.ms, this.f0, [double? f1, this.noise = 0, this.vol = 0.35]) : f1 = f1 ?? f0;
  final int ms;
  final double f0;
  final double f1;

  /// 0..1 mix of white noise.
  final double noise;
  final double vol;
}

List<double> render(List<Tone> tones) {
  final out = <double>[];
  final rnd = math.Random(7);
  var phase = 0.0;
  for (final t in tones) {
    final n = rate * t.ms ~/ 1000;
    for (var i = 0; i < n; i++) {
      final p = i / n;
      final f = t.f0 + (t.f1 - t.f0) * p;
      phase += f / rate;
      final square = (phase % 1) < 0.5 ? 1.0 : -1.0;
      final noise = rnd.nextDouble() * 2 - 1;
      // Short attack, linear release: no clicks.
      final env = math.min(1.0, i / (rate * 0.003)) * (1 - p * 0.85);
      out.add(((1 - t.noise) * square + t.noise * noise) * env * t.vol);
    }
  }
  return out;
}

void writeWav(String path, List<double> samples) {
  final data = ByteData(44 + samples.length * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(44 + i * 2, (samples[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
  }
  File(path).writeAsBytesSync(data.buffer.asUint8List());
}

void main() {
  final sounds = {
    // Quick rising double blip.
    'eat': [const Tone(35, 880), const Tone(45, 1320)],
    // Crunchy downward sweep: the tail coming off.
    'shed': [const Tone(160, 700, 160, 0.45)],
    // Bright rising arpeggio, held at the top.
    'lock': [const Tone(55, 660), const Tone(55, 880), const Tone(55, 1100), const Tone(160, 1320)],
    // Long falling sweep into noise.
    'death': [const Tone(320, 520, 90, 0.15), const Tone(220, 120, 60, 0.7, 0.3)],
    // Warbling upward sweep for rewind.
    'rewind': [const Tone(90, 300, 600), const Tone(90, 450, 900), const Tone(90, 600, 1200)],
    // Soft tick for buttons and the countdown.
    'tick': [const Tone(25, 1000, 1000, 0, 0.2)],
  };
  for (final e in sounds.entries) {
    final path = 'assets/audio/${e.key}.wav';
    writeWav(path, render(e.value));
    stdout.writeln('wrote $path');
  }
}
