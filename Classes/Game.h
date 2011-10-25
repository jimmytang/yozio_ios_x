//
//  Serialize.h
//  Example For Example
//
//  Created by Rob Blackwood on 5/30/10.
//

#import "SpaceManagerCocos2d.h"
#import "GameConfig.h"
#import "Bomb.h"
#import "Yozio.h"

@interface Game : CCLayer<SpaceManagerSerializeDelegate>
{
	SpaceManagerCocos2d *smgr;
  Yozio *yozio;

	NSMutableArray	*_bombs;
	Bomb			*_curBomb;
	
	int _enemiesLeft;
}

@property (readonly) SpaceManager* spaceManager;
@property (retain) Yozio* yozio;

+(id) scene;
-(id) initWithSaved:(BOOL)loadIt;


-(BOOL) aboutToReadShape:(cpShape*)shape shapeId:(long)id;
-(void) save;
-(void) enemyKilled;

@end

