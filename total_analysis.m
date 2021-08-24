%% Data directories

num_blocks = 19;
dir = fullfile('/Users', 'kshinozuka', 'Documents', 'Oxford', 'Research', 'Data Analysis', '1808');
datadir = fullfile(dir, 'data');
spmdir = fullfile(dir, 'spm_files');
epocheddir = fullfile(dir, 'epoched');
continuousdir = fullfile(dir, 'continuous');
strucdir = fullfile(dir, 'structurals');
coregdir = fullfile(dir, 'coreg');
fieldtripdir = fullfile(dir, 'fieldtrip');
optdir = fullfile(dir, 'opt');
maxfilterdir = fullfile(dir, 'maxfilter'); % python ohba_maxfilter.py cmore_fifs.txt /ohba/pi/mwoolrich/mvanes/analysis/cmore/maxfilt_data/ --maxpath /neuro/bin/util/maxfilter --scanner Neo --inorder 9 --tsss --mode multistage --headpos --movecompinter --hpig 0.97
maxfilterv2dir = fullfile(dir, 'maxfilter_v2'); % python ohba_maxfilter.py cmore_fifs.txt /ohba/pi/mwoolrich/mvanes/analysis/cmore/maxfilt_data/ --scanner Neo --tsss --mode multistage --headpos --movecomp
maxfilterv3dir = fullfile(dir, 'maxfilter_v3'); % same as above but without movecomp
maxfilterv4dir = fullfile(dir, 'maxfilter_v4'); % maxfilter \
                                                % -cal /vols/MEG/TriuxNeo/system/sss/sss_cal.dat\
                                                % -ctc /vols/MEG/TriuxNeo/system/ctc/ct_sparse.fif\
                                                % -v -st -movecomp -hpig 0.96
                                                % -f <in-file> -o <out-file> &> <log-file>
maxfilterv5dir = fullfile(dir, 'maxfilter_v5'); % same as v4 but without movecomp 
maxfilterv5_no_mcdir = fullfile(dir, 'maxfilter_v5', 'no_MC');
maxfilterv6dir = fullfile(dir, 'maxfilter_v6'); % same as v1 but hpig = 0.96
maxfilterv7dir = fullfile(dir, 'maxfilter_v7'); % same as v5 but without temporal extension
spm_no_maxfilterdir = fullfile(dir, 'spm_no_maxfilter');
amplitude_timecoursesdir = fullfile(continuousdir, 'amplitude_timecourses');
spectrogram_and_smartglassdir = fullfile(continuousdir, 'spectrogram_and_triggers_smartglass');
spectrograms_magdir = fullfile(continuousdir, 'spectrograms_MEGMAG');
spectrograms_planardir = fullfile(continuousdir, 'spectrograms_MEGPLANAR');
psd_alldir = fullfile(continuousdir, 'PSD_all_MEGPLANAR');
psd_visualdir = fullfile(continuousdir, 'PSD_visual_MEGPLANAR');
psd_motordir = fullfile(continuousdir, 'PSD_motor_MEGPLANAR');
smartglass_timecoursedir = fullfile(dir, 'smartglass_timecourse');
icadir = fullfile(spm_no_maxfilterdir, 'ICA');
mnedir = fullfile(spmdir, 'MNE');
mne_africadir = fullfile(spmdir, 'MNE_plus_AFRICA');
auditory_ERFdir = fullfile(epocheddir, 'auditory_ERF');
movement_TFRdir = fullfile(epocheddir, 'fieldtrip', 'movement_TFR');
comparisondir = fullfile(epocheddir, 'fieldtrip', 'comparison_Smartglass_trigger_ERF');

currentsession = '_v5';

%% SPM conversion (OSL)

for j=1:num_blocks
    session_name{j} = sprintf(['%d' currentsession],j);
    D = osl_import(fullfile(maxfilterv5_no_mcdir, [num2str(j) '_nomc_mf.fif']));
    D_files{j} = D.copy(fullfile(spmdir,session_name{j}));
end

%% Preprocessing (OSL)

