
close all
clear all

% polyphase combiner
% combine N am signals using polyphase methods
% creates a iq binary file to be played using gnuradio

% folder to have audio files, have odd number of audio files in directory
% get audio file strings
strpath = 'C:\wavfiles\';  % directory of just audio files !!!
wavstr = dir(strpath);   % get structure of directory 

% 
Naudio = length(wavstr) - 2;  %number of audio files, best to be odd number
txtimesec = 60;  % audio length in seconds to keep 


fsam = 30e3;  % sample rate for audio files 
Mbanks = Naudio + 1;  % best to be even number!!
fs = fsam * Mbanks;   % final sample rate out of poly bank
audiosamples = txtimesec * fsam;
wavmaxtrix = zeros(Mbanks,audiosamples);


% make poly filter bank weights
N = 1024;
x = floor(N / Mbanks);
N = x * Mbanks;
fc = fs / (2 * Mbanks);
fc = 0.85 * fc;
fc = fc / (fs/2);
hlpf = fir1(N-1,fc);
hpoly = reshape(hlpf,Mbanks,[]);  % poly lpf matrix


% get audio files
% read in each audio file , resample , and stack audio matrix

for k = 1:Naudio
    xstr = [ strpath wavstr(k+2).name ];   % get audio file string
    audiostruct = audioinfo(xstr);
    audiotime = audiostruct.Duration;
    audioFs = audiostruct.SampleRate;

    if audiotime > txtimesec
        bb = round(txtimesec*audioFs);
        [xwav,fswav] = audioread(xstr,[1 bb] ); % read in wav file
    else
        [xwav,fswav] = audioread(xstr); % read in wav file
    end


    [~,nch] = size(xwav);   % get nch and nsamples
   

        % stereo to mono
        if nch == 2
            xwav = xwav(:,1) + xwav(:,2);
            xwav = xwav.';
        else
            xwav = xwav(:,1);
            xwav = xwav.';
        end


        % resample audio file to expected audio sample rate
        if fswav ~= fsam
            b = gcd(fswav,fsam);
            x1 = fsam / b;
            x2 = fswav / b;
            xwav = resample(xwav,x1,x2);
            
        end

            Nsamples = length(xwav);

    % trim audio file to expected time duration
     if Nsamples >= audiosamples
        xwav = xwav(1:audiosamples);
    else
        x = floor(audiosamples / Nsamples);
        x = x + 2;
        xwav = repmat(xwav,[1,x]);
        xwav = xwav(1:audiosamples);
    end

    
        % scale and apply baseband AM modulation to audio vector
        xwav = xwav / max(xwav);  % -1 to 1
        xwav = 1.3*xwav + 1;       %  mod index plus carrier
        xwav = xwav / max(xwav);  %  -1 to 1
       wavmaxtrix(k,:) = xwav;

end   % end of read audio files


% ensure band edge bank has zeros and no audio
a = Mbanks / 2;
a = a + 1;
wavmaxtrix(end,:) = wavmaxtrix(a,:);
wavmaxtrix(a,:) = zeros(1,audiosamples);





% audio matrix into ifft block
wavmaxtrix = ifft(wavmaxtrix,[],1);
[a,b] = size(wavmaxtrix);
outmatrix = zeros(a,b);

% poly filter the audio matrix
for k = 1:Mbanks
    outmatrix(k,:) = filter(hpoly(k,:) , 1 , wavmaxtrix(k,:) );
end

% output to final IQ file
outmatrix = reshape(outmatrix,1,[]);
outmatrix = outmatrix / max(abs(outmatrix));  % -1 to 1
outmatrix = [ real(outmatrix).'   imag(outmatrix).' ];
fsstr = num2str(fs);
wavfilestr = [ 'polyAM' fsstr 'Hz.wav'];
x = ['C:\GNURadio_IQ\'  wavfilestr];
audiowrite(x,outmatrix,fs,'BitsPerSample',16);


































