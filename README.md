UnityRefractionURP
=============

 Refraction shader for Unity's URP (Universal Render Pipeline).

 Based on HDRP's ScreenSpaceRefraction.

 This shader is created in Shader Graph, so you can easily modify it to add more features. (ex. NormalMap)

 **Please read the Documentation and Requirements before using this repository.**

Screenshots
------------
**(Sample)**

 ![Sample](https://github.com/jiaozi158/UnityRefractionURP/blob/main/Documentation/Images/Demo/Sample.jpg)

 ![RefractionInScene](https://github.com/jiaozi158/UnityRefractionURP/blob/main/Documentation/Images/Demo/RefractionInScene.gif)

Dithered Transparent Shadows are available in URP 14 (Unity 2022.2) and above. ([with high PCF shadow sampling](https://github.com/Unity-Technologies/Graphics/blob/master/Packages/com.unity.render-pipelines.universal/CHANGELOG.md#added-1))

 ![DitheredTransparentShadow](https://github.com/jiaozi158/UnityRefractionURP/blob/main/Documentation/Images/Demo/DitheredTransparentShadow.jpg)

Documentation
------------
Please refer to [this](https://github.com/jiaozi158/UnityRefractionURP/blob/main/Documentation/Documentation.md).

Requirements
------------
- URP 12.1 and above. (URP 14 if using Dithered Transparent Shadow)
- Depth Texture Enabled in current URP Asset.
- Opaque Texture Enabled in current URP Asset.
- Set Material Type to Transparent.
- Enable Alpha Clipping in material if using Dithered Transparent Shadow.
- Perspective Camera (Orthographic Projection is not supported)

Limitation
------------
- Will not handle recursive refraction.
- Other transparent objects will not appear in refraction. 
- Does not support rough refraction. ([Color Pyramid](https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@12.0/manual/Custom-Pass-buffers-pyramids.html) Custom Renderer Feature needed)
- ~~Does not support transparent shadow. (Dithered Transparent Shadow in Shader Graph?)~~ **(Done)**
- Will not support transparent colored shadow.

License
------------
MIT ![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)