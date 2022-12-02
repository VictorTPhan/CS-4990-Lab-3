/// You do not need to change anything in this file, but you can
/// For example, if you want to add additional options controllable by keys
/// keyPressed would be the place for that.

ArrayList<PVector> waypoints = new ArrayList<PVector>();
int lastt;


Map map = new Map();

void setup() {
  System.out.println(WIDTH);
  System.out.println(HEIGHT);
  
  size(800, 600);
  randomSeed(0);
  map.generate(0);
}

int depth = 1;
void keyPressed()
{
    if (key == 'g')
    {
       println("Generating");
       map.generate(0);
       println("Generation Complete");
    }
    if (key == 'h')
    {
       depth++;
       map.generate(depth);
    }
}


void draw() {
  background(0);

  float dt = (millis() - lastt)/1000.0;
  lastt = millis();
  
  map.update(dt);  
}
