function [stimDisplayUpdateEvents,numStimShownEvents,wordOut,codecsAll] = getmworksinfo(mworksFilename,forceProcess)
% GETMWORKSINFO extracts useful data from mworks files recorded in lab that
% can be aligned to neural activity gathered simultaneously

% prerequisites: make sure you have mworks installed, and add the path of
% the location of the mworks matlab application support to your matlab path

% [Y1,Y2,Y3,Y4] = GETMWORKSINFO(X1,X2) returns data from the
% #stimDisplayUpdate, number_of_stm_shown, and wordout_var taglines
% (Y1,Y2,Y3) in a given mworks file as well as the entire codecs associated
% with a given mworks file  for further processing

% INPUT:
%       mworksFilename: filename (including path) of .mwk file for a
%       given mworks task
%
%       forceProcess : flag to reprocess code which has already been
%       processed by get_mworks_info.m 0 = do not process again if you do
%       not want to 1 = process again
%
% OUTPUT:
%       stimDisplayUpdateEvents: structure that holds every state mworks
%       moves through
%
%       numStimShownEvents: structure that lets you know how many stimuli
%       were on a screen at a particular time
%
%       wordOut: structure of words that were sent out from mworks, this is
%       often CRITICAL to alignment of spiketimes
%
%       codecsAll: the codecs associated with a given mworks file, if you
%       want to add to things below, you can look at this codecs file and
%       adjust code accordingly

% Author: RT Raghavan Version: v1.2
% Date: January 9, 2017

%=========================================================================%

%make sure you put something sensible for the inputs
assert(forceProcess==0 | forceProcess==1,'inappropriate entry for forceProcess')
assert(exist(mworksFilename)==2 | exist(mworksFilename)==7,'could not locate that given mworks file')

%also make sure that mworks code is accessible, if it isn't you're gonna be
%in trouble

assert(exist('getEvents.m','file')==2,['Could not find a basic script provided by mWorks. '...,
    'Did you forget to add the mworks matlab support folder to your path?'])

%at the end of each run of get_mworks_info.m, a file is written of the
%convention mworksFilename_mworks_output.mat that contains the variables
%above check to make sure it exists and if so load that data unless
%explicitly told not too by the forceProcess flag above

if exist([mworksFilename(1:end-4) '_mworks_output.mat'],'file')==2 && forceProcess == 0 %load the  mat file
    disp('you already processed this file, loading it now')
    load([mworksFilename(1:end-4) '_mworks_output.mat'])
else %process the file

    %first get codecs associated with your mworks file, this should output
    %a rather large structure
    getCodecsOutput = getCodecs(mworksFilename);
    codecsAll = getCodecsOutput.codec; %this is a place where mworks files can confuse you, the output of get_Codecs is a structure containing a variable called codec


    %get code for where information on stim display is stored
    codeStimDisplayUpdateIndex = cellfun(@(x) strcmp(x,'#stimDisplayUpdate'),{codecsAll.tagname});
    codeStimDisplayUpdate = codecsAll(codeStimDisplayUpdateIndex).code;

    %get code for where the number of stim shown are stored
    codeNumStimShownIndex = cellfun(@(x) strcmp(x,'number_of_stm_shown'),{codecsAll.tagname});
    codeNumStimShown = codecsAll(codeNumStimShownIndex).code;

    %get code for where the word out data is stored.
    codeWordoutIndex = cellfun(@(x) strcmp(x,'wordout_var'),{codecsAll.tagname});
    codeWordout = codecsAll(codeWordoutIndex).code;

    %mWorks getEvents function gets the useful information out of the
    %original data given the mworksFilename and associated code. A task
    %completed below

    stimDisplayUpdateEvents = getEvents(mworksFilename,codeStimDisplayUpdate);
    numStimShownEvents = getEvents(mworksFilename,codeNumStimShown);
    wordOut = getEvents(mworksFilename,codeWordout);

    %finally save a mat file to save you time later on
    save([mworksFilename(1:end-4) '_mworks_output.mat'],'stimDisplayUpdateEvents','numStimShownEvents','wordOut','codecsAll')
end


end
