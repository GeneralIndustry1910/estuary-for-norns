# estuary for norns

A four-current, time-based sample instrument for monome norns. Samples loop
continuously, their levels rise as their playheads approach one another, and
per-current tide modulation shapes the resulting mix.

## crow waveform LFOs

Connect a monome crow to send one sample-synchronized waveform from each
current:

| current | crow output |
| --- | --- |
| 1 | 1 |
| 2 | 2 |
| 3 | 3 |
| 4 | 4 |

Each output reads that current's selected LFO shape at the sample playhead.
Consequently the CV stays locked to the sample loop and follows changes to its
speed and direction. The default range is bipolar `-5 V` to `+5 V`; unloaded
currents and cleanup output `0 V`.

In PARAMETERS > ESTUARY, `crow waveform output` enables or disables all four
outputs. Each CURRENT group provides `crow minimum`, `crow maximum`, and
`crow slew`. The minimum and maximum can be reversed to invert an output.

> Check the voltage limits of the receiving module before connecting it, and
> adjust the per-current range when it does not accept bipolar or 10 V signals.
