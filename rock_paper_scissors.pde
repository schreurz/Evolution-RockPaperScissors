int DIM=32; //exponent of 2
float MY=0.01; // Mutation Rate
int GAMES = 100; // Games played per draw() calls
boolean WELL_MIXED = true; // True for well-mixed, false for spacial
boolean RANDOM_PLAYER = false;
float RESET = -1;  // Number of draw() calls before reset. -1 if no reset
// Number of games played before reset will be GAMES * RESET
boolean RESET_AT_END = true;

// RED = ROCK
// GREEN = PAPER
// BLUE = SCISSORS
// A lot of red -> green strives
// A lot of green -> blue strives
// A lot of blue -> red strives
// Shoult oscillate from red->green->blue->red for well mixed
// For grouping red takes blue, blue takes green, green takes red

                        // R   P   S
float[][] payoffMatrix={{1.0, 0.0, 2.0}, // R
                        {2.0, 1.0, 0.0}, // P
                        {0.0, 2.0, 1.0}};// S

int[] xm={0, 1, 0, -1};
int[] ym={-1, 0, 1, 0};

Agent[][] area;

// Org counter for no mutations
int[] org_count = new int[4];


// Place agents into the area
int repeat = 0;
int state = 0;
PrintWriter output;
void setup()
{
  size(640, 640);
  resetEverything();
}

void resetEverything()
{
  if (repeat == 30)
  {
    exit();
  }
  if (state%2 == 1)
  {
    RANDOM_PLAYER = true;
  }
  else 
  {
    RANDOM_PLAYER = false;
  }
  if (state >= 2)
  {
    WELL_MIXED = true;
  }
  else 
  {
    WELL_MIXED = false;
  }
  for(int i=0;i<4;i++)
  {
    org_count[i] = 0;
  }
  area=new Agent[DIM][DIM];
  for (int i=0; i<DIM; i++)
  {
    for (int j=0; j<DIM; j++)
    {
      area[i][j]=new Agent(null, i, j); // Null because no parent
      area[i][j].show();
    }
  }

  if (MY == 0.0)
  {
    output = createWriter("data_"+str(repeat)+".csv");
    output.println("R,P,S,M,Size,Well Mixed,Random");
  }
  //output.println(",,,,"+str(DIM)+','+str(WELL_MIXED)+','+str(RANDOM_PLAYER));
}

class Agent {
  float[] genome;
  float payoff;
  int x, y;
  int type; // for org_hm

  // Constructor
  Agent(Agent from, int _x, int _y)
  {
    genome=new float[3];
    payoff=0.0;
    x=_x;
    y=_y;

    // Setup for root agent
    if (from==null)
    {
      genome[0]=genome[1]=genome[2]=0.0; // Create a genome with values 0.0
      int tmp = (int)random(3);
      genome[tmp]=1.0;                   // Make deterministic
      type = tmp;


      if (RANDOM_PLAYER)
      {
        // Make 1/4th of the agents random players
        if ((int)random(4)==0)
        {
          tmp = 3;
          genome[0]=genome[1]=genome[2]=1.0/3.0;
          type = tmp;
        }
      }
      if (MY == 0.0)
      {
        org_count[type]++;
      }
    }

    // Setup for agent from parent
    else
    {
      boolean didIChange=false;
      for (int i=0; i<3; i++)
      {
        if (random(0.0, 1.0) < MY)
        {
          genome[i]=random(0.0, 1.0);
          didIChange=true;
        }
        else
        {
          genome[i]=from.genome[i];
          type = from.type;
        }
      }
      if (didIChange) // mutations
      {
        float sum=genome[0]+genome[1]+genome[2];
        for (int i=0; i<3; i++)
          genome[i]/=sum;
      }
    }
  }

  // Creates a 10x10 pixel on the screen with appropriate color
  void show() {
    noStroke();
    fill(color(255.0*genome[0], 255.0*genome[1], 255.0*genome[2]));
    rect(x*10, y*10, 10, 10);
  }


  void play(Agent who)
  {
    float P1=0.0; // Player1 Payoff
    float P2=0.0; // Player2 Payoff
    for (int i=0; i<3; i++)
    {
      for (int j=0; j<3; j++)
      {
        P1+=payoffMatrix[i][j]*genome[i]*who.genome[j];
        P2+=payoffMatrix[j][i]*genome[i]*who.genome[j];
      }
    }
    payoff=P1;
    who.payoff=P2;
  }
};

// What is called every update
int count = 0;
void draw()
{
  count++;
  if (MY == 0.0 && count == 20)
  {
    //println(Integer.toString(org_count[0])+' '+Integer.toString(org_count[1])+' '+Integer.toString(org_count[2])+' '+Integer.toString(org_count[3]));
    count = 0;
    int nrZ = 0;
    for(int i=0;i<4;i++)
    {
      //output.print(str(org_count[i]));
      if(i!=0)
      {
        output.print(",");
      }
      output.print(str(org_count[i]));
      if (org_count[i] == 0)
        nrZ++;
    }
    output.print(','+str(DIM)+','+str(WELL_MIXED)+','+str(RANDOM_PLAYER));
    output.print("\n");
    output.flush();
    if(nrZ == 3)
    {
      output.close();
      repeat++;
      state = (state+1)%4;
      resetEverything();
      //saveFrame("frame_#####.png");
    }
  }
  for (int i=0; i<GAMES; i++) {
    int x=(int)random(DIM);
    int y=(int)random(DIM);
    int x2, y2;
    int dir=(int)random(4);

    // Choose who to play against based on WELL_MIXED
    if (WELL_MIXED)
    {
      x2=(int)random(DIM);
      y2=(int)random(DIM);

      // check to make sure x != x2 and y != y2
      if (x==x2)
      {
        x2 = (x2+1)%DIM;
      }
      if (y==y2)
      {
        y2 = (y2+1)%DIM;
      }
    }
    else
    {
      x2 = (x+xm[dir])&(DIM-1);
      y2 = (y+ym[dir])&(DIM-1);
    }

    // Play games
    float P1, P2;

    // Grouping
    area[x][y].play(area[x2][y2]);

    P1=area[x][y].payoff;
    P2=area[x2][y2].payoff;
    if (random(0.0, 1.0)<(P1/(P1+P2)))
    {
      // P1 wins
      org_count[area[x2][y2].type] -= 1;
      area[x2][y2] = new Agent(area[x][y], x2, y2);
      org_count[area[x2][y2].type] += 1;
      area[x2][y2].show();
    }
    else
    {
      // P2 wins
      org_count[area[x][y].type] -= 1;
      area[x][y] = new Agent(area[x2][y2], x, y);
      org_count[area[x][y].type] += 1;
      area[x][y].show();
    }
  }
}