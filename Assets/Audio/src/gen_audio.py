# เพลง + เสียงประกอบ สังเคราะห์ด้วยโค้ด (ไม่มีลิขสิทธิ์คนอื่น) · [Claude 10 ต.ค. 2569]
# สไตล์อีสาน/ชนบทไทย: พิณ (ดีดแบบ Karplus-Strong) · แคน (ลิ้นเสียงต่อเนื่อง) · ระนาด/โปงลาง · ฉิ่ง-ฉาบ · เกราะไม้
# บันไดเสียงเพนทาโทนิก · เพลงวนลูปได้ (ความยาวพอดีห้อง) · ใช้: python3 gen_audio.py <Assets/Audio>
import math, os, subprocess, sys, wave
import numpy as np

OUT = sys.argv[1]
SR = 44100
rng = np.random.default_rng(7)


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def env_adsr(n, a, d, s, r):
    e = np.ones(n) * s
    a, d, r = int(a * SR), int(d * SR), int(r * SR)
    a = max(a, 1)
    e[:a] = np.linspace(0, 1, a)
    if d > 0:
        e[a:a + d] = np.linspace(1, s, min(d, max(0, n - a)))[: len(e[a:a + d])]
    if r > 0 and r < n:
        e[-r:] *= np.linspace(1, 0, r)
    return e


def pluck(freq, dur, bright=0.5, decay=0.996):
    """พิณ: Karplus-Strong"""
    n = int(dur * SR)
    p = max(2, int(SR / freq))
    buf = rng.uniform(-1, 1, p)
    # กรองให้นุ่ม
    for _ in range(2):
        buf = 0.5 * (buf + np.roll(buf, 1))
    out = np.zeros(n)
    b = buf.copy()
    idx = 0
    for i in range(n):
        out[i] = b[idx]
        nxt = (idx + 1) % p
        b[idx] = decay * (bright * b[idx] + (1 - bright) * b[nxt]) if bright != 0.5 else decay * 0.5 * (b[idx] + b[nxt])
        idx = nxt
    out *= np.linspace(1, 0.0, n) ** 0.3
    return out * 0.6


def khaen(freqs, dur, vol=0.18):
    """แคน: ลิ้นเสียง (ฮาร์มอนิกคี่ + คู่จาง ๆ) เสียงลมหายใจ ค่อย ๆ ดัง"""
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    vib = 1 + 0.003 * np.sin(2 * math.pi * 5.2 * t)
    for f in freqs:
        ph = 2 * math.pi * f * np.cumsum(vib) / SR
        for h, a in [(1, 1.0), (2, 0.35), (3, 0.45), (4, 0.15), (5, 0.22), (7, 0.1)]:
            out += a * np.sin(h * ph) / len(freqs)
    breath = np.convolve(rng.normal(0, 1, n), np.ones(30) / 30, mode="same") * 0.05
    swell = 0.75 + 0.25 * np.sin(2 * math.pi * t / max(dur, 0.1) * 1.0 - math.pi / 2) ** 2
    return (out + breath) * env_adsr(n, 0.25, 0.1, 0.9, 0.35) * swell * vol


def ranat(freq, dur, vol=0.35):
    """ระนาด/โปงลาง: ไม้ตี เสียงสั้น"""
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = np.sin(2 * math.pi * freq * t) * np.exp(-t * 7) + 0.35 * np.sin(2 * math.pi * freq * 3.98 * t) * np.exp(-t * 18)
    s += 0.15 * np.sin(2 * math.pi * freq * 9.2 * t) * np.exp(-t * 40)
    return s * vol * env_adsr(n, 0.002, 0, 1, 0.02)


def ching(dur, open_=True, vol=0.1):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = sum(np.sin(2 * math.pi * f * t + rng.uniform(0, 6)) for f in (2630, 3910, 5270, 6650))
    return s / 4 * np.exp(-t * (3.5 if open_ else 22)) * vol