for i=1:num_blocks
    
    spm_file = fullfile(spmdir, [num2str(i) currentsession '.mat']);
    D = spm_eeg_load(spm_file);
    
    % AFRICA
    % Manual artefact rejection for OLP blocks in order to remove
    % Smartglass artefact
    if i == 2 || (mod(i,2) == 1 && i ~= 1) || i == 18 % select OLP blocks
        artefact_types = {'ECG','EOG','EMG'};
        D = osl_africa(D,'used_maxfilter',true,...
        'artefact_channels',artefact_types, ...
        'modality', {'MEGANY'});
        D.save;
        % manually select bad components to remove Smartglass artefact
        D = osl_africa(D, 'do_ident', 'manual',...
        'used_maxfilter',true,...
        'modality', {'MEGANY'});
        D.save;
    else
        artefact_types = {'ECG','EOG','EMG'};
        D = osl_africa(D,'used_maxfilter',true,...
        'artefact_channels',artefact_types, ...
        'modality', {'MEGANY'});
        D.save;
    end 
    
    D = spm_eeg_downsample(struct('D',D,'fsample_new',250));

    % Filter
    D = osl_filter(D,[.1 100],'prefix','');

    % Notch filter
    for ifilt = 50:50:100
        D = osl_filter(D,-[ifilt-2 ifilt+2],'prefix','');
    end

    % Bad Segments
    D = osl_detect_artefacts(D,'badchannels',true, 'badtimes', true, 'modalities',{'MEGMAG','MEGPLANAR'});
    
    D_continuous = D;
    session_name{i} = sprintf(['%d_continuous' currentsession],i);
    D_continuous.copy(fullfile(continuousdir,session_name{i})); 
   
end
 
%% Amplitude timecourse over all gradiometers (OSL)

for i = 1:num_blocks
    continuous_files{i} = fullfile(continuousdir, [num2str(i) '_continuous' currentsession '.mat']);
    D = spm_eeg_load(continuous_files{i});
    chaninds = D.indchantype('MEGPLANAR');
    figure();
    plot(D.time,squeeze(mean(D(chaninds,:,:))));
    saveas(gcf, fullfile(amplitude_timecoursesdir, [num2str(i) '_amptc' currentsession '.fig']));
end     

%% Spectrogram over all sensors (OSL)

for i = 1:num_blocks         
    continuous_files{i} = fullfile(continuousdir, [num2str(i) '_continuous' currentsession '.mat']);
    D = spm_eeg_load(continuous_files{i});    
    S = struct('D',D);
    S.chantype='MEGPLANAR';
    [spectrogram, F, T] = osl_plotspectrogram(S);
    figure; imagesc(T, F, spectrogram); colorbar
    caxis manual
    caxis([-6.5 1.5]); % colorbar limits set to limits of spectrogram for v5
    saveas(gcf, fullfile(spectrograms_planardir, [num2str(i) '_spectrogram_planar' currentsession '.fig']));
end

%% Power spectral density over all planar gradiometers (OSL)

for i = 1:num_blocks
    D = spm_eeg_load(fullfile(continuousdir, [num2str(i) '_continuous' currentsession '.mat']));
    osl_quick_spectra(D);
    saveas(gcf, fullfile(psd_alldir, ['psd' num2str(i) '_planar' currentsession '.fig']));
end

%% Power spectral density over one gradiometer on visual cortex (OSL)

for i = 1:num_blocks
    D = spm_eeg_load(fullfile(continuousdir, [num2str(i) '_continuous_nonotch' currentsession '.mat']));
    osl_quick_spectra_indiv(D,233); % ind 233 = MEG1931
    saveas(gcf, fullfile(psd_visualdir, ['psd_nonotch_' num2str(i) '_planar' currentsession '.fig']));
end

%% Power spectral density over one gradiometer on motor cortex (OSL)

for i = 1:num_blocks
    D = spm_eeg_load(fullfile(continuousdir, [num2str(i) '_continuous_nonotch' currentsession '.mat']));
    osl_quick_spectra_indiv(D,88); % ind 88 = MEG0643
    saveas(gcf, fullfile(psd_motordir, ['psd_nonotch_' num2str(i) '_planar' currentsession '.fig']));
end

%% Plot spectrogram alongside timecourse of Smartglass triggers (FieldTrip)

addpath('/Users/kshinozuka/Documents/Oxford/Research/Data Analysis/hline_vline');

