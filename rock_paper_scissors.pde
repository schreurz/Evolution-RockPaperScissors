
/*
 Rock paper scissors agent based survival and evolution visualization

 RED = ROCK
 GREEN = PAPER
 BLUE = SCISSORS
 A lot of red -> green strives
 A lot of green -> blue strives
 A lot of blue -> red strives
 Shoult oscillate from red->green->blue->red for well mixed
 For grouping red takes blue, blue takes green, green takes red
*/




int GAMES_PER_DRAW = 100; // Games played per draw() calls
int DATA_UPDATE_FREQUENCY = 20; // Draw() calls per .csv file update
String DATA_DIR = "data/"+month()+'-'+day()+'-'+year()+'_'+hour()+':'+minute()+':'+second()+'/';  // Directory to save data to
int REPEAT_MAX = 500;

boolean well_mixed = true; // True for well-mixed, false for spacial
int dim=16; //exponent of 2
float my=0.0; // Mutation Rate
boolean random_player = false;

                        // R   P   S
float[][] payoffMatrix={{1.0, 0.0, 2.0}, // R
                        {2.0, 1.0, 0.0}, // P
                        {0.0, 2.0, 1.0}};// S

int[] xm={0, 1, 0, -1};
int[] ym={-1, 0, 1, 0};

Agent[][] area;

// Org counter for no mutations
int[] org_count = new int[4];

void setup()
{
  size(640, 640);
  resetEverything();
}

int state = 0;
void setState()
{
  random_player = boolean(state & 1);
  well_mixed = boolean((state >> 1) & 1);
  state = (state+1)%4;
}

int repeat = 0;
PrintWriter output;
void resetEverything()
{
  if (repeat == REPEAT_MAX)
  {
    exit();
  }
  setState();
  
  if (my == 0.0)
  // only count orgs when no evolution
  {
    for(int i=0;i<4;i++)
    {
      org_count[i] = 0;
    }
  }
  
  area=new Agent[dim][dim];
  for (int i=0; i<dim; i++)
  {
    for (int j=0; j<dim; j++)
    {
      area[i][j]=new Agent(null, i, j); // Null because no parent
      area[i][j].show();
    }
  }

  if (my == 0.0)
  {
    output = createWriter(DATA_DIR+"data_"+str(repeat)+".csv");
    output.println("R,P,S,M,Size,Well Mixed,Random");
  }
  //output.println(",,,,"+str(dim)+','+str(well_mixed)+','+str(random_player));
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


      if (random_player)
      {
        // Make 1/4th of the agents random players
        if ((int)random(4)==0)
        {
          type = 3;
          genome[0]=genome[1]=genome[2]=1.0/3.0;
        }
      }
      if (my == 0.0)
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
        if (random(0.0, 1.0) < my)
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

int count = 0; // variable for knowing when to update the .csv file
void draw()
{
  if (my == 0.0 && !boolean((count%DATA_UPDATE_FREQUENCY)))
  {
    
    //println(Integer.toString(org_count[0])+' '+Integer.toString(org_count[1])+' '+Integer.toString(org_count[2])+' '+Integer.toString(org_count[3]));
    
    int nrZ = 0; // number of extinct species (always includes random strategy)
    for(int i=0;i<4;i++)
    {
      if(i!=0) // don't print comma on initial loop
      {
        output.print(",");
      }
      output.print(str(org_count[i]));
      if (org_count[i] == 0) // organism is extinct
        nrZ++;
    }
    output.print(','+str(dim)+','+str(well_mixed)+','+str(random_player));
    output.print("\n");
    output.flush();
    if(nrZ == 3)
    {
      output.close();
      repeat++;
      resetEverything();
      //saveFrame("frame_#####.png");
    }
  }
  count = (count+1)%DATA_UPDATE_FREQUENCY;
  
  for (int i=0; i<GAMES_PER_DRAW; i++) {
    int x=(int)random(dim);
    int y=(int)random(dim);
    int x2, y2;

    // Choose who to play against based on well_mixed
    if (well_mixed)
    {
      x2=(int)random(dim);
      y2=(int)random(dim);

      // check to make sure x != x2 and y != y2
      if (x==x2)
      {
        x2 = (x2+1)&(dim-1);
      }
      if (y==y2)
      {
        y2 = (y2+1)&(dim-1);
      }
    }
    else
    {
      int dir=(int)random(4);
      x2 = (x+xm[dir])&(dim-1);
      y2 = (y+ym[dir])&(dim-1);
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