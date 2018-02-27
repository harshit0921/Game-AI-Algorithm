import java.io.FileReader;
import java.io.FileWriter;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileNotFoundException;
import java.util.Random;
import java.util.ArrayList;
import java.util.List;
import java.util.Arrays;

static final int SQUARE_WIDTH = 50;
static final int NUM_COLUMNS = 8;

boolean whiteTurn = true;
// We want to keep these enum values so that flipping ownership is just a sign change
static final int WHITE = 1;
static final int NOBODY = 0;
static final int BLACK = -1;
static final int TIE = 2;
static final int INFINITY = Integer.MAX_VALUE;
static final int maxDepth = 11;

Random rng = new Random();

static final float WIN_ANNOUNCE_X = NUM_COLUMNS / 2 * SQUARE_WIDTH;
static final float WIN_ANNOUNCE_Y = (NUM_COLUMNS + 0.5) * SQUARE_WIDTH;

static final int BACKGROUND_BRIGHTNESS = 128;

Move best;

float WIN_VAL = 100;

boolean gameOver = false;

int[][] board;

void settings() {
  size(SQUARE_WIDTH * NUM_COLUMNS, SQUARE_WIDTH * (NUM_COLUMNS + 1));
}

void setup() {
  resetBoard();
}

void resetBoard() {
  board = new int[NUM_COLUMNS][NUM_COLUMNS];
  board[NUM_COLUMNS/2-1][NUM_COLUMNS/2-1] = WHITE;
  board[NUM_COLUMNS/2][NUM_COLUMNS/2] = WHITE;
  board[NUM_COLUMNS/2-1][NUM_COLUMNS/2] = BLACK;
  board[NUM_COLUMNS/2][NUM_COLUMNS/2-1] = BLACK;
}

void draw() {
  drawGame();
}
  
void drawGame() {
  background(BACKGROUND_BRIGHTNESS);
  if (gameOver) return;
  drawBoardLines();
  ArrayList<Move> legalMoves = generateLegalMoves(board,true);
  while (whiteTurn && legalMoves.isEmpty()) {
    ArrayList<Move> blackLegalMoves = generateLegalMoves(board, false);
    if (!blackLegalMoves.isEmpty()) {
      AIPlay(board, false, blackLegalMoves);
    } else {
      int winner = findWinner(board);   // We'll just end up doing this until the end of time
      drawBoardPieces();
      declareWinner(winner);
      return;
    }
    legalMoves = generateLegalMoves(board,true);
  }
  if (!whiteTurn) {
     ArrayList<Move> blackLegalMoves = generateLegalMoves(board,false);
     if (!blackLegalMoves.isEmpty()) {
       AIPlay(board, false, blackLegalMoves);
     }
     whiteTurn = true;
  }
  if (mousePressed) {
    int col = mouseX / SQUARE_WIDTH;  // intentional truncation
    int row = mouseY / SQUARE_WIDTH;
   
    if (whiteTurn) {
      if (legalMoves.contains(new Move(row,col))) {
        board[row][col] = WHITE;
        capture(board, row, col, true);
        whiteTurn = false;
        drawBoardPieces();
        fill(255);
        text("thinking...", WIN_ANNOUNCE_X, WIN_ANNOUNCE_Y);
        whiteTurn = false;
      }
    }
  }
  drawBoardPieces();
}


// findWinner assumes the game is over
int findWinner(int[][] board) {
  int whiteCount = 0;
  int blackCount = 0;
  for (int row = 0; row < NUM_COLUMNS; row++) {
    for (int col = 0; col < NUM_COLUMNS; col++) {
      if (board[row][col] == WHITE) whiteCount++;
      if (board[row][col] == BLACK) blackCount++;
    }
  }
  if (whiteCount > blackCount) {
    return WHITE;
  } else if (whiteCount < blackCount) {
    return BLACK;
  } else {
    return TIE;
  }
}

// declareWinner:  just for displaying winner text
void declareWinner(int winner) {
  textSize(28);
  textAlign(CENTER);
  fill(255);
  if (winner == WHITE) {
    text("Winner:  WHITE", WIN_ANNOUNCE_X, WIN_ANNOUNCE_Y);
  } else if (winner == BLACK) {
    text("Winner:  BLACK", WIN_ANNOUNCE_X, WIN_ANNOUNCE_Y);
  } else if (winner == TIE) {
    text("Winner:  TIE", WIN_ANNOUNCE_X, WIN_ANNOUNCE_Y);
  }
}

// drawBoardLines and drawBoardPieces draw the game
void drawBoardLines() {
  for (int i = 1; i <= NUM_COLUMNS; i++) {
    line(i*SQUARE_WIDTH, 0, i*SQUARE_WIDTH, SQUARE_WIDTH * NUM_COLUMNS);
    line(0, i*SQUARE_WIDTH, SQUARE_WIDTH * NUM_COLUMNS, i*SQUARE_WIDTH);
  }
}

