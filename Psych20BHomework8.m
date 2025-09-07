
%                                 SETUP                                  %

clear all      %clear previously-defined variables from workspace
close all      %close any open figure windows
sca            %close any open Psychtoolbox windows
rng shuffle    %seed the random number generator based on the current time
ListenChar(2) ;%suppress keyboard output to command window



Screen('Preference', 'VisualDebugLevel', 1) ; %suppress welcome screen
Screen('Preference', 'SkipSyncTests'   , 1) ; %skip sync testing

allScreenNums = Screen('Screens')  ; % vector giving the screen-numbers of all available monitors
mainScreenNum = max( Screen('Screens') ) ; %screen number of main monitor
bkgdColor     = [0 0 0]                  ; %black background color
lightColor    = [80 250 245];
midColor      = [55 125 220];
darkColor     = [100 100 100];

w = PsychImaging('OpenWindow', mainScreenNum, bkgdColor);%open full window
Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA') ;
ShowCursor('Hand', w) ; % change mouse-cursor symbol to hand with pointing finger

% For screens with Retina coordinates problem
% PsychImaging('PrepareConfiguration') ; % prepare to configure screen (in the next line)
% PsychImaging('AddTask', 'General', 'UseRetinaResolution') % use Retina screen coordinates
 
avgRefreshRate = FrameRate(w);               %estimate average refresh rate
% avgFlipInterval = Screen('GetFlipInterval', w);%estimate avg flip interval
% halfFlipInterval = avgFlipInterval / 2;        %half flip-interval
halfFlipInterval  = (1 / avgRefreshRate) / 2 ; % half the flip interval of the monitor
Priority( MaxPriority(w) )                  ; % set Psychtoolbox display priority to maximum level

[wWidth, wHeight] = Screen('WindowSize', w) ; %screen width and height
xmid              = round(wWidth    / 2)    ; %screen horizontal midpoint
ymid              = round(wHeight   / 2)    ; %screen  vertical  midpoint
xquart            = round(xmid      / 2)    ; %screen horizontal midpoint
x3quart           = round(xmid + xquart)    ; %screen horizontal midpoint
% do we need xmid? or just xquart
 
Screen( 'TextSize', w, round(wHeight/30) ) ; %set size 1/30th screen height
Screen( 'TextFont', w, 'Arial' )           ; %set font to Arial
mainTextColor    = [255 255 255] ; %set main  text color to white
warningTextColor = [255 127   0] ; %set error text color to orange

%key-numbers
KbName('UnifyKeyNames') % use OSX key-name system
keyNumSpace     = min( KbName('space'    ) ); %key-number for  'space'  key
keyNumReturn    = min( KbName('return'   ) ); %key-number for  'return' key
keyNumQ         = min( KbName('q'        ) ); %key-number for    'Q'    key
keyNumT         = min( KbName('t'        ) ); %key-number for    'T'    key
keyNumLeftShift = min( KbName('LeftShift') ); %key-number for 'L.Shift' key
 

%prime time-sensitive functions now to avoid first-use delays
KbCheck ;
GetSecs ;
WaitSecs(0) ;
DrawFormattedText(w, '') ;
Screen('FillRect', w, [], [0 0 0 0]) ;
Screen('FillOval', w, [], [0 0 0 0]) ;
Screen('Flip', w) ;
 

% Vector definitions %
 
numTrial = 4; %to be able to change number of trials (for testing code)

trialTypeOrdered = repelem(1:4, numTrial/4) ; % unshuffled types
% Shuffle vector with uniform distribution
trialType = trialTypeOrdered(randperm(length(trialTypeOrdered))) ;

% 30 random values between 3 and 6 with a continuous uniform distribution
nominalDelay = 3 + (6-3)*rand(1,numTrial) ;

% rt = subject's response times
rt = NaN (1,numTrial) ;          %Initialize response time vector with 0
actualDelay = NaN (1,numTrial) ; %Initialize delay time vector with 0
userAnswer = NaN (1,numTrial) ; %Initialize user response vector with 0 ADDED
 

% Rect definitions %

% Initial position of the yellow circle, centered, diameter 1/4 of screen
% width (so radius = 1/8 of screen width)

circleRectLeft  = [xquart  - round(wWidth  / 8)...
                   ymid    - round(wWidth  / 8)...
                   xquart  + round(wWidth  / 8)...
                   ymid    + round(wWidth  / 8)]; % circle initial position

circleRectRight = [x3quart - round(wWidth  / 8)...
                   ymid    - round(wWidth  / 8)...
                   x3quart + round(wWidth  / 8)...
                   ymid    + round(wWidth  / 8)]; % circle initial position

% Get size of text box

subjIDTextDimRect = ceil(Screen('TextBounds', w, ...
'Please enter your assigned subject number: ')) ; %age text box dimensions


%                         ENTER SUBJECT NUMBER                           %

%initialize flag indicating whether a valid subject number has been entered

isSubjectValid = 0 ; 

