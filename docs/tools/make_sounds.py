"""Nape uyarı seslerini sentezler. Çıktı: Nape/Resources/nudge_<ad>.wav ve silence.wav.
Dış bağımlılık yok; `python3 docs/tools/make_sounds.py` deponun kökünden çalıştırılır."""
import wave, struct, math, os
rate = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', '..', 'Nape', 'Resources')

def write(name, samples):
    with wave.open(os.path.join(OUT, f'{name}.wav'), 'w') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(rate)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, s)) * 32767)) for s in samples))

def tone(f, dur, amp=0.5, harm=False, attack=0.01):
    n = int(rate * dur); out = []
    for i in range(n):
        t = i / rate; env = min(1, t / attack, (dur - t) / attack)
        v = math.sin(2 * math.pi * f * t)
        if harm: v = (v + 0.5 * math.sin(2 * math.pi * f * 3 * t) + 0.25 * math.sin(2 * math.pi * f * 5 * t)) / 1.75
        out.append(amp * env * v)
    return out

gap = lambda d: [0.0] * int(rate * d)

write('silence', [0.0] * rate)
n = int(rate * 0.35); chime = []
for i in range(n):
    t = i / rate; env = math.sin(math.pi * i / n)
    chime.append(0.35 * env * (math.sin(2 * math.pi * 660 * t) + 0.4 * math.sin(2 * math.pi * 990 * t)))
write('nudge_chime', chime)
beeps = []
for k in range(3): beeps += tone(1200 + k * 200, 0.11, 0.55, True) + gap(0.06)
write('nudge_beeps', beeps)
alarm = []
for k in range(4): alarm += tone(800 if k % 2 == 0 else 1000, 0.18, 0.6, True) + gap(0.04)
write('nudge_alarm', alarm)
siren = []
for _ in range(2):
    n = int(rate * 0.45); ph = 0
    for i in range(n):
        t = i / rate; f = 600 + 1200 * (t / 0.45); ph += 2 * math.pi * f / rate
        env = min(1, t / 0.02, (0.45 - t) / 0.02); siren.append(0.55 * env * math.sin(ph))
    siren += gap(0.05)
write('nudge_siren', siren)
rapid = []
for k in range(6): rapid += tone(2000, 0.05, 0.5, True, 0.005) + gap(0.05)
write('nudge_rapid', rapid)
print('ok')
