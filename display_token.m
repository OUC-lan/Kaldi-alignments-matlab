function display_token(tokenfile,datfile,framec,audiodir,uidflag)
% The .mat file datfile is created with con
% May need addpath('/local/matlab/voicebox')

% word=1 indicates that the the offset is part of the uid

% display_token('/local/res/stress/datar/WASaa1_AH1.tok','/projects/speech/data/matlab-mat/ls3all.mat')
% display_token('/local/res/ls3/wdata/MYay1.tok','/projects/speech/data/matlab-mat/ls3all.mat')
% display_token('/local/res/stress/datar/CANae1_AE1.tok','/projects/speech/data/matlab-mat/ls3all.mat')
% 3-syllable words in Librispeech monophone model:
%    display_token('/local/matlab/Kaldi-alignments-matlab/data/syl3.tok','/local/matlab/Kaldi-alignments-matlab/data/ls3mono100a.mat')
%    display_token('/local/matlab/Kaldi-alignments-matlab/data/syl3-010.tok','/local/matlab/Kaldi-alignments-matlab/data/ls3mono100a.mat')

% 4-syllable words
% display_token('/local/matlab/Kaldi-alignments-matlab/data/syl4-1020.tok','/local/matlab/Kaldi-alignments-matlab/data/ls3mono100a.mat')
% display_token('/local/matlab/Kaldi-alignments-matlab/data/syl4-2010.tok','/local/matlab/Kaldi-alignments-matlab/data/ls3mono100a.mat')

% display_token('/local/matlab/Kaldi-alignments-matlab/data-bpn/bpn.tok','/local/matlab/Kaldi-alignments-matlab/data-bpn/bpn.mat')
% display_token('/local/matlab/Kaldi-alignments-matlab/data-bpn/word/alguma2.wrd.tok','/local/matlab/Kaldi-alignments-matlab/data-bpn/bpn.mat')

% Tokens of NOT.  First one is the sanity check.
% display_token('/local/res/stress/datar/NOTaa1.tok','/local/matlab/Kaldi-alignments-matlab/data/ls3mono100a.mat')

if nargin < 4
    audiodir = 0;
end

if nargin < 3
    framec = 100;
end


% Default for demo.
if nargin < 1
    % datfile = '/local/matlab/Kaldi-alignments-matlab/data/ls3mono100.mat'; %All the 100k data.
    datfile = '/projects/speech/data/matlab-mat/bp0V.mat';
    tokenfile = '/projects/speech/sys/kaldi-master/egs/bp_ldcWestPoint/bpw2/exp/u1/decode_word_1/tab4-long-err';
    uidflag = 1;
    audiodir = 0; % Audio will be read using Kaldi.
    %cat /projects/speech/sys/kaldi-trunk/egs/librispeech3/s5/data/train_clean_100_V/text | awk -f ../token-index.awk -v WORD=WILLih1 > ls3-WILLih1a.tok
    % tokenfile = /local/matlab/Kaldi-alignments-matlab/data/ls3-WILLih1a.tok.tok';
    % 1836 tokens of SOME
    % tokenfile = '/local/res/stress/datar/SOMEah1.tok'; %ok
    % tokenfile =  '/local/res/stress/datar/CANae1_AE1.tok' 
    % Number of frames to display.
    framec = 160;
end

if nargin == 1
    datfile = '/projects/speech/data/matlab-mat/ls3all.mat';
    audiodir = 0; % Audio will be read using Kaldi.
    tokenfile = ['/local/res/stress/datar/',tokenfile];
    % Number of frames to display.
    framec = 120;
end

% Load sets dat to a structure. It has to be initialized first.
dat = 0;
load(datfile);

Scp = dat.scp;
P = dat.phone_indexer;
Uid = dat.uid;
% Wrd = dat.wrd;
Basic = dat.basic;
Align_pdf = dat.pdf;
Align_phone = dat.align_phone;
Align_phone_len = dat.phone_seq;
Tra = dat.tra;



% Cell array of uids for tokens.
% Indexing and the below corresonds to line numbers in the token file.
Tu = {};
% Vector of word offsets for tokens.
To = [];
% All of the fields. The token file has a variable number of columns
% with properties of the token.
Pa = {};

