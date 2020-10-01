# vt-face-vto
v1.0.10

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
    
    let productJSON = [
  {
    "name": "Provocative",
    "productVariantID": "PV0000005392",
    "sliderImage": "https://content.vettons.com/media/VIN0000004069-PV0000005392-1.webp",
    "faceImage": "https://firebasestorage.googleapis.com/v0/b/vto-asset.appspot.com/o/Product%2FVIN0000004069%2FLLIPSTICK-01.png?alt=media&token=697df1c4-0a7c-4325-9fd4-e46a5cee4a10"
  },
  {
    "name": "Positive",
    "productVariantID": "PV0000005393",
    "sliderImage": "https://content.vettons.com/media/VIN0000004069-PV0000005393-1.webp",
    "faceImage": "https://firebasestorage.googleapis.com/v0/b/vto-asset.appspot.com/o/Product%2FVIN0000004069%2FLLIPSTICK-02.png?alt=media&token=cf462192-df4c-46e1-acb5-1a8e64d1bcd2"
  },
  {
    "name": "Alluring",
    "productVariantID": "PV0000005394",
    "sliderImage": "https://content.vettons.com/media/VIN0000004069-PV0000005394-1.webp",
    "faceImage": "https://firebasestorage.googleapis.com/v0/b/vto-asset.appspot.com/o/Product%2FVIN0000004069%2FLLIPSTICK-03.png?alt=media&token=b6dab1e3-41b3-4e75-94e3-04df82801d2d"
  },
  {
    "name": "Classy",
    "productVariantID": "PV0000005395",
    "sliderImage": "https://content.vettons.com/media/VIN0000004069-PV0000005395-1.webp",
    "faceImage": "https://firebasestorage.googleapis.com/v0/b/vto-asset.appspot.com/o/Product%2FVIN0000004069%2FLLIPSTICK-04.png?alt=media&token=990f096d-fe1c-41e5-b10b-9c650954aacf"
  },
  {
    "name": "Powerful",
    "productVariantID": "PV0000005396",
    "sliderImage": "https://content.vettons.com/media/VIN0000004069-PV0000005396-1.webp",
    "faceImage": "https://firebasestorage.googleapis.com/v0/b/vto-asset.appspot.com/o/Product%2FVIN0000004069%2FLLIPSTICK-05.png?alt=media&token=39b1b944-8679-4e1b-aad8-bec9d7fa06c1"
  }
]

    // supported vtoType as for now
    // glass, makeup
    let vtoType = "makeup"


    /**
     * JSON object example
     * "name": "Powerful",
     * "productVariantID": "PV0000005396",
     * "sliderImage": "https://content.vettons.com/media/VIN0000004069-PV0000005396-1.webp",
     * "faceImage": "https://firebasestorage.googleapis.com/v0/b/vto-asset.appspot.com/o/Product%2FVIN0000004069%2FLLIPSTICK-05.png?alt=media&token=39b1b944-8679-4e1b-aad8-bec9d7fa06c1"
     */
    let json = JSON.stringify(productJSON)

    /**
     * Display the Face VTO
     * @param {String} url URL of the asset ()
     * @param {String} vtoType Type of VTO
     * @param {String} json JSON of the variants
     * @param {Int} currentIndex Current index of the variant
     */
    FaceVTO.display(url, vtoType, json, currentIndex);

    /**
     * Listen to event from Native
     * onPress and error events
     */
    FaceVTOEvent.Emitter.addListener('onPress', (onPress) => {
        if (onPress.type === 'capture') {
        if (onPress.data.clicked) {
          console.log('capture button Clicked');

        }
      }
      if (onPress.type === 'dismiss') {
        if (onPress.data.clicked) {
          console.log('dismiss button Clicked');
          console.log('Product Name : ' + onPress.data.name);
          console.log('Product Variant ID : ' + onPress.data.productVariantID);
          console.log('Index : ' + onPress.data.index)
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
