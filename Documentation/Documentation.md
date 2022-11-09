Documentation
=============

Global Setup
-------------

UnityRefractionURP requires:

- Depth Texture and Opaque Texture enabled.

 ![EnableDepthAndOpaqueTextures](https://github.com/jiaozi158/UnityRefractionURP/blob/main/Documentation/Images/EnableDepthAndOpaqueTextures.png)

- Material Type set to Transparent.

 ![TransparentMaterialType](https://github.com/jiaozi158/UnityRefractionURP/blob/main/Documentation/Images/TransparentSurfaceType.jpg)

Scene Setup
-------------

UnityRefractionURP uses Reflection Probe to approximate the scene shape.

 ![ApproximatedSceneShape](https://github.com/jiaozi158/UnityRefractionURP/blob/main/Documentation/Images/ApproximatedSceneShape.jpg)

In order to create more accurate refraction, it is suggested to:

- Adjust the Reflection Probe Shape (Influence Volume) so that it better matches the scene.

- Use Box Projected Reflection Probes.

- Provide reasonable mesh thickness (radius if Sphere) to material's Thickness parameter. (1 unit = 1 meter)

Details
-------------

For detailed explanation, please refer to [HDRP's refraction documentation](https://github.com/Unity-Technologies/Graphics/blob/5816fd03c02c7339c554271ee6a308475ea76aa3/com.unity.render-pipelines.high-definition/Documentation~/Refraction-in-HDRP.md).