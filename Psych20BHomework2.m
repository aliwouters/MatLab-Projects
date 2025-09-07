% SETUP
clear all   % clear previously-defined objects from workspace
close all   % close any open figure windows
sca         % close any open Psychtoolbox windows
rng shuffle % seed the random number generator based on the current time

Screen('Preference', 'VisualDebugLevel', 1) ; % suppress Psychtoolbox welcome screen
Screen('Preference', 'SkipSyncTests'   , 1) ; % skip sync testing that causes errors

ListenChar(2) ; % suppress keyboard output to command window
HideCursor      % hide mouse-cursor

mainScreenNum = max( Screen('Screens') ) ; % screen number of main monitor
bkgdColor     = [100 149 237]            ; % background color (corn flower blue)

w = PsychImaging('OpenWindow', mainScreenNum, bkgdColor)             ; % open full-screen window called 'w'
Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA') ; % set blend function for anti-aliasing (makes drawing smoother)

[wWidth, wHeight] = Screen('WindowSize', w) ; % width and height    of screen in pixels
xmid              = round(wWidth  / 2)      ; % horizontal midpoint of screen in pixels
ymid              = round(wHeight / 2)      ; % vertical   midpoint of screen in pixels

% define rect of coordinates for each quadrant of the screen
quadRectTopLeft     = [0     0     xmid    ymid   ] ;
quadRectTopRight    = [xmid  0     wWidth  ymid   ] ;
quadRectBottomLeft  = [0     ymid  xmid    wHeight] ;
quadRectBottomRight = [xmid  ymid  wWidth  wHeight] ;

% get dimensions (in pixels) of the word "random," using the font and text-size in which it will appear
Screen( 'TextFont' , w, 'Courier'         )                   ; % set font to Courier
Screen( 'TextSize' , w, round(wHeight/40) )                   ; % set text size to 1/40th the screen height (round because text size must be whole number)
randomTextDimRect = ceil( Screen('TextBounds', w, 'random') ) ; % rect giving dimensions of the word "random" (rounding up to whole numbers of pixels)

% generate vectors of random coordinates and random grayscale tones for the word "random"
% we use the text dimensions computed above to constrain the possible coordinates so the full word always fits on the screen
% randomTextDimRect(3) is the width of the word, and randomTextDimeRect(4) is the height of the word
numRandPlace  = 50                                                                           ; % number of random placements
randX         = randi([1                     wWidth-randomTextDimRect(3)], [1 numRandPlace]) ; % vector of random x-coordinates
randY         = randi([randomTextDimRect(4)  wHeight                    ], [1 numRandPlace]) ; % vector of random y-coordinates
randGrayValue = randi([0                     255                        ], [1 numRandPlace]) ; % vector of random grayscale values

% DISPLAY TEXT

% set size and style for colored text (we've already set the font)
Screen( 'TextSize' , w, round(wHeight/20) ) ; % set text size to 1/20th the screen height (round because text size must be whole number)
Screen( 'TextStyle', w, 1                 ) ; % set text style to bold (1 means bold)

% draw different colored text in different quadrants of the screen
DrawFormattedText(w, 'RED\nTOP-LEFT'       , 'center', 'center', [255    0    0], [], [], [], [], [], quadRectTopLeft    ) ;
DrawFormattedText(w, 'GREEN\nTOP-RIGHT'    , 'center', 'center', [  0  255    0], [], [], [], [], [], quadRectTopRight   ) ;
DrawFormattedText(w, 'BLUE\nBOTTOM-LEFT'   , 'center', 'center', [  0    0  255], [], [], [], [], [], quadRectBottomLeft ) ;
DrawFormattedText(w, 'YELLOW\nBOTTOM-RIGHT', 'center', 'center', [255  255    0], [], [], [], [], [], quadRectBottomRight) ;

% set size and style for grayscale text
Screen( 'TextSize' , w, round(wHeight/40) ) ; % set text size to 1/40th the screen height (round because text size must be whole number)
Screen( 'TextStyle', w, 0                 ) ; % set text style to regular (0 means regular)

% draw the word "random" at random positions in random grayscale tones
for iPlacement = 1:numRandPlace
    DrawFormattedText( w, 'random', randX(iPlacement), randY(iPlacement), randGrayValue(iPlacement) ) ;
end

% put all the text on the screen
Screen('Flip', w) ;

% EXIT

WaitSecs(10)  ; % wait 10 seconds
ListenChar(1) ; % restore keyboard output to command window
sca             % close Psychtoolbox window and restore the mouse cursor