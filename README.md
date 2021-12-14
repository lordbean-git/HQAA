# HQAA
Merges SMAA and FXAA aiming to balance both for high quality AA effect.
This is accomplished by calculating the settings for each pass of anti-aliasing
from two master user-controlled settings in the ReShade UI in order to maximize
aliasing correction yet cause only a minimal level of blur in the resulting image.

HQAA requires the SMAA search pattern textures. They can be acquired from my
reshade-shaders repository or the SweetFX package.
