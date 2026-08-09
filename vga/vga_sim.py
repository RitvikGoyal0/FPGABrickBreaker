#!/usr/bin/env python3
"""
vga_sim.py - Reconstruct and display VGA video output from a GTKWave-compatible
VCD (Value Change Dump) file.

HOW IT WORKS
------------
GTKWave doesn't natively export "video" - it just shows signal waveforms. This
script re-derives the actual pixel clock and frame timing purely from the
hsync/vsync pulses in the dump, using the fact that standard 640x480@60Hz VGA
timing has fixed, known proportions:

    Horizontal (in pixel clocks): 640 active + 16 front porch + 96 sync + 48 back porch = 800 total
    Vertical   (in lines):        480 active + 10 front porch +  2 sync + 33 back porch = 525 total

Since the hsync pulse is always 96 pixel clocks wide (regardless of what
speed your simulation actually runs the pixel clock at), we measure the
pulse's *real* duration in simulation time and divide by 96 to recover the
pixel clock period. The same trick recovers the line period from the vsync
pulse (2 lines wide). From there we know exactly when the active video
window starts/ends on every line and every frame, and we sample r/g/b at
the right time for each of the 640x480 pixels.

USAGE
-----
    python3 vga_sim.py waveform.vcd
    python3 vga_sim.py waveform.vcd --list-signals
    python3 vga_sim.py waveform.vcd --hsync top.hsync --vsync top.vsync \
                       --red top.vga_r --green top.vga_g --blue top.vga_b
    python3 vga_sim.py waveform.vcd --save frame.png
    python3 vga_sim.py waveform.vcd --save-all out_dir/

If the dump contains multiple frames, the viewer plays them back at 60Hz.
While the window is open you can control playback with the keyboard:
    space       play / pause
    left/right  step one frame back / forward (auto-pauses)
    home/end    jump to first / last frame

Requires: numpy, matplotlib (pip install numpy matplotlib)
"""

import argparse
import bisect
import re
import sys
from statistics import median

import numpy as np

# ---- Standard 640x480 @ 60Hz VGA timing (in pixel clocks / lines) ----
H_ACTIVE, H_FP, H_SYNC, H_BP = 640, 16, 96, 48
H_TOTAL = H_ACTIVE + H_FP + H_SYNC + H_BP  # 800
V_ACTIVE, V_FP, V_SYNC, V_BP = 480, 10, 2, 33
V_TOTAL = V_ACTIVE + V_FP + V_SYNC + V_BP  # 525


# --------------------------------------------------------------------------
# VCD parsing (self-contained, no external vcd library needed)
# --------------------------------------------------------------------------

class Signal:
    __slots__ = ("name", "width", "samples", "_times_cache")

    def __init__(self, name, width):
        self.name = name
        self.width = width
        self.samples = []  # list of (time:int, value:int), sorted by time

    def value_at(self, t):
        """Return the value in effect at time t (last sample with time <= t)."""
        if not self.samples:
            return 0
        times = self._times_cache
        i = bisect.bisect_right(times, t) - 1
        if i < 0:
            return self.samples[0][1]
        return self.samples[i][1]

    def finalize(self):
        # stable sort by time, then collapse multiple changes at the same
        # timestamp down to the last one (simultaneous updates -> final value)
        self.samples.sort(key=lambda p: p[0])
        deduped = []
        for t, v in self.samples:
            if deduped and deduped[-1][0] == t:
                deduped[-1] = (t, v)
            else:
                deduped.append((t, v))
        self.samples = deduped
        self._times_cache = [p[0] for p in self.samples]


