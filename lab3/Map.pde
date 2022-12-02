import java.util.*;

class Wall
{
   PVector start;
   PVector end;
   PVector normal;
   PVector direction;
   float len;
   
   int x1,x2,y1,y2;
   
   Wall(PVector start, PVector end, int x1, int y1, int x2, int y2)
   {
      this.start = start;
      this.end = end;
      direction = PVector.sub(this.end, this.start);
      len = direction.mag();
      direction.normalize();
      normal = new PVector(-direction.y, direction.x);
      this.x1 = x1;
      this.x2 = x2;
      this.y1 = y1;
      this.y2 = y2;
   }
   
   // Return the mid-point of this wall
   PVector center()
   {
      return PVector.mult(PVector.add(start, end), 0.5);
   }
   
   void draw()
   {
       strokeWeight(3);
       line(start.x, start.y, end.x, end.y);
       if (SHOW_WALL_DIRECTION)
       {
          PVector marker = PVector.add(PVector.mult(start, 0.2), PVector.mult(end, 0.8));
          circle(marker.x, marker.y, 5);
       }
   }
   
    @Override
    public boolean equals(Object o) {
      Wall w = (Wall) o;
      return ((x1 == w.x1) && (x2 == w.x2) && (y1 == w.y1) && (y2 == w.y2));
    }
}

class Node 
{
  PVector center;
  ArrayList<Wall> walls;
  ArrayList<Node> neighbors;
  ArrayList<Node> connected = new ArrayList<Node>();
  
  Node(ArrayList<Wall> walls, PVector center)
  {
     this.walls = walls;
     this.neighbors = new ArrayList<Node>();
     this.center = center;
  }
  
  public boolean neighbors(Node n)
  {
    for (Wall myWall: walls)
    {
      for (Wall theirWall: n.walls)
      {
        if (myWall.equals(theirWall))
          return true;
      }
    }
    
    return false;
  }
  
  public void setNeighbor(Node n)
  {
    neighbors.add(n);
    n.neighbors.add(this);
  }
  
  public void setConnected(Node n)
  {
    connected.add(n);
    
    Wall w1 = null;
    Wall w2 = null;
    
    //which wall did they share?
    for (Wall w: walls)
    {
      for (Wall wn: n.walls)
      {
        if (w.equals(wn))
        {
          w1 = w;
          w2 = wn;
        }
      }
    }
    
    if (w1 != null && w2 != null)
    {
      walls.remove(w1);
      n.walls.remove(w2);
    }
  }
  
  @Override
  public boolean equals(Object o) {
    Node n = (Node) o;
    return (this.center.equals(n.center));
  }
}

class Frontier
{
  Frontier last;
  Node n;
  
  public Frontier(Frontier last, Node n)
  {
    this.last = last;
    this.n = n;
    if (last != null) last.n.setConnected(n);
  }
}

class Map
{
   ArrayList<Wall> walls;
   Node[][] nodes;
   
   Map()
   {
      walls = new ArrayList<Wall>();
   }
   
   void generate(int which)
   {
      int grid_w = WIDTH/GRID_SIZE;
      int grid_h = HEIGHT/GRID_SIZE;
      nodes = new Node[grid_w][grid_h];
      walls.clear();
      
      splitMap(grid_w, grid_h);
      establishNeighbors(grid_w, grid_h);
      
      primGen(grid_w, grid_h, which);
   }
   
   void splitMap(int grid_w, int grid_h)
   {
     for (int i = 0; i<grid_w; i++)
      {
         for (int j = 0; j<grid_h; j++)
         {
            int w = i * GRID_SIZE;
            int w2 = (i + 1) * GRID_SIZE;
            int h = j * GRID_SIZE;
            int h2 = (j + 1) * GRID_SIZE;
           
            PVector NW = new PVector(w,h); //i j
            PVector NE = new PVector(w2, h); //i+1 j
            PVector SW = new PVector(w, h2); //i j+1
            PVector SE = new PVector(w2, h2); //i+1 j+1
            
            Wall N = new Wall(NW, NE, i, j, i+1, j);
            Wall E = new Wall(NE, SE, i+1, j, i+1, j+1);
            Wall S = new Wall(SW, SE, i, j+1, i+1, j+1);
            Wall W = new Wall(NW, SW, i, j, i, j+1);
            
            walls.add(N);
            walls.add(E);
            walls.add(S);
            walls.add(W);
            
            ArrayList<Wall> nodeWalls = new ArrayList<Wall>();
            nodeWalls.add(N);
            nodeWalls.add(E);
            nodeWalls.add(S);
            nodeWalls.add(W);
            
            PVector center = new PVector(w + GRID_SIZE/2, h + GRID_SIZE/2);
            
            nodes[i][j] = new Node(nodeWalls, center);
         }
      }
   }
   
