function [y, L, M] = srconvert(x, fsIn, fsOut, A, beta)
%SRCONVERT Rational sample-rate conversion by windowed-sinc interpolation.
%
%   y = SRCONVERT(x, fsIn, fsOut) resamples the columns of x from sample
%   rate fsIn to fsOut using bandlimited ("ideal" sinc) interpolation,
%   windowed with a Kaiser window. Uses base MATLAB only - no toolboxes.
%
%   The conversion is polyphase: x is conceptually upsampled by L,
%   lowpass filtered at min(fsIn,fsOut)/2, and downsampled by M, where
%   L/M = fsOut/fsIn in lowest terms (44100 -> 48000 gives L/M = 160/147).
%   The lowpass is a zero-phase (centered) Kaiser-windowed sinc, so the
%   output is time-aligned with the input: y(m) is the signal value at
%   input time (m-1)*M/L samples. Passband amplitude is preserved.
%
%   [y, L, M] = SRCONVERT(...) also returns the rational factors.
%
%   y = SRCONVERT(x, fsIn, fsOut, A, beta) sets the kernel quality:
%     A    - sinc zero-crossings per side at the lower of the two rates
%            (default 24; kernel half-length is A*max(L,M) high-rate taps)
%     beta - Kaiser window shape (default 10, ~ -100 dB stopband)
%
%   NOTE on resampling FIR filter kernels (as opposed to signals):
%   amplitude-preserving resampling scales a kernel's transfer function
%   by fsOut/fsIn (denser impulse-response samples make the convolution
%   sum larger). To carry a filter to a new rate with its gain-vs-
%   physical-frequency response unchanged, rescale the result:
%       h_new = srconvert(h, fsIn, fsOut) * (fsIn/fsOut);
%
%   Intended primarily for resampling short FIR equalisation kernels
%   (e.g. to run a 44.1 kHz calibrated filter on 48 kHz audio); it also
%   works on full audio signals but is O(Nx*L/M*taps) and unoptimised.

if nargin < 4 || isempty(A),    A = 24;  end
if nargin < 5 || isempty(beta), beta = 10; end

g = gcd(round(fsIn), round(fsOut));
L = round(fsOut)/g;
M = round(fsIn)/g;

wasRow = isrow(x);
if wasRow, x = x(:); end
if L == M
    y = x;
    if wasRow, y = y.'; end
    return
end

[Nx, nch] = size(x);
Ny = ceil(Nx*L/M);

% --- Prototype lowpass at the high (upsampled) rate fsIn*L ---------------
% Cutoff = min(fsIn,fsOut)/2, i.e. 1/(2K) cycles/high-rate-sample.
K  = max(L, M);
Nh = A*K;                          % half-length: taps at n = -Nh..Nh
n  = (-Nh:Nh).';
h  = (1/K) * localsinc(n/K);       % 2*fc*sinc(2*fc*n) with fc = 1/(2K)
w  = besseli(0, beta*sqrt(max(0, 1 - (n/Nh).^2))) / besseli(0, beta);
h  = L * (h .* w);                 % gain L compensates zero-stuffing

% --- Polyphase evaluation ------------------------------------------------
% y(m) = sum_n x(n) * h(m*M - n*L)   (0-based, h centered).
% Group output indices by residue class c = mod(m, L): within a class the
% required filter taps h(r + L*j) form one fixed subfilter, and the output
% is that subfilter convolved with x, read out every M samples.
y = zeros(Ny, nch);
W = cell(1, nch);
for c = 0:L-1
    r  = mod(c*M, L);
    qc = (c*M - r)/L;
    j0 = ceil((-Nh - r)/L);
    j1 = floor(( Nh - r)/L);
    e  = h((j0:j1).'*L + r + Nh + 1);     % subfilter for this class
    t  = (0:floor((Ny - 1 - c)/L)).';     % class members: m = c + L*t
    idx = qc + t*M - j0 + 1;              % 1-based index into conv result
    for ch = 1:nch
        W{ch} = conv(x(:,ch), e);
        ok = idx >= 1 & idx <= numel(W{ch});
        y(c + L*t(ok) + 1, ch) = W{ch}(idx(ok));
    end
end

if wasRow, y = y.'; end
end

function s = localsinc(t)
% sin(pi*t)./(pi*t) with the t==0 limit handled (sinc() needs a toolbox).
s = ones(size(t));
nz = t ~= 0;
s(nz) = sin(pi*t(nz)) ./ (pi*t(nz));
end
