import { NativeModules } from 'react-native';

const NativeFaceVTO = NativeModules.FaceVTO;

export default class FaceVTO {
    
    /**
     * Display the Face VTO
     * @param {String} url URL of the 3D Model
     * @param {String} vtoType Type of VTO
     */
    static display(url,vtoType){
        NativeFaceVTO.display(url,vtoType);
    }
}
