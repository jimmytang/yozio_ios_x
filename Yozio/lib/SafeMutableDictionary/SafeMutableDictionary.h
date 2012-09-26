//
//  SafeMutableDictionary.h
//  Yozio
//
//  Created by Jimmy Tang on 9/26/12.
//  Copyright (c) 2012 University of California at Berkeley. All rights reserved.
//

@interface SafeMutableDictionary : NSMutableDictionary
{
  NSLock *lock;
  NSMutableDictionary *underlyingDictionary;
}

@end