def wood(dur=0.15, freq=900, vol=0.25):
    n = int(dur * SR)
    t = np.arange(n) / SR
    return (np.sin(2 * math.pi * freq * t) + 0.5 * np.sin(2 * math.pi * freq * 2.7 * t)) * np.exp(-t * 45) * vol


def drum(dur=0.4, vol=0.5):
    """กลองยาว/โทน: ตุ้ม"""
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = 120 * np.exp(-t * 6) + 60
    return np.sin(2 * math.pi * np.cumsum(f) / SR) * np.exp(-t * 9) * vol


def pad(freqs, dur, vol=0.08):
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = sum(np.sin(2 * math.pi * f * t) + 0.3 * np.sin(2 * math.pi * f * 2.001 * t) for f in freqs) / len(freqs)
    return out * env_adsr(n, 0.8, 0.2, 0.9, 0.8) * vol


def add(buf, sig, at):
    i = int(at * SR)
    if i >= len(buf):
        return
    j = min(len(buf), i + len(sig))
    buf[i:j] += sig[: j - i]


def echo(x, delay=0.27, fb=0.28, mix=0.25):
    d = int(delay * SR)
    y = x.copy()
    for k in range(1, 5):
        y[d * k:] += x[: len(x) - d * k] * (fb ** k) * mix / fb
    return y


def loop_wrap(x, tail):
    """หางเสียงที่เลยท้ายเพลงวนกลับมาซ้อนต้นเพลง → ลูปไม่สะดุด"""
    n = len(x) - tail
    y = x[:n].copy()
    y[:tail] += x[n:]
    return y


def save(name, x, stereo_w=0.0):
    x = x / max(1e-6, np.max(np.abs(x))) * 0.89
    if stereo_w:
        d = int(0.011 * SR)
        r = np.concatenate([np.zeros(d), x[:-d]])
        st = np.stack([x * (1 - stereo_w) + r * stereo_w, x], 1)
    else:
        st = np.stack([x, x], 1)
    pcm = (st * 32767).astype(np.int16)
    music = name.startswith("Music/")
    tmp = os.path.join("/tmp", name.replace("/", "_") + ".wav") if music else os.path.join(OUT, name + ".wav")
    with wave.open(tmp, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    if music:
        ogg = os.path.join(OUT, name + ".ogg")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "4", ogg], check=True)
        print("ok", ogg)
    else:
        print("ok", tmp)


