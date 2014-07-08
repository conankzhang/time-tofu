/**
 * Code to make flyingEnemy
 */
package Assets {
	
	import Box2D.Collision.Shapes.b2PolygonShape;
	import Box2D.Collision.b2RayCastInput;
	import Box2D.Collision.b2RayCastOutput;
	import Box2D.Common.Math.b2Math;
	import Box2D.Common.Math.b2Vec2;
	import Box2D.Dynamics.Joints.b2RevoluteJoint;
	import Box2D.Dynamics.Joints.b2RevoluteJointDef;
	import Box2D.Dynamics.b2Body;
	import Box2D.Dynamics.b2BodyDef;
	import Box2D.Dynamics.b2FilterData;
	import Box2D.Dynamics.b2Fixture;
	import Box2D.Dynamics.b2FixtureDef;
	import Box2D.Dynamics.b2World;
	
	import Parents.*;
	
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	public class FlyingEnemy extends Objects{
		/**Class Member Variables*/
		//STAGE
		private var stage_Sprite:Sprite = Stage.sprites;
		private var world_Sprite:b2World = Stage.world;
		private var metricPixRatio:Number = Stage.metricPixRatio;
		
		//PROPERTIES
		private var position:Point;
		private var flyingEnemyClip:MovieClip;
		private var flyingEnemy_Width:Number;
		private var flyingEnemy_Height:Number;
		private var flyingEnemy_LinearDamping:Number;
		private var flyingEnemyHealth:int;
		
		//BOX2D COLLISION & PHYSICS
		private var collisionBody:b2Body;
		private var flyingEnemyFixture:b2FixtureDef;

		//AI
		private var beginRayCast:b2Vec2;
		private var endRayCast:b2Vec2;
		private var lambda:Number;
		
		private var beginRayCast2:b2Vec2;
		private var endRayCast2:b2Vec2;
		private var lambda2:Number;
		
		private var rayFixture:b2Fixture;
		private var	rayPoint:b2Vec2;
		private var rayNormal:b2Vec2;
		private var rayFraction:Number;
		
		private var rayFixture2:b2Fixture;
		private var	rayPoint2:b2Vec2;
		private var rayNormal2:b2Vec2;
		private var rayFraction2:Number;
		/**Constructor*/
		public function FlyingEnemy(xPos:Number, yPos:Number, width:Number, height:Number){
			//assign parameters to class member variables
			position = new Point(xPos, yPos);
			
			//initialize default private variables
			flyingEnemy_Width = width;
			flyingEnemy_Height = height;
			flyingEnemy_LinearDamping = 1;
			flyingEnemyHealth = 2;
			
			flyingEnemyFixture = new b2FixtureDef();
			
			make();
		}
		
		/**Makes FlyingEnemy*/
		public function make():void{
			//Box2D shape
			var flyingEnemyShape:b2PolygonShape = new b2PolygonShape();
			flyingEnemyShape.SetAsBox(flyingEnemy_Width/2, flyingEnemy_Height/3);
			
			//Box2D shape properties
			flyingEnemyFixture.shape = flyingEnemyShape;
			flyingEnemyFixture.userData = "ENEMY";
			flyingEnemyFixture.filter.categoryBits = 6;
			
			//Box2D collision shape
			var flyingEnemyCollision:b2BodyDef = new b2BodyDef();
			flyingEnemyCollision.position.Set(position.x + flyingEnemy_Width/2, position.y + flyingEnemy_Height/2);
			flyingEnemyCollision.type = b2Body.b2_dynamicBody;
			flyingEnemyCollision.linearDamping = flyingEnemy_LinearDamping;
			
			collisionBody = world_Sprite.CreateBody(flyingEnemyCollision);
			collisionBody.CreateFixture(flyingEnemyFixture);
			super.body = collisionBody;
			
			//Sprite
			flyingEnemyClip = new enemy_flying;
			flyingEnemyClip.stop();
			flyingEnemyClip.width = flyingEnemy_Width*metricPixRatio;
			flyingEnemyClip.height = flyingEnemy_Height*metricPixRatio;
			super.sprite = flyingEnemyClip;
			Stage.sprites.addChild(flyingEnemyClip);
		}
		
		/**Child Update [called by Object's update]*/
		public override function childUpdate():void{
			var direction:b2Vec2 = new b2Vec2();
			   						
			/**Follow player*/ 
			//get direction and magnitude to player
			direction = b2Math.SubtractVV(Stage.player.GetPosition() , collisionBody.GetPosition());
			
			beginRayCast = collisionBody.GetPosition();
			direction.Normalize();
			direction.Multiply(3);
			endRayCast = b2Math.AddVV(direction,collisionBody.GetPosition());
			endRayCast.x -= flyingEnemy_Width/3;
			endRayCast.y -= flyingEnemy_Height/3;
			
			beginRayCast2 = collisionBody.GetPosition();
			endRayCast2 = b2Math.AddVV(direction,collisionBody.GetPosition());
			endRayCast2.x -= flyingEnemy_Width/3;
			endRayCast2.y += flyingEnemy_Height/3;
			
			world_Sprite.RayCast(Callback ,beginRayCast,endRayCast);
			world_Sprite.RayCast(Callback2 ,beginRayCast2,endRayCast2);

//			lambda = 1;
//			lambda2 = 1;

			if(rayFixture != null){
//				var input:b2RayCastInput = new b2RayCastInput(beginRayCast, endRayCast);
//				var output:b2RayCastOutput = new b2RayCastOutput();
//				lambda = output.fraction;
				
				if(rayFixture.GetUserData() != "PLAYER" &&
				   rayFixture.GetUserData() != "FOOT" &&
				   rayFixture.GetUserData() != "RIGHT" &&
				   rayFixture.GetUserData() != "LEFT" &&
				   rayFixture.GetUserData() != "WEAPON"){
					if(rayNormal.y == -1 || rayNormal.y == 1){
						if(collisionBody.GetPosition().x < rayFixture.GetBody().GetPosition().x){
							direction.Set(-110, 0);
							collisionBody.SetAwake(true);
							collisionBody.ApplyForce(direction, collisionBody.GetPosition() );
						}
						else{
							direction.Set(110, 0);
							collisionBody.SetAwake(true);
							collisionBody.ApplyForce(direction, collisionBody.GetPosition() );
						}
					}
					else if(rayNormal.x == -1 || rayNormal.x == 1){
						if(collisionBody.GetPosition().y < rayFixture.GetBody().GetPosition().y){
							direction.Set(0, -110);
							collisionBody.SetAwake(true);
							collisionBody.ApplyForce(direction, collisionBody.GetPosition() );
						}
						else{
							direction.Set(0, 110);
							collisionBody.SetAwake(true);
							collisionBody.ApplyForce(direction, collisionBody.GetPosition() );
						}
					}
				}
				
				//remove current fixture
				rayFixture = null;
			}
			else if(rayFixture2 != null){
//				var input2:b2RayCastInput = new b2RayCastInput(beginRayCast2, endRayCast2);
//				var output2:b2RayCastOutput = new b2RayCastOutput();
//				lambda2 = output2.fraction;
				
				if(rayFixture2.GetUserData() != "PLAYER" &&
					rayFixture2.GetUserData() != "FOOT" &&
					rayFixture2.GetUserData() != "RIGHT" &&
					rayFixture2.GetUserData() != "LEFT" &&
					rayFixture2.GetUserData() != "WEAPON"){
					if(rayNormal2.y == -1 || rayNormal2.y == 1){
						if(collisionBody.GetPosition().x < rayFixture2.GetBody().GetPosition().x){
							direction.Set(-110, 0);
							collisionBody.SetAwake(true);
							collisionBody.ApplyForce(direction, collisionBody.GetPosition() );
						}
						else{
							direction.Set(110, 0);
							collisionBody.SetAwake(true);
							collisionBody.ApplyForce(direction, collisionBody.GetPosition() );
						}
					}
					else if(rayNormal2.x == -1 || rayNormal2.x == 1){
						if(collisionBody.GetPosition().y < rayFixture2.GetBody().GetPosition().y){
							direction.Set(0, -110);
							collisionBody.SetAwake(true);
							collisionBody.ApplyForce(direction, collisionBody.GetPosition() );
						}
						else{
							direction.Set(0, 110);
							collisionBody.SetAwake(true);
							collisionBody.ApplyForce(direction, collisionBody.GetPosition() );
						}
					}
				}
				
				//remove current fixture
				rayFixture2 = null;
			}
			else{
				//limit speed
				if(collisionBody.GetLinearVelocity().x < 20 &&
					collisionBody.GetLinearVelocity().x > -20 &&
					collisionBody.GetLinearVelocity().y < 20 &&
					collisionBody.GetLinearVelocity().y > -20){
					direction.Multiply(45);
				}
				
				//follow
				collisionBody.SetAwake(true);
				collisionBody.ApplyForce(direction, collisionBody.GetPosition() );
			}
			
			//moving even when there is slow motion
			if(Stage.usingSlowMotion && Stage.slowMotionAmount >= 0){
				//limit speed
				if(collisionBody.GetLinearVelocity().x < 20 &&
					collisionBody.GetLinearVelocity().x > -20 &&
					collisionBody.GetLinearVelocity().y < 20 &&
					collisionBody.GetLinearVelocity().y > -20){
					direction.Normalize();					
				}
				
				//follow
				collisionBody.SetAwake(true);
				collisionBody.ApplyForce(direction, collisionBody.GetPosition() );
			}
			
			//ray cast debug draw
//			var line:Shape = new Shape();
//			line.graphics.lineStyle(1, 0xffffff,1);
//			line.graphics.moveTo(beginRayCast.x*metricPixRatio, beginRayCast.y*metricPixRatio);
//			line.graphics.lineTo( (endRayCast.x*lambda +(1-lambda)*beginRayCast.x)*metricPixRatio,
//				(endRayCast.y*lambda +(1-lambda)*beginRayCast.x)*metricPixRatio);
//			stage_Sprite.addChild(line);
//			
//			var line2:Shape = new Shape();
//			line2.graphics.lineStyle(1, 0xffffff,1);
//			line2.graphics.moveTo(beginRayCast2.x*metricPixRatio, beginRayCast2.y*metricPixRatio);
//			line2.graphics.lineTo( (endRayCast2.x*lambda +(1-lambda)*beginRayCast2.x)*metricPixRatio,
//				(endRayCast2.y*lambda +(1-lambda)*beginRayCast2.x)*metricPixRatio);
//			stage_Sprite.addChild(line2);
			
			/**Oppose gravity*/
			direction.Set(0, -85);
			collisionBody.SetAwake(true);
			collisionBody.ApplyForce(direction, collisionBody.GetPosition() );
			
			/**Hurt yourself*/
			//destroy yourself with any contact
			if(collisionBody.GetFixtureList().GetUserData() == "DAMAGE"){				
				if(flyingEnemyHealth > 0){
					flyingEnemyHealth--;
				}

				collisionBody.GetFixtureList().SetUserData("ENEMY");
			}
			
			/**Kill yourself*/
			if(flyingEnemyHealth <= 0){				
				//don't collide with anything
				var deadFilter:b2FilterData = new b2FilterData();
				deadFilter.maskBits = 4;
				
				collisionBody.GetFixtureList().SetFilterData(deadFilter);
				collisionBody.GetFixtureList().SetUserData("DEAD");
				
				flyingEnemyClip.gotoAndStop("death");	

				if(EndAnimation.endEnemyDeath){
					EndAnimation.endEnemyDeath = false;
					
					//create random drop
					if(Math.random() > 0.9){
						//health
						if(Math.random() > 0.7 && Player.playerHealth < 6){
							var healthDrop:ItemDrop = new ItemDrop(collisionBody.GetPosition().x, collisionBody.GetPosition().y, 1.5, 1.5, 1);
						}
						else{
							//pistol ammo
							if(Math.random() < 0.6){
								var pistolDrop:ItemDrop = new ItemDrop(collisionBody.GetPosition().x, collisionBody.GetPosition().y, 1.5,1.5, 2);
							}
							//shotgun ammo
							else{
								var shotgunDrop:ItemDrop = new ItemDrop(collisionBody.GetPosition().x, collisionBody.GetPosition().y, 2.5,2.5, 3);
							}
						}
					}
		
					//destroy yourself
					destroyAll();
				}
			}
		}
		
		/**Get information from raycast*/
		private function Callback(fixture:b2Fixture, point:b2Vec2, normal:b2Vec2,fraction:Number):Number{
			rayFixture = fixture;        
			rayPoint = point;        
			rayNormal = normal;        
			rayFraction = fraction;        
			return 0;     
		}
		
		/**Get information from raycast2*/
		private function Callback2(fixture:b2Fixture, point:b2Vec2, normal:b2Vec2,fraction:Number):Number{
			rayFixture2 = fixture;        
			rayPoint2 = point;        
			rayNormal2 = normal;        
			rayFraction2 = fraction;        
			return 0;     
		}
		/**Setters*/
		public function set width(width:Number):void{
			flyingEnemy_Width = width;
		}
		
		public function set height(height:Number):void{
			flyingEnemy_Height = height;
		}
		
	}
}