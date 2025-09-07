
% GENERAL SETUP

clear all       % clear previously-defined variables from workspace
close all       % close any open figure windows
sca             % close any open Psychtoolbox windows
ListenChar(2) ; % suppress keyboard output to command window

Screen('Preference', 'VisualDebugLevel', 1) ; % suppress Psychtoolbox welcome screen
Screen('Preference', 'SkipSyncTests'   , 1) ; % skip sync testing that causes errors

allScreenNums = Screen('Screens')  ; % vector giving the screen-numbers of all available monitors
mainScreenNum = max(allScreenNums) ; % largest of those screen-numbers is presumed to be for the monitor we want to use
bkgdColor     = 0                  ; % background color for the screen (black)

%PsychImaging('PrepareConfiguration')                      ; % prepare to configure screen in next line (COMMENT THIS OUT UNLESS PROBLEM W/ MOUSE POSITION)
%PsychImaging('AddTask', 'General', 'UseRetinaResolution') ; % use Retina screen coordinates            (COMMENT THIS OUT UNLESS PROBLEM W/ MOUSE POSITION)

w = PsychImaging('OpenWindow', mainScreenNum, bkgdColor)             ; % open full-screen window called 'w'
Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA') ; % set blend function for anti-aliasing (makes certain drawing smoother)
Priority( MaxPriority(w) )                                           ; % set Psychtoolbox display priority to maximum level (MAY NOT WORK ON ALL SYSTEMS)

[wWidth, wHeight] = Screen('WindowSize', w) ; % width and height    of the screen in pixels
xmid              = round(wWidth  / 2)      ; % horizontal midpoint of the screen in pixels
ymid              = round(wHeight / 2)      ; % vertical   midpoint of the screen in pixels

% define key-numbers
KbName('UnifyKeyNames') % use OSX key-name system
keyNumLeftShift = min(KbName('LeftShift')) ;
keyNumTab       = min(KbName('tab'      )) ;

% text settings
Screen( 'TextSize', w, round( wHeight/30) ) ; % set text size to 1/30th of the screen height
Screen( 'TextFont', w, 'Helvetica')         ; % set font to Helvetica
textColor           = 255                   ; % text color (white)
promptTextYPosition = wHeight / 5           ; % y-coordinate for prompt text


% PREPARE SAM ICONS

samImage = imread('sam.bmp') ; % import SAM image from file into RGB array

% EXTRA CREDIT: Determine the width of the left border of SAM image RGB array.
%    On any page (color channel) of the array, a value less than 255 indicates that the pixel at that position must be non-white.
%    So we first find the column indexes of all the values in the array that are less than 255.
%    The lowest (i.e., leftmost) of those column indexes will be 1 pixel to the right of where the white border on the left of the image ends.
[~, nonWhiteColumnIndexes] = find(samImage < 255)           ; % column indexes of all non-white pixels (~ symbol is because we don't need the row indexes)
borderWidth                = min(nonWhiteColumnIndexes) - 1 ; % border width (1 less than the column index of the leftmost non-white pixel)

% create "padded" SAM image RGB array with white top and bottom borders to match left and right borders
samImagePad = padarray(samImage, borderWidth, 255) ;

% or if you didn't know about the padarray function, you could do this:
%    samOrigWidth = size(samImage, 2)                         ; % width of original SAM image RGB array; alternatively: samOrigWidth = width(samImage) ;
%    whiteBorder  = repmat(255, borderWidth, samOrigWidth, 3) ; % white border for top and bottom of SAM image RGB array
%    samImagePad  = [whiteBorder ; samImage ; whiteBorder]    ; % concatenate that border onto top and bottom of SAM image RGB array

% extract individual icons from the padded SAM image RGB array
iconWidth = round( size(samImage, 2) / 5 ) ; % width of each icon's RGB array (1/5th the width of the original image's RGB array)
                                             % alternatively:  iconWidth = round( width(samImage) / 5 ) ;

