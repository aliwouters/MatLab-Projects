
% GENERAL SETUP

clear all       % clear previously-defined variables from workspace
close all       % close any open figure windows
sca             % close any open Psychtoolbox windows (sca stands for "screen close all")
rng shuffle     % seed random number generator based on current time
HideCursor      % hide the mouse-cursor
ListenChar(2) ; % suppress keyboard output to command window

InitializePsychSound(1) ; % load the audio driver (1 means prioritize low latency)
numAudioChannels = 2    ; % number of audio channels (we don't need 2 for this experiment, but some systems require setting this to 2 anyway)

% open audio port for each sound effect
try % try using 44100 Hz sample rate
    audioSampleRate = 44100 ;   
    audioPortBonk   = PsychPortAudio('Open', [], [], [], audioSampleRate, numAudioChannels) ;
    
catch % if that produced an error, use 48000 Hz sample rate instead
    fprintf('\nAttempt to open audio port using 44100 Hz sample rate failed. Using 48000 Hz instead.\n\n')
    audioSampleRate = 48000 ;    
    audioPortBonk   = PsychPortAudio('Open', [], [], [], audioSampleRate, numAudioChannels) ;
end

audioPortWhoosh = PsychPortAudio('Open', [], [], [], audioSampleRate, numAudioChannels) ;

% screen stuff
Screen('Preference', 'VisualDebugLevel', 1) ; % suppress Psychtoolbox welcome screen
Screen('Preference', 'SkipSyncTests'   , 1) ; % skip sync testing that causes errors

allScreenNums = Screen('Screens')  ; % vector giving the screen-numbers of all available monitors
mainScreenNum = max(allScreenNums) ; % screen number of main monitor
bkgdColor     = 0                  ; % background color (black)
mainTextColor = 255                ; % main text color (white)
warningColor  = [255 255 0]        ; % warning text color (yellow)

w = PsychImaging('OpenWindow', mainScreenNum, bkgdColor)             ; % open full-screen window called 'w'
Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA') ; % set blend function for anti-aliasing (makes certain drawing smoother)
Priority(MaxPriority(w))                                             ; % set Psychtoolbox display priority to maximum level (doesn't work on all systems)

[wWidth, wHeight] = Screen('WindowSize', w) ; % width and height    of the screen in pixels
xmid              = round(wWidth  / 2)      ; % horizontal midpoint of the screen in pixels
ymid              = round(wHeight / 2)      ; % vertical   midpoint of the screen in pixels

Screen( 'TextSize' , w, round(wHeight/30) ) ; % set text size to 1/30th the screen height
Screen( 'TextFont' , w, 'Arial'           ) ; % set font to Arial

% identify key-numbers
KbName('UnifyKeyNames') % use OSX key-name system
keyNumTop1  = min( KbName('1!'   ) ) ;
keyNumTop2  = min( KbName('2@'   ) ) ;
keyNumB     = min( KbName('b'    ) ) ;
keyNumC     = min( KbName('c'    ) ) ;
keyNumR     = min( KbName('r'    ) ) ;
keyNumV     = min( KbName('v'    ) ) ;
keyNumSpace = min( KbName('space') ) ;

% ANIMATION SETUP

flipInterval    = Screen('GetFlipInterval', w)        ; % flip interval of monitor (this will be the seconds per frame in the animation)
secsPerCycle    = 5                                   ; % duration of each complete cycle of animation in seconds 
aniFrames       = round(secsPerCycle / flipInterval)  ; % number of frames in each complete cycle of animation
aniFramesOver2  = round(aniFrames/2)                  ; % halfway-point (in frames) of animation
circleColor     = [0 0 255]                           ; % circle color (blue)
squareColor     = 128                                 ; % square color (grey)
circleWidth     = round(wHeight / 30)                 ; % diameter of circle (set to 1/30th the height of the screen)
pixelsPerFrameX = (wWidth  - circleWidth) / aniFrames ; % number of pixels to move the circles horizontally each frame
pixelsPerFrameY = (wHeight - circleWidth) / aniFrames ; % number of pixels to move the circles vertically   each frame

circleStartRect1 = [                 0  wHeight-circleWidth  circleWidth      wHeight]' ; % starting position for circle 1 (bottom-left corner of screen)
circleStartRect2 = [wWidth-circleWidth                    0       wWidth  circleWidth]' ; % starting position for circle 2 (top-right   corner of screen)

shiftRect  = [ pixelsPerFrameX  -pixelsPerFrameY   pixelsPerFrameX  -pixelsPerFrameY]' ; % values added to or subtracted from circle rects to shift them
squareRect = [xmid-circleWidth  ymid-circleWidth  xmid+circleWidth  ymid+circleWidth]  ; % rect for square in middle of screen

% PREPARE AUDIO

% make "bonk" sound by oversaturating a sine wave and applying a linear fadeout across it
sineFreq       = 50 ; % frequency of sine-wave tone in Hz
sineLengthSecs = .2 ; % duration  of sine-wave tone in seconds
oversaturation = 5  ; % level of oversaturation (will be multiplied by the sine wave to create distortion)

sineTone        = MakeBeep(sineFreq, sineLengthSecs, audioSampleRate) ; % audio vector for sine-wave tone
sineToneOversat = sineTone * oversaturation                           ; % distorted (i.e., oversaturated) sine-wave tone
fadeOut4Bonk    = linspace(1, 0, numel(sineToneOversat))              ; % fade-out vector for bonk: linearly decreasing values from 1 to 0
bonk            = sineToneOversat .* fadeOut4Bonk                     ; % make bonk sound my applying fadeout to oversaturated sine-wave tone
bonk(bonk >  1) =  1                                                  ; % clip (flatten) the peaks in bonk wherever they exceed 1
bonk(bonk < -1) = -1                                                  ; % clip (flatten) the troughs in bonk wherever they go lower than -1
bonk            = repmat(bonk, numAudioChannels, 1)                   ; % replicate bonk into designated number of audio channels

% make "whoosh" sound by applying an exponential fade-in across a Gaussian white-noise burst
noiseLengthSecs             = .2                                           ; % duration of noise in seconds
fadeExp                     = 6                                            ; % exponent that will determine the steepness of the fade-in
noiseLengthSamples          = noiseLengthSecs * audioSampleRate            ; % duration of noise in samples
whiteNoise                  = randn(1, noiseLengthSamples)                 ; % Gaussian white noise (random numbers from standard normal distribution)
whiteNoise(whiteNoise >  1) =  1                                           ; % clip (flatten) the peaks in white noise wherever they exceed 1
whiteNoise(whiteNoise < -1) = -1                                           ; % clip (flatten) the troughs in white noise wherever they go lower than -1
fadeIn4WhiteNoise           = linspace(0, 1, numel(whiteNoise)) .^ fadeExp ; % fade-in vector for white noise: exponentially increasing values from 0 to 1
whoosh                      = whiteNoise .* fadeIn4WhiteNoise              ; % make whoosh sound by applying fade-in to white noise
whoosh                      = repmat(whoosh, numAudioChannels, 1)          ; % replicate whoosh into designated number of audio channels

% fill audio buffers with corresponding sound effects
PsychPortAudio('FillBuffer', audioPortBonk  , bonk  ) ;
PsychPortAudio('FillBuffer', audioPortWhoosh, whoosh) ;

% PREPARE VECTORS

numTrials = 20 ; % number of trials (must be divisible by 2 so there can be equal numbers of each trial-type)

% randomize trial-type presentation orders
trialTypeTemp = repmat(1:2, 1, numTrials/2) ; % initialize trial-type order before shuffling (1 = bonk, 2 = whoosh)
trialType     = Shuffle(trialTypeTemp)      ; % shuffle trial types (could delete this line if we used repelem instead of repmat above)

while any(strfind(trialType, [1 1 1])) || any(strfind(trialType, [2 2 2])) % keep shuffling until condition vector doesn't have 3 like conditions in a row
    trialType = Shuffle(trialTypeTemp) ;                                   % vector of shuffled trial-types
end

% initialize data vectors
bounceOrPass = NaN(1, numTrials) ; % whether subject saw "bounce" (coded as 1) or "pass" (coded as 2) on given trial
rt           = NaN(1, numTrials) ; % response-time in seconds (key-press time minus prompt-text time)

% PRIME FUNCTIONS
% "prime" the Psychtoolbox functions that will be used during the experiment
% (get their first use out of the way now so they don't have to be loaded later)

GetSecs ;
KbCheck ;
Screen('FillOval', w, 0, [0 0 0 0]) ;
Screen('FillRect', w, 0, [0 0 0 0]) ;
Screen('Flip', w) ;
PsychPortAudio('Start', audioPortBonk) ;
PsychPortAudio('Stop' , audioPortBonk) ;

% ENTER SUBJECT NUMBER

% get coordinates to center the subject-number prompt text
subjIDPromptDimRect = Screen('TextBounds', w, 'Enter subject number:') ; % rect giving dimensions of subject-number prompt text
subjIDPromptWidth   = round(subjIDPromptDimRect(3))                    ; % width  of subject-number prompt text (rounded to whole number of pixels)
subjIDPromptHeight  = round(subjIDPromptDimRect(4))                    ; % height of subject-number prompt text (rounded to whole number of pixels)
subjIDPromptX       = xmid - subjIDPromptWidth  / 2                    ; % x-coordinate for subject-number prompt text
subjIDPromptY       = ymid - subjIDPromptHeight / 2                    ; % y-coordinate for subject-number prompt text

% input subject ID number
isSubjIDValid = 0 ;  % initialize logical flag indicating whether a valid subject ID number has been entered
while ~isSubjIDValid % stay in while-loop until valid subject ID number is entered
    
    subjIDChar = GetEchoString(w, 'Enter subject number: ', subjIDPromptX, subjIDPromptY, mainTextColor, bkgdColor) ; % get subject ID as character array
    Screen('Flip', w) ; % this flip keeps the above GetEchoString text from staying on the screen after the next flip
    
    subjID = str2double(subjIDChar) ; % convert the entered subject ID from character array to numeric value
    if ismember(subjID, 1:1000)       % if entered subject ID is a whole number between 1 and 1000 inclusive
        
        outputFileName = ['psych20bhw7_subj' subjIDChar '.mat'] ; % filename for this subject's data
        
        if ~exist(outputFileName, 'file') % if filename for this subject doesn't already exist in the directory...
            isSubjIDValid = 1 ;           % ...then subject ID is valid; update logical flag to break while-loop
        else                              % otherwise, display warning below
            
            DrawFormattedText(w, ['WARNING: Data already exist for subject number ' num2str(subjID) ' and will be overwritten.\n\n' ...
                                  'Filename: ' outputFileName '\n\n' ...
                                  'Press spacebar to continue anyway, or press ''r'' to re-enter subject number.'], 'center', 'center', warningColor) ;
            Screen('Flip', w) ; % put warning on screen
          
            keyCode = zeros(1,256) ;                         % initialize vector of key statuses
            while sum( keyCode([keyNumR keyNumSpace]) ) ~= 1 % stay in while-loop until 'r' or spacebar is pressed   
                [~, keyCode] = KbWait(-1, 2) ;               % after all keys are up, wait for any key press, get keyCode vector that marks pressed key-numbers
            end
            
            if keyCode(keyNumSpace) % if spacebar pressed (i.e., overwriting data file has been okayed)...
                isSubjIDValid = 1 ; % ...then subject ID is valid, so we update logical flag to break while-loop
            end
        end

    else % if entered subject ID is not a whole number between 0 and 1000 inclusive, display error message below        
        DrawFormattedText(w, 'SUBJECT ID MUST BE WHOLE NUMBER\nBETWEEN 0 AND 1000 INCLUSIVE', 'center', 'center', warningColor) ; % error message
        Screen('Flip', w') ; % put error message on screen
        WaitSecs(2)        ; % hold error message on screen for 2 seconds
    end
end

% EXPERIMENT

% display the instructions
DrawFormattedText(w, ['In each round of this experiment, you will see two moving circles.\n\n' ...
                      'Then you will press 1 if they seemed to bounce off each other,\n' ...
                      'or press 2 if they seemed to pass through or by each other.\n\n' ...
                      'Press the spacebar to begin.'], 'center', 'center', mainTextColor) ;
Screen('Flip', w) ;

% wait for spacebar to be released (in case pressed in GET SUBJECT ID section to okay overwriting of previous datafile)
RestrictKeysForKbCheck(keyNumSpace) ; % ignore all keys except space
while KbCheck(-1)                     % stay in while-loop as long as key is being pressed
end

% wait for spacebar-press
while ~KbCheck(-1) % stay in while-loop until key-press detected (we're still ignoring all keys except space)
end

RestrictKeysForKbCheck([keyNumTop1 keyNumTop2]) ; % ignore all keys except '1!' and '2@' (the only keys we need during the trials)

% trials
for iTrial = 1:numTrials
    
    circle1Rect = circleStartRect1 ; % initialize rect for circle 1 position
    circle2Rect = circleStartRect2 ; % initialize rect for circle 2 position

    % animation
    for iFrame = 1:aniFrames                                            % show animation 1 frame at a time
        Screen('FillOval', w, circleColor, [circle1Rect circle2Rect]) ; % draw circles
        Screen('FillRect', w, squareColor, squareRect)                ; % draw square at center of screen
        Screen('Flip', w)                                             ; % put circles and square on the screen
        circle1Rect = circle1Rect + shiftRect                         ; % move circle 1 rect up   and to the right
        circle2Rect = circle2Rect - shiftRect                         ; % move circle 2 rect down and to the left
        
        if iFrame == aniFramesOver2 % if at the halfway point of the animation, play sound for given trial type
            if trialType(iTrial) == 1                      % if trial type is 1...
                PsychPortAudio('Start', audioPortBonk  ) ; % ...play bonk sound
                
            else                                           % else trial type must be 2...
                PsychPortAudio('Start', audioPortWhoosh) ; % ...play whoosh sound
            end
        end
    end

    % get response
    DrawFormattedText(w, ['Press 1 if the circles bounced off each other.\n\n' ...
                          'Press 2 if the circles passed through or by each other.'], 'center', 'center', mainTextColor) ; % prompt-text
    promptSecs = Screen('Flip', w) ; % put prompt text on screen, get timestamp for its appearance

    while KbCheck(-1) % wait for keys to be up (prevents early key-presses from registering)
    end
    
    keyCode = zeros(1,256) ;                       % initialize vector of key statuses
    while ~sum(keyCode)                            % stay in while-loop until key-press detected
        [~, keyPressSecs, keyCode] = KbCheck(-1) ; % get timestamp & vector of key-statuses
    end
    
    % record bounce-or-pass response as numeric value (1 for bounce, 2 for pass)
    if keyCode(keyNumTop1)
        bounceOrPass(iTrial) = 1 ;
    else
        bounceOrPass(iTrial) = 2 ;
    end
    
    rt(iTrial) = keyPressSecs - promptSecs ; % response-time (seconds elapsed from prompt to key-press)
    
    % save data
    save(outputFileName, 'wWidth', 'wHeight', 'flipInterval', 'subjID', 'trialType', 'bounceOrPass', 'rt')
end

% display thank-you message
DrawFormattedText(w, 'That''s the end of the experiment.\n\nThank you for participating!', 'center', 'center', mainTextColor) ;
Screen('Flip', w) ;

% EXIT

RestrictKeysForKbCheck([]) ; % stop ignoring keys
timerStart = GetSecs       ; % initialize timer

% stay in while-loop until 1-second timer expires
% timer keeps restarting when the exit key combo isn't being pressed, so you must hold the combo for 1 second straight to exit the loop
while GetSecs < timerStart + 1
    
    [~, ~, keyCode] = KbCheck(-1) ; % get vector of current key-statuses
    
    % restart timer unless 'b' and 'c' and 'v' keys (and no other keys) are being pressed
    if ~all( keyCode([keyNumB keyNumC keyNumV]) )  ||  sum(keyCode) > 3
        timerStart = GetSecs ;
    end
end

PsychPortAudio('Close') ; % close audio ports
Priority(0)             ; % reset Psychtoolbox display priority to normal
ListenChar(1)           ; % restore normal keyboard operation (i.e., allow keyboard output to command window)
sca                       % close Psychtoolbox window, restore mouse-cursor