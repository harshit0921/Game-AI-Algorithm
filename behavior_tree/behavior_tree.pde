import java.util.HashMap;

static final float AGENT_RADIUS = 20;
static final int ARENA_SIZE = 800;
static final int TEAM_SIZE = 5;
// Agent max speed
static final float MAX_SPEED = 5;
static final float MAX_ACCEL = 10;
// Max time to enemy:  max seconds in the future to predict enemy movement for pursue
static final float MAX_TIME_TO_ENEMY = 2;
static final float MAX_ROT_SPEED = ((float) Math.PI)/10;
static final float ALIGN_TARGET_RAD = ((float) Math.PI)/60;
static final float ALIGN_SLOW_RAD = ((float) Math.PI)/15;
static final float BULLET_WIDTH = 3;
static final float BULLET_SPEED = 10;
static final int MAX_HEALTH = 20;

// Return codes for Behavior Tree tasks.
// If you wanted to implement an action that takes several frames,
// you could add a BUSY signal as well as a way to keep track of where
// you are in the tree, picking up again on the next frame.  But this assignment
// doesn't require that.
static final int FAIL = 0;
static final int SUCCESS = 1;

Agent[] redTeam = new Agent[TEAM_SIZE];
Agent[] blueTeam = new Agent[TEAM_SIZE];

class Agent {
  float x;
  float y;
  boolean redTeam;
  float angle;
  Blackboard blackboard;
  Task btree;
  PVector velocity;
  PVector linear_steering;
  float rotational_steering;
  boolean dead;
  boolean firing;
  Bullet bullet;
  int health;

  Agent(float x, float y, boolean redTeam, float angle) {
    this.x = x;
    this.y = y;
    this.redTeam = redTeam;
    this.angle = angle;
    this.blackboard = new Blackboard();
    this.velocity = new PVector(0, 0);
    this.linear_steering = new PVector(0, 0);
    this.rotational_steering = 0;
    this.dead = false;
    this.firing = false;
    this.bullet = new Bullet();
    this.health = MAX_HEALTH;
  }

  void draw() {
    if (dead) {
      return;
    }
    translate(x, y);
    rotate(angle);
    if (redTeam) {
      fill(255*(health+2)/(MAX_HEALTH+2), 0, 0);
    } else {
      fill(0, 0, 255*(health+2)/(MAX_HEALTH+2));
    }
    ellipse(0, 0, AGENT_RADIUS*2, AGENT_RADIUS*2);
    line(0, 0, AGENT_RADIUS, 0);
    rotate(-angle);
    translate(-x, -y);
  }
  
  void setBTree(Task btree) {
    this.btree = btree;
  }

  void act() {
    checkDeath();
    if (dead) {
      return;
    }
    linear_steering = new PVector(0,0);
    rotational_steering = 0;
    
    if(blackboard.allEnemiesDead())
    return;
    
    if(btree.execute() == 0)
    {
      btree = btree.leftAction(blackboard);
    }
    else
    {
      btree = btree.rightAction(blackboard);
    }
    if (linear_steering.mag() > MAX_ACCEL) {
      linear_steering.setMag(MAX_ACCEL);
    }
    velocity.add(linear_steering);
    if (velocity.mag() > MAX_SPEED) {
      velocity.setMag(MAX_SPEED);
    }
    x += velocity.x;
    y += velocity.y;
    if (Math.abs(rotational_steering) > MAX_ROT_SPEED) {
      rotational_steering = Math.copySign(MAX_ROT_SPEED, rotational_steering);
    }
    angle += rotational_steering;
    if (firing && !bullet.active) {
      PVector firingVector = PVector.fromAngle(angle);
      PVector displacementVector = firingVector.copy().setMag(AGENT_RADIUS+BULLET_WIDTH);
      bullet = new Bullet(x + displacementVector.x, y + displacementVector.y,
                          firingVector);
      bullet.draw();
    } else if (bullet.active) {
      // We'll just do this here
      bullet.update();
      bullet.draw();
    }
  }
  
  // We will be in charge of damaging ourselves in response to enemy collisions & bullets;
  // same for them
  void checkDamage(Agent target) {
    if (target.dead) {
      return;
    }
    if (dist(x, y, target.x, target.y) < AGENT_RADIUS *2) {
      health--;
    }
    if (dist(x, y, target.bullet.x, target.bullet.y) < AGENT_RADIUS + BULLET_WIDTH/2) {
      health--;
      target.bullet.active = false;
    }
    // Death checked later to avoid unfair tiebreaking
    return;
  }
  
  void checkDeath() {
    if (health <= 0) {
      dead = true;
    }
  }
  
}

class Bullet {
  boolean active;
  float x;
  float y;
  PVector velocity;
  
  Bullet() {
    active = false;
    x = 0;
    y = 0;
    velocity = new PVector(0,0);
  }
  
  Bullet(float x, float y, PVector direction) {
    active = true;
    this.x = x;
    this.y = y;
    this.velocity = direction.setMag(BULLET_SPEED);
  }
  
  void draw() {
    if (!active) {
      return;
    }
    fill(0,0,0);
    ellipse(x,y, BULLET_WIDTH, BULLET_WIDTH);
  }
  
