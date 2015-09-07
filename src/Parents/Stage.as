/**
 * Parent class for all stages
 */
package Parents
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.SharedObject;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	import Assets.Bullet;
	import Assets.Player;
	import Assets.Weapon;
	
	import Box2D.Common.Math.b2Vec2;
	import Box2D.Dynamics.b2Body;
	import Box2D.Dynamics.b2DebugDraw;
	import Box2D.Dynamics.b2World;
	
	import Game.ContactListener;
	import Game.OptionsMenu;
	import Game.PauseMenu;
	import Game.PlayerHUD;
	
	public class Stage extends MovieClip
	{
		/**Class Member Variables*/
		//constant to determine how much a pixel is in metric units
		public const metricPixRatio: uint = 20;
		
		/**BOX2D*/
		//number of checks over position and velocity
		private var iterations:int;
		//speed of checks
		private var timeStep:Number;
		
		/**LOGIC*/
		//world is in slow motion
		public static var slowMotion:Boolean;
		//amount of slow motion
		public static var slowAmount:Number;
		//paused or playing
		public static var paused:Boolean;
		//flying enemy count
		public static var flyCount:int;
		//flying enemy count
		public static var smallFlyCount:int;
		//flying enemy count
		public static var bigFlyCount:int;
		//platform enemy count
		public static var platformCount:int;
		//platform enemy count
		public static var smallPlatformCount:int;
		//platform enemy count
		public static var bigPlatformCount:int;
		//ammunition count
		public static var ammunitionCount:int;
		//array to hold key presses
		private var keyPresses:Array;
		
		/**WORLD*/
		//world for all objects to exist in
		private static var worldStage:b2World;
		//variable for all images to be held in for camera movement
		private static var images:Sprite;
		//HUD
		private var gameHUD:PlayerHUD;
		//speed world is; slow motion or normal
		private var speed:Number;
		//rotate weapon
		public static var weaponRotation:Number;
		//screen
		public var screen:FlashGame;
		
		/**GAME*/
		//delay controls
		private var beginTimer:Timer;
		//pause
		private var pauseMenu:PauseMenu;
		//rain
		public var hasRain:Boolean;
		
		/**PLAYER*/
		//player
		public var player:Player;
		//player body for collision detection
		public static var playerBody:b2Body;
		//the last position the player was (for speed calculation)
		private var lastPos:Point;
		//horizontal speed
		private static var horizontal:Number;
		//vertical speed
		private static var vertical:Number;
		//acceleration
		private var acceleration:Number;
		//is the player jumping
		public static var jumping:Boolean;
		//is the player air jumping
		public static var airJumping:Boolean;
		//is the player wall jumping from the right
		public static var rightWall:Boolean;
		//is the player wall jumping from the left
		public static var leftWall:Boolean;
		//is the player standing
		public static var floor:Boolean;
		//how long have they been jumping
		public static var jumpTime:int;
		//limit to length of jumping
		public static var jumpLimit:int;
		//current number of times player can jump
		public static const defaultJumpAmount:int = 2;
		//current number of times player can jump
		public static var jumpAmount:int;
		//fix player rotation speed after slow motion is over
		private var slowRotation:Boolean;
		//flinching
		public static var flinchTime:int;
		
		/**WEAPON*/
		public var weapon:Weapon;
		public static var machineFire:Boolean;
		private var machineDelay:int;
		
		private var pacifistState:Boolean;
		private var worldState:int;
		private var difficultyState:int;
		
		/**AUDIO**/
		private var musicChannel:SoundChannel;
		
		private var stageMusic:Sound;
		private var settings:SharedObject;
				
		/**Constructor*/
		public function Stage(screenP:FlashGame, debugging:Boolean, playerX:Number, playerY:Number, pacifist:Boolean, world:int, difficulty:int, _musicChannel:SoundChannel,  _settings:SharedObject)
		{
			screen = screenP;
			pacifistState = pacifist;
			worldState = world;
			difficultyState = difficulty;
			
			settings = _settings;
			settings = SharedObject.getLocal("Settings");
			
			musicChannel = _musicChannel;
			
			stageMusic = new MenuMusic;
			musicChannel = stageMusic.play(0, int.MAX_VALUE);
			musicChannel.soundTransform = new SoundTransform(settings.data.musicVolume);
			
			/**BOX2D*/
			//initiate time
			iterations = 10;
			timeStep = 1/30;
						
			/**LOGIC*/
			keyPresses = new Array();
			weaponRotation = 0;
			flyCount = 0;
			smallFlyCount = 0;
			bigFlyCount = 0;
			platformCount = 0;
			smallPlatformCount = 0;
			bigPlatformCount = 0;
			ammunitionCount = 0;
			
			/**VISUAL*/
			//initiate images
			images = new Sprite();
			this.addChild(images);
			
			/**EVENT*/
			paused = false;
			
			/**WORLD*/
			var gravity:b2Vec2 = new b2Vec2(0, 85);
			var doSleep:Boolean = true;//don't simulate sleeping bodies
			worldStage = new b2World(gravity, doSleep);
			worldStage.SetContactListener(new ContactListener(settings) );
			slowMotion = false;
			slowAmount = 225;
			speed = 1;
			
			/**PLAYER*/
			lastPos = new Point();

			horizontal = 0;
			vertical = 0;
			acceleration = 0;
			jumping = false;
			airJumping = false;
			rightWall = false;
			leftWall = false;
			floor = false;
			jumpTime = 0;
			jumpLimit = 5;
			jumpAmount = defaultJumpAmount;
			slowRotation = false;
			flinchTime = 0;
						
			//PLAYER
			player = new Player(playerX, playerY, 3.5);
			this.setPlayer(player.body);
			Player.playerInvulnerable = 100;
			
			//WEAPON
			weapon = new Weapon(15, 7,1);
			machineFire = false;
			machineDelay = 2;
			
			//HUD
			gameHUD = new PlayerHUD(this, pacifist, world, difficulty);
			this.addChild(gameHUD);
			
			//delay controls
			beginTimer = new Timer(3000, 1);
			beginTimer.addEventListener(TimerEvent.TIMER, addControls);
			beginTimer.start();
			
			/**DEBUGGING*/
			if(debugging){
				debugDrawing();
			}
			
		}
		
		/**Stages can update their properties*/
		public function update():void{
			if(!paused){
				//clear sprites from last frame
				sprites.graphics.clear();
				
				/**CAMERA*/
				centerScreen(playerBody.GetPosition().x, playerBody.GetPosition().y);
				
				/**BOX2D*/
				world.Step(timeStep,iterations,iterations);
				world.ClearForces();
				world.DrawDebugData();
				
				/**OBJECTS*/
				for(var bodies:b2Body = world.GetBodyList(); bodies; bodies = bodies.GetNext() ){
					//if they exist update them
					if(bodies.GetUserData() != null){
						bodies.GetUserData().update();
						
						//slow motion
						var bodyVelocity:b2Vec2 = bodies.GetLinearVelocity();
						if(slowMotion == true && slowAmount > 0 ){
							var slowVelocity:b2Vec2 = new b2Vec2(bodyVelocity.x*0.5,bodyVelocity.y*0.5);
							
							bodies.SetLinearVelocity(slowVelocity);
						}
						else if(slowMotion == false){
							bodies.SetLinearVelocity(bodyVelocity);
						}
					}
				}
				
				/**FORCES & KEY PRESSES*/
				var direction:b2Vec2 = new b2Vec2();
				
				for(var i:uint = 0; i < keyPresses.length;i++){
					if(flinchTime == 0){
						switch(keyPresses[i]){
							case OptionsMenu.keybindings.fall:
								//downward velocity in air
								if(jumping){
									direction.Set(0, 180);
									playerBody.SetAwake(true);
									playerBody.ApplyForce(direction, playerBody.GetPosition() );
									if(Player.STATE != Player.DODGE ){
										Player.STATE = Player.FAST_FALL;
									}
								}
								break;
							case OptionsMenu.keybindings.jump:
								//initial jump
								if(jumping == false && !rightWall && !leftWall){
									jumping = true;
									direction.Set(0,-25);
									playerBody.SetAwake(true);
									playerBody.ApplyImpulse(direction, playerBody.GetPosition() );
									if(Player.STATE != Player.DODGE ){
										Player.STATE = Player.JUMPING;
									}
								}
									//continuing initial jump
								else if(jumping == true && 
									jumpTime <= jumpLimit && 
									jumpAmount == defaultJumpAmount){
									jumpTime++;
									direction.Set(0,-500);
									playerBody.SetAwake(true);
									playerBody.ApplyForce(direction, playerBody.GetPosition() );
								}
									//air jump initial
								else if(jumping == true &&
									jumpAmount < defaultJumpAmount && 
									jumpAmount > 0 &&
									!airJumping){
									jumpTime = 0;
									airJumping = true;
									direction.Set(playerBody.GetLinearVelocity().x,-25);
									playerBody.SetLinearVelocity(direction);
								}
									//continuing air jump
								else if(airJumping == true && 
									jumpTime <= jumpLimit && 
									jumpAmount > 0){
									jumpTime++;
									direction.Set(0,-500);
									playerBody.SetAwake(true);
									playerBody.ApplyForce(direction, playerBody.GetPosition() );
								}
									//hover
								else if(jumpTime == jumpLimit+1 && playerBody.GetLinearVelocity().y > 0 || jumpAmount == 0){
									direction.Set(0,-150);
									playerBody.SetAwake(true);
									playerBody.ApplyForce(direction, playerBody.GetPosition() );
									if(Player.STATE != Player.DODGE){
										Player.STATE = Player.HOVER;
									}
								}
									//initial jump off right wall
								else if(rightWall){
									jumping = true;
									rightWall = false;
									direction.Set(-90,-43);
									playerBody.SetAwake(true);
									playerBody.ApplyImpulse(direction, playerBody.GetPosition() );
									if(Player.STATE != Player.DODGE && !Stage.floor){
										Player.STATE = Player.JUMPING;
									}
								}
									//initial jump off left wall
								else if(leftWall){
									jumping = true;
									leftWall = false;
									direction.Set(90,-43);
									playerBody.SetAwake(true);
									playerBody.ApplyImpulse(direction, playerBody.GetPosition() );
									if(Player.STATE != Player.DODGE && !Stage.floor){
										Player.STATE = Player.JUMPING;
									}
								}
								break;	
							case OptionsMenu.keybindings.left:
								//limit speed
								if(horizontal>-2){
									direction.Set(-250*speed,0);
									playerBody.SetAwake(true);
									playerBody.ApplyForce(direction,playerBody.GetPosition());
									if(slowMotion && slowAmount > 0){
										Player.playerRotation = -20;
									}
									else{
										Player.playerRotation = -40;
									}
								}
								//animation
								if(Player.STATE != Player.DODGE && Player.STATE != Player.R_WALK && Player.STATE != Player.R_WALK_SLOW){
									if(!jumping && !leftWall && !rightWall && !slowMotion && Stage.floor || !jumping && !leftWall && !rightWall && slowMotion && slowAmount <= 0 && Stage.floor){
										Player.STATE = Player.L_WALK;
									}
									else if(!jumping && !leftWall && !rightWall && slowMotion && slowAmount > 0 && Stage.floor){
										Player.STATE = Player.L_WALK_SLOW;
									}
									else if(leftWall){
										Player.STATE = Player.L_WALL;
									}
								}
								else if(Player.STATE != Player.DODGE && Player.STATE == Player.R_WALK || Player.STATE == Player.R_WALK_SLOW){
									Player.STATE = Player.IDLE;
								}
								break;
							case OptionsMenu.keybindings.right:
								//limit speed
								if(horizontal<2){
									direction.Set(250*speed,0);
									playerBody.SetAwake(true);
									playerBody.ApplyForce(direction,playerBody.GetPosition());
									if(slowMotion && slowAmount > 0){
										Player.playerRotation = 20;
									}
									else{
										Player.playerRotation = 40;
									}
								}
								//animation
								if(Player.STATE != Player.DODGE && Player.STATE != Player.L_WALK && Player.STATE != Player.L_WALK_SLOW){
									if(!jumping && !rightWall && !leftWall && !slowMotion && Stage.floor || !jumping && !rightWall && !leftWall && slowMotion && slowAmount <= 0 && Stage.floor){
										Player.STATE = Player.R_WALK;
									}
									else if(!jumping && !rightWall && !leftWall && slowMotion && slowAmount > 0 && Stage.floor){
										Player.STATE = Player.R_WALK_SLOW;
									}
									else if(rightWall){
										Player.STATE = Player.R_WALL;
									}
								}
								else if(Player.STATE != Player.DODGE && Player.STATE == Player.L_WALK || Player.STATE == Player.L_WALK_SLOW){
									Player.STATE = Player.IDLE;
								}
								break;
							case OptionsMenu.keybindings.slow:
								if(slowMotion == false && slowAmount > 0 && Player.playerHealth > 0){
									slowMotion = true;
									jumpLimit = 12;
									if(Player.playerRotation > 0){
										Player.playerRotation = 20;
									}
									else{
										Player.playerRotation = -20;
									}
									slowRotation = true;
									speed = 0.75;
									if(jumpTime == 6){
										jumpTime = 13;
									}
								}
								else if(slowAmount > 0 && Player.playerHealth > 0){
									slowAmount-=3.375;
								}
								break;
						}
					}
					
				}
				
				//get current physics
				var currentPos:Point = new Point(playerBody.GetPosition().x, playerBody.GetPosition().y);
				var currentVelocity:Number = currentPos.x - lastPos.x;
				
				//update forces and positions
				acceleration = currentVelocity - horizontal;
				horizontal = currentVelocity;
				vertical = currentPos.y - lastPos.y;
				lastPos = currentPos;
				
				//slow meter
				if(slowAmount < 225 && !slowMotion){
					slowAmount+= 2.25;
				}
				else if(slowAmount <= 0 && slowMotion){
					jumpLimit = 5;
					speed = 1;
				}
				
				//fix rotation if necessary
				if(slowAmount <= 0 && slowRotation){
					slowRotation = false;
					Player.playerRotation = 40;
				}
				
				//flinch
				if(flinchTime > 1){
					flinchTime--;
				} 	
				else if(flinchTime == 1){
					flinchTime--;
					if(jumping){
						Player.STATE = Player.JUMPING;
					}
					else{
						Player.STATE = Player.IDLE;
					}
				}
				
				var mouseDirectionX:Number = mouseX - stage.stageWidth/2;
				var mouseDirectionY:Number = mouseY - stage.stageHeight/2;
				
				weaponRotation = Math.atan2(mouseDirectionY, mouseDirectionX);
				
				//fire machine gun
				if(machineFire == true){
					if(machineDelay == 2){
						var machineBullet:Bullet = new Bullet(playerBody.GetPosition().x + 3 * Math.cos(weaponRotation), playerBody.GetPosition().y + 3 * Math.sin(weaponRotation),0.3,0.3);
						Weapon.machinegunAmmo--;
						machineDelay = 0;
					}
					else{
						machineDelay++;
					}
					
					if(Weapon.machinegunAmmo <= 0){
						machineFire = false;
						machineDelay = 2;
					}
				}
				
				//HUD
				gameHUD.updateHUD();
				
			}
			
			if(pauseMenu != null){
				pauseMenu.update();
			}
		}
		
		/**Stages always center the screen on the player*/
		private function centerScreen(xPos:Number, yPos:Number):void{
			//get player position and screen size
			var x_Pos:Number = xPos*metricPixRatio;
			var y_Pos:Number = yPos*metricPixRatio;
			var stageHeight:Number = stage.stageHeight;
			var stageWidth:Number = stage.stageWidth;
			
			//center screen
			images.x = -1*x_Pos + stageWidth/2;
			images.y = -1*y_Pos + stageHeight/2;
		}
		
		/**Stages can detect key presses*/
		public function keyPressed(e:KeyboardEvent):void{
			var inArray:Boolean = false;
			//loop over key presses
			for(var i:uint =0; i< keyPresses.length; i++){
				//check if pressed key is same as a key in the array
				if(keyPresses[i] == e.keyCode){
					inArray = true;
				}
			}
			
			//add to array if wasn't in it
			if(!inArray){
				keyPresses.push(e.keyCode);
			}
			
			//pausing
			if(e.keyCode == OptionsMenu.keybindings.pause || e.keyCode == Keyboard.R){
				if(paused == false){
					pauseMenu = new PauseMenu(this, 350, 260, pacifistState, worldState, difficultyState, musicChannel, settings);
					paused = true;
				}
				else if(paused == true){
					pauseMenu.destroy();
					pauseMenu = null;
					
					paused = false;
				}
				
				var menuSelect:Sound = new MenuSelect;
				menuSelect.play(0,0, new SoundTransform(settings.data.effectsVolume));
			}
			//change weapon
			else if(e.keyCode == OptionsMenu.keybindings.weaponLeft){
				if(Weapon.weaponType == 1 && Weapon.machinegunAmmo > 0){
					Weapon.weaponType = 3;
					Weapon.changeWeapon = true;
				}
				else if(Weapon.weaponType == 1 && Weapon.machinegunAmmo <= 0 && Weapon.shotgunAmmo > 0){
					Weapon.weaponType = 2;
					Weapon.changeWeapon = true;
				}
				else if(Weapon.weaponType == 2 && Weapon.pistolAmmo > 0){
					Weapon.weaponType = 1;
					Weapon.changeWeapon = true;
				}
				else if(Weapon.weaponType == 2 && Weapon.pistolAmmo <= 0 && Weapon.machinegunAmmo > 0){
					Weapon.weaponType = 3;
					Weapon.changeWeapon = true;
				}
				else if(Weapon.weaponType == 3 && Weapon.shotgunAmmo > 0){
					Weapon.weaponType = 2;
					Weapon.changeWeapon = true;
				}
				else if(Weapon.weaponType == 3 && Weapon.shotgunAmmo <= 0 && Weapon.pistolAmmo > 0){
					Weapon.weaponType = 1;
					Weapon.changeWeapon = true;
				}
			}
			else if(e.keyCode == OptionsMenu.keybindings.weaponRight){
				if(Weapon.weaponType == 1 && Weapon.shotgunAmmo > 0){
					Weapon.weaponType = 2;
					Weapon.changeWeapon = true;
				}
				else if(Weapon.weaponType == 1 && Weapon.shotgunAmmo <= 0 && Weapon.machinegunAmmo > 0){
					Weapon.weaponType = 3;
					Weapon.changeWeapon = true;
				}
				else if(Weapon.weaponType == 2 && Weapon.machinegunAmmo > 0){
					Weapon.weaponType = 3;
					Weapon.changeWeapon = true;
				}
				else if(Weapon.weaponType == 2 && Weapon.machinegunAmmo <= 0 && Weapon.pistolAmmo > 0){
					Weapon.weaponType = 1;
					Weapon.changeWeapon = true;
				}
				else if(Weapon.weaponType == 3 && Weapon.pistolAmmo > 0){
					Weapon.weaponType = 1;
					Weapon.changeWeapon = true;
				}
				else if(Weapon.weaponType == 3 && Weapon.pistolAmmo <= 0 && Weapon.shotgunAmmo > 0){
					Weapon.weaponType = 2;
					Weapon.changeWeapon = true;
				}
			}
			else if(e.keyCode == OptionsMenu.keybindings.pistol){
				if(Weapon.pistolAmmo > 0){
					Weapon.weaponType = 1;
					Weapon.changeWeapon = true;
				}
			}
			else if(e.keyCode == OptionsMenu.keybindings.shotgun){
				if(Weapon.shotgunAmmo > 0){
					Weapon.weaponType = 2;
					Weapon.changeWeapon = true;
				}
			}
			else if(e.keyCode == OptionsMenu.keybindings.machinegun){
				if(Weapon.machinegunAmmo > 0){
					Weapon.weaponType = 3;
					Weapon.changeWeapon = true;
				}
			}
			else if(e.keyCode == OptionsMenu.keybindings.rain){
				removeAddRain();
			}
		}
		
		/**Stages can detect key releases*/
		public function keyReleased(e:KeyboardEvent):void{
			//loop over key releases
			for(var i:uint=0; i<keyPresses.length;i++){
				//check if released key is in array
				if(keyPresses[i] == e.keyCode){
					//remove it
					keyPresses.splice(i,1);
					i--;
				}
			}
			
			//jumping
			if(e.keyCode == OptionsMenu.keybindings.jump){
				airJumping = false;
				if(jumpAmount > 0){
					jumpAmount--;
				}
				
				if(Player.STATE == Player.HOVER){
					Player.STATE = Player.JUMPING;
				}
			}
			else if(e.keyCode ==OptionsMenu.keybindings.fall){
				if(Player.STATE == Player.FAST_FALL){
					Player.STATE = Player.JUMPING;
				}
			}
			//movement
			else if(e.keyCode == OptionsMenu.keybindings.right && !jumping && !rightWall || e.keyCode == OptionsMenu.keybindings.left && !jumping && !leftWall){
				Player.STATE = Player.IDLE;
			}
			//slow motion
			else if(e.keyCode == OptionsMenu.keybindings.slow){
				if(slowMotion == true){
					slowMotion = false;
					jumpLimit = 5;
					if(Player.playerRotation > 0){
						Player.playerRotation = 40;	
					}
					else{
						Player.playerRotation = -40;							
					}
					speed = 1;
				}
			}
		}
		
		/**Stages can detect left clicks*/
		public function leftClick(e:MouseEvent):void{
			if(Weapon.holdingWeapon && !paused && Player.playerHealth > 0){
				if(Weapon.weaponType == 1 && Weapon.pistolAmmo > 0){
					if(weaponRotation > -1.5 && weaponRotation < 1.5 && weapon.weaponClip.endFire){
						weapon.rightFire = true;
						weapon.weaponClip.endFire = false;
						
						var pistolRight:Bullet = new Bullet(playerBody.GetPosition().x + Math.cos(weaponRotation), playerBody.GetPosition().y +Math.sin(weaponRotation),0.3,0.3);	
						Weapon.pistolAmmo--;
					}
					else if(!weapon.leftFire && weapon.weaponClip.endFire){
						weapon.leftFire = true;
						weapon.weaponClip.endFire = false;
						
						var pistolLeft:Bullet = new Bullet(playerBody.GetPosition().x + Math.cos(weaponRotation), playerBody.GetPosition().y +Math.sin(weaponRotation),0.3,0.3);	
						Weapon.pistolAmmo--;
					}
				}
				else if(Weapon.weaponType == 2 && Weapon.shotgunAmmo > 0){
					if(weaponRotation > -1.5 && weaponRotation < 1.5 && weapon.weaponClip.endFire){
						weapon.rightFire = true;
						weapon.weaponClip.endFire = false;
							
						var shotgunRight1:Bullet = new Bullet(playerBody.GetPosition().x + Math.cos(weaponRotation), playerBody.GetPosition().y +Math.sin(weaponRotation),0.3,0.3);
						var shotgunRight2:Bullet = new Bullet(playerBody.GetPosition().x + Math.cos(weaponRotation), playerBody.GetPosition().y +Math.sin(weaponRotation),0.3,0.3);	
						var shotgunRight3:Bullet = new Bullet(playerBody.GetPosition().x + Math.cos(weaponRotation), playerBody.GetPosition().y +Math.sin(weaponRotation),0.3,0.3);	

						Weapon.shotgunAmmo--;
					}
					else if(!weapon.leftFire && weapon.weaponClip.endFire){
						weapon.leftFire = true;
						weapon.weaponClip.endFire = false;
						
						var shotgunLeft1:Bullet = new Bullet(playerBody.GetPosition().x + Math.cos(weaponRotation), playerBody.GetPosition().y +Math.sin(weaponRotation),0.3,0.3);	
						var shotgunLeft2:Bullet = new Bullet(playerBody.GetPosition().x + Math.cos(weaponRotation), playerBody.GetPosition().y +Math.sin(weaponRotation),0.3,0.3);	
						var shotgunLeft3:Bullet = new Bullet(playerBody.GetPosition().x + Math.cos(weaponRotation), playerBody.GetPosition().y +Math.sin(weaponRotation),0.3,0.3);	

						Weapon.shotgunAmmo--;
					}
				}
				else if(Weapon.weaponType == 3 && Weapon.machinegunAmmo > 0){
					if(weaponRotation > -1.5 && weaponRotation < 1.5){
						machineFire = true;
						weapon.rightFire = true;						
					}
					else{
						machineFire = true;
						weapon.leftFire = true;
					}
				}
			}
		}
		
		/**Stages can detect left mouse lifts*/
		public function leftUp(e:MouseEvent):void{
			if(Weapon.weaponType == 3){
				machineFire = false;
				weapon.rightFire = false;
				weapon.leftFire = false;
				machineDelay = 2;
			}
		}
		
		/**Stage can detect mouse wheels*/
		public function mouseWheeled(e:MouseEvent):void{
			if(Weapon.holdingWeapon && !paused && Player.playerHealth != 0){
				Weapon.changeWeapon = true;

				//up wheel
				if(e.delta > 0){
					if(Weapon.weaponType == 1 && Weapon.shotgunAmmo > 0){
						Weapon.weaponType = 2;
					}
					else if(Weapon.weaponType == 1 && Weapon.shotgunAmmo <= 0 && Weapon.machinegunAmmo > 0){
						Weapon.weaponType = 3;
					}
					else if(Weapon.weaponType == 2 && Weapon.machinegunAmmo > 0){
						Weapon.weaponType = 3;
					}
					else if(Weapon.weaponType == 2 && Weapon.machinegunAmmo <= 0 && Weapon.pistolAmmo > 0){
						Weapon.weaponType = 1;
					}
					else if(Weapon.weaponType == 3 && Weapon.pistolAmmo > 0){
						Weapon.weaponType = 1;
					}
					else if(Weapon.weaponType == 3 && Weapon.pistolAmmo <= 0 && Weapon.shotgunAmmo > 0){
						Weapon.weaponType = 2;
					}
				}
				//down wheel
				else{
					if(Weapon.weaponType == 1 && Weapon.machinegunAmmo > 0){
						Weapon.weaponType = 3;
					}
					else if(Weapon.weaponType == 1 && Weapon.machinegunAmmo <= 0 && Weapon.shotgunAmmo > 0){
						Weapon.weaponType = 2;
					}
					else if(Weapon.weaponType == 2 && Weapon.pistolAmmo > 0){
						Weapon.weaponType = 1;
					}
					else if(Weapon.weaponType == 2 && Weapon.pistolAmmo <= 0 && Weapon.machinegunAmmo > 0){
						Weapon.weaponType = 3;
					}
					else if(Weapon.weaponType == 3 && Weapon.shotgunAmmo > 0){
						Weapon.weaponType = 2;
					}
					else if(Weapon.weaponType == 3 && Weapon.shotgunAmmo <= 0 && Weapon.pistolAmmo > 0){
						Weapon.weaponType = 1;
					}
				}
			}
		}
		
		/**Add Controls to Stage*/
		private function addControls(e:TimerEvent):void{
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyReleased, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, leftClick);
			stage.addEventListener(MouseEvent.MOUSE_UP, leftUp);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheeled);
			beginTimer.removeEventListener(TimerEvent.TIMER, addControls);
			beginTimer.stop();
		}
		
		/**Destroy Stage*/
		public function destroy():void{
			gameHUD.destroy();
			
			musicChannel.stop();
			
			this.removeChild(images);
		
			pauseMenu = null;
			
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			stage.removeEventListener(KeyboardEvent.KEY_UP, keyReleased);
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, leftClick);
			stage.removeEventListener(MouseEvent.MOUSE_UP, leftUp);
			stage.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseWheeled);
			
			childDestroy();
			
			screen.removeChild(this);
		}
		
		/**Worlds remove differently*/
		public function childDestroy():void{}
		
		/**Remove or Add Rain*/
		public function removeAddRain():void{}
		
		/**Get and Set for stageWorld*/
		static public function get world():b2World{ return worldStage; }
		static public function set world(worldStageP:b2World):void{
			if(worldStage == null){
				worldStage = worldStageP;
			}
		}
		
		/**Get and Set for images*/
		static public function get sprites():Sprite{ return images; }
		static public function set sprites(imagesP:Sprite):void{
			if(images == null){
				images = imagesP;
			}
		}
		
		/**Set player*/
		protected function setPlayer(playerP:b2Body):void{
			playerBody = playerP;
		}
		
		/**Draws Box2D collision shapes*/
		private function debugDrawing():void{
			var debugDraw:b2DebugDraw = new b2DebugDraw();
			debugDraw.SetSprite(images);
			debugDraw.SetDrawScale(metricPixRatio);
			debugDraw.SetAlpha(0.3);
			debugDraw.SetLineThickness(1.0);
			
			debugDraw.SetFlags(b2DebugDraw.e_shapeBit|b2DebugDraw.e_jointBit);
			worldStage.SetDebugDraw(debugDraw);
		}
	}
}