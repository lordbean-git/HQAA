# HQAA
Merges SMAA and FXAA aiming to balance both for high quality AA effect.
This shader uses customized versions of SMAA and FXAA which have been
built to detect edges in as many different scenarios as possible while
still maintaining a very low rate of false positive detection. This
allows HQAA to apply aggressive aliasing correction to the input
scene while causing very few side effects (such as blur or artifacts).
HQAA is a quality-focused shader and runs notably slower than SMAA or
FXAA; however it is a very CPU-efficient shader as it is built to use
operations that can be performed by hardware GPU math to the limit that
it is possible. You will generally only see a framerate drop from HQAA
if the game you are playing was being limited by your GPU rather than
your CPU. For most older games, this means HQAA won't cause a noticeable
difference in performance.

You need the SMAA search textures (included here) placed in the ReShade
texture search path for games you want to use HQAA with.
