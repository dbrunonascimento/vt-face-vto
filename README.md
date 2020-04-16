# vt-face-vto

## Getting started

`$ yarn add https://github.com/syahman-vettons/vt-face-vto`

### Mostly automatic installation

`$ react-native link vt-face-vto`

### Pod install. Required

`$ cd ios && pod install`

## Usage
```javascript
import FaceVTO from 'vt-face-vto';

    // URL of the 3D Model File to download 
    let url = 'https://firebasestorage.googleapis.com/v0/b/armodel-a8171.appspot.com/o/Model%2FVTO%20Test%2Fvglass_2.usdz?alt=media&token=ed676e72-e653-4aa9-b08b-f393b5aa07cc'

    let vtoType = "glass"

    /**
     * Display the Face VTO
     * @param {String} url URL of the 3D Model / texture(KIV)
     * @param {String} vtoType Type of VTO
     */
    FaceVTO.display(url,vtoType)

```
