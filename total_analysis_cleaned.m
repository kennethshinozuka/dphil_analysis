%% Data directories

num_blocks = 19;
dir = fullfile('/Users', 'kshinozuka', 'Documents', 'Oxford', 'Research', 'Data Analysis');
datadir = fullfile(dir, 'Data', '1507');
spmdir = fullfile(dir, 'spm_files');
epocheddir = fullfile(dir, 'epoched');
continuousdir = fullfile(dir, 'continuous');
strucdir = fullfile(dir, 'structurals');
coregdir = fullfile(dir, 'coreg');
fieldtripdir = fullfile(dir, 'fieldtrip');

%% SPM conversion

for j=1:num_blocks
    session_name{j} = sprintf('%d',j);
    D = osl_import(fullfile(datadir, [num2str(j) '.fif']));
    D_files{j} = D.copy(fullfile(spmdir,session_name{j}));
end

%% Preprocessing (OSL)

i = 1;
    
spm_files{i} = fullfile(spmdir, [num2str(i) '.mat']);

D = spm_eeg_load(spm_files{i});

D = spm_eeg_downsample(struct('D',D,'fsample_new',250));
D = osl_filter(D,[.1 100],'prefix','');
D = osl_filter(D,-[48 52],'prefix',''); % removes line noise using a notch filter
D = osl_filter(D,-[98 102],'prefix','f'); % removes harmonic of line noise using a notch filter

modalities = {'MEGMAG','MEGPLANAR'};
D = osl_detect_artefacts(D,'badchannels',true,'badtimes',false,'modalities',modalities);
D = osl_detect_artefacts(D,'badchannels',false,'badtimes',true,'modalities',modalities);
D.save;

modality = {'MEGANY'};
artefact_channels = {'ECG','EOG', 'EMG'};
D = osl_africa(D,'used_maxfilter',true,...
    'auto_artefact_chans_corr_thresh',.35,...
    'artefact_channels',artefact_channels,...
    'modality',modality);

D_continuous = D;
session_name{i} = sprintf('%d_continuous',i);
D_continuous_files{i} = D_continuous.copy(fullfile(continuousdir,session_name{i}));
    
%% Spectrogram over all sensors (OSL)

% NOTE: this produces a very strange plot with a massive peak for the last
% few sensors
i = 1;
continuous_files{i} = fullfile(continuousdir, [num2str(i) '_continuous.mat']);
D = spm_eeg_load(continuous_files{i});
figure();plot(D(:,:));


%% Preprocessing (FieldTrip)

i = 1;
spm_files{i} = fullfile(spmdir, [num2str(i) '.mat']);

cfg                = [];
cfg.dataset        = spm_files{i};
cfg.channel        = 'all';                     % define channel type
cfg.hpfilter       = 'yes';                         % enable high-pass filtering
cfg.lpfilter       = 'yes';                         % enable low-pass filtering
cfg.hpfreq         = 1;                             % set up the frequency for high-pass filter
cfg.lpfreq         = 90;                           % set up the frequency for low-pass filter
cfg.bsfilter       = 'yes';
cfg.bsfreq         = [48 52];
cfg.reref          = 'yes';
cfg.refchannel     = 'all';
cfg.refmethod      = 'avg';
data_meg        = ft_preprocessing(cfg);     % read raw data        
        
time = cell2mat(data_meg.time);
trial = cell2mat(data_meg.trial);
trial = mean(trial);
figure(); plot(time,trial);


%% Spectrogram over all sensors over all blocks (FieldTrip)

cfg = [];
concat = ft_appenddata(cfg, data_meg_1, data_meg_2, data_meg_3, data_meg_4, data_meg_5, data_meg_6, data_meg_7, data_meg_8, data_meg_9, data_meg_10, data_meg_11, data_meg_12, data_meg_13, data_meg_14, data_meg_15, data_meg_16, data_meg_17, data_meg_18);

time = cell2mat(concat.time);
trial = cell2mat(concat.trial);
trial = mean(trial);
figure(); plot(time,trial);


%% Power spectral density over all sensors

cfg = [];
cfg.metric = 'zvalue';
cfg.layout = 'neuromag306all.lay';
cfg.channel = 'MEG';
cfg.keepchannel = 'no';
data_MEG_clean = ft_rejectvisual(cfg, concat);

cfg = [];
cfg.output     = 'pow';
cfg.method     = 'mtmfft'
cfg.taper      = 'hanning'
cfg.channel    = 'all';
cfg.foi        = 1:90;
cfg.keeptrials = 'yes'
freq_segmented = ft_freqanalysis(cfg, data_MEG_clean)
        
figure;
plot(freq_segmented.freq, squeeze(mean(squeeze(mean(freq_segmented.powspctrm,2)))), 'linewidth', 2)
xlabel('Frequency (Hz)')
ylabel('Power (\mu V^2)')
    

%% Power spectral density over visual cortex

cfg = [];
cfg.output  = 'pow';
cfg.channel = 'MEG1931';
cfg.method  = 'mtmfft';
cfg.taper   = 'hanning';
cfg.foi     = 1:100;

spectrum = ft_freqanalysis(cfg, data_MEG_clean);

figure;
hold on;
plot(spectrum.freq, (spectrum.powspctrm), 'linewidth', 2)
xlabel('Frequency (Hz)')
ylabel('Power (\mu V^2)')
    


%% Power spectral density over motor cortex

cfg = [];
cfg.output  = 'pow';
cfg.channel = 'MEG0641';
cfg.method  = 'mtmfft';
cfg.taper   = 'hanning';
cfg.foi     = 1:100;

spectrum = ft_freqanalysis(cfg, data_MEG_clean);

figure;
hold on;
plot(spectrum.freq, (spectrum.powspctrm), 'linewidth', 2)
xlabel('Frequency (Hz)')
ylabel('Power (\mu V^2)')
    
%% Power spectral density over all sensors (OSL)

D = spm_eeg_load(fullfile(continuousdir, '1_continuous.mat'));
osl_quick_spectra(D);
    
