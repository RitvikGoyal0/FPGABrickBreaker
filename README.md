# FPGA Brick Breaker

A hardware implementation of the classic Brick Breaker game, written entirely in Verilog and targeting an iCE40-based FPGA board with VGA output.

> **Status: Work in progress.** Core modules for VGA timing and clock generation are in place, but the project is not yet fully playable on hardware. See [Status & Roadmap](#status--roadmap) below.

## Overview

This project generates the video signal and game logic for Brick Breaker directly in FPGA hardware, rather than running it in software. A clock generator and PLL derive the correct pixel clock from the board oscillator, horizontal/vertical counters drive VGA sync timing, and a game logic module will track the paddle, ball, and bricks to render the play field. A Python-based simulation script allows the VGA output to be checked against a waveform dump before it's tested on real hardware.

## Tech Stack

- **Verilog** — all game logic and video timing hardware modules
- **iCE40 FPGA toolchain** — [Apio](https://apio-doc.readthedocs.io/) wrapping Yosys (synthesis), nextpnr (place & route), and IceStorm (bitstream generation)
- **Python** — `vga_sim.py` with `pyvcd`/`vcdvcd` to inspect simulated VGA output from waveform dumps
- **Icarus Verilog (implied by `main_tb.v`)** — for running the testbench in simulation before synthesizing to hardware

## Module Hierarchy
 
![FPGA Brick Breaker module hierarchy](./images/module_hierarchy.png)
 
The design is organized around three main submodules driven by a single `clk` input:
 
- **`vga_timer`** takes the board clock and produces the pixel clock (`vga_clk`), the active-video flag, sync signals (`hsync`/`vsync`), and the current scan position (`pixel_x`/`pixel_y`).
- **`game_logic`** takes the button inputs (`btn_go`, `btn_left`, `btn_right`, `btn_rst`) and the per-frame tick from the timer, and outputs the current game state — ball position, brick status, lives, paddle position, and score.
- **`pixel_mux`** combines the timer's pixel position with the game state to decide what should be drawn at each pixel, producing the final `b`/`g`/`r` color outputs.

`main` wires these three modules together, so `vga_active`, `frame_tick`, `pixel_x`, and `pixel_y` all flow from the timer into both `game_logic` and `pixel_mux`, while `game_logic`'s outputs feed into `pixel_mux` to be rendered. The color outputs as well as `hsync` and `vsync` are outputted through the PMOD pins to a VGA adapter.

## Acknowledgments

Built as a passion project exploring RTL digital logic design and VGA signal generation directly in FPGA hardware.