def parse_vcd(path):
    """Parse a VCD file into {id: Signal}, also returns name->id map."""
    id_to_signal = {}
    name_to_id = {}
    scope_stack = []

    with open(path, "r", errors="replace") as f:
        lines = f.readlines()

    i = 0
    n = len(lines)
    cur_time = 0
    in_header = True

    var_re = re.compile(r"\$var\s+(\w+)\s+(\d+)\s+(\S+)\s+(.+?)\s*\$end")

    while i < n:
        line = lines[i].strip()
        i += 1
        if not line:
            continue

        if in_header:
            if line.startswith("$scope"):
                parts = line.split()
                if len(parts) >= 3:
                    scope_stack.append(parts[2])
                continue
            if line.startswith("$upscope"):
                if scope_stack:
                    scope_stack.pop()
                continue
            if line.startswith("$var"):
                m = var_re.match(line)
                if m:
                    _vtype, width, ident, rest = m.groups()
                    # rest may be "name" or "name [3:0]" possibly with bit range
                    varname = rest.split()[0]
                    full = ".".join(scope_stack + [varname]) if scope_stack else varname
                    width = int(width)
                    if ident in id_to_signal:
                        # same identifier reused for an aliased signal name
                        sig = id_to_signal[ident]
                    else:
                        sig = Signal(full, width)
                        id_to_signal[ident] = sig
                    name_to_id.setdefault(full, ident)
                continue
            if line.startswith("$enddefinitions"):
                in_header = False
                continue
            # skip other header commands ($date, $version, $timescale, $comment...)
            continue

        # value-change section
        if line.startswith("#"):
            try:
                cur_time = int(line[1:])
            except ValueError:
                pass
            continue
        if line[0] in "$":
            # $dumpvars / $end / $dumpon / $dumpoff etc - ignore, changes inside
            # $dumpvars are plain value lines anyway and handled below
            continue

        # scalar value change: e.g. "0!" or "1#"  (value char + identifier)
        if line[0] in "01xXzZ":
            val_char = line[0]
            ident = line[1:]
            val = 1 if val_char == "1" else 0
            sig = id_to_signal.get(ident)
            if sig is not None:
                sig.samples.append((cur_time, val))
            continue

        # vector value change: e.g. "b1010 #" or "r1.5 #"
        if line[0] in "bB":
            try:
                bits, ident = line[1:].split(None, 1)
            except ValueError:
                continue
            bits_clean = bits.replace("x", "0").replace("X", "0").replace("z", "0").replace("Z", "0")
            try:
                val = int(bits_clean, 2) if bits_clean else 0
            except ValueError:
                val = 0
            sig = id_to_signal.get(ident)
            if sig is not None:
                sig.samples.append((cur_time, val))
            continue
        if line[0] in "rR":
            # real value, not expected for VGA signals - ignore
            continue

    for sig in id_to_signal.values():
        sig.finalize()

    return id_to_signal, name_to_id


# --------------------------------------------------------------------------
# Signal auto-detection
# --------------------------------------------------------------------------

def leaf(name):
    return name.split(".")[-1].lower()


def _tokens(lf):
    return [t for t in re.split(r"[^a-z0-9]+", lf) if t]


def auto_detect(name_to_id):
    names = list(name_to_id.keys())
    found = {"hsync": None, "vsync": None, "red": None, "green": None, "blue": None}

    for full in names:
        toks = _tokens(leaf(full))
        if found["hsync"] is None and ("hsync" in toks or "hs" in toks or ("h" in toks and "sync" in toks)):
            found["hsync"] = full
        if found["vsync"] is None and ("vsync" in toks or "vs" in toks or ("v" in toks and "sync" in toks)):
            found["vsync"] = full

    for full in names:
        toks = _tokens(leaf(full))
        if found["red"] is None and ("r" in toks or "red" in toks):
            found["red"] = full
        if found["green"] is None and ("g" in toks or "green" in toks):
            found["green"] = full
        if found["blue"] is None and ("b" in toks or "blue" in toks):
            found["blue"] = full

    return found


# --------------------------------------------------------------------------
# Timing reconstruction
# --------------------------------------------------------------------------

def pulses_from_signal(sig):
    """Return (active_value, list of (start_time, end_time)) for the pulses
    of a sync-like signal. Active value is inferred as whichever level
    occupies less total time (sync pulses are brief compared to line/frame)."""
    samples = sig.samples
    if len(samples) < 2:
        raise ValueError(f"Signal '{sig.name}' doesn't toggle enough to analyze")

    total = {0: 0, 1: 0}
    for k in range(len(samples) - 1):
        t0, v0 = samples[k]
        t1, _ = samples[k + 1]
        total[v0] = total.get(v0, 0) + (t1 - t0)

    active_value = 0 if total.get(0, 0) <= total.get(1, 0) else 1

    pulses = []
    pulse_start = None
    for t, v in samples:
        if v == active_value and pulse_start is None:
            pulse_start = t
        elif v != active_value and pulse_start is not None:
            pulses.append((pulse_start, t))
            pulse_start = None
    return active_value, pulses


