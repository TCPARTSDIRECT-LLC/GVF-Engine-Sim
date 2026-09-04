# GVF Engine™: PyTorch & snnTorch Algorithmic Simulator

[![License: Proprietary](https://img.shields.io/badge/License-Proprietary_TEA-blue.svg)](#commercial-licensing--hardware-evaluation-tier-3-tea)
[![Status: RTL Verified](https://img.shields.io/badge/Hardware_RTL-Verified_(IEEE_1800--2017)-success.svg)](#key-performance-metrics)
[![Python: 3.10+](https://img.shields.io/badge/Python-3.10%2B-brightgreen.svg)](https://python.org)

**GVF Engine™** (Global Voltage & Frequency / Gated Vector Field Governance) is a proprietary hardware resource governance IP designed for high-density Edge-AI, Spiking Neural Network (SNN), and recurrent inference accelerators.

By applying **phase-locked AC dynamic thresholding ($V_{\text{th}}(t)$)** directly at the sensing boundary, the GVF Engine intercepts sub-threshold activations before they trigger memory bitline charge dissipation or downstream clock-tree toggles.

---

## 🚀 Key Performance Metrics

### **Algorithmic Simulation (PyTorch / snnTorch)**
* **SRAM Read Suppression:** **68.40% reduction** in effective memory bus traffic across recurrent activation bursts.
* **Thermal Mitigation:** Estimated **~34.0°C thermal jitter reduction** under continuous compute workloads.

### **Hardware RTL Telemetry (1,000-Cycle Extended Stress Test)**
* **Extended Burst Traffic Suppression:** **66.60% exact traffic gating rate** ($666 / 1,000$ cycles) verified in cycle-accurate testbench simulations (`gvf_core_tb.sv`).
* **Sub-Cycle Gating Latency:** **0-cycle latency penalty** for valid activations via combinatorial bitline interlock logic (`bitline_gate_en`).
* **Clock-Tree Freezing:** Synchronous assertion of `clk_freeze_trig` on sub-threshold detection to disable downstream ALU register toggling.
* **Asynchronous Reset Recovery:** **100% instant restoration** to safe idle state during mid-operation hardware reset events.

---

## 🏗 System Architecture

```text
                       +-----------------------------------+
                       |  Phase Reference Clock (phase_ref)|
                       +-----------------+-----------------+
                                         |
                                         v
  [Raw Activation] ---> +-----------------------------------+ ---> [Bitline Gate EN = 0] (Suppress)
    (from SRAM)        |  GVF Engine™ Core (gvf_core_top)   | ---> [Clock Freeze Trigger = 1]
                       |  Phase-Locked AC Threshold V_th(t) | ---> [Gated Activation to ALU]
                       +-----------------+-----------------+
                                         |
                                         v
                       +-----------------------------------+
                       | Telemetry: Suppressed FLOP Counter|
                       +-----------------------------------+