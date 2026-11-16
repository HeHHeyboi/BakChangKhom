#!/usr/bin/env python3
"""[Claude 16 พ.ย. 2569 · 0.9.0 ขั้น C] รวมข้อมูลผู้ทดสอบ บักช่างขม → ตารางสำหรับเล่มรายงาน (Python 3.8+ ไม่ต้องลงอะไรเพิ่ม)

วิธีใช้
  python Tools/merge_playlog.py <โฟลเดอร์ zip> [--pre pre.csv] [--post post.csv] [--out ผลรวม]

  <โฟลเดอร์ zip>  ไฟล์ zip ที่ผู้ทดสอบส่งมา (ปุ่ม "ส่งออกข้อมูลการเล่น" ในเกม → BakChangKhom_playlog_<เวลา>.zip)
                  ในเกมไม่มีรหัสผู้ทดสอบ → ทีมเปลี่ยนชื่อไฟล์ให้มีรหัส เช่น T01.zip หรือ T01_BakChangKhom_playlog_….zip
                  (หาคำแรกแบบ ตัวอักษร 1–3 + เลข 1–3 ในชื่อไฟล์ · ไม่เจอ = ใช้ชื่อไฟล์) · คนเดียวหลายไฟล์ = ใช้ไฟล์ที่ส่งออกล่าสุด
  --pre / --post  CSV ที่ดาวน์โหลดจาก Google Form (ชีตคำตอบ → ไฟล์ → ดาวน์โหลด → CSV)
                  หาคอลัมน์รหัสเอง (หัวคอลัมน์มีคำว่า รหัส / tester / id) และคอลัมน์คะแนน (Score / คะแนน · แบบ "7 / 10" ก็ได้)
                  กำหนดเองได้ด้วย --id-col "ชื่อคอลัมน์" --score-col "ชื่อคอลัมน์"
  --out           โฟลเดอร์ผลลัพธ์ (ค่าเริ่ม: merged)

ผลลัพธ์
  participants.csv   1 แถวต่อผู้ทดสอบ: คะแนนก่อน/หลัง · เพิ่มขึ้น · เวลาเล่น (ชม.) · เดือนที่เล่นถึง · ยศ · ฉากจบ · ผลสอบเลื่อนยศ · วินิจฉัยถูกครั้งแรก
  prepost_stats.txt  n · ค่าเฉลี่ย · SD · paired t-test (t · df · p สองทาง) · Cohen's d (dz)
  all_<ไฟล์>.csv      รวม CSV ชนิดเดียวกันของทุกคน (events · achievements · ending · learn_log · scenario_log · session)
"""
import argparse
import csv
import io
import math
import os
import re
import statistics
import sys
import zipfile

ID_RE = re.compile(r"^[A-Z]{1,3}[0-9]{1,3}$")
NAME_ID_RE = re.compile(r"(?<![A-Za-z0-9])([A-Za-z]{1,3}[0-9]{1,3})(?![A-Za-z0-9])")


# ---------------------------------------------------------------- สถิติ (ไม่ใช้ scipy)

def _betacf(a, b, x):
    qab, qap, qam = a + b, a + 1.0, a - 1.0
    c, d = 1.0, 1.0 - qab * x / qap
    d = 1.0 / (d if abs(d) > 1e-30 else 1e-30)
    h = d
    for m in range(1, 300):
        m2 = 2 * m
        aa = m * (b - m) * x / ((qam + m2) * (a + m2))
        d = 1.0 + aa * d
        d = 1.0 / (d if abs(d) > 1e-30 else 1e-30)
        c = 1.0 + aa / c if abs(c) > 1e-30 else 1e-30
        h *= d * c
        aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2))
        d = 1.0 + aa * d
        d = 1.0 / (d if abs(d) > 1e-30 else 1e-30)
        c = 1.0 + aa / c if abs(c) > 1e-30 else 1e-30
        de = d * c
        h *= de
        if abs(de - 1.0) < 3e-12:
            break
    return h


def betainc(a, b, x):
    """regularized incomplete beta I_x(a, b)"""
    if x <= 0:
        return 0.0
    if x >= 1:
        return 1.0
    lbeta = math.lgamma(a + b) - math.lgamma(a) - math.lgamma(b) + a * math.log(x) + b * math.log(1 - x)
    if x < (a + 1) / (a + b + 2):
        return math.exp(lbeta) * _betacf(a, b, x) / a
    return 1.0 - math.exp(lbeta) * _betacf(b, a, 1 - x) / b


def t_two_sided_p(t, df):
    return betainc(df / 2.0, 0.5, df / (df + t * t))


def paired_t(pre, post):
    diffs = [b - a for a, b in zip(pre, post)]
    n = len(diffs)
    if n < 2:
        return None
    md = statistics.mean(diffs)
    sd = statistics.stdev(diffs)
    if sd == 0:
        return {"n": n, "mean_diff": md, "sd_diff": 0.0, "t": float("inf") if md else 0.0, "df": n - 1, "p": 0.0 if md else 1.0, "dz": float("inf") if md else 0.0}
    t = md / (sd / math.sqrt(n))
    return {"n": n, "mean_diff": md, "sd_diff": sd, "t": t, "df": n - 1, "p": t_two_sided_p(t, n - 1), "dz": md / sd}