for i = 1:num_blocks

    if i == 2 || (mod(i,2) == 1 && i ~= 1) || i == 18

        cfg = [];
        cfg.headerfile = fullfile(spmdir, [num2str(i) currentsession '.mat']);

        event = ft_read_event(cfg.headerfile, 'headerformat', [], 'eventformat', [], 'dataformat', []);

        for k=1:numel(event)
            x(k) = event(k).value;
            sample(k) = event(k).sample;
        end

%         continuous_files{i} = fullfile(continuousdir, [num2str(i) '_continuous' currentsession '.mat']);
%         D = spm_eeg_load(continuous_files{i});    
%         S = struct('D',D);
%         S.chantype='MEGPLANAR';
%         [spectrogram, F, T] = osl_plotspectrogram(S);
% 
%         figure(); 
%         subplot(211)
%         imagesc(T, F, spectrogram); colorbar
%         
%         addpath('/Users/kshinozuka/Documents/Oxford/Research/Data Analysis/hline_vline');
% 
%         subplot(212)
%         for k=1:size(sample,2)
%             time(k) = sample(k)/1000;
%             if x(k)==32
%                 vline(time(k),'red')
%             elseif x(k)==64
%                 vline(time(k),'blue')
%             end
%         end
% 
%         saveas(gcf, fullfile(spectrogram_and_smartglassdir, [num2str(i) '_spectrogram_triggers' currentsession '.fig']));
        
        % plot timecourse of triggers on its own
        figure();
        for k=1:size(sample,2)
            time(k) = sample(k)/1000;
            if x(k)==32
                vline(time(k),'red')
            elseif x(k)==64
                vline(time(k),'blue')
            end
        end
        
        saveas(gcf, fullfile(smartglass_timecoursedir, [num2str(i) '_smartglass_timecourse.fig']));
        
    end
    
end

%% Epoching (OSL)

% For the first couple data acquisitions, I sent the same trigger code for
% two different events in OLP blocks (auditory cue and button release).

for j=1:num_blocks
    continuous_files{j} = fullfile(continuousdir, [num2str(j) '_continuous' currentsession '.mat']);
end

for i = 1:num_blocks
            
    S = [];
    S.D = continuous_files{i};
    D_continuous=spm_eeg_load(continuous_files{i});

    pretrig = -1000;
    posttrig = 1000;
    S.timewin = [pretrig posttrig];

    % event definitions
    S.trialdef(1).conditionlabel = 'OptiTrack on';
    S.trialdef(1).eventtype = 'STI101_down';
    S.trialdef(1).eventvalue = 2; 
    S.trialdef(2).conditionlabel = 'OptiTrack off';
    S.trialdef(2).eventtype = 'STI101_down';
    S.trialdef(2).eventvalue = 3;     
    S.trialdef(3).conditionlabel = 'button released';
    S.trialdef(3).eventtype = 'STI101_down';
    S.trialdef(3).eventvalue = 4;
    S.trialdef(4).conditionlabel = 'button pressed';
    S.trialdef(4).eventtype = 'STI101_down';
    S.trialdef(4).eventvalue = 5;
    S.trialdef(5).conditionlabel = 'auditory left';
    S.trialdef(5).eventtype = 'STI101_down';
    S.trialdef(5).eventvalue = 8;
    S.trialdef(6).conditionlabel = 'auditory right';
    S.trialdef(6).eventtype = 'STI101_down';
    S.trialdef(6).eventvalue = 9;
    S.trialdef(7).conditionlabel = 'auditory central';
    S.trialdef(7).eventtype = 'STI101_down';
    S.trialdef(7).eventvalue = 10;          
    S.trialdef(8).conditionlabel = 'Smartglass transparent';
    S.trialdef(8).eventtype = 'STI101_down';
    S.trialdef(8).eventvalue = 32;
    S.trialdef(9).conditionlabel = 'Smartglass opaque';
    S.trialdef(9).eventtype = 'STI101_down';
    S.trialdef(9).eventvalue = 64;

    S.reviewtrials = 0;
    S.save = 0;
    S.epochinfo.padding = 0;
    S.event = D_continuous.events;
    S.fsample = D_continuous.fsample;
    S.timeonset = D_continuous.timeonset;

    [epochinfo{i}.trl, epochinfo{i}.conditionlabels] = spm_eeg_definetrial(S);

    S2 = epochinfo{i};
    S2.D = D_continuous;
    Dep = osl_epoch(S2);
    session_name{i} = sprintf(['%d_epoched' currentsession],i);
    Dep_files{i} = Dep.copy(fullfile(epocheddir,session_name{i}));
        
