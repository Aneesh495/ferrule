# ITU-T G.709 Optical Transport Network Hierarchy

The ITU-T G.709 standard defines the digital wrapper and framing architecture for optical transport networks, providing client independence, performance monitoring, and forward error correction.

## 1. Frame Structure

The standard G.709 frame is arranged as 4 rows by 4080 columns (16,320 bytes total):

```
+------------+-------+-----------------------------+-------------------+
| FAS (1..6) | ODU   | OPU Overhead & Payload      | RS(255, 239) FEC  |
| Cols 1-7   | 8-14  | Columns 15 to 3824          | Columns 3825-4080 |
+------------+-------+-----------------------------+-------------------+
| 4 Rows     |       | 15,232 Payload Bytes        | 1,024 FEC Parity  |
+------------+-------+-----------------------------+-------------------+
```

- **Columns 1 to 6 (Row 1)**: Frame Alignment Signal (FAS) fixed pattern: `0xF6 0xF6 0xF6 0x28 0x28 0x28`.
- **Column 7 (Row 1)**: Multi-Frame Alignment Signal (MFAS), an 8-bit counter cycling from 0 to 255.
- **Columns 8 to 14**: ODU overhead containing Tandem Connection Monitoring (TCM1 to TCM6), GCC1/2, and APS/PCC.
- **Columns 15 to 16**: OPU overhead containing client mapping parameters.
- **Columns 17 to 3824**: Optical Payload Unit (OPU) payload area.
- **Columns 3825 to 4080**: Reed-Solomon RS(255, 239) parity providing forward error correction.

## 2. Container Hierarchy and Bitrates

| Container | Nominal Bitrate (Gbps) | Primary Client Mapping |
|-----------|------------------------|------------------------|
| ODU0      | 1.244160               | Gigabit Ethernet (1GbE)|
| ODU1      | 2.498775               | STM-16 / 2x ODU0       |
| ODU2      | 9.995276               | STM-64 / 10GE LAN      |
| ODU2e     | 10.356001              | Overclocked 10GE LAN   |
| ODU3      | 40.150519              | STM-256 / 40GE         |
| ODU4      | 104.355975             | 100GE client           |
| ODUflex   | n * 1.244160           | Flexible client rate   |

## 3. Generic Mapping Procedure (GMP)

The Generic Mapping Procedure (GMP) maps asynchronous client signals into server frames using sigma-delta distribution.

For a server frame with `B` available payload positions and client rate requiring `C_m` entities, the step accumulator evaluates:

```
acc_next = acc_prev + C_m
is_payload = (acc_next >= B)
```

This distributes payload entities uniformly across the 15,232 payload byte positions, eliminating bursty buffer delays and minimizing jitter.
