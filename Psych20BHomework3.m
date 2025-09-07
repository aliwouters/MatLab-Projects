% SETUP
quit
clear all       % clear previously-defined variables from workspaclose all       % close any open figure windows
sca             % close any open Psychtoolbox windows
HideCursor      % hide mouse-cursor
ListenChar(2) ; % suppress keyboard output to command window

Screen('Preference', 'VisualDebugLevel', 1) ; % suppress Psychtoolbox welcome screen
Screen('Preference', 'SkipSyncTests'   , 1) ; % skip sync testing that causes errors

mainScreenNum = max( Screen('Screens') ) ; % screen number of main monitor
bkgdColor     = [0 0 128]                ; % background color for the screen (navy blue)

w = PsychImaging('OpenWindow', mainScreenNum, bkgdColor)             ; % open full-screen window called 'w'
Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA') ; % set blend function for anti-aliasing (makes certain drawing smoother)

[wWidth, wHeight] = Screen('WindowSize', w) ; % width and height    of the screen in pixels
xmid              = round(wWidth  / 2)      ; % horizontal midpoint of the screen in pixels
ymid              = round(wHeight / 2)      ; % vertical   midpoint of the screen in pixels

Screen( 'TextSize', w, round(wHeight/30) ) ; % set text size to 1/30th the screen height
Screen( 'TextFont', w, 'Arial' )           ; % set font to Arial

mainTextColor    = [255 255 255] ; % set main  text color to white
warningTextColor = [255 127   0] ; % set error text color to orange

% key-numbers
KbName('UnifyKeyNames') % use OSX key-name system
keyNumN     = min( KbName('n'    ) ) ;
keyNumY     = min( KbName('y'    ) ) ;
keyNumQ     = min( KbName('q'    ) ) ;
keyNumU     = min( KbName('u'    ) ) ;
keyNumI     = min( KbName('i'    ) ) ;
keyNumT     = min( KbName('t'    ) ) ;
keyNumSpace = min( KbName('space') ) ;

% get coordinates to center the age prompt text
agePromptDimRect = Screen('TextBounds', w, 'Please enter your age in years:') ; % rect giving dimensions of age prompt text
agePromptWidth   = agePromptDimRect(3)        ; % width  of age prompt text
agePromptHeight  = agePromptDimRect(4)        ; % height of age prompt text
xAgePrompt       = xmid - agePromptWidth  / 2 ; % x-coordinate for age prompt text
yAgePrompt       = ymid - agePromptHeight / 2 ; % y-coordinate for age prompt text

% get coordinates to center the favorite-color prompt text
faveColorPromptDimRect = Screen('TextBounds', w, 'Please enter your favorite color:') ; % rect giving dimensions of favorite-color prompt text
faveColorPromptWidth   = faveColorPromptDimRect(3)        ; % width  of favorite-color prompt text
faveColorPromptHeight  = faveColorPromptDimRect(4)        ; % height of favorite-color prompt text
xFaveColorPrompt       = xmid - faveColorPromptWidth  / 2 ; % x-coordinate for favorite-color prompt text
yFaveColorPrompt       = ymid - faveColorPromptHeight / 2 ; % y-coordinate for favorite-color prompt text

% SURVEY

% introduction
DrawFormattedText(w, 'Press the spacebar to begin the survey', 'center', 'center', mainTextColor) ; % prompt text
Screen('Flip', w)                   ; % put that text on screen
RestrictKeysForKbCheck(keyNumSpace) ; % disregard all keys except 'space'
KbPressWait(-1)                     ; % wait for fresh key-press

% get subject's native English speaker status
DrawFormattedText(w, 'Are you a native English speaker?\n\n(Y) Yes  (N) No', 'center', 'center', mainTextColor) ; % prompt text
Screen('Flip', w)                         ; % put that text on screen
RestrictKeysForKbCheck([keyNumN keyNumY]) ; % disregard all keys except 'n' and 'y'
[~, keyCode]  = KbPressWait(-1)           ; % wait for fresh key-press
nativeEnglish = keyCode(keyNumY)          ; % convert that response to numeric value (0='n', 1='y')

% get subject's voter registration status
DrawFormattedText(w, 'Are you registered to vote?\n\n(Y) Yes  (N) No', 'center', 'center', mainTextColor) ; % prompt text
Screen('Flip', w)               ; % put that text on screen
[~, keyCode] = KbPressWait(-1)  ; % wait for fresh key-press (we're still disregarding all keys except 'n' and 'y')
voter        = keyCode(keyNumY) ; % convert that response to numeric value (0='n', 1='y')

RestrictKeysForKbCheck([]) ; % stop disregarding keys

% get subject's age
isAgeValid = 0 ;  % initialize flag indicating whether a valid age has been entered
while ~isAgeValid % stay in while-loop until valid age entered
    
    ageChar = GetEchoString(w, 'Please enter your age in years: ', xAgePrompt, yAgePrompt, mainTextColor, bkgdColor) ; % input age as character array
    Screen('Flip', w) ; % flip now so GetEchoString text will be erased on next flip
    
    age = str2double(ageChar) ; % convert age from character array to number
    
    if age >= 10  &&  age <= 120                                                   % if valid age entered...
        isAgeValid = 1 ;                                                           % ...update isAgeValid flag (breaking the while-loop)   
        
    else
        DrawFormattedText(w, 'INVALID AGE', 'center', 'center', warningTextColor)  % otherwise, draw error message...
        Screen('Flip', w) ;                                                        % ...and display error message...
        WaitSecs(1) ;                                                              % ...and wait 1 second
    end
end

% get subject's favorite color
isFaveColorValid = 0 ;  % initialize flag indicating whether a valid color has been entered
while ~isFaveColorValid % stay in while-loop until valid color entered
    
    faveColor = GetEchoString(w, 'Please enter your favorite color: ', xFaveColorPrompt, yFaveColorPrompt, mainTextColor, bkgdColor) ; % input fave color
    Screen('Flip', w) ; % flip now so GetEchoString text will be erased on next flip
    
    if numel(faveColor) > 2                                                       % if favorite color is valid (i.e., more than 2 characters)... 
        isFaveColorValid = 1 ;                                                    % ...update isFaveColorValid flag (breaking the while-loop)
    else
        DrawFormattedText(w, 'INVALID COLOR', 'center', 'center', warningTextColor) % otherwise, draw error message...
        Screen('Flip', w) ;                                                       % ...and display error message...
        WaitSecs(1) ;                                                             % ...and wait 1 second
    end
end

% show thank-you screen
DrawFormattedText(w, 'The survey is complete.\n\nThank you!', 'center', 'center', mainTextColor) ; % thank-you text
Screen('Flip', w) ; % put that text on screen

% SAVE & EXIT

save('psych20bhw3data', 'nativeEnglish', 'voter', 'age', 'faveColor') % save survey data to file psych20bhw3data.mat

% wait for 'q' + 'u' + 'i' + 't' (and no other keys) to be down before exiting
keyCode = zeros(1, 256) ; % initialize vector of key-statuses
while sum( keyCode([keyNumQ keyNumU keyNumI keyNumT]) ) < 4  ||  sum(keyCode) > 4 % stay in while-loop until all 4 target keys, and no other keys, are down
    [~, keyCode] = KbWait(-1) ; % get vector of current key-statuses
end

ListenChar(1) ; % restore keyboard output to command window
sca             % close Psychtoolbox window and restore mouse-cursor