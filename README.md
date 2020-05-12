# vt-face-vto
v1.0.4

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
    let url = 'https://firebasestorage.googleapis.com/v0/b/vto-asset.appspot.com/o/Glass%2Falghero_7.usdz?alt=media&token=f882e977-0709-49cf-8aaf-32f3c63c969e'

    // URL of the Face Texture file to download
    // let url = 'https://firebasestorage.googleapis.com/v0/b/vto-asset.appspot.com/o/FaceTexture%2FBrand%20A%2Flips14.png?alt=media&token=f7685b25-e99a-4bd1-91a0-22950744c2c1'


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
