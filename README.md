# HQAA
Merges SMAA and FXAA aiming to balance both for high quality AA effect.
This is accomplished by calculating the settings for each pass of anti-aliasing
from two master user-controlled settings in the ReShade UI in order to maximize
aliasing correction yet cause only a minimal level of blur in the resulting image.

HQAA requires the supporting resources normally used by FXAA and SMAA - both header
files, and the search textures for SMAA. None are included in this project because
apart from using nonstandard settings for each method, HQAA makes no fundamental
changes to the way each pass actually calculates its results; therefore it can
load the same resource assets that FXAA and SMAA use.