  void update() {
    if (!active) {
      return;
    }
    x += velocity.x;
    y += velocity.y;
    if (x < 0 || y < 0 || x > ARENA_SIZE || y > ARENA_SIZE) {
      // offscreen
      active = false;
    }
    // We handle collisions elsewhere
  }
  
}

void settings() {
  size(ARENA_SIZE, ARENA_SIZE);
}

void setup() {

  for (int i = 0; i < TEAM_SIZE; i++) {
    redTeam[i] = new Agent((float)ARENA_SIZE/4, (float)ARENA_SIZE/8 + 100*i, true, (float)PI);
    redTeam[i].blackboard.put("Friends", redTeam);
    redTeam[i].blackboard.put("Enemies", blueTeam);
    redTeam[i].blackboard.put("Agent", redTeam[i]);
    redTeam[i].setBTree(new Mark(redTeam[i].blackboard));
    blueTeam[i] = new Agent((float)3*ARENA_SIZE/4, (float)ARENA_SIZE/8 + 100*i, false, 0);
    blueTeam[i].blackboard.put("Enemies", redTeam);
    blueTeam[i].blackboard.put("Friends", blueTeam);
    blueTeam[i].blackboard.put("Agent", blueTeam[i]);
    blueTeam[i].setBTree(new Mark(blueTeam[i].blackboard));
    
    
  }
  blueTeam[0].blackboard.leader = true;
}

void draw() {
  background(128,128,128);
  //delay(50);
  for (int i = 0; i < TEAM_SIZE; i++) {
    redTeam[i].act();
    blueTeam[i].act();
  }
  for (int i = 0; i < TEAM_SIZE; i++) {
    for (int j = 0; j < TEAM_SIZE; j++) {
      redTeam[i].checkDamage(blueTeam[j]);
      blueTeam[i].checkDamage(redTeam[j]);
    }
    redTeam[i].draw();
    blueTeam[i].draw();
  }
}

abstract class Task {
  abstract int execute();  // returns FAIL = 0, SUCCESS = 1
  Task success;
  Task fail;
  public Blackboard blackboard;
  
  abstract public Task leftAction(Blackboard bb);
  abstract public Task rightAction(Blackboard bb);
  // You can implement an abstract clone() here, or you may not find it necessary
}

class Blackboard {
  HashMap<String, Object> lookup;
  boolean marked;
  boolean pursuing;
  boolean aimed;
  boolean shooting;
  boolean leader;
  boolean busy;
  Agent target;
  

  Blackboard() {
    lookup = new HashMap<String, Object>();
    marked = false;
    pursuing = false;
    aimed = false;
    shooting = false;
    busy = false;
    target = null;
  }

  public Object get(String key) {
    return lookup.get(key);
  }

  public void put(String key, Object val) {
    lookup.put(key, val);
  }
  
  public boolean allEnemiesDead()
  {
    Agent[] enemies = (Agent[]) this.get("Enemies");
    int i;
    
    for(i=0; i<enemies.length; i++)
      if(!enemies[i].dead)
          break;
    
    if(i>=enemies.length)
    return true;
    
    return false;
  }
}

class Mark extends Task 
{
  Mark(Blackboard bb) {
    this.blackboard = bb;
  }
  
 int execute()
 {
    Agent agent = (Agent)blackboard.get("Agent");
    Agent[] targets = (Agent[])blackboard.get("Enemies");
    
    if(blackboard.target != null && blackboard.target.dead)
        for(int i=0; i<targets.length; i++)
          if(!targets[i].dead)
          blackboard.target = targets[i];
          
          
    for(int i=0; i<targets.length; i++)
    {
      if(blackboard.target == null && !targets[i].dead)
        blackboard.target = targets[i];
      if(!targets[i].dead)
        if(dist(agent.x, agent.y, targets[i].x, targets[i].y) < dist(agent.x, agent.y, blackboard.target.x, blackboard.target.y))
        {
          blackboard.target = targets[i];
        }
    }
    
    if(blackboard.target != null)
    {
      blackboard.busy = false;
      return SUCCESS;
    }
    
     return FAIL;
 }
 
 public Task leftAction(Blackboard bb)
 {
   return this;
 }
 
 public Task rightAction(Blackboard bb)
 {
   return new Pursue(blackboard);
 }
 
}

class Pursue extends Task 
{
  Pursue(Blackboard bb) {
    this.blackboard = bb;
  }
  
 int execute()
 {
    Agent agent = (Agent) blackboard.get("Agent");
    Agent enemy = blackboard.target;
    Agent[] enemies = (Agent[]) blackboard.get("Enemies");
    int i=0;
    
    while(i<TEAM_SIZE && enemies[i].dead)
    {
      i++;
    }
    
    if(i==TEAM_SIZE)
    {
      agent.velocity = new PVector(0, 0);
      return FAIL;
    }
    
    if(agent.redTeam)
      return SUCCESS;
    if(enemy!=null && !enemy.dead){
    PVector steering = new PVector(0, 0);
    
    PVector displacement = new PVector(agent.x - enemy.x, agent.y - enemy.y);
      steering.add(displacement);
      
    if (steering.mag() > MAX_ACCEL) {
      steering.setMag(MAX_ACCEL);
    }
    if(!agent.redTeam)
      agent.linear_steering.sub(steering);
      
      blackboard.busy = true;
      
      return SUCCESS;
      
    }
    
    return FAIL;
 }
 
