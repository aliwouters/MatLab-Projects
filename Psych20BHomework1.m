% 1.  Seed the random number generator based on the current time. Then
%     define a 10 x 20 matrix called matrixA, in which each value is
%     independently sampled from a normal distribution with mean 100 and
%     standard deviation 15.

rng shuffle                          % seed the random number generator based on the current time
matrixA = normrnd(100, 15, 10, 20) ; % 10x20 matrix of values sampled from normal distribution with mu=100 & sigma=15
                                     % alternative method:  matrixA = randn(10, 20) * 15 + 100 ;
                                     % you could also define mu and sigma in separate steps

% 2.  Define a 10 x 20 matrix called matrixB, in which each value is
%     the square of the corresponding value in matrixA. Of course, you
%     should have Matlab compute the matrix; don't simply "hard-code" the
%     values into a matrix one at a time.

matrixB = matrixA .^ 2 ;

% 3.  USING A SINGLE LINE OF CODE, define a 10-element column-vector called
%     matrixBRowMeans, in which each value is the mean of the corresponding
%     row in matrixB. Of course, you should have Matlab compute the values;
%     don't simply "hard-code" them into a vector one at a time.

matrixBRowMeans = mean(matrixB, 2) ;

% 4.  USING A SINGLE LINE OF CODE, define a 20-element row-vector called
%     numValuesOver100EachColumnInA, in which each element is the number of
%     values greater than 100 in the corresponding column of matrixA. Of
%     course, you should have Matlab compute the 20 values in this vector;
%     don't simply "hard-code" them into a vector one at a time.

numValuesOver100EachColumnInA = sum(matrixA > 100, 1) ; % the ", 1" is optional here

% 5.  Define a 10 x 20 matrix called matrixC. Make each odd-numbered
%     column consist of the integers from 1 to 10 (1 in the first row, 2 in
%     the second row, and so on). And make each even-numbered column
%     consist of the same integers in the opposite order (10 in the first
%     row, 9 in the second row, etc.). Be efficient; don't simply
%     "hard-code" all 200 values individually.

matrixC = repmat( [(1:10)' (10:-1:1)'], 1, 10 ) ;

% 6.  Define a 10 x 20 x 30 array called arrayABC, in which each of the
%     30 "pages" (sometimes called "slices") in the 3rd dimension is equal
%     matrixA, matrixB, or matrixC. Specifically, the pages should be
%     in repeating "ABC" order: The first page should be equal to
%     matrixA, the second page should be equal to matrixB, the third page
%     should be equal to matrixC, the fourth page should be equal to
%     matrixA, the fifth page should be equal to matrixB, the sixth page
%     should be equal to matrixC, and so on. You may want to do this in
%     2 steps.

singleSetABC = cat(3, matrixA, matrixB, matrixC) ; % single 3-page set of matrix A, B, and C
arrayABC     = repmat(singleSetABC, 1, 1, 10)    ; % replicate that set 10 times to make full 30-page array

% 7.  Define a 25 x 25 matrix called matrixD, in which the first column is
%     all ones, the middle column is all ones, the last column is all ones,
%     the top row is all ones, the middle row is all ones, the bottom row
%     is all ones, and all other values are zeros. You may want to do this
%     in a few steps.

matrixD = zeros(25)        ; % initialize matrixD as a 25x25 matrix of zeros; could also say:  matrixD = zeros(25, 25) ;
matrixD([1 13 end], :) = 1 ; % make first, middle, and last rows all ones
matrixD(:, [1 13 end]) = 1 ; % make first, middle, and last columns all ones

% 8.  USING A SINGLE LINE OF CODE, define an 18 x 24 matrix called
%     twosAndThrees, in which each value is randomly generated to be either
%     a 2 or a 3 (with equal probability).

twosAndThrees = randi([2 3], [18 24]) ;

% 9.  Use a for-loop to have Matlab display a countdown of integers from 10
%     to 0, with a one-second pause between integers. Each integer should
%     appear below the previous number in the command window.

% method 1 (using the disp function automatically inserts 2 line-breaks after each displayed number)
for iNumber = 10:-1:0 % loop through the countdown integers
    disp(iNumber)     % display current countdown integer
    pause(1)          % wait 1 second
end

% method 2 (using the fprintf function, we'll insert a single line-break after each displayed number)
for iNumber = 10:-1:0                  % loop through the countdown integers
    fprintf( [num2str(iNumber) '\n'] ) % display current countdown integer ('\n' indicates line-break)
    pause(1)                           % wait 1 second
end

% method 3 (prioritizes accuracy of total countdown time); here we use the disp function, but we could also use fprintf
tic                             % start countdown timer
for iNumber = 10:-1:0           % loop through the countdown integers
    disp(iNumber)               % display current integer
    pause( (10-toc) / iNumber ) % wait-time is the total time remaining divided by the current countdown integer
end

% 10. Prompt the user to input an integer, using the following prompt:
%     "Please enter an integer: ". If the user inputs an even integer,
%     print the following message to the command window: "Your number is
%     even!" If the user inputs an odd integer, print the following message
%     to the command window: "Your number is odd!" If the user inputs a
%     non-integer (such as 1.5 or nothing at all), print the following
%     message: "Not an integer!"

% method 1: using round (using fix, floor, or ceil instead of round will also work)
inputValue = input('\nPlease enter an integer: ') ; % input value

if inputValue/2 == round(inputValue/2)  % if the value is divisible by 2...
    fprintf('\nYour number is even!\n') % ...then say it's even
    
elseif inputValue == round(inputValue)  % else if it's an integer...
    fprintf('\nYour number is odd!\n')  % ...then say it's odd
else
    fprintf('\nNot an integer!\n')      % in all other cases, say it's not an integer
end

% method 2: using rem ("remainder after division"); using mod instead of rem will also work
inputValue = input('\nPlease enter an integer: ') ; % input value

if rem(inputValue, 2) == 0              % if the value is divisible by 2...
    fprintf('\nYour number is even!\n') % ...then say it's even
    
elseif rem(inputValue, 1) == 0          % else if it's an integer...
    fprintf('\nYour number is odd!\n')  % ...then say it's odd
else
    fprintf('\nNot an integer!\n')      % in all other cases, say it's not an integer
end