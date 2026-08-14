package
{
   import com.gskinner.utils.Rndm;
   import flash.geom.Rectangle;
   import flash.utils.getTimer;
   
   public class MUSHROOMS
   {
      
      public static var _mushroom:BFOUNDATION;
      
      public static var _mushroomID:int;

      // ============================
      // EXTREME MUSHROOM SETTINGS
      // ============================
      
      private static const INITIAL_RING_COUNT:int = 20;
      private static const MUSHROOMS_PER_RING:int = 50;
      
      // Maximum number of mushrooms retained by the system.
      private static const MAX_MUSHROOMS:int = 1000;
      
      // Spawn one batch this often.
      // 1 = effectively every timestamp/update cycle where Setup() runs.
      private static const SPAWN_INTERVAL:int = 1;
      
      // Maximum mushrooms added by one timed spawn.
      private static const MAX_TIMED_SPAWN:int = 1000;
      
      // Search attempts for a valid spawn location.
      private static const MAX_SPAWN_ATTEMPTS:int = 50000;
      
      // Golden mushroom probability.
      // 1 = 100%, 2 = 50%, 4 = 25%, etc.
      private static const GOLDEN_CHANCE:int = 1;
      
      // Rewards.
      private static const NORMAL_GOLDEN_REWARD:int = 1000;
      private static const BONUS_GOLDEN_REWARD:int = 5000;
      
      public function MUSHROOMS()
      {
         super();
      }
      
      public static function Setup() : void
      {
         var mushroomCount:int;
         var count:int = 0;
         var t:int = 0;
         var num:Number = NaN;
         var twist:int = 0;
         var i:int = 0;
         var dist:int = 0;
         var angle:int = 0;
         var spawn:int = 0;
         var X:Number = NaN;
         var Y:Number = NaN;
         var a:int = 0;
         var b:int = 0;
         var s:int = 0;
         var n:int = 0;
         var X2:Number = NaN;
         var Y2:Number = NaN;
         var shroom:Object = null;
         var replace:Boolean = false;
         var spawnCount:int = 0;
         
         if(!GLOBAL._flags.mushrooms && GLOBAL.mode == GLOBAL.e_BASE_MODE.BUILD)
         {
            return;
         }
         
         if(!BASE.isMainYard)
         {
            return;
         }
         
         mushroomCount = 0;
         
         try
         {
            if(BASE._lastSpawnedMushroom == 0)
            {
               BASE._mushroomList = [];
               
               count = 0;
               t = getTimer();
               num = Math.random();
               twist = int(Math.random() * 360);
               
               i = 1;
               
               // Much larger initial spawn.
               while(i <= INITIAL_RING_COUNT)
               {
                  dist = i * 100 + 300;
                  angle = i * 60 + twist;
                  
                  spawn = MUSHROOMS_PER_RING;
                  
                  X = Math.sin(angle * 0.0174532925) * dist;
                  Y = Math.cos(angle * 0.0174532925) * dist;
                  
                  a = 100 + Math.random() * 80;
                  b = 100 + Math.random() * 80;
                  
                  s = 0;
                  
                  while(s < spawn)
                  {
                     n = int(Math.random() * 5) + 1;
                     
                     X2 = X + Math.sin(int(Math.random() * 360) * 0.0174532925) * a;
                     Y2 = Y + Math.cos(int(Math.random() * 360) * 0.0174532925) * b;
                     
                     X2 = int(X2 / 10) * 10;
                     Y2 = int(Y2 / 10) * 10;
                     
                     _mushroom = BASE.addBuildingC(7);
                     
                     _mushroom.Setup({
                        "X":X2,
                        "Y":Y2,
                        "id":mushroomCount,
                        "t":1,
                        "frame":n
                     });
                     
                     mushroomCount++;
                     s++;
                  }
                  
                  i++;
               }
               
               BASE._lastSpawnedMushroom = GLOBAL.Timestamp();
            }
            else
            {
               i = 0;
               
               // Restore up to MAX_MUSHROOMS instead of 20.
               while(i < Math.min(BASE._mushroomList.length, MAX_MUSHROOMS))
               {
                  shroom = {
                     "frame":BASE._mushroomList[i][0],
                     "X":BASE._mushroomList[i][1],
                     "Y":BASE._mushroomList[i][2],
                     "id":mushroomCount,
                     "t":1
                  };
                  
                  replace = false;
                  
                  if(shroom.X > GLOBAL._mapWidth * 0.5)
                  {
                     replace = true;
                  }
                  else if(shroom.X < 0 - GLOBAL._mapWidth * 0.5)
                  {
                     replace = true;
                  }
                  else if(shroom.Y > GLOBAL._mapHeight * 0.5)
                  {
                     replace = true;
                  }
                  else if(shroom.Y < 0 - GLOBAL._mapHeight * 0.5)
                  {
                     replace = true;
                  }
                  
                  if(!replace)
                  {
                     _mushroom = BASE.addBuildingC(7);
                     _mushroom.Setup(shroom);
                  }
                  else
                  {
                     Spawn(1);
                  }
                  
                  mushroomCount++;
                  i++;
               }
               
               if(BASE._mushroomList.length > MAX_MUSHROOMS)
               {
                  i = int(BASE._mushroomList.length - 1);
                  
                  while(i >= MAX_MUSHROOMS)
                  {
                     delete BASE._mushroomList[i];
                     i--;
                  }
               }
            }
         }
         catch(e:Error)
         {
            LOGGER.Log(
               "err",
               "MUSHROOMS.SetupA: " + e.message + " | " + e.getStackTrace()
            );
            
            GLOBAL.ErrorMessage("");
         }
         
         try
         {
            spawnCount = Math.floor(
               (GLOBAL.Timestamp() - BASE._lastSpawnedMushroom) /
               SPAWN_INTERVAL
            );
            
            if(spawnCount > 0)
            {
               BASE._lastSpawnedMushroom = GLOBAL.Timestamp();
               
               if(spawnCount > MAX_TIMED_SPAWN)
               {
                  spawnCount = MAX_TIMED_SPAWN;
               }
               
               if(mushroomCount + spawnCount > MAX_MUSHROOMS)
               {
                  spawnCount = MAX_MUSHROOMS - mushroomCount;
               }
               
               if(spawnCount > 0)
               {
                  Spawn(spawnCount);
               }
            }
         }
         catch(e:Error)
         {
            LOGGER.Log(
               "err",
               "MUSHROOMS.SetupB: " + e.message + " | " + e.getStackTrace()
            );
            
            GLOBAL.ErrorMessage("");
         }
      }
      
      public static function Spawn(param1:int) : void
      {
         var _loc2_:BFOUNDATION = null;
         var _loc4_:int = 0;
         var _loc5_:Boolean = false;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         
         if(!GLOBAL._flags.mushrooms && GLOBAL.mode == GLOBAL.e_BASE_MODE.BUILD)
         {
            return;
         }
         
         if(!BASE.isMainYard)
         {
            return;
         }
         
         BASE._lastSpawnedMushroom = GLOBAL.Timestamp();
         
         LOGGER.Stat([35,param1]);
         
         var _loc3_:int = 0;
         
         while(_loc3_ < param1)
         {
            _loc4_ = int(Math.random() * 5) + 1;
            
            _loc5_ = false;
            _loc6_ = 0;
            _loc7_ = 0;
            _loc8_ = 0;
            
            while(!_loc5_ && _loc8_ < MAX_SPAWN_ATTEMPTS)
            {
               _loc8_++;
               
               _loc6_ =
                  200 +
                  GLOBAL._mapWidth * 0.5 -
                  Math.random() * (GLOBAL._mapWidth + 400);
               
               _loc7_ =
                  200 +
                  GLOBAL._mapHeight * 0.5 -
                  Math.random() * (GLOBAL._mapHeight + 400);
               
               if(
                  _loc6_ > GLOBAL._mapWidth * 0.5 ||
                  _loc6_ < 0 - GLOBAL._mapWidth * 0.5 ||
                  _loc7_ > GLOBAL._mapHeight * 0.5 ||
                  _loc7_ < 0 - GLOBAL._mapHeight * 0.5
               )
               {
                  _loc5_ = true;
               }
               
               if(
                  !_loc5_ &&
                  !GRID.FootprintBlocked(
                     [new Rectangle(0,0,30,30)],
                     GRID.ToISO(_loc6_,_loc7_,0),
                     true
                  )
               )
               {
                  _loc5_ = true;
               }
            }
            
            if(_loc5_)
            {
               _mushroom = BASE.addBuildingC(7);
               
               ++BASE._buildingCount;
               
               _mushroom.Setup({
                  "X":_loc6_,
                  "Y":_loc7_,
                  "id":BASE._buildingCount,
                  "t":1,
                  "frame":_loc4_
               });
            }
            
            _loc3_++;
         }
      }
      
      public static function PickWorker(param1:BFOUNDATION) : void
      {
         if(!param1._picking)
         {
            if(QUEUE.Add("mushroom" + param1._id,param1))
            {
               param1._mc.alpha = 0.5;
               param1._picking = true;
            }
            else
            {
               POPUPS.DisplayWorker(2,param1);
            }
         }
      }
      
      public static function Pick(mushroom:BFOUNDATION) : Boolean
      {
         if(BASE._pendingPurchase.length > 0)
         {
            return false;
         }
         
         var mushroomId:int = mushroom._id;
         var workerMessage:String = "";
         var shinyAwarded:int = 0;
         
         var positionRng:Rndm =
            new Rndm(int(mushroom.x * mushroom.y));
         
         // 100% golden.
         var isGolden:Boolean =
            int(positionRng.random() * GOLDEN_CHANCE) == 0;
         
         ++QUESTS._global.mushroomspicked;
         
         if(isGolden)
         {
            ++QUESTS._global.goldmushroomspicked;
            
            GLOBAL.ValidateMushroomPick(mushroom);
         }
         
         mushroom.RecycleC();
         
         if(isGolden)
         {
            // Always use the highest reward.
            shinyAwarded = BONUS_GOLDEN_REWARD;
            
            workerMessage = KEYS.Get(
               "pop_mushroom_msg1",
               {
                  "v1":shinyAwarded
               }
            );
            
            // Keep the existing purchase flow.
            BASE.Purchase(
               "MUSHROOM2",
               shinyAwarded,
               "MUSHROOMS"
            );
            
            var shinyPopup:popup_mushroomshiny =
               new popup_mushroomshiny();
            
            shinyPopup.tTitle.htmlText =
               "<b>" +
               KEYS.Get("pop_goldenmushroom_title") +
               "</b>";
            
            shinyPopup.tMessage.htmlText =
               KEYS.Get(
                  "pop_goldenmushroom_desc",
                  {
                     "v1":shinyAwarded
                  }
               );
            
            POPUPS.Push(
               shinyPopup,
               null,
               null,
               "chaching",
               "goldmushroom.png"
            );
         }
         else
         {
            var flavourKeys:Array = [
               "pop_mushroom_msg2",
               "pop_mushroom_msg3",
               "pop_mushroom_msg4"
            ];
            
            workerMessage = KEYS.Get(
               flavourKeys[
                  int(Math.random() * flavourKeys.length)
               ]
            );
            
            BASE.Save();
         }
         
         LOGGER.Stat([34, shinyAwarded]);
         
         QUESTS.Check();
         
         WORKERS.Say(
            workerMessage,
            QUEUE.Remove(
               "mushroom" + mushroomId,
               true
            ),
            3000
         );
         
         return true;
      }
   }
}