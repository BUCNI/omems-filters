# Dual 44.1 / 48 kHz operation — technical notes

*(Added 2026-07-13.)*

## Summary

`apply_filter.m` now accepts audio files at **44100 or 48000 samples/sec.** (batches may mix both rates). The equalisation filters themselves remain calibrated at 44.1 kHz; for a 48 kHz file the script resamples the **filter kernel** (~4001 taps) to 48 kHz once — the audio itself is never resampled.

Resampling the short kernel rather than the audio is both cheaper and cleaner: it is a one-off conversion of a few thousand samples instead of two lossy passes (48 → 44.1 → 48 kHz) over every stimulus file.

## The sample rate converter: `srconvert.m`

Pure base MATLAB — no toolboxes (`sinc`, `resample`, `upfirdn`, `kaiser`, `firpm` etc. from Signal Processing Toolbox are all avoided; even `sinc` is reimplemented locally).

- Rational conversion by L/M = `fsOut/fsIn` in lowest terms; 44.1 → 48 kHz gives **L/M = 160/147** via `gcd`.
- Bandlimited ("ideal") interpolation: Kaiser-windowed sinc lowpass at `min(fsIn,fsOut)/2`, evaluated polyphase — `y[m] = Σₙ x[n]·h(mM − nL)` grouped by output residue class, so the ×160 zero-stuffed signal is never materialised.
- Zero-phase (centred kernel), so time alignment with `conv(..., 'same')` is preserved.
- Quality parameters: `A` = sinc zero-crossings per side (default 24; `apply_filter.m` uses 64 for kernel conversion since cost is negligible), `beta` = Kaiser shape (default 10, ≈ −100 dB stopband).

### Measured quality (MATLAB R2026a, 2026-07-13)

- Round-trip 44.1 → 48 → 44.1 kHz tone error: ≈ **−100 dB** in-band (100 Hz – 15 kHz); −35 dB at 20 kHz with default `A=24` (transition band; use larger `A` if that matters).
- Passband amplitude error on a 1 kHz tone: ~3×10⁻⁶.
- Resampled 4001-tap equalisation kernel vs. original: transfer-function match **< 0.001 dB** at every frequency where the equaliser has meaningful response; RMS deviation 0.027 dB over 50 Hz – 20 kHz (the only larger dB deviations sit inside notches at −100 dB response and below, where dB differences are meaningless).
- End-to-end: the same 1 kHz tone rendered at 44.1 and at 48 kHz, filtered through the respective kernels, differs by **0.00006 dB**.

## The subtle bit: kernel vs. signal scaling

Naively sinc-resampling the kernel gives a uniform **+0.736 dB** gain error — exactly `20·log10(48000/44100)`.

Amplitude-preserving resampling is the correct convention for *signals*, but a *filter kernel's* transfer function scales by `fsOut/fsIn` when resampled that way: the impulse-response samples become denser, so the convolution sum `Σ h[k]·x[n−k]` grows by the rate ratio. To carry a filter to a new rate with its gain-vs-physical-frequency response unchanged, rescale after resampling:

```matlab
h48 = srconvert(h44, 44100, 48000) * (44100/48000);
```

`apply_filter.m` does this automatically (see also the note in `srconvert.m`'s help).

## Caveats / future work

- The filters' native rate is hard-coded as `FILTER_FS = 44100` in `apply_filter.m`, because the `.mat` filter files do not store a sample rate. If a future calibration is performed at 48 kHz, save `fs` into the `.mat` alongside `eqfilter` and read it in `apply_filter.m`.
- Equalisation only covers the calibrated band: content above 22.05 kHz in 48 kHz files simply passes through the resampled kernel's rolloff. This is physically correct — there is no calibration data above 22.05 kHz.