end


%% Smartglass ERF (FieldTrip)

for i = 1:num_blocks
    
    if i == 2 || (mod(i,2) == 1 && i ~= 1) || i == 18 % OLP trials, where the Smartglass is intermittently on/off
        
        epoched_files{i} = fullfile(epocheddir, [num2str(i) '_epoched' currentsession '.mat']);
        D = spm_eeg_load(epoched_files{i});
        data = spm2fieldtrip(D);
        
        cfg = [];
        cfg.data = data;
        cfg.trials = data.trialinfo == 2;          % corresponds to the Smartglass turning off
        data_sg_off = ft_redefinetrial(cfg, data); % sg_off = opaque Smartglass
        
        cfg = [];
        avg = ft_timelockanalysis(cfg, data_sg_off);
        
        cfg1 = [];
        cfg1.channel='meg';
        
        cfg2 = [];
        cfg2.channel='STI101';
        
        figure;
        subplot(211)
        ft_singleplotER(cfg1, avg);
        subplot(212)
        ft_singleplotER(cfg2, avg);
        
        saveas(gcf, fullfile(comparisondir, ['epoching_trigger_MEG_' num2str(i) currentsession '.fig']));
               
    end 
end

%% Compare auditory ERF across CLP/OLP blocks, and between CLP & OLP blocks

%% across CLP blocks

for i = 1:num_blocks
    
    if mod(i,2) == 0 && i > 3 && i < 15
    
        epoched_files{i} = fullfile(epocheddir, [num2str(i) '_epoched' currentsession '.mat']);
        D = spm_eeg_load(epoched_files{i});
        
        good_AL_trials = D.indtrial('auditory left', 'good');
        good_AR_trials = D.indtrial('auditory right', 'good');
        good_auditory_trials = cat(2, good_AL_trials, good_AR_trials);
    
        cfg = [];
        cfg.channel = {'all'};
        cfg.colorbar = 'yes';
        cfg.layout = fullfile(osldir,'layouts','neuromag306mag.lay');
        
        topo                = squeeze(mean(D(indchantype(D,'MEGPLANAR'),:,good_auditory_trials),3));
        topos_CLP{i}        = topo;
    
        data                = [];
        data.dimord         = 'chan_comp';
        data.topo           = topo;
        data.topolabel      = D.chanlabels(indchantype(D,'MEGMAG'));
        data.time           = {D.time};
        data_array{i}       = data;
        
        ft_topoplotER(cfg, data);
        saveas(gcf, fullfile(auditory_ERFdir, [num2str(i) '_CLP_auditory_ERF' currentsession '.fig']));
        
    end
    
end


%% across OLP blocks

for i = 1:num_blocks
    
    if mod(i,2) == 1 && i > 3 && i < 16
    
        epoched_files{i} = fullfile(epocheddir, [num2str(i) '_epoched' currentsession '.mat']);
        D = spm_eeg_load(epoched_files{i});
        
        good_AC_trials = D.indtrial('auditory central', 'good');

        cfg = [];
        cfg.channel = {'all'};
        cfg.colorbar = 'yes';
        cfg.layout = fullfile(osldir,'layouts','neuromag306mag.lay');
        
        topo                    = squeeze(mean(D(indchantype(D,'MEGPLANAR'),:,good_AC_trials),3));
        topos_OLP{i}            = topo;
    
        data                = [];
        data.dimord         = 'chan_comp';
        data.topo           = topo;
        data.topolabel      = D.chanlabels(indchantype(D,'MEGMAG'));
        data.time           = {D.time};
        
        ft_topoplotER(cfg, data);
        saveas(gcf, fullfile(auditory_ERFdir, [num2str(i) '_OLP_auditory_ERF' currentsession '.fig']));
        
    end
    
end