samIcon1 = samImagePad(:,             1 :   iconWidth, :) ; % SAM icon 1: very sad
samIcon2 = samImagePad(:,   iconWidth+1 : 2*iconWidth, :) ; % SAM icon 2: somewhat sad
samIcon3 = samImagePad(:, 2*iconWidth+1 : 3*iconWidth, :) ; % SAM icon 3: neutral
samIcon4 = samImagePad(:, 3*iconWidth+1 : 4*iconWidth, :) ; % SAM icon 4: somewhat happy
samIcon5 = samImagePad(:, 4*iconWidth+1 :         end, :) ; % SAM icon 5: very happy

% initialize yellow-tinted version of each icon's RGB array
samIconYellow1 = samIcon1 ;
samIconYellow2 = samIcon2 ;
samIconYellow3 = samIcon3 ;
samIconYellow4 = samIcon4 ;
samIconYellow5 = samIcon5 ;

% make yellow-tinted version of each of icon's RGB array by setting blue layer to all zeros
samIconYellow1(:, :, 3) = 0 ;
samIconYellow2(:, :, 3) = 0 ;
samIconYellow3(:, :, 3) = 0 ;
samIconYellow4(:, :, 3) = 0 ;
samIconYellow5(:, :, 3) = 0 ;

% compute rects for where SAM icons will appear on the screen
pixelsBetweenIcons      = 4                                               ; % number of pixels to put between adjacent icon rects
samIconWidthHeightRatio = size(samIcon1, 2) / size(samIcon1, 1)           ; % width-height ratio of each icon; alternatively: width(samIcon1)/height(samIcon1)
samIconRectWidth        = (wWidth -4*pixelsBetweenIcons) / 5              ; % set icon rect width so row of 5 icons fills the screen (minus pixels between icons)
samIconRectHeight       = samIconRectWidth / samIconWidthHeightRatio      ; % set icon rect height to retain original width-height ratio
samIconTopEdge          = ymid - samIconRectHeight/2                      ; % y-coordinate  for top    edge  of icon rects
samIconBottomEdge       = samIconTopEdge + samIconRectHeight - 1          ; % y-coordinate  for bottom edge  of icon rects
samIconLeftEdges        = (0:4) * (samIconRectWidth + pixelsBetweenIcons) ; % vector of x-coordinates for left  edges of icon rects
samIconRightEdges       = samIconLeftEdges + samIconRectWidth - 1         ; % vector of x-coordinates for right edges of icon rects

samIconRect1 = [samIconLeftEdges(1) samIconTopEdge samIconRightEdges(1) samIconBottomEdge] ; % rect for icon 1
samIconRect2 = [samIconLeftEdges(2) samIconTopEdge samIconRightEdges(2) samIconBottomEdge] ; % rect for icon 2
samIconRect3 = [samIconLeftEdges(3) samIconTopEdge samIconRightEdges(3) samIconBottomEdge] ; % rect for icon 3
samIconRect4 = [samIconLeftEdges(4) samIconTopEdge samIconRightEdges(4) samIconBottomEdge] ; % rect for icon 4
samIconRect5 = [samIconLeftEdges(5) samIconTopEdge samIconRightEdges(5) samIconBottomEdge] ; % rect for icon 5