% Load the token data.
% Running index.
j = 1;
token_stream = fopen(tokenfile);

itxt = fgetl(token_stream);
while ischar(itxt)
    itxt = strtrim(itxt);
    if (uidflag == 1)
        part = strsplit(itxt);
        part2 = strsplit(part{1},'-');
        offset = str2num(part2{length(part2)});
        part3 = part2(2:(length(part2) - 1));
        part3 = part3';
        part3 = sprintf("-%s",part3{:});
        uid = sprintf("%s%s",part2{1},part3);
        uid = uid{1,1};
    else
        part = strsplit(itxt);
        uid = part{1};
        offset = str2num(part{2});
    end
    Tu{j} = uid;
    To{j} = offset;
    % Store all of the fields.
    Part{j} = part;
    itxt = fgetl(token_stream);
    j = j + 1;
end
fclose(token_stream);

% Given a token index j,
%   Tu{j} is the uid for the token as a string, e.g. 'f01br16b22k1-s001'.
%   To{j} is the word offset
%   Part{j} has the fields of the token file.  Part{j}{6} is the word form,
%   e.g. 'este0V'.
 
% Index in Tu and To of token being displayed.
ti = 1;
% Corresponding index in Uid.
ui = dat.um(Tu{ti});
 
% Index in Uid and Align of the utterance being displayed.
% ui = Tu

% Maximum values for uid indices and token indices.
[~,U] = size(Uid);
[~,T] = size(Tu);

% Initialize some variables.


% Variables that are set in nested functions.
uid = 0; uid2 = 0; F = 0; Sb = 0; Pb = 0; Wb = 0; w = 0; w2 = 0; fs = 0;

M = 0; S1 = 0; SN = 0; N = 100;
F = 0; F1 = 0; FN = 0; nsample = 0; nframe = 0; 
PX = 0; ya = 0; tra = 0; wi = 1;
Fn = 0; PDF = 0; lft = 0;
sR = 0; x1 = 0; xn = 0;
positionVector1 = 0;
positionVector2 = 0;

% Pitch.
% Return values for fxrapt.
fx = 0; tt = 0; 

% Return values for fxpfac.
fx2 = 0; pv2 = 0;

% Version of tt with frame indexing.
ttf = 0;
% ttf and fx restricted to the frames being displayed.
fx3 =0; tt3=0;
AX = 0;AX2 = 0;

utterance_data(ui);

