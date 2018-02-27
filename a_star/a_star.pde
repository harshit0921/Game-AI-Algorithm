import java.util.Random;
import java.util.Set;
import java.util.Comparator;
import java.util.HashSet;
import java.util.PriorityQueue;

int stage = 0;
Pt root;
Pt goal;
int MAX_POINTS = 1000000;
int SPARSITY = 4;  // 1 in X chance of a particular edge existing
int MAPSIZE = 480;
int pathFound = 0;

class Pt {
  int name;  // index in graph array
    float x;
    float y;
    Pt parent;          //parent of point
    float total_cost;    //current cost + heuristic
    float heuristic;    //the heuristic cost
    float curr_cost;    //cost from starting point to this point
    
    Pt(int name, float x, float y) {
      this.name = name;
      this.x = x;
      this.y = y;
      parent = null;
      total_cost = 0;
      heuristic = 0;
      curr_cost = Float.MAX_VALUE;
    }
}

class PtList {
  Pt p;
  PtList next;
  
  PtList(Pt p, PtList next) {
    this.p = p;
    this.next = next;
  }
}

class Graph {
  Pt[] pts;
  PtList[] adjList;  // Look up by "name" (index) of point
  int nextOpen;  // index of next point in array
  
  Graph() {
    pts = new Pt[MAX_POINTS];
    adjList = new PtList[MAX_POINTS];
    nextOpen = 0;
  }
  
  void addPt(float x, float y) {
    Pt newPt = new Pt(nextOpen, x, y);
    pts[nextOpen++] = newPt;
  }
  
  // assume edges are undirected
  void addEdge(int name1, int name2) {
    // Push onto existing list
    PtList newEntry = new PtList(pts[name2], adjList[name1]);
    adjList[name1] = newEntry;
    // And for the other direction, because undirected
    PtList newEntry2 = new PtList(pts[name1], adjList[name2]);
    adjList[name2] = newEntry2;
  }
  
  void draw() {
    stroke(255,0,0);
    for (int i = 0; i < nextOpen; i++) {
      point(pts[i].x, pts[i].y);
    }
    // We will draw each edge twice because it's undirected
    // and that is fine
    stroke(0,0,0);
    for (int i = 0; i < nextOpen; i++) {
      PtList edge = adjList[i];
      while(edge != null) {
        line(pts[i].x, pts[i].y, edge.p.x, edge.p.y);
        edge = edge.next;
      }
    }
  }
    
}

Graph g;

void settings() {
  size(MAPSIZE, MAPSIZE);
}

void setup() {
  Random prng = new Random(1337);  // deterministic so we can all work with same graph
  root = null;
  goal = null;
  pathFound = 0;
  g = new Graph();
  for (int i = 0; i < MAPSIZE/10; i++) {
    for (int j = 0; j < MAPSIZE/10; j++) {
      int ptNum = g.nextOpen;
      g.addPt(j*10,i*10);
      // Each of the following maybe's is deterministic for ease of grading
      // Maybe add edge up
      if (i > 0 && prng.nextInt(SPARSITY) == 0) {
        g.addEdge(ptNum, ptNum - MAPSIZE/10);
      }
      // Maybe add edge left
      if (j > 0 && prng.nextInt(SPARSITY) == 0) {
        g.addEdge(ptNum, ptNum - 1);
      }
      
      // Maybe add edge up and left
      if (i > 0 && j > 0 && prng.nextInt(SPARSITY) == 0) {
        g.addEdge(ptNum, ptNum - MAPSIZE/10 - 1);
      }
      // Maybe add edge up and right
      if (i > 0 && j < MAPSIZE/10 - 1 && prng.nextInt(SPARSITY) == 0) {
        g.addEdge(ptNum, ptNum - MAPSIZE/10 + 1);
      }
    }
  }
}