% concatenate those icon rects into single matrix that we can input to 'DrawTextures' (each rect is a column in the matrix)
samIconRects = [samIconRect1' samIconRect2' samIconRect3' samIconRect4' samIconRect5'] ;

% convert all SAM icons to textures
samIconTexture1 = Screen('MakeTexture', w, samIcon1) ;
samIconTexture2 = Screen('MakeTexture', w, samIcon2) ;
samIconTexture3 = Screen('MakeTexture', w, samIcon3) ;
samIconTexture4 = Screen('MakeTexture', w, samIcon4) ;
samIconTexture5 = Screen('MakeTexture', w, samIcon5) ;

samIconYellowTexture1 = Screen('MakeTexture', w, samIconYellow1) ;
samIconYellowTexture2 = Screen('MakeTexture', w, samIconYellow2) ;
samIconYellowTexture3 = Screen('MakeTexture', w, samIconYellow3) ;
samIconYellowTexture4 = Screen('MakeTexture', w, samIconYellow4) ;
samIconYellowTexture5 = Screen('MakeTexture', w, samIconYellow5) ;


% GET MOOD RATING

SetMouse(xmid, .8*wHeight, w) ; % initialize mouse cursor position to horizontal center, 80% of the way down the screen

mood = NaN ;      % initialize mood-rating as missing
while isnan(mood) % stay in while-loop until mood-rating collected
    
    [xMousePos, yMousePos, mouseButtons] = GetMouse(w) ; % get mouse's current cursor-position and button-statuses
    
    if IsInRect(xMousePos, yMousePos, samIconRect1) % if mouse is on icon 1, use yellow icon 1 and make other icons untinted
        Screen('DrawTextures', w, [samIconYellowTexture1 samIconTexture2 samIconTexture3 samIconTexture4 samIconTexture5], [], samIconRects) ;
        if any(mouseButtons) % if mouse button pressed while on icon 1, record mood as 1
            mood = 1 ;
        end
        
    elseif IsInRect(xMousePos, yMousePos, samIconRect2) % if mouse is on icon 2, use yellow icon 2 and make other icons untinted
        Screen('DrawTextures', w, [samIconTexture1 samIconYellowTexture2 samIconTexture3 samIconTexture4 samIconTexture5], [], samIconRects) ;
        if any(mouseButtons) % if mouse button pressed while on icon 2, record mood as 2
            mood = 2 ;
        end
        
    elseif IsInRect(xMousePos, yMousePos, samIconRect3) % if mouse is on icon 3, use yellow icon 3 and make other icons untinted
        Screen('DrawTextures', w, [samIconTexture1 samIconTexture2 samIconYellowTexture3 samIconTexture4 samIconTexture5], [], samIconRects) ;
        if any(mouseButtons) % if mouse button pressed while on icon 3, record mood as 3
            mood = 3 ;
        end
        
    elseif IsInRect(xMousePos, yMousePos, samIconRect4) % if mouse is on icon 4, use yellow icon 4 and make other icons untinted
        Screen('DrawTextures', w, [samIconTexture1 samIconTexture2 samIconTexture3 samIconYellowTexture4 samIconTexture5], [], samIconRects) ;
        if any(mouseButtons) % if mouse button pressed while on icon 4, record mood as 4
            mood = 4 ;
        end
        
    elseif IsInRect(xMousePos, yMousePos, samIconRect5) % if mouse is on icon 5, use yellow icon 5 and make other icons untinted
        Screen('DrawTextures', w, [samIconTexture1 samIconTexture2 samIconTexture3 samIconTexture4 samIconYellowTexture5], [], samIconRects) ;
        if any(mouseButtons) % if mouse button pressed while on icon 5, record mood as 5
            mood = 5 ;
        end
        
    else % if mouse not on any icon, make all icons untinted
        Screen('DrawTextures', w, [samIconTexture1 samIconTexture2 samIconTexture3 samIconTexture4 samIconTexture5], [], samIconRects) ;
    end
    
    DrawFormattedText(w, 'Click on the image that best represents your current mood', 'center', promptTextYPosition, textColor) ; % draw prompt text
    Screen('Flip', w) ; % put icons and prompt text on the screen
end

DrawFormattedText(w, 'Thank you!', 'center', 'center', textColor) ; % thank-you message
Screen('Flip', w, GetSecs + .2)                                   ; % put thank-you message on screen after 200-ms pause
                                                                    % this is a fairly crude way to do the timing, but it's fine for this purpose   

% SAVE & EXIT

save('psych20bmood.mat') % save all the variables in the workspace

% wait for any mouse-button(s), left shift, tab, and no other keys on the keyboard, to be down before exiting
mouseButtons = zeros(1,   3) ; % initialize vector of mouse-button statuses
keyCode      = zeros(1, 256) ; % initialize vector of key statuses

while ~any(mouseButtons)  ||  ~keyCode(keyNumTab)  ||  ~keyCode(keyNumLeftShift)  ||  sum(keyCode) > 2 % stay in while-loop until target combo detected
    [~, ~, mouseButtons] = GetMouse   ; % get vector of current mouse-button statuses (we don't need to input w here because we don't care about position)
    [~, keyCode]         = KbWait(-1) ; % get vector of current key-statuses
end

sca             % close any open Psychtoolbox windows
ListenChar(1) ; % restore keyboard output to command window
Priority(0)   ; % reset Psychtoolbox display priority to normal