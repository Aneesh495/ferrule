"""Performance benchmark suite for Ferrule.
Measures RMSA solver latency, optical physics throughput, and GN-model scaling.
"""

import time
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from engine.bridge import OpticalPhysicsBridge, ModulationBridge

def bench_optical_physics(iterations: int = 10000):
    start = time.perf_counter()
    for _ in range(iterations):
        gsnr = OpticalPhysicsBridge.evaluate_gsnr_db(1400.0, 18, 4, 0.0)
    elapsed = time.perf_counter() - start
    rate = iterations / elapsed
    print(f"  + Optical Impairment / GN-Model Throughput: {rate:10.1f} evals/sec ({elapsed*1000/iterations:.3f} us/eval)")

def bench_rmsa_selection(iterations: int = 5000):
    start = time.perf_counter()
    for _ in range(iterations):
        mod = ModulationBridge.select_best_modulation(1200.0, 18.5)
        slots = ModulationBridge.required_slots(400.0, mod or "DP-QPSK")
    elapsed = time.perf_counter() - start
    rate = iterations / elapsed
    print(f"  + Modulation & Spectrum Allocation Rate:    {rate:10.1f} solves/sec ({elapsed*1000/iterations:.3f} us/solve)")

def main():
    print("=" * 70)
    print("  Ferrule Optical Transport Engine: Microbenchmark Suite")
    print("=" * 70)
    bench_optical_physics()
    bench_rmsa_selection()
    print("=" * 70)

if __name__ == "__main__":
    main()