%% between CLP & OLP blocks

cfg = [];
cfg.channel = {'all'};
cfg.colorbar = 'yes';
cfg.layout = fullfile(osldir,'layouts','neuromag306mag.lay');

% concatenate CLP topos
for i = 4:2:14
    if i == 4
        cat_CLP_topos = topos_CLP{i};
    else
        cat_CLP_topos = cat(2, topos_CLP{i}, cat_CLP_topos);
    end
end

% concatenate OLP topos
for i = 5:2:15
    if i == 5
        cat_OLP_topos = topos_OLP{i};
    else
        cat_OLP_topos = cat(2, topos_OLP{i}, cat_OLP_topos);
    end
end

% assume all D_epoched have the same time and MEGMAG/MEGPLANAR channel
% indices
D = spm_eeg_load(epoched_files{4});

data_CLP                = [];
data_CLP.dimord         = 'chan_comp';
data_CLP.topo           = cat_CLP_topos;
data_CLP.topolabel      = D.chanlabels(indchantype(D,'MEGMAG'));
data_CLP.time           = {D.time};

data_OLP                = [];
data_OLP.dimord         = 'chan_comp';
data_OLP.topo           = cat_OLP_topos;
data_OLP.topolabel      = D.chanlabels(indchantype(D,'MEGMAG'));
data_OLP.time           = {D.time};

ft_topoplotER(cfg, data_CLP);
saveas(gcf, fullfile(auditory_ERFdir, ['concat_CLP_auditory_ERF' currentsession '.fig']));

ft_topoplotER(cfg, data_OLP);
saveas(gcf, fullfile(auditory_ERFdir, ['concat_OLP_auditory_ERF' currentsession '.fig']));

%% Timecourse of button presses and auditory cues (to determine time-window of interest for ERS/ERD analysis)

addpath('/Users/kshinozuka/Documents/Oxford/Research/Data Analysis/hline_vline');
clear x
clear sample
clear event

i = 1;

cfg = [];
cfg.headerfile = fullfile(spmdir, [num2str(i) currentsession '.mat']);
cfg.chanindx = 323;
cfg.detectflank = 'bitoff'; 

event = ft_read_event(cfg.headerfile, 'headerformat', [], 'eventformat', [], 'dataformat', []);

for k=1:numel(event)
    x(k) = event(k).value;
    sample(k) = event(k).sample;
end

%         continuous_files{i} = fullfile(continuousdir, [num2str(i) '_continuous' currentsession '.mat']);
%         D = spm_eeg_load(continuous_files{i});    
%         S = struct('D',D);
%         S.chantype='MEGPLANAR';
%         [spectrogram, F, T] = osl_plotspectrogram(S);
% 
%         figure(); 
%         subplot(211)
%         imagesc(T, F, spectrogram); colorbar
%         
%         addpath('/Users/kshinozuka/Documents/Oxford/Research/Data Analysis/hline_vline');
% 
%         subplot(212)
%         for k=1:size(sample,2)
%             time(k) = sample(k)/1000;
%             if x(k)==32
%                 vline(time(k),'red')
%             elseif x(k)==64
%                 vline(time(k),'blue')
%             end
%         end
% 
%         saveas(gcf, fullfile(spectrogram_and_smartglassdir, [num2str(i) '_spectrogram_triggers' currentsession '.fig']));

% plot timecourse of triggers on its own
figure();
for k=1:size(sample,2)
    time(k) = sample(k)/1000;
