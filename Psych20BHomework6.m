% GENERAL SETUP


clear all       % clear previously-defined variables from workspace
close all       % close any open figure windows
sca             % close any open Psychtoolbox windows
rng shuffle     % seed the random number generator based on the current time
HideCursor      % hide mouse-cursor
ListenChar(2) ; % suppress keyboard output to command window

InitializePsychSound(1) ; % load the audio driver (1 means prioritize low-latency)

% open stereophonic (i.e., 2-channel) audio port for each tone
try % try using 44100 Hz sample rate
    audioSampleRate   = 44100 ;    
    audioPortToneLeft = PsychPortAudio('Open', [], [], [], audioSampleRate, 2) ;
    
catch % if that produced an error, use 48000 Hz sample rate instead
    fprintf('\nAttempt to open audio port using 44100 Hz sample rate failed. Using 48000 Hz instead.\n\n')
    audioSampleRate   = 48000 ;    
    audioPortToneLeft = PsychPortAudio('Open', [], [], [], audioSampleRate, 2) ;
end

audioPortToneRight  = PsychPortAudio('Open', [], [], [], audioSampleRate, 2) ;
audioPortToneDiotic = PsychPortAudio('Open', [], [], [], audioSampleRate, 2) ;

% screen stuff
Screen('Preference', 'VisualDebugLevel', 1) ; % suppress Psychtoolbox welcome screen
Screen('Preference', 'SkipSyncTests'   , 1) ; % skip sync testing that causes errors

allScreenNums = Screen('Screens')  ; % vector giving the screen-numbers of all available monitors
mainScreenNum = max(allScreenNums) ; % screen number of main monitor
bkgdColor     = 0                  ; % background color for the screen (black)

w = PsychImaging('OpenWindow', mainScreenNum, bkgdColor)             ; % open full-screen window called 'w'
Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA') ; % set blend function for anti-aliasing (makes certain drawing smoother)

[wWidth, wHeight] = Screen('WindowSize', w) ; % width and height    of the screen in pixels
xmid              = round(wWidth  / 2)      ; % horizontal midpoint of the screen in pixels
ymid              = round(wHeight / 2)      ; % vertical   midpoint of the screen in pixels

% identify key-numbers
KbName('UnifyKeyNames')                % use OSX key-name system
keyNumR      = min(KbName('r'     )) ; % key-number for 'r'
keyNumW      = min(KbName('w'     )) ; % key-number for 'w'
keyNumT      = min(KbName('t'     )) ; % key-number for 't'
keyNumReturn = min(KbName('Return')) ; % key-number for 'Return'
keyNumSpace  = min(KbName('space' )) ; % key-number for 'space'

Screen( 'TextSize', w, round(wHeight/30) ) ; % set text size to 1/30th of the screen height
Screen( 'TextFont', w, 'Arial' )           ; % set font to Arial
mainTextColor = [255 255 255]              ; % main text color (white)
warningColor  = [255 255   0]              ; % warning text color (yellow)

% randomize trial-type vector (1=left, 2=right, 3=diotic)
numTrials             = 3                                   ; % number of trials (must be multiple of 3 so there will be an equal number of each type)
trialTypeTemp         = repmat(1:3, 1, numTrials/3)          ; % temporary vector of trial types (before order is randomized)
trialTypeShuffleOrder = randperm(numTrials)                  ; % random order that will be used to shuffle the trial types
trialType             = trialTypeTemp(trialTypeShuffleOrder) ; % trial types in randomized order

% delay (time between prompt and tone) in seconds for each trial: random values from uniform distribution between 3 and 7
delay = rand(1, numTrials) * (7 - 3) + 3 ;

% initialize response-time vector (time between tone-onset & spacebar-press on each trial)
rt = NaN(1, numTrials) ;

% PREPARE AUDIO

% create a single-channel 1-kHz 200-ms sine wave tone that we'll use to make the audio; we divide by 4 to make amplitude 1/4th full volume
tone = MakeBeep(1000, .2, audioSampleRate) / 4 ;

