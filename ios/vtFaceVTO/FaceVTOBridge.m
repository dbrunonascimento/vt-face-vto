//
//  FaceVTOBridge.m
//  VtFacevto
//
//  Created by Muhammad Syahman on 15/04/2020.
//  Copyright © 2020 Vettons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridge.h>
#import <React/RCTEventEmitter.h>



@interface RCT_EXTERN_MODULE(FaceVTO, NSObject);

RCT_EXTERN_METHOD(display:(NSString)url type:(NSString)vtoType data:(NSString)variantData withIndex:(NSInteger)index);
RCT_EXTERN_METHOD(sendString:(NSString)string);

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

@end

@interface RCT_EXTERN_MODULE(FaceVTOEvent, RCTEventEmitter)

RCT_EXTERN_METHOD(supportedEvents)

@end