%     if x(k)==5
%         vline(time(k),'red')
%     elseif x(k) == 8 | x(k) == 9
%         vline(time(k),'blue')
    if x(k)==4
        vline(time(k)','green')
    end
end

%% (Numerical) timeline of all triggers

for i = 1:num_blocks
    
    if i ~= 16
        
        cfg = [];
        cfg.headerfile = fullfile(spmdir, [num2str(i) currentsession '.mat']);

        event = ft_read_event(cfg.headerfile, 'headerformat', [], 'eventformat', [], 'dataformat', []);

        timeline = [];
        samples = [];
        values = [];
        onoff = [];

        for j=1:numel(event)
            samples = [samples event(j).sample];
            values = [values event(j).value];
            if strcmp(event(j).type, 'STI101_down')
                onoff = [onoff 0];
            else
                onoff = [onoff 1];
            end
        end

        max_sample = event(numel(event)).sample;
        isoff = true;

        for k=1:max_sample     
            if ismember(k,samples)
                sample_idx = find(samples==k);
                if onoff(sample_idx) == 0
                    isoff = true;
                    timeline = [timeline 0];
                else
                    isoff = false;
                    val = values(sample_idx);
                    timeline = [timeline val];
                end
            else
                if isoff
                    timeline = [timeline 0];
                else
                    timeline = [timeline val];
                end
            end
        end

        bounds = [0];
        vals = [0];
        for l=2:size(timeline,2)
            if timeline(l) ~= timeline(l-1)
                bounds = [bounds l];
                vals = [vals timeline(l)];
            end
        end

        output = [bounds(:) vals(:)];
        outputs{i} = output;
        
    end
end

%% Beta ERS & ERD

close all

for i = 1:num_blocks
    
    if i ~= 16
        
%         continuous_files{i} = fullfile(continuousdir, [num2str(i) '_continuous' currentsession '.mat']);
%         D = spm_eeg_load(continuous_files{i});
%         data = spm2fieldtrip(D);

        continuous_files{i} = fullfile(continuousdir, [num2str(i) '_continuous' currentsession '.mat']);

        cfg                         = [];
        cfg.datafile                = continuous_files{i};
        cfg.headerfile              = continuous_files{i};
        cfg.trialfun                = 'ft_trialfun_general'; % this is the default
        cfg.trialdef.eventtype      = 'STI101_down';
        cfg.trialdef.eventvalue     = [4]; 
        if i == 1 || (mod(i,2) == 0 && i ~= 2 && i ~= 16 && i ~= 18) % CLP blocks
            cfg.trialdef.prestim        = 1.8; % cue = 0.3s (after button press) + point = 1s + 0.5s
            cfg.trialdef.poststim       = 2.4; % time until next button press + 0.5s
        else
            cfg.trialdef.prestim        = 3.0; % get ready = 1s + wait = 0.5s + point = 1s 
            cfg.trialdef.poststim       = 3.0; % time until next button press + 0.5s
        end 

        cfg = ft_definetrial(cfg);
        data_preproc = ft_preprocessing(cfg);

        cfg = [];
        cfg.trials   = data_preproc.trialinfo == 4;
        data_release = ft_redefinetrial(cfg, data_preproc);

        cfg            = [];
        cfg.output     = 'pow';
        % select channels over the motor cortex
        cfg.channel    = {'MEG0123' 'MEG0122' 'MEG0342' 'MEG0343' 'MEG0323' 'MEG0322' 'MEG0332' 'MEG0333' 'MEG0643' 'MEG0642' 'MEG0623' 'MEG0622' 'MEG1033' 'MEG1032' 'MEG1242' 'MEG1243' 'MEG1233' 'MEG1232' 'MEG1222' 'MEG1223' 'MEG1413' 'MEG1412'};
        cfg.method     = 'mtmconvol';
        cfg.foi        = 13:30;
        cfg.t_ftimwin  = 5./cfg.foi;
        cfg.tapsmofrq  = 0.2 *cfg.foi;
        if i == 1 || (mod(i,2) == 0 && i ~= 2 && i ~= 16 && i ~= 18) % CLP blocks
            cfg.toi    = -1.6:0.05:2.2;
        else
            cfg.toi    = -2.8:0.05:2.8;
        end
        TFRmult        = ft_freqanalysis(cfg, data_release);

        cfg = [];
        cfg.baseline     = [-0.15 0]; % has to be a period when the power is relatively constant
        cfg.baselinetype = 'absolute';
        cfg.showlabels   = 'yes';
        cfg.layout       = fullfile(osldir,'layouts','neuromag306planar.lay');
        cfg.colorbar     = 'yes';
        figure
        ft_singleplotTFR(cfg, TFRmult)
        saveas(gcf, fullfile(movement_TFRdir, [num2str(i) '_movement_TFR_CLPRO_1.8_2.4_OLPRO_3.0_3.0_baseline_0.15_0.2sm' currentsession '.fig']));

    end
    
end




