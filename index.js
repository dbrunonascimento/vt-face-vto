import { NativeModules } from 'react-native';

const NativeFaceVTO = NativeModules.FaceVTO;

export default class FaceVTO {
    
    static display(url,vtoType){
        NativeFaceVTO.display(url,vtoType);
    }
}
