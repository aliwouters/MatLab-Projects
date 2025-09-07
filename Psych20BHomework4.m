
% SETUP
 
qtt
clear all       % clear previously-defined variables from workspace
close all       % close any open figure windows
sca             % close any open Psychtoolbox windows
rng shuffle     % seed the random number generator based on the current time
HideCursor      % hide mouse-cursor
ListenChar(2) ; % suppress keyboard output to command window

Screen('Preference', 'VisualDebugLevel', 1) ; % suppress Psychtoolbox welcome screen
Screen('Preference', 'SkipSyncTests'   , 1) ; % skip sync testing that causes errors

allScreenNums = Screen('Screens')  ; % vector giving the screen-numbers of all available monitors
mainScreenNum = max(allScreenNums) ; % screen number of main monitor
bkgdColor     = 0                  ; % background color for the screen (black)

w = PsychImaging('OpenWindow', mainScreenNum, bkgdColor)             ; % open full-screen window called 'w'
Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA') ; % set blend function for anti-aliasing (makes certain drawing smoother)
Priority( MaxPriority(w) )                                           ; % set Psychtoolbox display priority to maximum level (MAY NOT WORK ON SOME SYSTEMS)

[wWidth, wHeight] = Screen('WindowSize', w)  ; % width and height    of the screen in pixels
xmid              = round(wWidth  / 2)       ; % horizontal midpoint of the screen in pixels
ymid              = round(wHeight / 2)       ; % vertical   midpoint of the screen in pixels
avgRefreshRate    = FrameRate(w)             ; % estimate monitor's average refresh rate
halfFlipInterval  = (1 / avgRefreshRate) / 2 ; % half the flip interval of the monitor

shapeRect      = [xmid-wWidth/8  ymid-wWidth/8  xmid+wWidth/8  ymid+wWidth/8] ; % rect for initial shape position (has 1/4th the width of the screen)
shapeRectShift = shapeRect - wWidth/16                                        ; % same rect but shifted up & to the left by 1/16th the screen-width each direction

Screen( 'TextSize', w, round(wHeight/30) ) ; % set text size to 1/30th of the screen height
Screen( 'TextFont', w, 'Arial'           ) ; % set font to Arial
mainTextColor    = [255 255 255]           ; % main    text color (white)
warningTextColor = [255 128   0]           ; % warning text color (orange)

% identify key-numbers
KbName('UnifyKeyNames') % use OSX key-name system
keyNumQ         = min( KbName('q'        ) ) ;
keyNumT         = min( KbName('t'        ) ) ;
keyNumReturn    = min( KbName('Return'   ) ) ;
keyNumSpace     = min( KbName('space'    ) ) ;
keyNumLeftShift = min( KbName('LeftShift') ) ;

% define colors for shapes
yellow = [255 255 0] ;
red    = [255   0 0] ;

