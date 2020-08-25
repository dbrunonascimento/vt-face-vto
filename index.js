import { NativeModules, NativeEventEmitter } from 'react-native';

const NativeFaceVTO = NativeModules.FaceVTO;

export default class FaceVTO {
    
    /**
     * Display the Face VTO
     * @param {String} url URL of the asset
     * @param {String} vtoType Type of VTO
     * @param {String} json JSON of the variants
     * @param {Int} currentIndex Current index of the variant
     */
    static display(url,vtoType,json,currentIndex){
        NativeFaceVTO.display(url,vtoType,json,currentIndex);
    }

    static sendString(string){
        NativeFaceVTO.sendString(string);
    }
}

export class FaceVTOEvent {
    /**Event from native */
    static Emitter = new NativeEventEmitter(NativeModules.FaceVTOEvent);
}