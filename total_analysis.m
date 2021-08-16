%% Data directories

num_blocks = 19;
dir = fullfile('/Users', 'kshinozuka', 'Documents', 'Oxford', 'Research', 'Data Analysis', '1407');
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
maxfilterv6dir = fullfile(dir, 'maxfilter_v6'); % same as v1 but hpig = 0.96
maxfilterv7dir = fullfile(dir, 'maxfilter_v7'); % same as v5 but without temporal extension
spm_no_maxfilterdir = fullfile(dir, 'spm_no_maxfilter');
amplitude_timecoursesdir = fullfile(continuousdir, 'amplitude_timecourses');
spectrogram_and_smartglassdir = fullfile(continuousdir, 'spectrogram_and_triggers_smartglass');
comparisondir = fullfile(epocheddir, 'comparison_Smartglass_trigger_ERF');
spectrograms_magdir = fullfile(continuousdir, 'spectrograms_MEGMAG');
spectrograms_planardir = fullfile(continuousdir, 'spectrograms_MEGPLANAR');
psd_alldir = fullfile(continuousdir, 'PSD_all_MEGPLANAR');
psd_visualdir = fullfile(continuousdir, 'PSD_visual_MEGPLANAR');
psd_motordir = fullfile(continuousdir, 'PSD_motor_MEGPLANAR');
smartglass_timecoursedir = fullfile(dir, 'smartglass_timecourse');
icadir = fullfile(spm_no_maxfilterdir, 'ICA');
mnedir = fullfile(spmdir, 'MNE');
mne_africadir = fullfile(spmdir, 'MNE_plus_AFRICA');

currentsession = '_v5';

%% SPM conversion (OSL)

for j=1:num_blocks
    if j == 5
        session_name{j} = sprintf(['%d' currentsession],j);
        D = osl_import(fullfile(maxfilterv5dir, [num2str(j) '_raw.fif']));
        D_files{j} = D.copy(fullfile(spmdir,session_name{j}));
    end
end

%% Preprocessing (OSL)

for i=1:num_blocks
    
    if i == 2 || (mod(i,2) == 1 && i ~= 1) || i == 18 % select OLP blocks

    spm_file = fullfile(spmdir, [num2str(i) currentsession '.mat']);
    D = spm_eeg_load(spm_file);
    
    % AFRICA
    % Manual artefact rejection for OLP blocks in order to remove
    % Smartglass artefact
%     if i == 2 || (mod(i,2) == 1 && i ~= 1) || i == 18 % select OLP blocks
%         artefact_types = {'ECG','EOG','EMG'};
%         D = osl_africa(D,'used_maxfilter',true,...
%         'artefact_channels',artefact_types, ...
%         'modality', {'MEGANY'});
%         D.save;
%         % manually select bad components to remove Smartglass artefact
%         D = osl_africa(D, 'do_ident', 'manual',...
%         'used_maxfilter',true,...
%         'modality', {'MEGANY'});
%         D.save;
%     else
        artefact_types = {'ECG','EOG','EMG'};
        D = osl_africa(D,'used_maxfilter',true,...
        'artefact_channels',artefact_types, ...
        'modality', {'MEGANY'});
        D.save;
%     end 
    
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
    session_name{i} = sprintf(['%d_continuous_no_manual_ICA' currentsession],i);
    D_continuous.copy(fullfile(continuousdir,session_name{i}));

   end 
   
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
    
    if i == 5 % || (mod(i,2) == 1 && i ~= 1) || i == 18
        continuous_files{i} = fullfile(continuousdir, [num2str(i) '_continuous_no_manual_ICA' currentsession '.mat']);
        D = spm_eeg_load(continuous_files{i});    
        S = struct('D',D);
        S.chantype='MEGPLANAR';
        [spectrogram, F, T] = osl_plotspectrogram(S);
        figure; imagesc(T, F, spectrogram); colorbar
        caxis manual
        caxis([-6.5 1.5]); % colorbar limits set to limits of spectrogram for v5
        saveas(gcf, fullfile(spectrograms_planardir, ['spectrogram_' num2str(i) '_planar_no_manual_ICA' currentsession '.fig']));
    end
    
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

for i = 1:num_blocks

    if i == 2 || (mod(i,2) == 1 && i ~= 1) || i == 18

        cfg = [];
        cfg.headerfile = fullfile(spmdir, [num2str(i) currentsession '.mat']);
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
        data_meg           =  ft_preprocessing(cfg);     % read raw data

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
    
    if i == 2 || (mod(i,2) == 1 && i ~= 1) || i == 18
        
        S = [];
        S.D = continuous_files{i};
        D_continuous=spm_eeg_load(continuous_files{i});

        pretrig = -1000;
        posttrig = 1000;
        S.timewin = [pretrig posttrig];
        
        % event definitions
        S.trialdef(1).conditionlabel = 'Smartglass transparent';
        S.trialdef(1).eventtype = 'STI101_down';
        S.trialdef(1).eventvalue = 32;
        S.trialdef(2).conditionlabel = 'Smartglass opaque';
        S.trialdef(2).eventtype = 'STI101_down';
        S.trialdef(2).eventvalue = 64;
        
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

end

%% ERF (FieldTrip)

for i = 1:num_blocks
    
    if i == 2 || (mod(i,2) == 1 && i ~= 1) || i == 18 % OLP trials, where the Smartglass is intermittently on/off
        
        epoched_files{i} = fullfile(epocheddir, [num2str(i) '_epoched_v5.mat']);
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