% Set phone and audio data for k'th utterance.
    function utterance_data(k)
        uid = cell2mat(Uid(k));
        [F,Sb,Pb,Wb,tra] = parse_ali(uid,Align_pdf,Align_phone_len,Tra,P,k);
        % Escape underline for display.
        uid2 = strrep(uid, '_', '\_');
        PX = Align_phone{k};
        PDF = Align_pdf{k};
        % Maximum frame index
        [~,Fn] = size(F);
        % Load audio. Cat the pipe Scp(uid) into a temporary file.
        % cmd = [Scp(uid), ' cat > /tmp/display_ali_tmp.wav'];
        % This helps flac work.
        % setenv('PATH', '/opt/local/bin:/opt/local/sbin:/opt/local/bin:/opt/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin');
        % system(cmd);
        % wav = '/tmp/display_ali_tmp.wav';
        % Read the temporary wav file.
        % [w,fs] = audioread(wav);
        % Number of audio samples in a centisecond frame.
        wav = find_audio(uid);
        disp(wav);
        [w,fs] = audioread(wav); 
        
        % Deal with possibility of two channels.
        w2 = w;
        [~,ch] = size(w);
        if (ch == 2)
            w = w(:,2);
        end
        
        M = fs / 100;
        [nsample,~] = size(w);
        [~,nframe] = size(F);
        % pitch
        [fx,tt]=fxrapt(w,fs);
        
        % pitch via fxpefax
        tinc = 0.01;
        [fx2a,tx2a,pv2a,fv2a] = fxpefac(w,fs,tinc);
        % Frame version of the time vector tx2.
        tx2b = ceil(tx2a .* (fs / M))';
        % Frame indexed probability of voicing.
        pv2 = ones(1,nframe) * NaN;
        pv2(tx2b) = pv2a;
        % Frame indexed pitch.
        fx2 = ones(1,nframe) * NaN;
        fx2(tx2b) = fx2a;
        
    end

    % Range of samples being displayed, this is global.
    SR = [];
    
    function wav = find_audio(uid)
        % Load the audio, either by using Kaldi to generate a tmp wav file,
        % or by reading from audiodir
        if (audiodir ~= 0)
            wav = [audiodir '/' uid '.wav'];
        else
            % Cat the pipe Scp(uid) into a temporary file.
            cmd = [Scp(uid), ' cat > /tmp/display_ali_tmp.wav'];
            % This helps flac work.
            setenv('PATH', '/opt/local/bin:/opt/local/sbin:/opt/local/bin:/opt/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin');
            system(cmd);
            wav = '/tmp/display_ali_tmp.wav';
        end
    end

    function display_alignment(f)
        subplot('Position',positionVector1);
        % f is the suggested start frame
        % Start frame
        F1 = max([1,min([Fn - framec,f])]);
        % End frame
        FN = min([F1 + framec, Fn]);
        % Display the frame interval to terminal.
        disp([F1,FN])
        % First and last samples to display.
        S1 = floor((F1 - 1) * M + 1); 
        SN = floor((FN - 1) * M - 1);
        % Range of samples to display.
        SR = S1:SN;
        
        % Vertical scale for waveform.
        sk = 1.2 * max(abs(w));
        % Plot the waveform.
        plot(SR/M,w(SR)/sk,'Color',[0.7,0.7,0.7]);
        % Play the sound.
        sound(w(SR),fs);
        
        ya = 1.0;
        disp([S1/M, SN/M, -ya, ya]);
        axis([S1/M, SN/M, -ya, ya]);
        AX = axis();
               
        % Draw subphone bars.
        % SU(N) subphone that the Nth frame is in.
        % SUstart(PH(p)) start of pth phone
        % for p = (SU(F1) + 1):SU(FN)
        % For each subphone in the display range, except for the first.
        for p = (F(1,F1) + 1):F(1,FN)
           % k is a frame
           % k = SUstart(p);
           k = Sb(1,p);
           line([k,k],[-ya,ya],'LineWidth',2.0,'Color',[0.2,0.8,0.8]);
           pdfindex = int2str(PDF(k));
           text(k,ya *  (-0.7 + mod(p,2) * 0.08),pdfindex,'FontSize',12);
        end
        
        % Draw phone bars.
        % For each phone in the display range, except for the first.
        % for p = (PH(F1) + 1):PH(FN)
        for p = (F(2,F1) + 1):F(2,FN)
           % p is a phone as index
           % k is frame where phone p starts.
           k = Pb(1,p);
           pn = int2str(p);
           ps = P.ind2phone(PX(k));
           bar = line([k,k],[-ya,ya] * 0.99,'LineWidth',2.0,'Color',[0.2,0.2,0.85]);
           text(k,ya * 0.8,trim_phone(ps),'FontSize',18);
        end
        
       
        [~,wm] = size(Wb(1,:));
        % For each word index.
        for k = 1:wm
           % Frame index of start of word k.
           ks = Wb(1,k);
           % If the frame index of the word start is in the display range.
           if (F1 <= ks && ks <= FN)
              bar = line([ks,ks],[-ya,ya] * 0.99,'LineWidth',2.0,'Color',[0.85,0.2,0.2]);
              text(ks,-ya * 0.8,tra(k),'FontSize',18);
           end
        end

        skf = max(fx);
        
        tt1 = tt(:,1);
        tt2 = tt1 >= S1 & tt1 <= SN;
        tt3 = tt1(tt2) / M;
        fx3 = (2 * fx(tt2)/skf) - 1.0;
        
        hold;
        plot(tt3,fx3,'*');

        % Plot probability of voicing
        % plot(F1:FN, pv2(F1:FN),'o','MarkerFaceColor',[0.9 0.9 0]);
        plot(F1:FN, pv2(F1:FN),'o','color',[0.7 0.7 0]);
        
        pp = patch([F1,FN,FN,F1],[0,0,ya,ya],'g');
        ps = patch([F1,FN,FN,F1],[0,0,-0.7 * ya,-0.7 * ya],'r' );
        pw = patch([F1,FN,FN,F1],[-0.7 * ya,-0.7 * ya,-ya,-ya],'g' );
        
        % Function handles for use in gui.
        hspp = @subphoneplay;
        hpp = @phoneplay;
        hwp = @wordplay;
        
        set(ps,'ButtonDownFcn',hspp,... 
            'PickableParts','all','FaceColor','r','FaceAlpha',0.02);

        set(pp,'ButtonDownFcn',hpp,... 
            'PickableParts','all','FaceColor','g','FaceAlpha',0.02);
        
        set(pw,'ButtonDownFcn',hwp,... 
            'PickableParts','all','FaceColor','b','FaceAlpha',0.02);
        
        %title([int2str(ui),' ', uid2, ' ', Part{To{ti}}{6}],'FontSize',18);
        title([int2str(ui),' ', uid2, ' ', tra{To{ti}}],'FontSize',18);
        subplot('Position',positionVector2);
        %v = v_ppmvu(w(SR),fs,'e'); 
        %plot(v);
        %figure;
        %plot(tt3,fx3,'g*');
        % rms amplitude
        % rms2(signal, windowlength, overlap, zeropad)
        % These values give smooth plot. Used to be 200 100.
        windowlength = 400;
        overlap = 200;
        d2 = windowlength - overlap;

        r = rms2(w(SR),windowlength,overlap,1);
        [~,ssr] = size(SR);
        x1 = SR(1)/M;
        xn = SR(ssr)/M;
        [~,sR] = size(r);
        XR = (((1:sR)/sR) * (xn - x1)) + (ones(1,sR) * x1);
        
        plot(XR,r);        
        AX2 = axis();
        AX2(1) = AX(1);
        AX2(2) = AX(2);
        axis(AX2);
        
        
    end

    function display_centered_alignment()
       wrdi = To{ti}; 
       lft = floor((Wb(1,wrdi) + Wb(2,wrdi))/2 - 50);
       disp(lft);
       % Display the fields from the token file to the command window.
       %disp(Pa{ti});
       display_alignment(lft);
    end


    function p2 = trim_phone(p)
        % Remove the part of phone symbol p after '_'.
        p2 = p;
        loc = strfind(p,'_');
        if loc
           p2 = p2(1:(loc - 1)); 
        end 
    end

    function subphoneplay(~,y)
        subphone = F(1,int16(floor(y.IntersectionPoint(1))));
        disp(sprintf('subphone %d, pdf %d, frame %d-%d',subphone,PDF(Sb(1,subphone)),Sb(1,subphone),Sb(2,subphone)));
        M = fs / 100;
        % Use floor to get an integer.
        st = max(1,floor((Sb(1,subphone) - 1) * M));
        en = min(floor(Sb(2,subphone) * M),SN);
        sound(w(st:en),fs);
    end

    function phoneplay(~,y)
        % phone = PH(int16(floor(y.IntersectionPoint(1))));
        phone = F(2,int16(floor(y.IntersectionPoint(1))));
        disp(sprintf('phone %d, frame %d-%d, pdf',phone,Pb(1,phone),Pb(2,phone)));
        disp(sprintf(' %d',PDF(Pb(1,phone):Pb(2,phone))));
        M = fs / 100;
        % Use floor to get an integer.
        st = max(1,floor((Pb(1,phone) - 1) * M));
        en = min(floor(Pb(2,phone) * M),SN);
        sound(w(st:en),fs);
    end

    function wordplay(x,y)
        word = F(3,int16(floor(y.IntersectionPoint(1))));
        btn = y.Button;
        %disp(x);
        disp(btn);
        % Value is 0 in a silence.
        if word > 0
            %disp(sprintf('word %d, frame %d-%d %s %s',word,Wb(1,word),Wb(2,word),uid,tra{word}));
            % Display the token that is clicked in token table format.
            fprintf('%s\t%d\t%d\t%d\t%s\n',uid, word,Wb(1,word),Wb(2,word),tra{word});
            % uid offset left-bd right-bd wordform
            M = fs / 100;
            st = max(1,floor((Wb(1,word) - 1) * M));
            if (btn==3)
                % Two words, two-finger tap as my mac is configures.
                % Need to fix this to take into account the right edge.
                en = min(floor(Wb(2,word + 1) * M),SN);
            else
                % One word 
                en = min(floor(Wb(2,word) * M),SN);
            end
            sound(w2(st:en),fs);
        end
    end   

    function play_current(~,~)
        % phone = PH(int16(floor(y.IntersectionPoint(1))));
        % disp(sprintf('phone %d',phone));
        %M = fs / 100;
        %st = (PHstart(phone) - 1) * M;
        %en = PHend(phone) * M;
        sound(w(SR),fs);
    end

    function play_all(~,~)
        sound(w,fs);
    end

    function next_utterance(~,~)
        ti = ti + 1;
        ui = dat.um(Tu{ti});
        %wi = 1;
        utterance_data(ui);
        clf;
        display_centered_alignment();
        add_buttons;
    end

    function previous_utterance(~,~)
        ui = max(1,ui - 1);
        utterance_data(ui);
        clf;
        display_alignment(1); 
        add_buttons;
    end

    function new_by_uid(H,~)
        unew = get(H,'string');
        disp(unew);
        inew = find(cellfun(@(x) strcmp(x,unew),Uid));
        disp(inew);
        disp('-----');
        if inew
            ui = inew;
            wi = 1;
            utterance_data(ui);
            clf;
            display_alignment(1); 
            add_buttons;
        end
    end

    function debug_from_gui(~,~)
        keyboard
    end
