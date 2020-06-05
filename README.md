# vt-face-vto
v1.0.5

## Getting started

`$ yarn add https://github.com/syahman-vettons/vt-face-vto`

### Mostly automatic installation

`$ react-native link vt-face-vto`

### Pod install. Required

`$ cd ios && pod install`

## Usage
```javascript
import FaceVTO, {FaceVTOEvent} from 'vt-face-vto';

    // URL of the 3D Model File to download 
    let url = 'https://firebasestorage.googleapis.com/v0/b/vto-asset.appspot.com/o/Glass%2Falghero_8.usdz?alt=media&token=2edf6df0-adf8-4005-a46d-606f703d566f'

    // URL of the Face Texture file to download
    // let url = 'https://firebasestorage.googleapis.com/v0/b/vto-asset.appspot.com/o/FaceTexture%2FBrand%20A%2FfullMakeup4.png?alt=media&token=d2e15884-d9e0-4132-b56c-d83b453d18ab'


    // supported vtoType as for now
    // glass, makeup
    let vtoType = "glass"

    /**
     * Display the Face VTO
     * @param {String} url URL of the 3D Model / texture(KIV)
     * @param {String} vtoType Type of VTO
     */
    FaceVTO.display(url,vtoType)

    /**
     * Listen to event from Native
     * onPress and error events
     */
    FaceVTOEvent.Emitter.addListener('onPress', (onPress) => {
        if (onPress.type === 'capture') {
        if (onPress.data.clicked) {
          console.log('capture button Clicked');
          // this.props.navigation.navigate('ARCategory'); //Navigate to AR Category page
        }
      }
      if (onPress.type === 'dismiss') {
        if (onPress.data.clicked) {
          console.log('dismiss button Clicked');
        }
      }
      if (onPress.type === 'share') {
        if (onPress.data.clicked) {
          console.log('share button Clicked');
        }
      }
    });

    FaceVTOEvent.Emitter.addListener('error', (error) => {
        console.log('error.type : ', error.type);
        console.log('error.message : ', error.message);
    });

```

## TODO

Android version