% create tone audio by concatenating the above sine wave with silence (for the left and right tones) or with itself (for diotic tone)
% we reduce amplitude of diotic tone by a factor of sqrt(2) to give it the same subjective loudness as the single-channel tones
toneLeft   = [tone ; zeros( 1, numel(tone) )] ; % tone in left  channel, silence in right channel
toneRight  = [zeros( 1, numel(tone) ) ; tone] ; % tone in right channel, silence in left  channel
toneDiotic = [tone ; tone] / sqrt(2)          ; % tone in both channels

% fill each audio buffer with its corresponding tone
PsychPortAudio('FillBuffer', audioPortToneLeft  , toneLeft  ) ;
PsychPortAudio('FillBuffer', audioPortToneRight , toneRight ) ;
PsychPortAudio('FillBuffer', audioPortToneDiotic, toneDiotic) ;

% prime the PsychPortAudio 'Start' function so it's already loaded when the experiment starts (just start and immediately stop any audio buffer) 
PsychPortAudio('Start', audioPortToneLeft) ;
PsychPortAudio('Stop' , audioPortToneLeft) ;

% ENTER SUBJECT NUMBER

% get coordinates to center the subject-number prompt text
subjIDPromptDimRect = Screen('TextBounds', w, 'Enter subject number:') ; % rect giving dimensions of subject-number prompt text
subjIDPromptWidth   = subjIDPromptDimRect(3)                           ; % width  of subject-number prompt text
subjIDPromptHeight  = subjIDPromptDimRect(4)                           ; % height of subject-number prompt text
subjIDPromptX       = xmid - subjIDPromptWidth  / 2                    ; % x-coordinate for subject-number prompt text
subjIDPromptY       = ymid - subjIDPromptHeight / 2                    ; % y-coordinate for subject-number prompt text