void draw() {
  background(150,150,150);
  stroke(0,0,0);
  g.draw();
  if(root != null)      //print the starting point
  {
    fill(255);
    ellipse(root.x, root.y, 10, 10);
  }
  
  if(goal != null)      //print the goal
  {
    fill(255);
    ellipse(goal.x, goal.y, 10, 10);
  }
  
  if(pathFound == 1)    //print the path if it exists
  drawPath();
  
      
}

void mousePressed()
{
  if (stage == 0)
  {
    setup();                //reset the graph
    float dist = 20;
    for(int i=0; i<g.nextOpen; i++)        //loop to get the nearest point to the mouse click location
    {
      if(getDistance(mouseX, mouseY, g.pts[i]) < dist)
      {
        dist = getDistance(mouseX, mouseY, g.pts[i]);
        root = g.pts[i];                //set the starting point
      }
    }
    stage++;
  }
  
  else if (stage == 1)
  {
    float dist = 20;
    for(int i=0; i<g.nextOpen; i++)    //loop to get the nearest point to the mouse click location
    {
      if(getDistance(mouseX, mouseY, g.pts[i]) < dist)
      {
        dist = getDistance(mouseX, mouseY, g.pts[i]);
        goal = g.pts[i];                //set the goal
      }
    }
    getPath();                        //find path between starting point and goal
    stage = 0;
  }
  
}

float getDistance(float x, float y, Pt p2)        //distance between mouseclick coordinate and a point
{
  float dist;
  dist = sqrt(sq(x-p2.x) + sq(y-p2.y));
  return dist;
}

void getPath()                        //method to get the path between starting point and goal
  {
    PriorityQueue<Pt> PQ = new PriorityQueue<Pt>(new Comparator<Pt>() {        //the priority queue

      @Override
      public int compare(Pt arg0, Pt arg1)         //defining the comparator
      {
        if(arg0.total_cost < arg1.total_cost)
          return -1;
        else if(arg0.total_cost > arg1.total_cost)
          return 1;
        else
          return 0;
      }
    });
    
    Set<Pt> open_list = new HashSet<Pt>();
    Set<Pt> closed_list = new HashSet<Pt>();
    
    open_list.add(root);
    root.heuristic = distance(root, goal);
    root.curr_cost = 0;
    root.total_cost = distance(root, goal);
    root.parent = null;
    PQ.add(root);
    
    PtList nb;
    Pt current;
    
    float new_cost;
    
    while(open_list.size()!=0)
    {
      current = PQ.poll();
      if(current == goal)                  //reached the goal with minimum total cost
        break;
      open_list.remove(current);
      closed_list.add(current);
      for(nb = g.adjList[current.name]; nb!=null; nb = nb.next)    //checking all the neighbours of the current point
      {
        if(closed_list.contains(nb.p))
          continue;
        
        if(!open_list.contains(nb.p))
        {
          nb.p.parent = current;
          nb.p.heuristic = distance(nb.p, goal);
          nb.p.curr_cost = current.curr_cost + distance(current, nb.p);
          nb.p.total_cost = nb.p.curr_cost + nb.p.heuristic;
          open_list.add(nb.p);
          PQ.add(nb.p);
        }
        
        new_cost = current.curr_cost + distance(current, nb.p);
        
        if(new_cost >= nb.p.curr_cost)                            //neighbour already has a better path
          continue;
        
        //setting a new path for the neighbour
        nb.p.parent = current;
        nb.p.curr_cost = new_cost;
        nb.p.total_cost = nb.p.curr_cost + nb.p.heuristic;
      }
      
    }
    
    if(goal.parent != null)    //we were able to reach the goal from starting point
      pathFound = 1;
      
  }
 
float distance(Pt a, Pt b)      //calculate distance between two points
  {
    if(a==b)
      return 0;
    else
      return (float) Math.sqrt((a.x-b.x)*(a.x-b.x) + (a.y-b.y)*(a.y-b.y));
  }
  
void drawPath()                //draw the path between starting point and goal
  {
    stroke(0, 255, 0);
    Pt p = goal;
    while(p.parent!=null)
    {
      line(p.parent.x, p.parent.y, p.x, p.y);
      p = p.parent;
    }
  }