   void establishNeighbors(int grid_w, int grid_h)
   {
     for (int i = 0; i<grid_w; i++)
      {
         for (int j = 0; j<grid_h; j++)
         {
            // if not at bottom, connect with below
            if (j < grid_h-1) {
              nodes[i][j].setNeighbor(nodes[i][j+1]);
            }
            
            // if not at rightmost, connect with right
            if (i < grid_w-1){
              nodes[i][j].setNeighbor(nodes[i+1][j]);
            }
         }
      }
   }
   
   /*
   Instead of starting with the entire graph, you pick a random starting node, and expand the tree outwards.
   You will need to keep track of which nodes you have already visited (starting with the randomly chosen one), 
   and what the "frontier" of new nodes to explore is. However, instead of storing a frontier of nodes, 
   it may be easier to store a frontier of "walls" that can be removed next: The start node has up to four 
   walls adjacent to it (you can not remove the outer walls of the map), so these are the initial "frontier", 
   then you choose a random wall from the frontier, and check if the node on the other side has not been 
   visited yet. Then you add a connection, if the other node has not been visited yet. In either case, you 
   remove that wall from your frontier. You keep repeating this until all nodes have been visited.
   */
   void primGen(int grid_w, int grid_h, int depth)
   {
      Random rand = new Random();

      int r_x = rand.nextInt(grid_w);
      int r_y = rand.nextInt(grid_h);
      
      ArrayList<Node> visited = new ArrayList<Node>();
      ArrayList<Node> nodePool = getNodePool(grid_w, grid_h);
      
      Node startNode = nodes[r_x][r_y];
      nodePool.remove(startNode);
      visited.add(startNode);
      Frontier frontier = new Frontier(null, startNode);
      
      //loop until all nodes consumed
      while (nodePool.size() > depth)
      {
       // println("NODES LEFT: " + nodePool.size());
        
        ArrayList<Node> potentialPaths = new ArrayList<Node>();
        
        //get all neighbors of nodePool
        //filter out which ones have not been visited
        for (Node neighbor: frontier.n.neighbors)
        {
          if (!visited.contains(neighbor))
          {
            potentialPaths.add(neighbor);
          }
        }
        
        //println("NEIGHBORS: " + potentialPaths.size());
        
        //if no neighbors, then we got stuck
        //move back a node
        if (potentialPaths.size() == 0){ //<>//
          frontier = frontier.last;
        } else {
          //move to random neighbor
          Node nextNode = potentialPaths.get(rand.nextInt(potentialPaths.size()));
          nodePool.remove(nextNode);
          visited.add(nextNode);
          frontier = new Frontier(frontier, nextNode);
        }
      }
      
      println(nodePool.size());
   }
   
   ArrayList<Node> getNodePool(int grid_w, int grid_h)
   {
      ArrayList<Node> nodePool = new ArrayList<Node>();
      for (int i = 0; i<grid_w; i++)
      {
         for (int j = 0; j<grid_h; j++)
         {
            nodePool.add(nodes[i][j]);
         }
      }
      return nodePool;
   }
   
   void update(float dt)
   {
      draw();
   }
   
   void draw()
   {
      stroke(255);
      strokeWeight(3);
      
      for (int i = 0; i<WIDTH/GRID_SIZE; i++)
      {
         for (int j = 0; j<HEIGHT/GRID_SIZE; j++)
         {
            Node n = nodes[i][j];
            
            stroke(255, 255, 255);
            strokeWeight(1);  // Default
            for (Wall w : n.walls)
            {
               w.draw();
            }
           
            stroke(255, 0, 0);
            strokeWeight(1);  // Default
            
            for (Node c: n.connected)
            {
              //line(n.center.x, n.center.y, c.center.x, c.center.y);
            }
            /*
            for (Node neighbor: n.neighbors)
            {
               stroke(255, 0, 0);
               strokeWeight(1);  // Default
               line(n.center.x, n.center.y, neighbor.center.x, neighbor.center.y);
            }
            */
         }
      }
   }
}