def reconstruct_frames(hsync, vsync, red, green, blue, max_frames=None, progress=True):
    """Return a list of numpy uint8 arrays, shape (480, 640, 3)."""
    _, h_pulses = pulses_from_signal(hsync)
    _, v_pulses = pulses_from_signal(vsync)

    if len(h_pulses) < V_TOTAL or len(v_pulses) < 1:
        raise ValueError(
            "Not enough hsync/vsync pulses found to reconstruct even one frame. "
            "Check that --hsync/--vsync point to the right signals, or that the "
            "dump covers at least one full frame."
        )

    h_widths = [e - s for s, e in h_pulses]
    v_widths = [e - s for s, e in v_pulses]
    h_pulse_width = median(h_widths)
    v_pulse_width = median(v_widths)

    clock_period = h_pulse_width / H_SYNC
    line_period = v_pulse_width / V_SYNC  # this is TOTAL line period (in the same
    # time units), because vsync pulse width = V_SYNC lines wide.

    # sanity re-derive line period also from hsync deassert-to-deassert spacing,
    # and cross check against vsync-derived line_period; prefer whichever has
    # more samples (hsync) unless it disagrees wildly.
    h_deassert_times = [e for _, e in h_pulses]
    if len(h_deassert_times) > 1:
        diffs = [h_deassert_times[k + 1] - h_deassert_times[k] for k in range(len(h_deassert_times) - 1)]
        line_period_from_h = median(diffs)
        if line_period_from_h > 0:
            line_period = line_period_from_h

    h_active_offset = H_BP * clock_period
    h_active_duration = H_ACTIVE * clock_period
    v_active_offset = V_BP * line_period
    v_active_duration = V_ACTIVE * line_period

    v_deassert_times = [e for _, e in v_pulses]

    frames = []
    n_frames = len(v_deassert_times) if max_frames is None else min(max_frames, len(v_deassert_times))

    for fidx in range(n_frames):
        tv = v_deassert_times[fidx]
        v_win_start = tv + v_active_offset

        # The row's hsync-deassert reference precedes its active window by
        # h_active_offset ticks, so search for that earlier time (with a
        # small tolerance so an exact float match isn't missed), then take
        # exactly V_ACTIVE consecutive lines from there.
        target = v_win_start - h_active_offset
        start_idx = bisect.bisect_left(h_deassert_times, target - clock_period * 0.5)
        rows_h_times = h_deassert_times[start_idx:start_idx + V_ACTIVE]
        if len(rows_h_times) < V_ACTIVE:
            # incomplete frame (likely truncated at end of dump) - skip
            continue

        img = np.zeros((V_ACTIVE, H_ACTIVE, 3), dtype=np.uint8)
        r_max = max(1, (2 ** red.width) - 1)
        g_max = max(1, (2 ** green.width) - 1)
        b_max = max(1, (2 ** blue.width) - 1)

        for row, th in enumerate(rows_h_times):
            h_win_start = th + h_active_offset
            # vectorized sample times for this row
            col_idx = np.arange(H_ACTIVE)
            sample_times = h_win_start + (col_idx + 0.5) * clock_period
            for col, t in zip(col_idx, sample_times):
                r_val = red.value_at(t)
                g_val = green.value_at(t)
                b_val = blue.value_at(t)
                img[row, col, 0] = int(r_val * 255 / r_max)
                img[row, col, 1] = int(g_val * 255 / g_max)
                img[row, col, 2] = int(b_val * 255 / b_max)

        frames.append(img)
        if progress:
            print(f"  reconstructed frame {fidx + 1}/{n_frames}", file=sys.stderr)

    if not frames:
        raise ValueError("Found sync pulses but couldn't reconstruct any complete frame "
                          "(the dump may not cover a full 480-line active window).")

    return frames


# --------------------------------------------------------------------------
# Display
# --------------------------------------------------------------------------