% nonzeros(cellfun(@(x) strcmp(x,'ahh05_sr221_trn'),C))

    hnu = @next_utterance;
    hpu = @previous_utterance;
    hinc = @increment_frame;
    hdec = @decrement_frame;
    hcurr = @play_current;
    hall = @play_all;
    huid = @new_by_uid;
    hdebug = @debug_from_gui;
    
    function increment_frame(~,~)
        clf;
        display_alignment(F1 + 20); 
        add_buttons;
    end

    function decrement_frame(~,~)
        clf;
        display_alignment(F1 - 20); 
        add_buttons;
    end

    function add_buttons 
        bprev = uicontrol('Callback',hpu,'String','<T','Position', [10 10 25 25]);
        bnext = uicontrol('Callback',hnu,'String','T>','Position', [40 10 25 25]);
        bdec = uicontrol('Callback',hdec,'String','<F','Position', [90 10 25 25]);
        binc = uicontrol('Callback',hinc,'String','F>','Position', [120 10 25 25]);
        binc = uicontrol('Callback',hdebug,'String','debug','Position', [600 10 50 25]);
        bcurr = uicontrol('Callback',hcurr,'String','P','Position', [160 10 25 25]);
        ball = uicontrol('Callback',hall,'String','A','Position', [200 10 25 25]);
        euid = uicontrol('Callback',huid,'Style','edit','Position',[260 10 120 25]);
        %title([int2str(ui),' ',uid2],'FontSize',18);
    end

figure();
positionVector1 = [0.05, 0.3, 0.9, 0.6];
subplot('Position',positionVector1)
positionVector2 = [0.05, 0.1, 0.9, 0.15];
subplot(2,1,1);
display_centered_alignment();
add_buttons;      



    function segment(unit,segfile)
     % print out a segment table for the current utterance
     % for unit=1 subphone, unit=2 phone, unit=3 ..
       segstream = fopen(segfile,'w');
       switch unit
           case 1
              [~,m] = size(Sb);
              for i = 1:m
                fprintf(segstream,'%s-%d\t%s\t%d\t%d\n',uid,i,uid,Sb(1,i) - 1,Sb(2,i) - 1);
              end
           case 2 
              [~,m] = size(Pb);
              for i = 1:m
                fprintf(segstream,'%s-%d\t%s\t%d\t%d\n',uid,i,uid,Pb(1,i) - 1,Pb(2,i) - 1);
              end
           case 3
              [~,m] = size(Wb); 
              for i = 1:m
                fprintf(segstream,'%s-%d\t%s\t%d\t%d\n',uid,i,uid,Wb(1,i) - 1,Wb(2,i) - 1);
              end
       end
       fclose(segstream);
    end
 
end