# ---------------------------------------------------------------- อ่านไฟล์

def norm_id(s):
    t = (s or "").strip().upper().replace(" ", "")
    return t if ID_RE.match(t) else ""


def read_csv_text(text):
    text = text.lstrip("﻿")
    return list(csv.DictReader(io.StringIO(text)))


def zip_id(name):
    stem = os.path.splitext(name)[0]
    m = NAME_ID_RE.search(stem)
    return norm_id(m.group(1)) if m else stem


def exported_at(path):
    try:
        with zipfile.ZipFile(path) as z:
            for line in z.read("info.txt").decode("utf-8", "replace").splitlines():
                if line.startswith("exported="):
                    return line.split("=", 1)[1].strip()
    except (KeyError, zipfile.BadZipFile):
        pass
    return ""


def latest_zips(folder):
    """{ รหัส: path ของ zip ที่ส่งออกล่าสุด }"""
    best = {}
    for name in sorted(os.listdir(folder)):
        if not name.lower().endswith(".zip"):
            continue
        path = os.path.join(folder, name)
        tid, when = zip_id(name), exported_at(path)
        if tid not in best or when > best[tid][0]:
            best[tid] = (when, path)
    return {k: v[1] for k, v in best.items()}


def load_zip(path):
    """{ ชื่อไฟล์ csv: [แถว] } + info"""
    out, info = {}, {}
    with zipfile.ZipFile(path) as z:
        for n in z.namelist():
            if n == "info.txt":
                for line in z.read(n).decode("utf-8", "replace").splitlines():
                    if "=" in line:
                        k, v = line.split("=", 1)
                        info[k.strip()] = v.strip()
            elif n.startswith("playlog/") and n.endswith(".csv") and "_old_" not in n:
                out[os.path.basename(n)] = read_csv_text(z.read(n).decode("utf-8", "replace"))
    return out, info


def parse_score(v):
    """'7 / 10' → (7, 10) · '7' → (7, None) · อ่านไม่ได้ = None"""
    if v is None:
        return None
    m = re.match(r"\s*([0-9]+(?:\.[0-9]+)?)\s*(?:/\s*([0-9]+(?:\.[0-9]+)?))?", str(v))
    if not m:
        return None
    return float(m.group(1)), (float(m.group(2)) if m.group(2) else None)


def pick_col(cols, wanted, keys):
    if wanted:
        if wanted not in cols:
            sys.exit("ไม่พบคอลัมน์ %r (มี: %s)" % (wanted, ", ".join(cols)))
        return wanted
    for c in cols:
        lc = c.lower()
        if any(k in lc for k in keys):
            return c
    return None


def load_form(path, id_col, score_col):
    """{ รหัส: คะแนน } · ส่งซ้ำ = ใช้แถวล่าสุด (แถวหลังในไฟล์)"""
    with open(path, encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f))
    if not rows:
        return {}, None
    cols = list(rows[0].keys())
    ic = pick_col(cols, id_col, ["รหัส", "tester", " id", "id "]) or pick_col(cols, None, ["id"])
    sc = pick_col(cols, score_col, ["score", "คะแนน"])
    if not ic or not sc:
        sys.exit("%s: หาคอลัมน์รหัส/คะแนนไม่เจอ · ใช้ --id-col / --score-col (คอลัมน์ที่มี: %s)" % (path, ", ".join(cols)))
    out, full = {}, None
    for r in rows:
        tid = norm_id(r.get(ic, ""))
        sc_v = parse_score(r.get(sc))
        if tid and sc_v:
            out[tid] = sc_v[0]
            full = sc_v[1] or full
    return out, full


# ---------------------------------------------------------------- สรุปต่อคน

def num(v, default=0.0):
    try:
        return float(v)
    except (TypeError, ValueError):
        return default


def summarize(tid, files, info):
    s = {"tester_id": tid, "game_version": info.get("game_version", "")}
    sess = files.get("session.csv", [])
    s["sessions"] = len(sess)
    play = num(info.get("playtime_sec"), 0)
    if sess:
        play = max(play, max(num(r.get("total_playtime")) for r in sess))
        last = sess[-1]
        s["chapter_reached"] = int(num(last.get("chapter")))
        s["rank"] = int(num(last.get("rank")))
        s["money"] = int(num(last.get("money")))
    s["playtime_h"] = round(play / 3600.0, 2)
    learn = files.get("learn_log.csv", [])
    s["exam_answers"] = len(learn)
    s["exam_correct_rate"] = round(sum(num(r.get("correct")) for r in learn) / len(learn), 3) if learn else ""
    scen = files.get("scenario_log.csv", [])
    s["scenarios"] = len(scen)
    s["diag_first_try_rate"] = round(sum(num(r.get("first_try")) for r in scen) / len(scen), 3) if scen else ""
    s["achievements"] = len(files.get("achievements.csv", []))
    end = files.get("ending.csv", [])
    s["ending"] = end[-1].get("ending", "") if end else ""
    s["months_hit"] = end[-1].get("months_hit", "") if end else ""
    return s


