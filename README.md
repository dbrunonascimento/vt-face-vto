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
    let url = 'https://developer.apple.com/augmented-reality/quick-look/models/vintagerobot2k/toy_robot_vintage.usdz'

    FaceVTO.display(url,vtoType)

```