% input subject ID number
isSubjIDValid = 0 ;  % initialize logical flag indicating whether a valid subject ID number has been entered
while ~isSubjIDValid % stay in while-loop until valid subject ID number is entered
    
    subjIDChar = GetEchoString(w, 'Enter subject number: ', subjIDPromptX, subjIDPromptY, mainTextColor, bkgdColor) ; % get subject ID as character array
    Screen('Flip', w) ; % this flip keeps the above GetEchoString text from staying on the screen after the next flip
    
    subjID = str2double(subjIDChar) ; % convert the entered subject ID from character array to numeric value
    if ismember(subjID, 1:1000)       % if entered subject ID is a whole number between 1 and 1000 inclusive
        
        outputFileName = ['psych20bhw6_subj' subjIDChar '.mat'] ; % filename for this subject's data
        
        if ~exist(outputFileName, 'file') % if filename for this subject doesn't already exist in the directory; could also say: if isempty(dir(outputFileName))...
            isSubjIDValid = 1 ;           % ...then subject ID is valid; update logical flag to break while-loop
        else                              % otherwise, display warning below
            
            DrawFormattedText(w, ['WARNING: Data already exist for subject number ' num2str(subjID) ' and will be overwritten.\n\n' ...
                                  'Filename: ' outputFileName '\n\n' ...
                                  'Press spacebar to continue anyway, or press ''r'' to re-enter subject number.'], 'center', 'center', warningColor) ;
            Screen('Flip', w) ; % put warning on screen
          
            keyCode = zeros(1,256) ;                     % initialize vector of key statuses
            while ~sum( keyCode([keyNumR keyNumSpace]) ) % stay in while-loop until 'r' or spacebar is pressed   
                [~, keyCode] = KbWait(-1) ;              % wait for key-press, get keyCode vector that marks pressed key-numbers
            end
            
            if keyCode(keyNumSpace) % if spacebar pressed (i.e., overwriting data file has been okayed)
                isSubjIDValid = 1 ; % then subject ID is valid; update logical flag to break while-loop (otherwise, stay in loop)
            end
        end

    else % if entered subject ID is not a whole number between 1 and 1000 inclusive, display error message below        
        DrawFormattedText(w, 'SUBJECT ID MUST BE WHOLE NUMBER\nBETWEEN 1 AND 1000 INCLUSIVE', 'center', 'center', warningColor) ; % error message
        Screen('Flip', w') ; % put error message on screen
        WaitSecs(2)        ; % hold error message on screen for 2 seconds
    end
end

% EXPERIMENT

% show instructions
DrawFormattedText(w, ['Please put on your headphones.\n\n' ...
                      'In each round of this experiment,\n' ...
                      'you will hear a tone from the left, right, or center.\n\n' ...
                      'Your task is to press the spacebar as quickly as possible\n' ...
                      'once you hear the tone.\n\n' ...
                      'Press <Return> to begin.'], 'center', 'center', mainTextColor) ;
Screen('Flip', w) ;

% wait for keys to be up (prevents instructions from getting skipped due to lingering Return-press from subject number input)
while KbCheck(-1)
end

% trials
for iTrial = 1:numTrials
    
    % wait for Return-key to be pressed
    RestrictKeysForKbCheck(keyNumReturn) ; % ignore all keys except 'Return'
    while ~KbCheck(-1)                     % stay in while-loop until key-press detected
    end
    
    % ignore all keys except spacebar
    RestrictKeysForKbCheck(keyNumSpace) ;
    
    % prompt subject
    DrawFormattedText(w, 'Press the spacebar as soon as you hear the tone.', 'center', 'center', mainTextColor) ; % draw prompt text
    spacePromptSecs = Screen('Flip', w) ; % put prompt text on screen, and get timestamp
    
    % play tone after delay (the 1 in the PsychPortAudio 'Start' commands means wait for audio to start before continuing)   
    if trialType(iTrial) == 1                                                                  % if trial type is 1...
        PsychPortAudio('Start', audioPortToneLeft  , [], spacePromptSecs + delay(iTrial), 1) ; % ...play tone in left ear
        
    elseif trialType(iTrial) == 2                                                              % elseif trial type is 2...
        PsychPortAudio('Start', audioPortToneRight , [], spacePromptSecs + delay(iTrial), 1) ; % ...play tone in right ear
        
    else                                                                                       % else trial type must be 3...
        PsychPortAudio('Start', audioPortToneDiotic, [], spacePromptSecs + delay(iTrial), 1) ; % ...play tone in both ears
    end

    % wait for spacebar to be up (prevents cheating by holding down spacebar in advance)
    while KbCheck(-1)
    end
    
    % wait for spacebar-press (which we can do by waiting for ANY key-press, since we're ignoring all keys except the spacebar)
    isKeyDown = 0 ; % initialize logical flag indicating whether key is being pressed
    
    while ~isKeyDown                                % stay in while-loop as long as key is up
        [isKeyDown, spacePressSecs] = KbCheck(-1) ; % check whether key is pressed, get timestamp
    end
    
    rt(iTrial) = spacePressSecs - ( spacePromptSecs + delay(iTrial) ) ; % response time (elpased time between tone-presentation & spacebar-press)
    
    % save data
    save(outputFileName, 'audioSampleRate', 'trialType', 'delay', 'subjID', 'rt')
    
    % if that wasn't the last trial, prompt the subject to press <Return> to continue
    if iTrial < numTrials
        DrawFormattedText(w, 'Press <Return> to do another round.', 'center', 'center', mainTextColor) ;
        Screen('Flip', w) ;
    end
end

% display thank-you message
DrawFormattedText(w, 'Thanks. You''re done!', 'center', 'center', mainTextColor) ;
Screen('Flip', w) ;

% EXIT

RestrictKeysForKbCheck([]) ; % stop ignoring keys
timerStart = GetSecs       ; % initialize timer

% stay in while-loop until 2-second timer expires
% timer keeps restarting when the exit key-and-button combo isn't being pressed, so you must hold the combo for 2 seconds straight to exit the loop
while GetSecs < timerStart + 2
    
    [~, ~, keyCode     ] = KbCheck(-1) ; % get vector of current key-statuses
    [~, ~, mouseButtons] = GetMouse    ; % get mouse button statuses (we don't need to input w here because we don't care about mouse position)
    
    % restart timer unless 'w' and 't' (and no other keys) and at least 1 mouse button are being pressed
    if ~keyCode(keyNumW)  ||  ~keyCode(keyNumT)  ||  sum(keyCode) > 2   ||  ~any(mouseButtons)
        timerStart = GetSecs ;
    end
end

PsychPortAudio('Close') ; % close audio ports
ListenChar(1)           ; % restore normal keyboard operation (i.e., allow keyboard output to command window)
sca                       % close Psychtoolbox window, restore mouse-cursor