def write_csv(path, rows, cols=None):
    if cols is None:
        cols = []
        for r in rows:
            for k in r:
                if k not in cols:
                    cols.append(k)
    with open(path, "w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols, extrasaction="ignore")
        w.writeheader()
        for r in rows:
            w.writerow(r)


def main(argv=None):
    ap = argparse.ArgumentParser(description="รวมข้อมูลผู้ทดสอบ บักช่างขม")
    ap.add_argument("zips")
    ap.add_argument("--pre")
    ap.add_argument("--post")
    ap.add_argument("--id-col")
    ap.add_argument("--score-col")
    ap.add_argument("--out", default="merged")
    a = ap.parse_args(argv)
    os.makedirs(a.out, exist_ok=True)

    people, merged = {}, {}
    for tid, path in latest_zips(a.zips).items():
        files, info = load_zip(path)
        people[tid] = summarize(tid, files, info)
        for name, rows in files.items():
            for r in rows:
                r.setdefault("tester_id", tid)
            merged.setdefault(name, []).extend(rows)
    for name, rows in merged.items():
        write_csv(os.path.join(a.out, "all_" + name), rows)

    pre, pre_full = load_form(a.pre, a.id_col, a.score_col) if a.pre else ({}, None)
    post, post_full = load_form(a.post, a.id_col, a.score_col) if a.post else ({}, None)
    for tid in set(pre) | set(post):
        people.setdefault(tid, {"tester_id": tid})
    for tid, p in people.items():
        p["pre_score"] = pre.get(tid, "")
        p["post_score"] = post.get(tid, "")
        p["gain"] = (post[tid] - pre[tid]) if tid in pre and tid in post else ""
    cols = ["tester_id", "pre_score", "post_score", "gain", "playtime_h", "sessions", "chapter_reached", "rank", "money",
            "exam_answers", "exam_correct_rate", "scenarios", "diag_first_try_rate", "achievements", "months_hit", "ending", "game_version"]
    rows = [people[k] for k in sorted(people)]
    write_csv(os.path.join(a.out, "participants.csv"), rows, cols)

    lines = ["ผู้ทดสอบที่มีไฟล์ข้อมูล: %d คน · มีคะแนนก่อน %d · หลัง %d" % (len(latest_zips(a.zips)), len(pre), len(post))]
    both = [k for k in sorted(people) if k in pre and k in post]
    lines.append("มีทั้งก่อนและหลัง: %d คน (%s)" % (len(both), ", ".join(both)))
    missing = [k for k in sorted(people) if not (k in pre and k in post)]
    if missing:
        lines.append("ขาดคะแนนก่อนหรือหลัง: " + ", ".join(missing))
    if pre_full or post_full:
        lines.append("คะแนนเต็ม: ก่อน %s · หลัง %s" % (pre_full or "?", post_full or "?"))
    if len(both) >= 2:
        a_pre = [pre[k] for k in both]
        a_post = [post[k] for k in both]
        r = paired_t(a_pre, a_post)
        lines += [
            "ก่อนเล่น  เฉลี่ย %.2f  SD %.2f" % (statistics.mean(a_pre), statistics.stdev(a_pre)),
            "หลังเล่น  เฉลี่ย %.2f  SD %.2f" % (statistics.mean(a_post), statistics.stdev(a_post)),
            "ผลต่าง    เฉลี่ย %.2f  SD %.2f" % (r["mean_diff"], r["sd_diff"]),
            "paired t-test: t(%d) = %.3f · p (สองทาง) = %.4f · Cohen's dz = %.2f" % (r["df"], r["t"], r["p"], r["dz"]),
            "สรุป: " + ("คะแนนหลังเล่นสูงกว่าก่อนเล่นอย่างมีนัยสำคัญที่ .05" if r["p"] < 0.05 and r["mean_diff"] > 0 else "ยังไม่พบความต่างที่มีนัยสำคัญที่ .05"),
        ]
        times = [num(people[k].get("playtime_h")) for k in both if people[k].get("playtime_h") not in ("", None)]
        if times:
            lines.append("เวลาเล่น (ชม.) เฉลี่ย %.1f · ต่ำสุด %.1f · สูงสุด %.1f" % (statistics.mean(times), min(times), max(times)))
    else:
        lines.append("ยังทำ paired t-test ไม่ได้ (ต้องมีอย่างน้อย 2 คนที่มีทั้งก่อนและหลัง)")
    with open(os.path.join(a.out, "prepost_stats.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print("\n".join(lines))
    print("→ เขียนผลไว้ที่ %s" % os.path.abspath(a.out))


if __name__ == "__main__":
    main()
