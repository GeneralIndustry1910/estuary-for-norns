# Estuary

Estuary is a deliberately small four-current looping instrument for
[monome norns](https://monome.org/docs/norns/). Each current is one sample that
plays continuously in Softcut while a slow, independent tide changes only its
volume. The screen is centered on four moving playheads. Each current also gets
louder as its playhead approaches another playhead and fades to silence at the
maximum circular distance. This proximity gain scales the tide; it never
restarts or moves a sample.

## Install

Copy this repository into any directory under `dust/code`, restart norns, and
launch **estuary** from the SELECT menu. Estuary resolves its modules relative
to the script directory, so the repository folder does not need to be renamed.
Estuary does not ship audio: choose a file for each current from
**PARAMETERS > EDIT** before playing.

## Controls

- **E1** selects a current.
- **E2** changes that current's playback speed.
- **E3** changes that current's tide period.
- **K2** resets the selected current's tide phase.

Use **PARAMETERS > EDIT** to choose samples. The PARAMETERS menu also exposes
speed, tide period, tide phase, volume, remembered per-sample gain, LFO shape,
LFO rate, and delay LFO amount for all four currents. Global parameters set
the proximity falloff curve and the shared delay time and feedback. Sample gain
is stored by full file path and restored automatically the next time that sample
is loaded.