# ---------------------------------------------------------------- เพลงเมนู: "เย็นที่ทุ่งนา" (ช้า · แคน + พิณ · A ไมเนอร์เพนทาโทนิก)
def song_menu():
    bpm, bars = 80, 16
    beat = 60 / bpm
    L = bars * 4 * beat
    tail = int(3 * SR)
    buf = np.zeros(int(L * SR) + tail)
    A = [57, 60, 62, 64, 67, 69, 72, 74, 76]  # A3 C4 D4 E4 G4 A4 C5 D5 E5
    # แคน: เสียงยืน A–E + เปลี่ยนคอร์ดทุก 4 ห้อง
    chords = [[45, 52, 57], [43, 50, 55], [41, 48, 57], [45, 52, 57]]
    for b in range(0, bars, 4):
        c = chords[(b // 4) % 4]
        add(buf, khaen([midi(n) for n in c], 4 * 4 * beat + 0.3, 0.2), b * 4 * beat)
    # พิณ: ทำนอง (โน้ต, จังหวะเป็นเขบ็ต 1 ชั้น)
    mel = [(69, 2), (72, 1), (74, 1), (76, 3), (74, 1), (72, 2), (69, 2), (67, 4),
           (69, 2), (67, 1), (64, 1), (62, 2), (64, 2), (69, 8),
           (76, 2), (79, 2), (76, 1), (74, 1), (72, 2), (74, 3), (72, 1), (69, 4),
           (67, 2), (69, 2), (72, 2), (69, 1), (67, 1), (64, 4), (69, 4),
           (69, 2), (72, 1), (74, 1), (76, 3), (74, 1), (72, 2), (69, 2), (67, 4),
           (64, 2), (67, 2), (69, 2), (72, 2), (74, 2), (72, 2), (69, 4),
           (76, 1), (74, 1), (72, 2), (74, 1), (72, 1), (69, 2), (67, 2), (64, 2), (62, 4),
           (64, 2), (67, 2), (69, 12)]
    t = 0.0
    for n, d in mel:
        dur = d * beat / 2
        add(buf, pluck(midi(n), min(dur + 0.6, 2.2), decay=0.997), t)
        if d >= 3:
            add(buf, pluck(midi(n + 12), 0.6, decay=0.993) * 0.25, t + beat / 2)  # ดีดซ้ำเบา ๆ
        t += dur
    # ฉิ่ง ทุกจังหวะ 2 (เปิด) 4 (ปิด) · ห้อง 1–2 เงียบ
    for b in range(2, bars):
        add(buf, ching(1.2, True, 0.06), (b * 4 + 1) * beat)
        add(buf, ching(0.2, False, 0.06), (b * 4 + 3) * beat)
    x = echo(buf, 0.36, 0.3, 0.3)
    save("Music/bgm_menu", loop_wrap(x, tail), 0.3)


# ---------------------------------------------------------------- เพลงหมู่บ้าน/ร้าน: "เช้าวันเปิดร้าน" (สดใส · C เมเจอร์เพนทาโทนิก)
def song_village():
    bpm, bars = 108, 16
    beat = 60 / bpm
    L = bars * 4 * beat
    tail = int(2.5 * SR)
    buf = np.zeros(int(L * SR) + tail)
    prog = [48, 48, 45, 43, 48, 48, 45, 43, 41, 43, 48, 45, 41, 43, 48, 48]  # เบส C C A G …
    for b, root in enumerate(prog):
        for k in range(4):
            add(buf, pluck(midi(root if k % 2 == 0 else root + 7), 0.5, decay=0.993) * 0.8, (b * 4 + k) * beat)
        add(buf, drum(0.4, 0.35), (b * 4) * beat)
        add(buf, drum(0.3, 0.2), (b * 4 + 2.5) * beat)
        for k in range(4):
            add(buf, wood(0.12, 1100 if k % 2 else 800, 0.12), (b * 4 + k + 0.5) * beat)
        add(buf, ching(0.8, True, 0.05), (b * 4 + 2) * beat)
    # ทำนองโปงลาง (ระนาดไม้)
    mel = [(72, 1), (74, 1), (76, 2), (79, 2), (76, 2), (74, 1), (72, 1), (74, 2), (76, 4),
           (72, 1), (69, 1), (67, 2), (69, 2), (72, 2), (74, 4), (72, 4),
           (76, 1), (79, 1), (81, 2), (79, 2), (76, 2), (79, 1), (76, 1), (74, 2), (72, 4),
           (69, 2), (72, 2), (74, 2), (76, 2), (74, 4), (72, 4)]
    for rep in range(2):
        t = rep * 8 * 4 * beat
        for n, d in mel:
            dur = d * beat / 2
            add(buf, ranat(midi(n), min(dur + 0.4, 1.2), 0.3), t)
            if rep == 1:
                add(buf, ranat(midi(n - 12), min(dur + 0.4, 1.2), 0.12), t)
            t += dur
    # แคนคลอเบา ๆ ครึ่งหลัง
    add(buf, khaen([midi(60), midi(67)], 8 * 4 * beat, 0.08), 8 * 4 * beat)
    x = echo(buf, 0.22, 0.25, 0.18)
    save("Music/bgm_village", loop_wrap(x, tail), 0.25)


# ---------------------------------------------------------------- เพลงตอนทำงาน (มินิเกม/ขมOS): ชิล · ระนาดเบา + แพด · D เพนทาโทนิก
def song_work():
    bpm, bars = 72, 16
    beat = 60 / bpm
    L = bars * 4 * beat
    tail = int(3 * SR)
    buf = np.zeros(int(L * SR) + tail)
    chords = [[50, 57, 62, 66], [47, 54, 59, 62], [43, 50, 55, 59], [45, 52, 57, 61]]
    for b in range(bars):
        c = chords[(b // 2) % 4]
        if b % 2 == 0:
            add(buf, pad([midi(n) for n in c], 2 * 4 * beat + 0.8, 0.09), b * 4 * beat)
        add(buf, drum(0.35, 0.12), b * 4 * beat)
        for k in (1, 3):
            add(buf, wood(0.1, 1300, 0.05), (b * 4 + k) * beat)
    arp_notes = [74, 78, 81, 78, 76, 74, 71, 74]
    for b in range(bars):
        root_shift = [0, -3, -7, -5][(b // 2) % 4]
        for k, n in enumerate(arp_notes):
            if (b + k) % 3 == 2 and b % 4 == 3:
                continue
            add(buf, ranat(midi(n + root_shift), 0.6, 0.12), (b * 4 + k * 0.5) * beat)
    x = echo(buf, 0.42, 0.35, 0.3)
    save("Music/bgm_work", loop_wrap(x, tail), 0.35)


# ---------------------------------------------------------------- จบเดโม (สั้น ไม่วน)
def jingle_demo():
    beat = 60 / 90
    buf = np.zeros(int(7 * SR))
    for i, n in enumerate([60, 64, 67, 72, 76]):
        add(buf, pluck(midi(n), 2.5, decay=0.998), i * beat / 2)
        add(buf, ranat(midi(n + 12), 1.0, 0.15), i * beat / 2)
    add(buf, khaen([midi(48), midi(55), midi(64)], 4.5, 0.25), 5 * beat / 2)
    add(buf, ching(2.5, True, 0.12), 5 * beat / 2)
    save("Music/jingle_demo_end", echo(buf, 0.3, 0.3, 0.3), 0.3)


# ---------------------------------------------------------------- เสียงประกอบ
def sfx():
    t = lambda d: np.arange(int(d * SR)) / SR
    # คลิกปุ่ม (ไม้เบา ๆ)
    save("Sfx/click", wood(0.08, 1400, 0.6))
    # สำเร็จ (โปงลางขึ้น)
    b = np.zeros(int(1.4 * SR))
    for i, n in enumerate([72, 76, 79, 84]):
        add(b, ranat(midi(n), 0.8, 0.5), i * 0.09)
    save("Sfx/success", echo(b, 0.12, 0.3, 0.3))
    # ผิด/เตือน (ลงต่ำ)
    b = np.zeros(int(0.8 * SR))
    for i, n in enumerate([64, 58]):
        add(b, ranat(midi(n), 0.5, 0.5), i * 0.16)
    save("Sfx/fail", b)
    # เงินเข้า (เหรียญ)
    tt = t(0.5)
    coin = (np.sin(2 * math.pi * 1568 * tt) * (tt < 0.08) + np.sin(2 * math.pi * 2093 * tt) * (tt >= 0.08)) * np.exp(-tt * 9) * 0.5
    save("Sfx/coin", coin)
    # บูตเครื่อง (ปี๊บ POST + เสียงพัดลม)
    tt = t(1.2)
    beep = np.sin(2 * math.pi * 1000 * tt) * (tt < 0.18) * 0.4
    fan = np.convolve(rng.normal(0, 1, len(tt)), np.ones(60) / 60, mode="same") * np.minimum(tt * 3, 1) * 0.25
    save("Sfx/boot", beep + fan)
    # เปิดหน้า/เด้ง (pop)
    tt = t(0.12)
    save("Sfx/pop", np.sin(2 * math.pi * (500 + 1500 * tt / 0.12) * tt) * np.exp(-tt * 30) * 0.5)


song_menu()
song_village()
song_work()
jingle_demo()
sfx()