while ~isSubjectValid %stay in while-loop 'til valid subject number entered

    subjIDChar = GetEchoString(w, ...
        'Please enter your assigned subject number: ',...
        round(xmid - subjIDTextDimRect(3)/2), ...
        round(ymid - subjIDTextDimRect(4)/2), ...
        mainTextColor, bkgdColor) ; %command, center screen, color

    Screen('Flip', w) ; %flip so GetEchoString text erases on next flip
   
    subjID = str2double(subjIDChar) ;  %convert subject # char array to #
   
    if subjID >= 1  &&  subjID <= 1000 %if valid subject number entered,
        isSubjectValid = 1 ;           %break while-loop  
    
    else
        DrawFormattedText(w, 'INVALID SUBJECT NUMBER', 'center',...
            'center', warningTextColor)  %otherwise, draw error message,
        Screen('Flip', w) ;              %and display error message,
        WaitSecs(1) ;                    %and wait 1 second
    end

end

  

]%                             EXPERIMENT                                 %


% Introduction %

DrawFormattedText(w,...
    ['In each round of this experiment, you will see two blue circles.\n'...
    'Then after a few seconds, one of the circles will change luminance (get lighter or darker)\n\n'...
    'Your task is to click the circle that changed\n'...
    'as quickly as possible once you notice the change.\n\nPress <Return> to begin.'],...
    'center', 'center', mainTextColor) ; %prompt text

Screen('Flip', w)                    ; %put that text on screen
RestrictKeysForKbCheck(keyNumReturn) ; %disregard all keys except 'return'
KbPressWait(-1)                      ; %wait for fresh key-press


% Trials %
%%%%%%%%%%


for iTrial = 1:numTrial
    
    SetMouse(xmid, .8*wHeight, w) ; % initialize mouse cursor position to horizontal center, 80% of the way down the screen
 
  while isnan (userAnswer(iTrial)) % stay in while-loop until mood-rating collected

    %Display a filled yellow circle in the position defined by shapeRect
    Screen('FillOval', w, midColor, circleRectLeft) ; %draw yellow circle COMBINED
    Screen('FillOval', w, midColor, circleRectRight) ; %draw yellow circle

    refTime = Screen('Flip', w)                     ; %put circle on screen

    if trialType(iTrial) == 1 %if trial type is 1
        Screen('FillOval', w, lightColor, circleRectLeft); %draw red circle COMBINED
        Screen('FillOval', w, midColor, circleRectRight) ; %draw yellow circle

    elseif trialType(iTrial) == 2 %if trial type is 2

        Screen('FillOval', w, darkColor, circleRectLeft); %draw yellow square
        Screen('FillOval', w, midColor, circleRectRight) ; %draw yellow circle

    elseif trialType(iTrial) == 3 %if trial type is 3

        Screen('FillOval', w, lightColor, circleRectRight); %draw yellow square
        Screen('FillOval', w, midColor, circleRectLeft) ; %draw yellow circle

    else                          %if trial type is 4

        Screen('FillOval', w, darkColor, circleRectRight);%shift yellow O
        Screen('FillOval', w, midColor, circleRectLeft) ; %draw yellow circle

    end

    flipTime = Screen('Flip', w, refTime + nominalDelay(iTrial) - ...
        halfFlipInterval) ; %define flip time

    mouseButtons = [0 0 0] ; % initialize vector of mouse-button statuses 
    
    while ~any(mouseButtons)
       [xMousePos, yMousePos, mouseButtons] = GetMouse(w) ; % get mouse's current cursor-position and button-statuses
         
        if IsInRect(xMousePos, yMousePos, circleRectLeft) && any(mouseButtons)
                userAnswer(iTrial) = 1 ;
                clickTime = GetSecs ;
                break
                
        elseif IsInRect(xMousePos, yMousePos, circleRectRight) && any(mouseButtons)
                userAnswer(iTrial) = 2 ;
                clickTime = GetSecs ;
                break
        end
     end
       
    rt(iTrial) = clickTime - flipTime ;  %Record subject response time
    actualDelay(iTrial) = flipTime - refTime ;%Record actual shape time

    if iTrial < numTrial
        DrawFormattedText(w, 'Press <Return> to do another round.', ...
           'center', 'center', mainTextColor) ;%prompt text

        Screen('Flip', w)                    ; %put that text on screen

        KbPressWait(-1)                      ; %wait for fresh key-press

    end

  end

end

 

Screen('TextStyle', w, 1) ;            %use bold text   

DrawFormattedText(w, 'Thanks. You're done!', 'center', 'center',...
    mainTextColor) ;                   %prompt text

Screen('Flip', w)                    ; %put that text on screen

RestrictKeysForKbCheck([]) ;           %stop disregarding keys


%                             SAVE & EXIT                                %

% save subject data to file psych20bhw4subj###.mat with ### = subject #

save(['psych20bFinalsubj' subjIDChar '.mat'], 'subjID', 'trialType',...
    'nominalDelay', 'actualDelay', 'circleRectLeft', 'circleRectRight', ...
    'rt', 'wWidth', 'wHeight', 'darkColor', 'lightColor', 'avgRefreshRate');

ListenChar(1) ; %restore keyboard output to command window

sca             %close Psychtoolbox window and restore mouse-cursor

 