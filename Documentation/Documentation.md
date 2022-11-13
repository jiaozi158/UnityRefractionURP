Documentation
=============

Global Setup
-------------

UnityRefractionURP requires:

- Depth Texture and Opaque Texture enabled.

 ![EnableDepthAndOpaqueTextures](https://github.com/jiaozi158/UnityRefractionURP/blob/main/Documentation/Images/EnableDepthAndOpaqueTextures.png)

- Material Type set to Transparent.

 ![TransparentMaterialType](https://github.com/jiaozi158/UnityRefractionURP/blob/main/Documentation/Images/TransparentSurfaceType.jpg)

- Material's Alpha Clipping enabled. (if enabling Dithered Transparent Shadow)

 ![EnableAlphaClipping](https://github.com/jiaozi158/UnityRefractionURP/blob/main/Documentation/Images/EnableAlphaClipping.jpg)

Scene Setup
-------------

UnityRefractionURP uses Reflection Probe to approximate the scene shape.

 ![ApproximatedSceneShape](https://github.com/jiaozi158/UnityRefractionURP/blob/main/Documentation/Images/ApproximatedSceneShape.jpg)

In order to create more accurate refraction, it is suggested to:

- Adjust the Reflection Probe Shape (Influence Volume) so that it better matches the scene.

- Use Box Projected Reflection Probes.

- Provide reasonable mesh thickness (diameter if Sphere Model) to material's Thickness parameter. (1 unit = 1 meter)

Dithered Transparent Shadow
-------------

It's suggested to use transparent shadow on URP 14 (Unity 2022.2) or above. ([with high PCF shadow sampling](https://github.com/Unity-Technologies/Graphics/blob/master/Packages/com.unity.render-pipelines.universal/CHANGELOG.md#added-1))

- Enable Alpha Clipping is a must.

- Enable Soft Shadow is important.

- This effect can be better under higher Soft Shadow quality.

- This effect can be better under higher Shadow Resolution.

- The effect of Approximate Thickness is not ideal on Additional Lights.

Details
-------------

For detailed explanation, please refer to [HDRP's refraction documentation](https://github.com/Unity-Technologies/Graphics/blob/5816fd03c02c7339c554271ee6a308475ea76aa3/com.unity.render-pipelines.high-definition/Documentation~/Refraction-in-HDRP.md).