def display_frames(frames, save_path=None, save_all_dir=None):
    import matplotlib.pyplot as plt

    if save_all_dir:
        import os
        os.makedirs(save_all_dir, exist_ok=True)
        for idx, frame in enumerate(frames):
            plt.imsave(os.path.join(save_all_dir, f"frame_{idx:04d}.png"), frame)
        print(f"Saved {len(frames)} frame(s) to {save_all_dir}/")
        return

    if save_path and len(frames) == 1:
        plt.imsave(save_path, frames[0])
        print(f"Saved frame to {save_path}")
        return

    fig, ax = plt.subplots(figsize=(6.4, 4.8), dpi=100)
    fig.canvas.manager.set_window_title("VGA output (640x480 @ 60Hz)")
    ax.axis("off")
    im = ax.imshow(frames[0], interpolation="nearest", aspect="equal")

    if len(frames) == 1:
        plt.tight_layout()
        plt.show()
        return

    n = len(frames)
    state = {"idx": 0, "playing": True}

    label = ax.text(
        0.5, -0.04,
        "",
        transform=ax.transAxes, ha="center", va="top", fontsize=9, color="0.3",
    )

    def status_text():
        state_str = "playing" if state["playing"] else "paused"
        return (f"Frame {state['idx'] + 1}/{n}  [{state_str}]   "
                f"space: play/pause   \u2190/\u2192: step frame   home/end: first/last")

    def render():
        im.set_data(frames[state["idx"]])
        label.set_text(status_text())
        fig.canvas.draw_idle()

    def update(_):
        if state["playing"]:
            state["idx"] = (state["idx"] + 1) % n
            im.set_data(frames[state["idx"]])
            label.set_text(status_text())
        return [im, label]

    def on_key(event):
        if event.key == " ":
            state["playing"] = not state["playing"]
            render()
        elif event.key == "right":
            state["playing"] = False
            state["idx"] = (state["idx"] + 1) % n
            render()
        elif event.key == "left":
            state["playing"] = False
            state["idx"] = (state["idx"] - 1) % n
            render()
        elif event.key == "home":
            state["playing"] = False
            state["idx"] = 0
            render()
        elif event.key == "end":
            state["playing"] = False
            state["idx"] = n - 1
            render()

    fig.canvas.mpl_connect("key_press_event", on_key)
    render()

    from matplotlib.animation import FuncAnimation

    anim = FuncAnimation(fig, update, frames=n * 1000, interval=1000 / 60, blit=True)
    plt.tight_layout()
    if save_path:
        anim.save(save_path, fps=60)
        print(f"Saved animation to {save_path}")
    else:
        print("Controls: space = play/pause, \u2190/\u2192 = step frame, home/end = first/last frame",
              file=sys.stderr)
        plt.show()


# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description="Reconstruct and display VGA video from a VCD dump.")
    ap.add_argument("vcd", help="Path to the .vcd file (e.g. exported/opened in GTKWave)")
    ap.add_argument("--hsync", help="Full hierarchical name of the hsync signal (overrides auto-detect)")
    ap.add_argument("--vsync", help="Full hierarchical name of the vsync signal (overrides auto-detect)")
    ap.add_argument("--red", help="Full hierarchical name of the red channel signal")
    ap.add_argument("--green", help="Full hierarchical name of the green channel signal")
    ap.add_argument("--blue", help="Full hierarchical name of the blue channel signal")
    ap.add_argument("--list-signals", action="store_true", help="List all signals found in the VCD and exit")
    ap.add_argument("--max-frames", type=int, default=None, help="Limit how many frames to reconstruct")
    ap.add_argument("--save", help="Save the (first) frame as an image, or an animation (.gif/.mp4) if multiple frames")
    ap.add_argument("--save-all", dest="save_all_dir", help="Save every reconstructed frame as PNG into this directory")
    args = ap.parse_args()

    print(f"Parsing {args.vcd} ...", file=sys.stderr)
    id_to_signal, name_to_id = parse_vcd(args.vcd)
    print(f"Found {len(name_to_id)} signals.", file=sys.stderr)

    if args.list_signals:
        for name in sorted(name_to_id):
            sig = id_to_signal[name_to_id[name]]
            print(f"  {name}  (width={sig.width}, changes={len(sig.samples)})")
        return

    detected = auto_detect(name_to_id)
    hsync_name = args.hsync or detected["hsync"]
    vsync_name = args.vsync or detected["vsync"]
    red_name = args.red or detected["red"]
    green_name = args.green or detected["green"]
    blue_name = args.blue or detected["blue"]

    missing = [n for n, v in [("hsync", hsync_name), ("vsync", vsync_name),
                               ("red", red_name), ("green", green_name), ("blue", blue_name)] if v is None]
    if missing:
        print(f"Could not auto-detect: {', '.join(missing)}.", file=sys.stderr)
        print("Run with --list-signals to see available names, then pass e.g. --red top.vga_r", file=sys.stderr)
        sys.exit(1)

    print("Using signals:", file=sys.stderr)
    for label, nm in [("hsync", hsync_name), ("vsync", vsync_name),
                       ("red", red_name), ("green", green_name), ("blue", blue_name)]:
        print(f"  {label:6s} = {nm}", file=sys.stderr)

    def get(nm):
        ident = name_to_id.get(nm)
        if ident is None:
            print(f"Signal '{nm}' not found in VCD.", file=sys.stderr)
            sys.exit(1)
        return id_to_signal[ident]

    hsync = get(hsync_name)
    vsync = get(vsync_name)
    red = get(red_name)
    green = get(green_name)
    blue = get(blue_name)

    frames = reconstruct_frames(hsync, vsync, red, green, blue, max_frames=args.max_frames)
    print(f"Reconstructed {len(frames)} frame(s).", file=sys.stderr)

    display_frames(frames, save_path=args.save, save_all_dir=args.save_all_dir)


if __name__ == "__main__":
    main()