void drawBoardPieces() {
  for (int row = 0; row < NUM_COLUMNS; row++) {
    for (int col= 0; col < NUM_COLUMNS; col++) {
      if (board[row][col] == WHITE) {
        fill(255,255,255);
      } else if (board[row][col] == BLACK) {
        fill(0,0,0);
      }
      if (board[row][col] != NOBODY) {
        ellipse(col*SQUARE_WIDTH + SQUARE_WIDTH/2, row*SQUARE_WIDTH + SQUARE_WIDTH/2,
                SQUARE_WIDTH-2, SQUARE_WIDTH-2);
      }
    }
  }
}

class Move {
  int row;
  int col;
  
  Move(int r, int c) {
    row = r;
    col = c;
  }
  
  public boolean equals(Object o) {
    if (o == this) {
      return true;
    }
    
    if (!(o instanceof Move)) {
      return false;
    }
    Move m = (Move) o;
    return (m.row == row && m.col == col);
  }
}

// Generate the list of legal moves for white or black depending on whiteTurn
ArrayList<Move> generateLegalMoves(int[][] board, boolean whiteTurn) {
  ArrayList<Move> legalMoves = new ArrayList<Move>();
  for (int row = 0; row < NUM_COLUMNS; row++) {
    for (int col = 0; col < NUM_COLUMNS; col++) {
      if (board[row][col] != NOBODY) {
        continue;  // can't play in occupied space
      }
      // Starting from the upper left ...short-circuit eval makes this not terrible
      if (capturesInDir(board,row,-1,col,-1, whiteTurn) ||
          capturesInDir(board,row,-1,col,0,whiteTurn) ||    // up
          capturesInDir(board,row,-1,col,+1,whiteTurn) ||   // up-right
          capturesInDir(board,row,0,col,+1,whiteTurn) ||    // right
          capturesInDir(board,row,+1,col,+1,whiteTurn) ||   // down-right
          capturesInDir(board,row,+1,col,0,whiteTurn) ||    // down
          capturesInDir(board,row,+1,col,-1,whiteTurn) ||   // down-left
          capturesInDir(board,row,0,col,-1,whiteTurn)) {    // left
            legalMoves.add(new Move(row,col));
      }
    }
  }
  return legalMoves;
}

// Check whether a capture will happen in a particular direction
// row_delta and col_delta are the direction of movement of the scan for capture
boolean capturesInDir(int[][] lboard, int row, int row_delta, int col, int col_delta, boolean whiteTurn) {
  // Nothing to capture if we're headed off the board
  if ((row+row_delta < 0) || (row + row_delta >= NUM_COLUMNS)) {
    return false;
  }
  if ((col+col_delta < 0) || (col + col_delta >= NUM_COLUMNS)) {
    return false;
  }
  // Nothing to capture if the neighbor in the right direction isn't of the opposite color
  int enemyColor = (whiteTurn ? BLACK : WHITE);
  if (lboard[row+row_delta][col+col_delta] != enemyColor) {
    return false;
  }
  // Scan for a friendly piece that could capture -- hitting end of the board
  // or an empty space results in no capture
  int friendlyColor = (whiteTurn ? WHITE : BLACK);
  int scanRow = row + 2*row_delta;
  int scanCol = col + 2*col_delta;
  while ((scanRow >= 0) && (scanRow < NUM_COLUMNS) &&
          (scanCol >= 0) && (scanCol < NUM_COLUMNS) && (board[scanRow][scanCol] != NOBODY)) {
      if (lboard[scanRow][scanCol] == friendlyColor) {
          return true;
      }
      scanRow += row_delta;
      scanCol += col_delta;
  }
  return false;
}

// capture:  flip the pieces that should be flipped by a play at (row,col) by
// white (whiteTurn == true) or black (whiteTurn == false)
// destructively modifies the board it's given
void capture(int[][] lboard, int row, int col, boolean whiteTurn) {
  for (int row_delta = -1; row_delta <= 1; row_delta++) {
    for (int col_delta = -1; col_delta <= 1; col_delta++) {
      if ((row_delta == 0) && (col_delta == 0)) {
        // the only combination that isn't a real direction
        continue;
      }
      if (capturesInDir(lboard, row, row_delta, col, col_delta, whiteTurn)) {
        // All our logic for this being valid just happened -- start flipping
        int flipRow = row + row_delta;
        int flipCol = col + col_delta;
        int enemyColor = (whiteTurn ? BLACK : WHITE);
        // No need to check for board bounds - capturesInDir tells us there's a friendly piece
        while(lboard[flipRow][flipCol] == enemyColor) {
          // Take advantage of enum values and flip the owner
          lboard[flipRow][flipCol] = -lboard[flipRow][flipCol];
          flipRow += row_delta;
          flipCol += col_delta;
        }
      }
    }
  }
}

