% millipede parts as per the RFC in https://github.com/getmillipede/millipede-rfc/
enum PART = {EYE, CHEST, CHESTLEFT, CHESTRIGHT, MANDIBLELEFT, MANDIBLERIGHT, LEGLEFT, LEGRIGHT, LEGPART};
int: width = 14; % size of the board
int: height = 10; % size of the board
int: length = 7; % length of the body of the millipede

% our millipede lives in a world with obstacles
int: nObstacles = 3;
set of int: OBSTACLES = 1..nObstacles;
array[OBSTACLES,1..2] of int: obstacles = [| 1,1
                                           | 3,3
                                           | 10,8
                                           |];

% decision variables
set of int: PART0 = 0..(length(PART));
set of int: XDX = 1..width;
set of int: YDX = 1..height;
array[XDX,YDX] of var PART0: millipede;

% constraint the body parts count
include "globals.mzn";
constraint global_cardinality(array1d(millipede),
  [EYE, MANDIBLERIGHT, MANDIBLELEFT]
  ++ [CHEST, CHESTLEFT, CHESTRIGHT, LEGLEFT, LEGRIGHT, LEGPART],
  [2,1,1]
  ++ [3*length, length, length, length, length, 2*length]);

% constraint head
% model variable to locate the head
var YDX: headY;

constraint forall(x in XDX, y in YDX)
  (millipede[x,y] = EYE -> headY = y);
% model variable to locate the eyes
array[0..1] of var XDX: eyesX;
constraint eyesX[1] = eyesX[0] + 2;
constraint millipede[eyesX[0], headY] = EYE;
constraint millipede[eyesX[1], headY] = EYE;
constraint millipede[eyesX[0]-1, headY] = MANDIBLELEFT;
constraint millipede[eyesX[1]+1, headY] = MANDIBLERIGHT;

% constraint body line
% model variable to locate the chest lines
array[1..length] of var YDX: bodylinesY;
array[1..length] of var XDX: chestX;
constraint forall(c in 1..length)
  (  let { var XDX: x = chestX[c]; var YDX: y = bodylinesY[c] } in
     millipede[x-2,y] = LEGLEFT  
  /\ millipede[x-1,y] = LEGPART
  /\ millipede[x  ,y] = CHESTLEFT
  /\ millipede[x+1,y] = CHEST
  /\ millipede[x+2,y] = CHEST
  /\ millipede[x+3,y] = CHEST
  /\ millipede[x+4,y] = CHESTRIGHT
  /\ millipede[x+5,y] = LEGPART
  /\ millipede[x+6,y] = LEGRIGHT
  );
constraint forall(c in 1..length-1)(abs(chestX[c] - chestX[c+1]) <= 1);

% the body continues from the head line by line
constraint forall(c in 1..length)
                 (bodylinesY[c] = headY + c);

% eyes are in front of the body
constraint millipede[eyesX[0], bodylinesY[1]] = CHEST;
constraint millipede[eyesX[1], bodylinesY[1]] = CHEST;

% dodging obstacles
constraint forall(o in OBSTACLES)
  (let { int: oX = obstacles[o,1], int: oY = obstacles[o,2] }
  in millipede[oX,oY] = 0
  );

% search hints
solve ::int_search([headY], first_fail, indomain_min, complete)
  satisfy;
 
% display obstacles
array[XDX,YDX] of var 0..nObstacles: displayObstacle;
constraint sum(x in XDX, y in YDX)(displayObstacle[x,y]>0) = nObstacles;
constraint forall(x in XDX, y in YDX)
  (displayObstacle[x,y] > 0 <-> (obstacles[displayObstacle[x,y],1] = x /\ obstacles[displayObstacle[x,y],2] = y));

array[PART0] of string: display =
  array1d(PART0,[" ", "⊙", "█", "(", ")", "╚", "╝", "╚", "╝", "═"]);
output [ concat([ if fix(displayObstacle[x,y]) > 0 then "x" else display[fix(millipede[x,y])] endif | x in XDX]) ++ "\n" | y in YDX ]
%   ++ ["\n\(displayObstacle)"]
  ;
