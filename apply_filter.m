%% Get input and output locations
%% WARNING - output can overwrite if existing files with same name are present
[file,location,indx] = uigetfile( ...
    {'*.wav;*.flac;*.mp3;*.m4a;*.mp4;*.ogg;*.oga;*.opus', ...
    'Sound Files (*.wav, *.flac, *.mp3, *.m4a, *.mp4, *.ogg, *.oga, *.opus)'}, ...
    'Select One or More Sound Files', ...
    'MultiSelect', 'on');

[filter_file,filter_location,filter_indx] = uigetfile( ...
    {'*.mat', ...
    'Filter File (*.mat)'}, ...
    'Select Filter File', ...
    'eqfilter-omems.mat');
filter_file=fullfile(filter_location, filter_file);

fprintf('\n')
disp("Loading filter file: " + filter_file + "...")
eqfilter = load(filter_file);

% Assume first (i.e. earliest created) field contains filter
fns = fieldnames(eqfilter);
eqfilter = eqfilter.(fns{1});

if size(eqfilter, 2) ~= 2
    error('Must be a two channel (i.e. stereo) filter')
end

%%
fprintf('\n')
disp("Enter gain in dialogue box (or select ""OK"" - zero dB (x1) - for no change in gain)...")
answer = inputdlg("Enter gain in dB (e.g. 6dB ~= double amplitude)","GAIN",[1 45],"0");
if isempty(answer)
    warning("""Cancel"" selected. Setting gain to zero dB (x1)")
    answer={"0"};
end
gain_dB = str2double(answer{1});
gain = 10.^(gain_dB / 20); % 20 dB is 10x gain
disp("Applying gain x" + gain + "(" + gain_dB + " dB)")
eqfilter = eqfilter * gain;

%% WARNING - can overwrite e.g. output directory same as input directory
opdir = uigetdir(pwd, 'Output Directory *** WARNING - WILL OVERWRITE EXISTING FILES ***');

%% Filtering loop, with peak level checking
input_global_max = 0;
output_global_max = 0;

for f = string(file)
    input_full_path = fullfile(location,f{1});
    disp("Reading: "+ input_full_path+"...");
    [y,fs]=audioread(input_full_path);

    if fs ~= 44100
        error("Sampling rate " + fs + " samples/sec. is not supported. Currently only 44100 samples/sec. is supported.")
    end

    switch size(y,2)
        case 1
            warning('Mono file. Converting to stereo.')
            y=repmat(y,1,2);
        case 2
            % Already stereo - nothing to do
        otherwise
            error("This script can only handle mono or stereo files.")
    end

    input_max = max(abs(y(:)));
    input_global_max = max(input_global_max, input_max);
    disp("Input max. amplitude: " + input_max + " (" +  20*log10(input_max) + " dB)");

    disp("Filtering...")
    for channel=1:2
        y(:,channel) = conv(y(:,channel), eqfilter(:,channel), 'same');
    end

    output_max = max(abs(y(:)));
    output_global_max = max(output_global_max, output_max);
    disp("Output max. amplitude: " + output_max + " (" +  20*log10(output_max) + " dB)");

    output_full_path = fullfile(opdir, f{1});
    disp("Writing: "+ output_full_path+"...");
    audiowrite(output_full_path,y,fs);
end
disp('Finished normally.')
disp('Summary:')
disp("Input max. amplitude: " + input_global_max + " (" +  20*log10(input_global_max) + " dB)");
disp("Output max. amplitude: " + output_global_max + " (" +  20*log10(output_global_max) + " dB)");
