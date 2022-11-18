# GMPLS Control Plane and Optical Protection Switching

Safety-critical optical core infrastructure mandates resilient protection mechanisms capable of restoring traffic within a strict 50 millisecond time budget following physical fiber cuts or amplifier failures.

## 1. Link Management Protocol (RFC 4204)

Ferrule models the Link Management Protocol (LMP) running over out-of-band or in-band optical supervisory channels (OSC, 1510 nm / 1610 nm).

The Control Channel (CC) state machine enforces neighbor discovery and fast fault isolation:

```
[Down] ---> (Transmit Config) ---> [ConfSend]
  |                                    |
(Receive Config)              (Receive ConfigAck)
  |                                    |
  v                                    v
[ConfRcvd] ---> (Send ConfigAck) ---> [Up]
```

Rapid Hello messages (150 ms period, 600 ms dead interval) ensure sub-second detection of control conduit failures.

## 2. ITU-T G.808.1 Linear Protection Switching

Optical 1+1 and 1:N protection architectures monitor trail signal quality and trigger immediate selector switching upon signal failure.

### Request Priorities (G.808.1 Section 6.2)

1. **Lockout of Protection (LO)**: Administrative command preventing protection channel usage.
2. **Forced Switch (FS)**: Operator override directing traffic to the backup path.
3. **Signal Fail Working (SF-W)**: Physical loss of signal (LOS) or framing (LOF) on the primary path.
4. **Signal Fail Protect (SF-P)**: Failure on the protection entity.
5. **Signal Degrade (SD)**: Pre-FEC bit error rate exceeding the degraded threshold.
6. **Manual Switch (MS)**: Operator requested trial switch.
7. **Wait to Restore (WTR)**: Guard timer (typically 300 seconds) preventing flapping after link repair.
8. **No Request (NR)**: Normal operating condition.

## 3. Sub-50ms Timing Budget Breakdown

```
+-----------------------------------+------------+
| Action                            | Budget     |
+-----------------------------------+------------+
| Photodiode LOS hardware detection |  2.0 ms    |
| APS K1/K2 byte signaling dispatch |  4.0 ms    |
| Optical switch matrix actuation   |  8.0 ms    |
| Receiver DSP frame re-lock        |  4.4 ms    |
+-----------------------------------+------------+
| Total Switch Completion Time      | 18.4 ms    |
| (ITU-T G.808.1 Standard Budget)   | 50.0 ms    |
+-----------------------------------+------------+
```