 public Task leftAction(Blackboard bb)
 {
   return new Help(blackboard);
 }
 
 public Task rightAction(Blackboard bb)
 {
   return new Aim(blackboard);
 }
 
}

class Aim extends Task 
{
  Aim(Blackboard bb) {
    this.blackboard = bb;
  }
  
 int execute()
 {
   Agent agent = (Agent)blackboard.get("Agent");
   PVector direction;
    if(blackboard.target != null)
    {
      direction = new PVector(blackboard.target.x - agent.x, blackboard.target.y - agent.y);
      direction.normalize();
      float angle = direction.heading();
      
      if (angle != agent.angle) 
      {
        float difference = angle - agent.angle;
    
        while (difference < -PI) {
          difference += 2*PI;
        }
        while (difference >= PI) {
          difference -= 2*PI;
        }
      
        float rotationSize = abs(difference);
        if (rotationSize < ALIGN_TARGET_RAD) {
          return SUCCESS;
        }
        
        float targetRotation;
        if (rotationSize > ALIGN_SLOW_RAD) {
          targetRotation = MAX_ROT_SPEED;
        } else {
          targetRotation = MAX_ROT_SPEED * rotationSize / ALIGN_SLOW_RAD;
        }
        targetRotation *= difference / rotationSize;
        
        agent.angle += targetRotation;
        
        return FAIL;
      }
      
      return FAIL;
    }
    return FAIL;
 }
 
 public Task leftAction(Blackboard bb)
 {
   return this;
 }
 
 public Task rightAction(Blackboard bb)
 {
   return new Shoot(blackboard);
 }
 
}

class Shoot extends Task 
{
    Shoot(Blackboard bb) {
    this.blackboard = bb;
  }
  
 int execute()
 {
    Agent agent = (Agent) blackboard.get("Agent");
    Agent enemy = blackboard.target;
    
    if(agent.bullet.active)
    return FAIL;
    
    if(!enemy.dead && lineOfSight())
    {
      agent.firing = true;
      return SUCCESS;
    }
      agent.firing = false;
      blackboard.busy = false;
      return FAIL;
 }
 
 boolean lineOfSight()
 {
   Agent agent = (Agent) blackboard.get("Agent");
   Agent[] friends = (Agent[]) blackboard.get("Friends");
   Agent[] enemies = (Agent[]) blackboard.get("Enemies");
    Agent enemy = blackboard.target;
    
    PVector A, B;
    float dot, dist;
    
    for(int i=0; i<TEAM_SIZE; i++)
    {
      A = new PVector(friends[i].x - agent.x, friends[i].y - agent.y);
      B = new PVector(enemy.x - agent.x, enemy.y - agent.y);
      dot = PVector.dot(A, B)/B.mag();
      B.normalize();
      B.mult(dot);
      dist = dist(friends[i].x, friends[i].y, B.x, B.y);
      if(dist < AGENT_RADIUS)
        return false;
    }
    
    for(int i=0; i<TEAM_SIZE; i++)
    {
      if(enemies[i]!=enemy){
      A = new PVector(enemies[i].x - agent.x, enemies[i].y - agent.y);
      B = new PVector(enemy.x - agent.x, enemy.y - agent.y);
      dot = PVector.dot(A, B)/B.mag();
      B.normalize();
      B.mult(dot);
      dist = dist(enemies[i].x, enemies[i].y, B.x, B.y);
      if(dist < AGENT_RADIUS)
        return false;
      }
    }
    
    return true;
 }
 
 public Task leftAction(Blackboard bb)
 {
   return new Help(blackboard);
 }
 
 public Task rightAction(Blackboard bb)
 {
   return new Pursue(blackboard);
 }
 
}

class Help extends Task 
{
    Help(Blackboard bb) {
    this.blackboard = bb;
  }
  
 int execute()
 {
    Agent agent = (Agent) blackboard.get("Agent");
    Agent[] agents = (Agent[]) blackboard.get("Friends");
    Agent closest = null;
    for(int i=0; i<agents.length; i++)
    {
      if(agents[i] != agent && agents[i].blackboard.target != null && !agents[i].blackboard.target.dead)
        {
          if(closest == null)
            closest = agents[i];
          else if(dist(agent.x, agent.y, closest.x, closest.y) > dist(agent.x, agent.y, agents[i].x, agents[i].y))
            closest = agents[i];  
        }
    }
    
    if(closest!=null){
    blackboard.target = closest.blackboard.target;
    return SUCCESS;
    }
    
    return FAIL;
    
 }
 
 public Task leftAction(Blackboard bb)
 {
   return new Mark(blackboard);
 }
 
 public Task rightAction(Blackboard bb)
 {
   return new Pursue(blackboard);
 }
 
}