% "prime" the Psychtoolbox functions that will be used during experiment (get their first use out of the way now so they don't have to be loaded later)
GetSecs ;
WaitSecs(0) ;
KbCheck ;
Screen('FillOval', w, 0, [0 0 0 0]) ;
Screen('FillRect', w, 0, [0 0 0 0]) ;
DrawFormattedText(w, '') ;
Screen('Flip', w) ;

% randomize trial-type vector (1="change color", 2="change shape", 3="change position")
numTrials             = 30                                   ; % number of trials
trialTypeTemp         = repmat(1:3, 1, numTrials/3)          ; % temporary vector of trial types (before order is randomized)
trialTypeShuffleOrder = randperm(numTrials)                  ; % random order that will be used to shuffle the trial types
trialType             = trialTypeTemp(trialTypeShuffleOrder) ; % trial types in randomized order

% nominal delay (intended time between original yellow circle and the change-stimulus) in seconds for each trial
% (this is "nominal" in that the actual delay will be slightly different, due to the finite refresh-rate of the monitor)
nominalDelay    = rand(1, numTrials) * 3 + 3      ; % vector of random values from uniform distribution between 3 and 6
nominalDelayAdj = nominalDelay - halfFlipInterval ; % adjusted nominal delay (half flip-interval early to improve flip-time accuracy)

% initialize data-vectors
actualDelay = NaN(1, numTrials) ; % vector giving the actual onset-time difference between the 1st & 2nd shape in each trial
rt          = NaN(1, numTrials) ; % vector giving the response-time for each trial (time between 2nd-shape onset & spacebar-press)

% ENTER SUBJECT NUMBER

% get coordinates to center the subject-number prompt text
subjIDPromptDimRect = Screen('TextBounds', w, 'Enter subject number:') ; % rect giving dimensions of subject-number prompt text (3rd value is width, 4th is height)
xSubjIDPrompt       = xmid - subjIDPromptDimRect(3) / 2                ; % x-coordinate for centered subject-number prompt text
ySubjIDPrompt       = ymid - subjIDPromptDimRect(4) / 2                ; % y-coordinate for centered subject-number prompt text

% input subject ID number
isSubjIDValid = 0 ;  % initialize logical flag indicating whether a valid subject ID number has been entered
while ~isSubjIDValid % stay in while-loop until valid subject ID number is entered
    
    subjIDChar = GetEchoString(w, 'Enter subject number: ', xSubjIDPrompt, ySubjIDPrompt, mainTextColor, bkgdColor) ; % get subject ID as character array
    
    Screen('FillRect', w, bkgdColor) ; % fill screen with background color so the GetEchoString text won't still show after the next flip
    
    subjID = str2double(subjIDChar) ;  % convert subject ID from character array to numeric value
    
    if ismember(subjID, 1:1000) % if entered subject ID is a whole number between 0 and 1000 inclusive....
        isSubjIDValid = 1  ;    % ...then update logical flag to break while-loop
    else                        % otherwise, display error message below
        
        DrawFormattedText(w, 'SUBJECT ID MUST BE WHOLE NUMBER\nBETWEEN 1 AND 1000 INCLUSIVE', 'center', 'center', warningTextColor) ; % error message
        Screen('Flip', w') ; % put error message on screen
        WaitSecs(2)        ; % hold error message on screen for 2 seconds
    end
end

% EXPERIMENT

% show instructions
DrawFormattedText(w, ['In each round of this experiment, you will see a yellow circle.\n' ...
                      'Then after a few seconds, the yellow circle will change\n' ...
                      'either its COLOR, SHAPE, or POSITION.\n\n' ...
                      'Your task is to press the spacebar as quickly as possible\n' ...
                      'once you notice the change.\n\n' ...
                      'Press <Return> to begin.'], 'center', 'center', mainTextColor) ;
Screen('Flip', w) ;

% trials
for iTrial = 1:numTrials
    
    % wait for 'Return' key to be pressed
    RestrictKeysForKbCheck(keyNumReturn) ; % disregard all keys except 'Return'
    while ~KbPressWait(-1)                 % stay in while-loop until fresh key press
    end
    
    % start-shape (yellow circle)
    Screen('FillOval', w, yellow, shapeRect)  ; % draw start-shape
    startShapeActualOnset = Screen('Flip', w) ; % put start-shape on the screen, get timestamp for this flip
    
    % draw target shape for given trial type
    if trialType(iTrial) == 1                           % if trial type is 1 ("change color")...
        Screen('FillOval', w, red, shapeRect)         ; % ...draw red circle in original circle position
        
    elseif trialType(iTrial) == 2                       % otherwise, if trial type is 2 ("change shape")...
        Screen('FillRect', w, yellow, shapeRect)      ; % ...draw yellow square in original circle position
        
    else                                                % otherwise, trial type must be 3 ("change position")...
        Screen('FillOval', w, yellow, shapeRectShift) ; % ...draw yellow circle in shifted position
    end
    
    % put target-shape on screen after designated delay, and get timestamp for that flip
    targetShapeActualOnset = Screen( 'Flip', w, startShapeActualOnset + nominalDelayAdj(iTrial) ) ;
    
    % wait for spacebar to be up (prevents "cheating" by holding down spacebar in advance)
    RestrictKeysForKbCheck(keyNumSpace) ; % disregard all keys except spacebar    
    while KbCheck(-1)                     % wait for spacebar to be up
    end
    
    % wait for spacebar to be down, and record timestamp for key-press
    spaceDown = 0                                 ; % initialize logical flag indicating whether spacebar is down
    while ~spaceDown                                % stay in while-loop as long as spacebar is up
        [spaceDown, spacePressSecs] = KbCheck(-1) ; % detect and get timestamp for key-press (we're still disregarding all keys except spacebar)
    end
    
    % compute actual delay and response-time for this trial
    actualDelay(iTrial) = targetShapeActualOnset - startShapeActualOnset  ; % actual delay based on reported timestamps for flips
    rt(iTrial)          = spacePressSecs         - targetShapeActualOnset ; % response time (elpased time between target-presentation & spacebar-press)
    
    % if that wasn't the last trial, prompt the subject to press <Return> to continue
    if iTrial < numTrials
        DrawFormattedText(w, 'Press <Return> to do another round.', 'center', 'center', mainTextColor) ;
        Screen('Flip', w) ;
    end
end

% display thank-you message
Screen('TextStyle', w, 1) ; % use bold text (1 is the style code for bold)
DrawFormattedText(w, 'Thank you. You''re done!', 'center', 'center', mainTextColor) ;
Screen('Flip', w) ;

% SAVE & EXIT

% save trial-information and data
save(['psych20bhw4subj' subjIDChar '.mat'], 'subjID', 'trialType', 'nominalDelay', 'actualDelay', 'shapeRect', 'shapeRectShift', 'rt', ...
                                            'wWidth', 'wHeight', 'avgRefreshRate')

% wait for 'q' and 't' and 'LeftShift' (and no other keys) to be down before exiting
RestrictKeysForKbCheck([]) ; % stop disregarding keys
keyCode = zeros(1, 256)    ; % initialize vector of key statuses

while sum( keyCode([keyNumQ keyNumT keyNumLeftShift]) ) < 3  ||  sum(keyCode) > 3 % stay in while-loop until target key combo is detected
    [~, keyCode] = KbWait(-1) ;                                                   % get vector of current key-statuses
end

ListenChar(1) ; % restore normal keyboard operation (i.e., allow keyboard output to command window)
Priority(0)   ; % reset Psychtoolbox display priority to normal
sca             % close Psychtoolbox window, restore mouse-cursor