// Current evaluation function is just a straight white-black count
float evaluationFunction(int[][] board) {
  float value = 0;
  for (int r = 0; r < NUM_COLUMNS; r++) {
    for (int c = 0; c < NUM_COLUMNS; c++) {
      value += board[r][c];
    }
  }
  return value;
}

// checkGameOver returns the winner, or NOBODY if the game's not over
// --recall the game ends when there are no legal moves for either side
int checkGameOver(int[][] board) {
  ArrayList<Move> whiteLegalMoves = generateLegalMoves(board, true);
  if (!whiteLegalMoves.isEmpty()) {
    return NOBODY;
  }
  ArrayList<Move> blackLegalMoves = generateLegalMoves(board, false);
    if (!blackLegalMoves.isEmpty()) {
    return NOBODY;
  }
  // No legal moves, so the game is over
  return findWinner(board);
}

// AIPlay both selects a move and implements it.
// It's given a list of legal moves because we've typically already done that
// work to check whether we should skip the turn because of no legal moves.
// You should implement this so that either white or black's move is selected;
// it's not any more complicated since you need to minimax regardless
void AIPlay(int[][] board, boolean whiteTurn, ArrayList<Move> legalMoves) {
  int currentDepth = 0;
  best = null;
  /*int[][] newBoard = new int[NUM_COLUMNS][NUM_COLUMNS];
  for(int j=0; j<NUM_COLUMNS; j++)
      for(int k=0; k<NUM_COLUMNS; k++)
        newBoard[j][k]=board[j][k];*/
  minmax(board, whiteTurn, maxDepth, currentDepth, -Float.MAX_VALUE, Float.MAX_VALUE);
  Move bestMove = new Move(best.row, best.col); //<>//
  board[bestMove.row][bestMove.col] = (whiteTurn? WHITE : BLACK);
  capture(board,bestMove.row,bestMove.col,whiteTurn);
  return;
}

float score(int[][] board, boolean whiteTurn)
{
  if(checkGameOver(board) == WHITE && whiteTurn)
    return WIN_VAL;
    
  else if(checkGameOver(board) == BLACK && whiteTurn)
    return -WIN_VAL;
    
  else if(checkGameOver(board) == BLACK && !whiteTurn)
    return WIN_VAL;
    
  else if(checkGameOver(board) == WHITE && !whiteTurn)
    return -WIN_VAL;
    
  else
    return 0;
  
}

float minmax(int[][] lboard, boolean whiteTurn, int maxDepth, int currentDepth, float alpha, float beta)
{

  List<Float> scores = new ArrayList<Float>();
  List<Move> legalMoves = new ArrayList<Move>();
  int[][] newBoard = new int[NUM_COLUMNS][NUM_COLUMNS];
  float value, bestVal;
  int index = 0;
  
  legalMoves = generateLegalMoves(lboard, whiteTurn);
  
  if(currentDepth == maxDepth || legalMoves.size() == 0)
  {
    if(checkGameOver(lboard)!=NOBODY)
      return score(board, whiteTurn);
    else
      return evaluationFunction(lboard);
  }
    
  if(!whiteTurn)
  {
    bestVal = -Float.MAX_VALUE;
    for(int i=0; i<legalMoves.size(); i++)
    {
      for(int j=0; j<NUM_COLUMNS; j++)
        for(int k=0; k<NUM_COLUMNS; k++)
          newBoard[j][k]=lboard[j][k];
          
      newBoard[legalMoves.get(i).row][legalMoves.get(i).col] = (whiteTurn? WHITE : BLACK);
      capture(newBoard,legalMoves.get(i).row,legalMoves.get(i).col,whiteTurn);
      bestVal = Float.max(bestVal, minmax(newBoard, !whiteTurn, maxDepth, currentDepth+1, alpha, beta));
      if(bestVal >= beta)
        return bestVal;
      
      best = legalMoves.get(i);
      alpha = Float.max(alpha, bestVal);
    }
    return bestVal;
  }
  

  
  else
  {
    bestVal = Float.MAX_VALUE;
    for(int i=0; i<legalMoves.size(); i++)
    {
      for(int j=0; j<NUM_COLUMNS; j++)
        for(int k=0; k<NUM_COLUMNS; k++)
          newBoard[j][k]=lboard[j][k];
          
      newBoard[legalMoves.get(i).row][legalMoves.get(i).col] = (whiteTurn? WHITE : BLACK);
      capture(newBoard,legalMoves.get(i).row,legalMoves.get(i).col,whiteTurn);
      bestVal = Float.min(bestVal, minmax(newBoard, !whiteTurn, maxDepth, currentDepth+1, alpha, beta));
      if(bestVal <= alpha)
        return bestVal;
      
      best = legalMoves.get(i);
      beta = Float.min(beta, bestVal);
    }
    return bestVal;
}
  
}