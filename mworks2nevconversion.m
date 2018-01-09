function [mworksCorrection] = mworks2nevconversion(mworksFilename,blackrockFilename,forceProcess)
 %MWORKS2NEVCONVERSION calculates a polyfit function's parameters that can
 %take times recorded in mworks and transform them into times recorded in
 %blackrock NEV files gathered simultaneously in lab. 
% Prerequisites:
% 
%         1. the function getmworksinfo.m
%         
%         2. Mworks installed and your matlab path including the location of
%         Mworks matlab files (on a mac these are in
%         /Library/ApplicationSupport/MWorks/Scripting/Matlab)
%         
%         3. the NPMK package from blackrock, download here
%         https://github.com/BlackrockMicrosystems/NPMK/tree/master/NPMK
%
% INPUT:
% 
%         mworksFilename: filename (including path) of .mwk file for a
%         given mworks task
% 
%         blackrockFilename: filename (including path) of a blackrock file
%         (.nev) run during a given mworks task
% 
%         forceProcess : flag to reprocess code which has already been
%         processed by getmworksinfo.m (the thing that extracts
%         behavioral data) 0 = do not process again if you do not want to 1
%         = process again
% 
% OUTPUT:
%         mworks_correction: output of a polyfit between mworks word times
%         and nev word times that allows you to align nev times to
%         arbitrary mworks data.



%make sure inputs are sensible
assert(forceProcess==0 | forceProcess==1,'inappropriate entry for forceProcess')
assert(exist(mworksFilename)==2 | exist(mworksFilename)==7,'could not locate that given mworks file')
assert(exist(blackrockFilename)==2,'blackrock file does not exist')


%process, or load mworks data
[~,~,wordOut,~] = getmworksinfo(mworksFilename,forceProcess);

%open .nev file (this uses the NPMK package from blackrock). This will will do the same
%check for seeing if the nev file is processed as get_mworks_info does.
NEV = openNEV(blackrockFilename);

%words are sent from mworks to blackrock, I first find the times in mworks, then I find the times in blackrock.
%NOTE: there is a tendency for blackrock to register more words, that's actually due to a sensitivity issue I think, I
%correct for it below
%%
%first find the times when mworks sends out a word, mworks data is stored in microseconds, IMAGINE THAT
mworksWordoutTimes = double(cell2mat({wordOut(cell2mat({wordOut.data})~=0).time_us}));

%do the same for nev files. As noted above there is a sensitivity issue in blackrock registering a word, sometimes it registers two
%very close together, you should note that and correct for it.
nevWordoutTimes = NEV.Data.SerialDigitalIO.TimeStamp;
nevWordoutTimesMicroseconds = double(nevWordoutTimes)/(double(NEV.MetaTags.SampleRes)/1e6);

%find the smallest interval between words in an mworks file
minimumIntervalBetweenWords = min(diff(mworksWordoutTimes));

%locate times in nev file when interword interval is less than half the
%minimum interword interval detected above and remove (by convention
%I am keeping the second of the two close values.

badNevTimes = find(diff(nevWordoutTimesMicroseconds)<minimumIntervalBetweenWords/2) + 1; %find nev inter_word_intervals that are too short
nevWordoutTimesMicroseconds(badNevTimes) = []; %remove these times

%make sure things are the same size, if not double check your file!
assert(isequal(size(mworksWordoutTimes(:)),size(nevWordoutTimesMicroseconds(:))),'mworks and nev word files not the same size even after correction')

mworksCorrection = polyfit(double(mworksWordoutTimes),nevWordoutTimesMicroseconds,1);

end
