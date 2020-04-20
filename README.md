# vt-face-vto
v1.0.3

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
    let url = 'https://firebasestorage.googleapis.com/v0/b/armodel-a8171.appspot.com/o/Model%2FVTO%20Test%2Fvglass_2.usdz?alt=media&token=ed676e72-e653-4aa9-b08b-f393b5aa07cc'

    // supported vtoType as for now
    // glass, glassWithMakeup, makeup, sample, sampleWithMakeup
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
