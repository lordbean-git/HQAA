/*               HQAA for ReShade 3.1.1+
 *
 *          (Hybrid high-Quality Anti-Aliasing)
 *
 *
 *     Smooshes FXAA and SMAA together as a single shader
 *
 * with customizations designed to maximize edge detection and
 *
 *                  minimize blurring
 *
 *                     by lordbean
 *
 */
 
 // This shader includes code adapted from:
 
 /**============================================================================


                    NVIDIA FXAA 3.11 by TIMOTHY LOTTES


------------------------------------------------------------------------------
COPYRIGHT (C) 2010, 2011 NVIDIA CORPORATION. ALL RIGHTS RESERVED.
------------------------------------------------------------------------------*/

/* AMD CONTRAST ADAPTIVE SHARPENING
// =======
// Copyright (c) 2017-2019 Advanced Micro Devices, Inc. All rights reserved.
// -------
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// -------
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
// --------*/

/** SUBPIXEL MORPHOLOGICAL ANTI-ALIASING (SMAA)
 * Copyright (C) 2013 Jorge Jimenez (jorge@iryoku.com)
 * Copyright (C) 2013 Jose I. Echevarria (joseignacioechevarria@gmail.com)
 * Copyright (C) 2013 Belen Masia (bmasia@unizar.es)
 * Copyright (C) 2013 Fernando Navarro (fernandn@microsoft.com)
 * Copyright (C) 2013 Diego Gutierrez (diegog@unizar.es)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to
 * do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software. As clarification, there
 * is no requirement that the copyright notice and permission be included in
 * binary distributions of the Software.
 **/
 
 /**
 * Deband shader by haasn
 * https://github.com/haasn/gentoo-conf/blob/xor/home/nand/.mpv/shaders/deband-pre.glsl
 *
 * Copyright (c) 2015 Niklas Haas
 *
 * Modified and optimized for ReShade by JPulowski
 * https://reshade.me/forum/shader-presentation/768-deband
 *
 * Do not distribute without giving credit to the original author(s).
 **/
 
 //* HFRAA from NFAA.fx by Jose Negrete AKA BlueSkyDefender

 /*------------------------------------------------------------------------------
 * THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *-------------------------------------------------------------------------------*/
 

/*****************************************************************************************************************************************/
/*********************************************************** UI SETUP START **************************************************************/
/*****************************************************************************************************************************************/

#include "ReShadeUI.fxh"

/////////////////////////////////////////////////////// CONFIGURABLE TOGGLES //////////////////////////////////////////////////////////////

#ifndef HQAA_ADVANCED_MODE
	#define HQAA_ADVANCED_MODE 0
#endif

#ifndef HQAA_OUTPUT_MODE
	#define HQAA_OUTPUT_MODE 0
#endif //HQAA_TARGET_COLOR_SPACE

#ifndef HQAA_DEBUG_MODE
	#define HQAA_DEBUG_MODE 0
#endif //HQAA_DEBUG_MODE

#ifndef HQAA_OPTIONAL_EFFECTS
	#define HQAA_OPTIONAL_EFFECTS 1
#endif //HQAA_ENABLE_OPTIONAL_TECHNIQUES

#if HQAA_OPTIONAL_EFFECTS
	#ifndef HQAA_OPTIONAL__TEMPORAL_STABILIZER
		#define HQAA_OPTIONAL__TEMPORAL_STABILIZER 1
	#endif //HQAA_OPTIONAL__TEMPORAL_STABILIZER
	#ifndef HQAA_OPTIONAL__DEBANDING
		#define HQAA_OPTIONAL__DEBANDING 1
	#endif
	#ifndef HQAA_OPTIONAL__SOFTENING
		#define HQAA_OPTIONAL__SOFTENING 1
	#endif
	#if HQAA_OPTIONAL__DEBANDING
		#ifndef HQAA_OPTIONAL__DEBANDING_PASSES
			#define HQAA_OPTIONAL__DEBANDING_PASSES 1
		#endif //HQAA_OPTIONAL__DEBANDING_PASSES
	#endif //HQAA_OPTIONAL__DEBANDING
	#if HQAA_OPTIONAL__SOFTENING
		#ifndef HQAA_OPTIONAL__SOFTENING_PASSES
			#define HQAA_OPTIONAL__SOFTENING_PASSES 2
		#endif
	#endif //HQAA_OPTIONAL__SOFTENING
#endif // HQAA_ENABLE_OPTIONAL_TECHNIQUES

#ifndef HQAA_FXAA_MULTISAMPLING
	#define HQAA_FXAA_MULTISAMPLING 2
#endif

#ifndef HQAA_TAA_ASSIST_MODE
	#define HQAA_TAA_ASSIST_MODE 0
#endif

/////////////////////////////////////////////////////// GLOBAL SETUP OPTIONS //////////////////////////////////////////////////////////////

uniform int HQAAintroduction <
	ui_spacing = 3;
	ui_type = "radio";
	ui_label = "Version: 28.5.030522";
	ui_text = "--------------------------------------------------------------------------------\n"
			"Hybrid high-Quality Anti-Aliasing, a shader by lordbean\n"
			"https://github.com/lordbean-git/HQAA/\n"
			"--------------------------------------------------------------------------------\n\n"
			"Currently Compiled Configuration:\n\n"
			#if HQAA_ADVANCED_MODE
			"Advanced Mode:                                                             on  *\n"
			#else
			"Advanced Mode:                                                            off\n"
			#endif
			#if HQAA_OUTPUT_MODE == 1
			"Output Mode:                                                         HDR nits  *\n"
			#elif HQAA_OUTPUT_MODE == 2
			"Output Mode:                                                      PQ accurate  *\n"
			#elif HQAA_OUTPUT_MODE == 3
			"Output Mode:                                                        PQ approx  *\n"
			#else
			"Output Mode:                                                        Gamma 2.2\n"
			#endif //HQAA_TARGET_COLOR_SPACE
			#if HQAA_FXAA_MULTISAMPLING < 2
			"FXAA Multisampling:                                                       off  *\n"
			#elif HQAA_FXAA_MULTISAMPLING > 3
			"FXAA Multisampling:                                                        4x  *\n"
			#elif HQAA_FXAA_MULTISAMPLING > 2
			"FXAA Multisampling:                                                        3x  *\n"
			#elif HQAA_FXAA_MULTISAMPLING > 1
			"FXAA Multisampling:                                                        2x\n"
			#endif //HQAA_FXAA_MULTISAMPLING
			#if HQAA_TAA_ASSIST_MODE
			"TAA Assist Mode:                                                           on  *\n"
			#else
			"TAA Assist Mode:                                                          off\n"
			#endif //HQAA_TAA_ASSIST_MODE
			#if HQAA_DEBUG_MODE
			"Debug Code:                                                                on  *\n"
			#else
			"Debug Code:                                                               off\n"
			#endif //HQAA_DEBUG_MODE
			#if HQAA_OPTIONAL_EFFECTS
			"Optional Effects:                                                          on\n"
			#else
			"Optional Effects:                                                         off  *\n"
			#endif //HQAA_ENABLE_OPTIONAL_TECHNIQUES
			#if HQAA_OPTIONAL_EFFECTS && HQAA_OPTIONAL__TEMPORAL_STABILIZER
			"Temporal Stabilizer:                                                       on\n"
			#elif HQAA_OPTIONAL_EFFECTS && !HQAA_OPTIONAL__TEMPORAL_STABILIZER
			"Temporal Stabilizer:                                                      off  *\n"
			#endif //HQAA_OPTIONAL__TEMPORAL_STABILIZER
			#if HQAA_OPTIONAL_EFFECTS && HQAA_OPTIONAL__DEBANDING
			"Debanding:                                                            on"
			#if HQAA_OPTIONAL__DEBANDING_PASSES < 2
			" (1x)\n"
			#elif HQAA_OPTIONAL__DEBANDING_PASSES > 3
			" (4x)  *\n"
			#elif HQAA_OPTIONAL__DEBANDING_PASSES > 2
			" (3x)  *\n"
			#elif HQAA_OPTIONAL__DEBANDING_PASSES > 1
			" (2x)  *\n"
			#endif //HQAA_OPTIONAL__DEBANDING_PASSES
			#elif HQAA_OPTIONAL_EFFECTS && !HQAA_OPTIONAL__DEBANDING
			"Debanding:                                                                off  *\n"
			#endif //HQAA_OPTIONAL__DEBANDING
			#if HQAA_OPTIONAL_EFFECTS && HQAA_OPTIONAL__SOFTENING
			"Image Softening:                                                      on"
			#if HQAA_OPTIONAL__SOFTENING_PASSES < 2
			" (1x)  *\n"
			#elif HQAA_OPTIONAL__SOFTENING_PASSES > 3
			" (4x)  *\n"
			#elif HQAA_OPTIONAL__SOFTENING_PASSES > 2
			" (3x)  *\n"
			#elif HQAA_OPTIONAL__SOFTENING_PASSES > 1
			" (2x)\n"
			#endif //HQAA_OPTIONAL__SOFTENING_PASSES
			#elif HQAA_OPTIONAL_EFFECTS && !HQAA_OPTIONAL__SOFTENING
			"Image Softening:                                                          off  *\n"
			#endif
			
			"\nRemarks:\n"
			
			#if HQAA_DEBUG_MODE
			"\nDebug code should be disabled when you are not using it because it has a small\n"
			"performance penalty while enabled.\n"
			#endif
			#if HQAA_OPTIONAL_EFFECTS && HQAA_OPTIONAL__DEBANDING && (HQAA_OUTPUT_MODE > 0)
			"\nPerforming Debanding is not recommended when using an HDR output format\n"
			"because the randomized noise used to fix the banding tends to be visible.\n"
			#endif
			#if HQAA_OPTIONAL_EFFECTS && (HQAA_OPTIONAL__DEBANDING || HQAA_OPTIONAL__SOFTENING)
			"\nYou can set the number of passes performed by debanding/softening in the same\n"
			"way as FXAA multisampling. Valid range is 1 to 4.\n"
			#endif
			#if HQAA_TAA_ASSIST_MODE
			"\nTAA Assist Mode is designed to help the game's internal Temporal Anti-Aliasing\n"
			"solution by performing corrections only on scenes that are moving. This helps to\n"
			"fix aliasing on moving objects and conserves GPU power by skipping parts of the\n"
			"scene that are not moving.\n"
			#endif
			
			"\nFXAA Multisampling can be used to increase correction strength in cases such\n"
			"as edges with more than one color gradient or along objects that have highly\n"
			"irregular geometry. Costs some performance for each extra pass.\n"
			"Valid range: 1 to 4. Higher values are ignored.\n"
			
			"\nValid Output Modes (HQAA_OUTPUT_MODE):\n"
			"0: Gamma 2.2 (default)\n"
			"1: HDR, direct nits scale\n"
			"2: HDR10, accurate encoding\n"
			"3: HDR10, fast encoding\n"
			"\n--------------------------------------------------------------------------------"
			"\nSee the 'Preprocessor definitions' section for color, feature, and mode toggles.\n"
			"--------------------------------------------------------------------------------";
	ui_tooltip = "LTS Final";
	ui_category = "About";
	ui_category_closed = true;
>;

#if HQAA_DEBUG_MODE
uniform uint HqaaDebugMode <
	ui_type = "radio";
	ui_category = "Debug";
	ui_category_closed = true;
	ui_spacing = 3;
	ui_label = " ";
	ui_text = "Debug Mode:";
	ui_items = "Off\n\n\0Detected Edges\0SMAA Blend Weights\n\n\0FXAA Results\0FXAA Lumas\0FXAA Metrics\n\n\0Hysteresis Pattern\n\n\0Show Alpha Channel\0";
	ui_tooltip = "Useful primarily for learning what everything\n"
				 "does when using advanced mode setup.";
> = 0;
#endif //HQAA_DEBUG_MODE

uniform int HqaaAboutEOF <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n--------------------------------------------------------------------------------";
>;

#if !HQAA_ADVANCED_MODE
uniform uint HqaaPreset <
	ui_type = "combo";
	ui_label = "Quality Preset";
	ui_tooltip = "Quality of the core Anti-Aliasing effect.\n"
				 "Higher presets look better but take more\n"
				 "GPU time to compute. Set HQAA_ADVANCED_MODE\n"
				 "to 1 to customize all options.";
	ui_items = "Low\0Medium\0High\0Ultra\0";
> = 2;

static const float HqaaLowLumaThreshold = 0.333333;
static const float HqaaHysteresisStrength = 12.5;
static const float HqaaHysteresisFudgeFactor = 1.0;
static const bool HqaaDoLumaHysteresis = true;
static const uint HqaaEdgeTemporalAggregation = 1;
static const bool HqaaFxEarlyExit = true;
static const uint HqaaSourceInterpolation = 0;
static const uint HqaaSourceInterpolationOffset = 0;

#else
uniform float HqaaEdgeThresholdCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_spacing = 3;
	ui_label = "Edge Detection Threshold";
	ui_tooltip = "Local contrast required to be considered an edge";
	ui_category = "Edge Detection";
	ui_category_closed = true;
> = 0.1;

uniform float HqaaLowLumaThreshold <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
	ui_label = "Low Luma Threshold";
	ui_tooltip = "Luma level below which dynamic thresholding activates";
	ui_spacing = 3;
	ui_category = "Edge Detection";
	ui_category_closed = true;
> = 0.333333;

uniform float HqaaDynamicThresholdCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "% Dynamic Range";
	ui_tooltip = "Maximum reduction of edge threshold (% base threshold)\n"
				 "permitted when detecting low-brightness edges.\n"
				 "Lower = faster, might miss low-contrast edges\n"
				 "Higher = slower, catches more edges in dark scenes";
	ui_category = "Edge Detection";
	ui_category_closed = true;
> = 75;

uniform uint HqaaSourceInterpolation <
	ui_type = "combo";
	ui_spacing = 9;
	ui_label = "Edge Detection Interpolation";
	ui_tooltip = "Offsets edge detection passes by either\n"
				 "two or four frames when enabled. This is\n"
				 "intended for specific usage cases where\n"
				 "the game's framerate is interpolated from\n"
				 "a low value to a higher one (eg capped 30\n"
				 "interpolated to 60fps). For the vast\n"
				 "majority of games, leave this setting off.";
	ui_items = "Off\0Single Interpolation\0Double Interpolation\0";
	ui_category = "Edge Detection";
	ui_category_closed = true;
> = 0;

uniform uint HqaaSourceInterpolationOffset <
	ui_type = "slider";
	ui_min = 0; ui_max = 3; ui_step = 1;
	ui_label = "Frame Count Offset\n\n";
	ui_tooltip = "Arbitrary offset applied when determining whether\n"
				 "to run or skip edge detection when using interpolation.\n"
				 "Adjust this if there seems to be synchronization\n"
				 "problems visible in the output.";
	ui_category = "Edge Detection";
	ui_category_closed = true;
> = 0;

uniform uint HqaaEdgeTemporalAggregation <
	ui_type = "radio";
	ui_label = "Mouseover for description";
	ui_spacing = 3;
	ui_text = "Temporal Edge Aggregation Mode:";
	ui_tooltip = "Determines the conditions under which edge detection\n"
				"temporal aggregation will keep detected edges.\n"
				"Loose = Keep any recent detection (possible ghosting)\n"
				"Balanced = Change false to true if two recent detections\n"
				"Strict = Only true if all recent frames true (might shimmer)";
	ui_items = "Loose\0Balanced\0Strict\0";
	ui_category = "SMAA";
	ui_category_closed = true;
> = 1;

uniform float HqaaSmCorneringCustom < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_spacing = 2;
	ui_label = "% Corner Rounding\n\n";
	ui_tooltip = "Affects the amount of blending performed when SMAA\ndetects crossing edges";
	ui_category = "SMAA";
	ui_category_closed = true;
> = 25;

uniform uint HqaaFxQualityCustom <
	ui_type = "slider";
	ui_spacing = 3;
	ui_min = 5; ui_max = 100; ui_step = 1;
	ui_label = "Scan Iterations";
	ui_tooltip = "Affects the maximum radius FXAA will\nsearch along an edge gradient";
	ui_category = "FXAA";
	ui_category_closed = true;
> = 25;

uniform float HqaaFxTexelCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.25; ui_max = 4.0; ui_step = 0.01;
	ui_label = "Edge Gradient Texel Size";
	ui_tooltip = "Determines how far along an edge FXAA will move\nfrom one scan iteration to the next.\n\nLower = slower, more accurate\nHigher = faster, causes more blur";
	ui_category = "FXAA";
	ui_category_closed = true;
> = 0.5;

uniform float HqaaFxBlendCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "% Blending Strength";
	ui_tooltip = "Percentage of blending FXAA will apply to edges.\n"
				 "Lower = sharper image, Higher = more AA effect";
	ui_category = "FXAA";
	ui_category_closed = true;
> = 75;

uniform bool HqaaFxEarlyExit <
	ui_label = "Allow Early Exit\n\n";
	ui_tooltip = "Normally, FXAA will early-exit when the\n"
				 "local contrast doesn't exceed the edge\n"
				 "threshold. Uncheck this to force FXAA to\n"
				 "process the entire scene.";
	ui_spacing = 3;
	ui_category = "FXAA";
	ui_category_closed = true;
> = true;

uniform bool HqaaDoLumaHysteresis <
	ui_spacing = 3;
	ui_label = "Enable Hysteresis";
	ui_tooltip = "Hysteresis measures the luma of each pixel\n"
				"before and affer changes are made to it and\n"
				"uses the delta to reconstruct detail from\n"
				"the original scene.";
	ui_category = "Hysteresis";
	ui_category_closed = true;
> = true;

uniform float HqaaHysteresisStrength <
	ui_type = "slider";
	ui_spacing = 3;
	ui_min = 0; ui_max = 100; ui_step = 0.1;
	ui_label = "% Strength";
	ui_tooltip = "0% = Off (keep anti-aliasing result as-is)\n100% = Aggressive Correction";
	ui_category = "Hysteresis";
	ui_category_closed = true;
> = 12.5;

uniform float HqaaHysteresisFudgeFactor <
	ui_type = "slider";
	ui_min = 0; ui_max = 25; ui_step = 0.01;
	ui_label = "% Fudge Factor\n\n";
	ui_tooltip = "Ignore up to this much difference between the\noriginal pixel and the anti-aliasing result";
	ui_category = "Hysteresis";
	ui_category_closed = true;
> = 1.0;
#endif //HQAA_ADVANCED_MODE

#if HQAA_OUTPUT_MODE == 1
uniform float HqaaHdrNits < 
	ui_spacing = 3;
	ui_type = "slider";
	ui_min = 500.0; ui_max = 10000.0; ui_step = 100.0;
	ui_label = "HDR Nits\n\n";
	ui_tooltip = "If the scene brightness changes after HQAA runs, try\n"
				 "adjusting this value up or down until it looks right.";
> = 1000.0;
#endif //HQAA_TARGET_COLOR_SPACE

uniform int HqaaOptionsEOF <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n--------------------------------------------------------------------------------";
>;

#if HQAA_OPTIONAL_EFFECTS
uniform bool HqaaEnableSharpening <
	ui_spacing = 3;
	ui_label = "Enable Sharpening";
	ui_tooltip = "Performs full-scene AMD Contrast-Adaptive Sharpening\n"
				"which uses SMAA edge data to reduce sharpen strength\n"
				"in regions containing edges.";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = true;

uniform float HqaaSharpenerStrength < __UNIFORM_SLIDER_FLOAT1
	ui_spacing = 3;
	ui_min = 0; ui_max = 1; ui_step = 0.01;
	ui_label = "Sharpening Strength";
	ui_tooltip = "Amount of sharpening to apply";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = 1.0;

uniform float HqaaSharpenerClamping < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 1; ui_step = 0.001;
	ui_label = "Clamp Strength\n\n";
	ui_tooltip = "How much to clamp sharpening strength when the pixel had AA applied to it\n"
	             "Zero means no clamp applied, one means no sharpening applied";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = 0.625;

uniform bool HqaaEnableBrightnessGain <
	ui_spacing = 3;
	ui_label = "Enable Brightness Booster";
	ui_category = "Brightness Booster";
	ui_category_closed = true;
> = false;

uniform float HqaaGainStrength < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 1.0; ui_step = 0.001;
	ui_spacing = 3;
	ui_label = "Boost";
	ui_tooltip = "Allows to raise overall image brightness\n"
			  "as a quick fix for dark games or monitors.";
	ui_category = "Brightness Booster";
	ui_category_closed = true;
> = 0.333333;

uniform bool HqaaGainLowLumaCorrection <
	ui_label = "Washout Correction\n\n";
	ui_tooltip = "Normalizes contrast ratio of resulting pixels\n"
				 "to reduce perceived contrast washout.";
	ui_category = "Brightness Booster";
	ui_category_closed = true;
> = true;

uniform bool HqaaEnableColorPalette <
	ui_spacing = 3;
	ui_label = "Enable Color Palette Manipulation";
	ui_category = "Color Palette";
	ui_category_closed = true;
> = false;

uniform float HqaaVibranceStrength < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_spacing = 3;
	ui_label = "% Vibrance";
	ui_tooltip = "Arbitrarily raises or lowers vibrance of the scene.\n"
				"Vibrance differs from Saturation in that it\n"
				"preserves the correct contrast ratio between\n"
				"color channels after being applied, so it cannot\n"
				"produce a grayscale image nor a blown-out one.";
	ui_category = "Color Palette";
	ui_category_closed = true;
> = 50;

 uniform float HqaaSaturationStrength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
	ui_label = "Saturation";
	ui_tooltip = "This setting is designed to try and help\n"
				 "compensate for contrast washout caused\n"
				 "by displaying a component YCbCr signal\n"
				 "on an ARGB display. 0.5 is neutral,\n"
				 "0.0 is grayscale, 1.0 is cartoony. Unlike\n"
				 "vibrance this setting will alter the\n"
				 "contrast ratio between color channels and\n"
				 "therefore can cause loss of detail.";
	ui_category = "Color Palette";
	ui_category_closed = true;
 > = 0.5;
 
uniform uint HqaaTonemapping <
	ui_spacing = 3;
	ui_type = "combo";
	ui_label = "Tonemapping\n\n";
	ui_items = "None\0Reinhard\0Reinhard Extended\0Reinhard Luminance\0Reinhard-Jodie\0Uncharted 2\0ACES approx\0";
	ui_category = "Color Palette";
	ui_category_closed = true;
> = 0;
 
#if HQAA_OPTIONAL__TEMPORAL_STABILIZER
uniform float HqaaPreviousFrameWeight < __UNIFORM_SLIDER_FLOAT1
	ui_spacing = 3;
	ui_min = 0; ui_max = 0.75; ui_step = 0.001;
	ui_label = "Previous Frame Weight";
	ui_category = "Temporal Stabilizer";
	ui_category_closed = true;
	ui_tooltip = "Blends the previous frame with the\ncurrent frame to stabilize results.";
> = 0.25;

uniform bool HqaaTemporalEdgeHinting <
	ui_spacing = 3;
	ui_label = "Use SMAA Blend Hinting";
	ui_tooltip = "Adaptively adjusts previous frame weight\nby referencing SMAA blending weights.";
	ui_category = "Temporal Stabilizer";
	ui_category_closed = true;
> = true;

uniform bool HqaaTemporalClamp <
	ui_label = "Clamp Weight";
	ui_category = "Temporal Stabilizer";
	ui_category_closed = true;
	ui_tooltip = "Adjusts the weight given to the past\n"
				 "frame using the chroma change between\n"
				 "frames as the reference. This is done\n"
				 "after SMAA hinting if it's also enabled.";
> = true;

uniform bool HqaaHighFramerateAssist <
	ui_label = "High Framerate Assist Enhancement";
	ui_spacing = 3;
	ui_tooltip = "Combines HFRAA with the temporal stabilizer\nto enhance the effect. Your framerate must be\ncapped to the monitor refresh rate for this to work well.";
	ui_category = "Temporal Stabilizer";
	ui_category_closed = true;
> = false;

uniform float HqaaHFRJitterStrength <
	ui_label = "HFRAA Jitter Strength\n\n";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
	ui_tooltip = "Size (in pixels) of the jitter applied\nto the scene every second frame";
	ui_category = "Temporal Stabilizer";
	ui_category_closed = true;
> = 0.5;
#endif //HQAA_OPTIONAL__TEMPORAL_STABILIZER

#if HQAA_OPTIONAL__DEBANDING
uniform uint HqaaDebandPreset <
	ui_type = "combo";
	ui_items = "Automatic\0Low\0Medium\0High\0Very High\0Extreme\0";
	ui_spacing = 3;
    ui_label = "Strength";
    ui_tooltip = "Performs a fast debanding pass similar\n"
			  "to Deband.fx to mitigate color banding.\n"
			  "Stronger presets catch more banding but\n"
			  "increase the risk of detail loss.\n"
			  "The automatic setting uses the edge\n"
			  "threshold to calculate the profile.";
	ui_category = "Debanding";
	ui_category_closed = true;
> = 0;

uniform float HqaaDebandRange < __UNIFORM_SLIDER_FLOAT1
    ui_min = 4.0;
    ui_max = 32.0;
    ui_step = 1.0;
    ui_label = "Scan Radius";
    ui_tooltip = "Maximum distance from each dot to check\n"
    			 "for possible color banding artifacts\n";
	ui_category = "Debanding";
	ui_category_closed = true;
> = 32.0;

uniform bool HqaaDebandIgnoreLowLuma <
	ui_label = "Skip Dark Pixels";
	ui_tooltip = "Skips performing debanding in areas with\n"
				 "low luma. This can help to preserve detail\n"
				 "in games that have dark scenes or areas.";
	ui_spacing = 3;
	ui_category = "Debanding";
	ui_category_closed = true;
> = true;

uniform bool HqaaDebandUseSmaaData <
	ui_label = "SMAA Hinting\n\n";
	ui_tooltip = "Skips performing debanding where SMAA\n"
				 "recorded blending weights. Helps to\n"
				 "preserve detail when using stronger\n"
				 "debanding settings.";
	ui_category = "Debanding";
	ui_category_closed = true;
> = true;

uniform uint HqaaDebandSeed < source = "random"; min = 0; max = 32767; >;
#endif //HQAA_OPTIONAL__DEBANDING

#if HQAA_OPTIONAL__SOFTENING
uniform float HqaaImageSoftenStrength <
	ui_type = "slider";
	ui_spacing = 3;
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
	ui_label = "Softening Strength";
	ui_tooltip = "HQAA image softening measures error-controlled\n"
				"average differences for the neighborhood around\n"
				"every pixel to apply a subtle blur effect to the\n"
				"scene. Warning: may eat stars.";
	ui_category = "Image Softening";
	ui_category_closed = true;
> = 0.125;

uniform float HqaaImageSoftenOffset <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
	ui_label = "Sampling Offset";
	ui_tooltip = "Adjust this value up or down to expand or\n"
				 "contract the sampling patterns around the\n"
				 "central pixel. Effectively, this gives the\n"
				 "middle dot either less or more weight in\n"
				 "each sample pattern, causing the overall\n"
				 "result to look either more or less blurred.";
	ui_category = "Image Softening";
	ui_category_closed = true;
> = 0.875;

uniform bool HqaaSoftenerSpuriousDetection <
	ui_label = "Spurious Pixel Correction";
	ui_tooltip = "Uses different blending strength when an\n"
				 "overly bright or dark pixel (compared to\n"
				 "its surroundings) is detected.";
	ui_spacing = 3;
	ui_category = "Image Softening";
	ui_category_closed = true;
> = true;

uniform float HqaaSoftenerSpuriousThreshold <
	ui_label = "Detection Threshold";
	ui_tooltip = "Difference in contrast between the middle\n"
				 "pixel and the neighborhood around it to be\n"
				 "considered a spurious pixel";
	ui_min = 0.0; ui_max = 0.5; ui_step = 0.001;
	ui_type = "slider";
	ui_category = "Image Softening";
	ui_category_closed = true;
> = 0.125;

uniform float HqaaSoftenerSpuriousStrength <
	ui_label = "Spurious Softening Strength\n\n";
	ui_tooltip = "Overrides the base softening strength to this\n"
				 "when a pixel is flagged as spurious.";
	ui_type = "slider";
	ui_min = 0; ui_max = 2.0; ui_step = 0.001;
	ui_category = "Image Softening";
	ui_category_closed = true;
> = 0.75;
#endif //HQAA_OPTIONAL__SOFTENING

uniform int HqaaOptionalsEOF <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n--------------------------------------------------------------------------------";
>;
#endif //HQAA_OPTIONAL_EFFECTS

#if HQAA_DEBUG_MODE
uniform int HqaaDebugExplainer <
	ui_type = "radio";
	ui_spacing = 3;
	ui_label = " ";
	ui_text = "----------------------------------------------------------------\n"
			  "When viewing the detected edges, the colors shown in the texture\n"
			  "are not related to the image on the screen directly, rather they\n"
			  "are markers indicating the following:\n"
			  "- Green = Probable Horizontal Edge Here\n"
			  "- Red = Probable Vertical Edge Here\n"
			  "- Yellow = Probable Diagonal Edge Here\n\n"
			  "SMAA blending weights and FXAA results show what each related\n"
			  "pass is rendering to the screen to produce its AA effect.\n\n"
			  "The FXAA luma view compresses its calculated range to 0.25-1.0\n"
			  "so that black pixels mean the shader didn't run in that area.\n"
			  "Grayscale values represent edges detected using luma, red values\n"
			  "represent edges detected using chroma.\n\n"
			  "FXAA metrics draws a range of green to red where the selected\n"
			  "pass ran, with green representing not much execution time used\n"
			  "and red representing a lot of execution time used.\n\n"
			  "The Hysteresis pattern is a representation of where and how\n"
			  "strongly the hysteresis pass is performing corrections, but it\n"
			  "does not directly indicate the color that it is blending (it is\n"
			  "the absolute value of a difference calculation, meaning that\n"
			  "decreases are the visual inversion of the actual blend color).\n\n"
			  "Alpha channel view is for curiosity's sake only. HQAA does not\n"
			  "use or modify the alpha channel. In most SDR games, this means\n"
			  "you will simply see a black screen. When there is alpha data in\n"
			  "the buffer, it displays as a grayscale image, the intensity of\n"
			  "which represents the value in the channel.\n"
	          "----------------------------------------------------------------";
	ui_category = "DEBUG README";
	ui_category_closed = true;
>;
#endif //HQAA_DEBUG_MODE

///////////////////////////////////////////////// HUMAN+MACHINE PRESET REFERENCE //////////////////////////////////////////////////////////

#if HQAA_ADVANCED_MODE
uniform int HqaaPresetBreakdown <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n"
			  "--------------------------------------------------------------\n"
			  "|        |       Edges       |  SMAA  |        FXAA          |\n"
	          "|--Preset|-Threshold---Range-|-Corner-|-Scan---Texel---Blend-|\n"
	          "|--------|-----------|-------|--------|------|-------|-------|\n"
			  "|     Low|    0.20   | 50.0% |    8%  |  12  |  2.0  |  50%  |\n"
			  "|  Medium|    0.16   | 66.7% |   16%  |  24  |  1.0  |  75%  |\n"
			  "|    High|    0.12   | 75.0% |   24%  |  36  |  1.0  |  83%  |\n"
			  "|   Ultra|    0.08   | 80.0% |   32%  |  72  |  0.5  |  90%  |\n"
			  "--------------------------------------------------------------";
	ui_category = "Click me to see what settings each preset uses!";
	ui_category_closed = true;
>;

#define __HQAA_EDGE_THRESHOLD (HqaaEdgeThresholdCustom)
#define __HQAA_DYNAMIC_RANGE (HqaaDynamicThresholdCustom / 100.0)
#define __HQAA_SM_CORNERS (HqaaSmCorneringCustom / 100.0)
#define __HQAA_FX_QUALITY (HqaaFxQualityCustom)
#define __HQAA_FX_TEXEL (HqaaFxTexelCustom)
#define __HQAA_FX_BLEND (HqaaFxBlendCustom / 100.0)

#else

static const float HQAA_THRESHOLD_PRESET[4] = {0.2, 0.16, 0.12, 0.08};
static const float HQAA_DYNAMIC_RANGE_PRESET[4] = {0.5, 0.666667, 0.75, 0.8};
static const float HQAA_SMAA_CORNER_ROUNDING_PRESET[4] = {0.08, 0.16, 0.24, 0.32};
static const uint HQAA_FXAA_SCAN_ITERATIONS_PRESET[4] = {12, 24, 36, 72};
static const float HQAA_FXAA_TEXEL_SIZE_PRESET[4] = {2.0, 1.0, 1.0, 0.5};
static const float HQAA_SUBPIX_PRESET[4] = {0.5, 0.75, 0.833333, 0.9};

#define __HQAA_EDGE_THRESHOLD (HQAA_THRESHOLD_PRESET[HqaaPreset])
#define __HQAA_DYNAMIC_RANGE (HQAA_DYNAMIC_RANGE_PRESET[HqaaPreset])
#define __HQAA_SM_CORNERS (HQAA_SMAA_CORNER_ROUNDING_PRESET[HqaaPreset])
#define __HQAA_FX_QUALITY (HQAA_FXAA_SCAN_ITERATIONS_PRESET[HqaaPreset])
#define __HQAA_FX_TEXEL (HQAA_FXAA_TEXEL_SIZE_PRESET[HqaaPreset])
#define __HQAA_FX_BLEND (HQAA_SUBPIX_PRESET[HqaaPreset])

#endif //HQAA_ADVANCED_MODE

uniform uint HqaaFramecounter < source = "framecount"; >;
#define __HQAA_ALT_FRAME ((HqaaFramecounter + HqaaSourceInterpolationOffset) % 2 == 0)
#define __HQAA_QUAD_FRAME ((HqaaFramecounter + HqaaSourceInterpolationOffset) % 4 == 1)

/*****************************************************************************************************************************************/
/*********************************************************** UI SETUP END ****************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/******************************************************** SYNTAX SETUP START *************************************************************/
/*****************************************************************************************************************************************/

#define __HQAA_DISPLAY_NUMERATOR max(BUFFER_HEIGHT, BUFFER_WIDTH)
#define __HQAA_SMALLEST_COLOR_STEP rcp(intpow(2, BUFFER_COLOR_BIT_DEPTH))
#define __HQAA_CONST_E 2.718282
#define __HQAA_LUMA_REF float3(0.2126, 0.7152, 0.0722)
#define __HQAA_AVERAGE_REF float3(0.333333, 0.333334, 0.333333)
#define __HQAA_NORMAL_REF float3(0.299, 0.587, 0.114)

#define __HQAA_SM_RADIUS 4.0f
#define __HQAA_SM_BUFFERINFO float4(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT, BUFFER_WIDTH, BUFFER_HEIGHT)
#define __HQAA_SM_AREATEX_RANGE 16
#define __HQAA_SM_AREATEX_RANGE_DIAG 20
#define __HQAA_SM_AREATEX_TEXEL float2(0.00625, 0.001786) // 1/{160,560}
#define __HQAA_SM_AREATEX_SUBTEXEL 0.142857 // 1/7
#define __HQAA_SM_SEARCHTEX_SIZE float2(66.0, 33.0)
#define __HQAA_SM_SEARCHTEX_SIZE_PACKED float2(64.0, 16.0)

#define HQAA_Tex2D(tex, coord) tex2Dlod(tex, (coord).xyxy)
#define HQAA_Tex2DOffset(tex, coord, offset) tex2Dlodoffset(tex, (coord).xyxy, offset)
#define HQAA_DecodeTex2D(tex, coord) ConditionalDecode(tex2Dlod(tex, (coord).xyxy))
#define HQAA_DecodeTex2DOffset(tex, coord, offset) ConditionalDecode(tex2Dlodoffset(tex, (coord).xyxy, offset))

#define HQAAmax3(x,y,z) max(max(x,y),z)
#define HQAAmax4(w,x,y,z) max(max(w,x),max(y,z))
#define HQAAmax5(v,w,x,y,z) max(max(max(v,w),x),max(y,z))
#define HQAAmax6(u,v,w,x,y,z) max(max(max(u,v),max(w,x)),max(y,z))
#define HQAAmax7(t,u,v,w,x,y,z) max(max(max(t,u),max(v,w)),max(max(x,y),z))
#define HQAAmax8(s,t,u,v,w,x,y,z) max(max(max(s,t),max(u,v)),max(max(w,x),max(y,z)))
#define HQAAmax9(r,s,t,u,v,w,x,y,z) max(max(max(max(r,s),t),max(u,v)),max(max(w,x),max(y,z)))
#define HQAAmax10(q,r,s,t,u,v,w,x,y,z) max(max(max(max(q,r),max(s,t)),max(u,v)),max(max(w,x),max(y,z)))
#define HQAAmax11(p,q,r,s,t,u,v,w,x,y,z) max(max(max(max(p,q),max(r,s)),max(max(t,u),v)),max(max(w,x),max(y,z)))
#define HQAAmax12(o,p,q,r,s,t,u,v,w,x,y,z) max(max(max(max(o,p),max(q,r)),max(max(s,t),max(u,v))),max(max(w,x),max(y,z)))
#define HQAAmax13(n,o,p,q,r,s,t,u,v,w,x,y,z) max(max(max(max(n,o),max(p,q)),max(max(r,s),max(t,u))),max(max(max(v,w),x),max(y,z)))
#define HQAAmax14(m,n,o,p,q,r,s,t,u,v,w,x,y,z) max(max(max(max(m,n),max(o,p)),max(max(q,r),max(s,t))),max(max(max(u,v),max(w,x)),max(y,z)))
#define HQAAmax15(l,m,n,o,p,q,r,s,t,u,v,w,x,y,z) max(max(max(max(l,m),max(n,o)),max(max(p,q),max(r,s))),max(max(max(t,u),max(v,w)),max(max(x,y),z)))
#define HQAAmax16(k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z) max(max(max(max(k,l),max(m,n)),max(max(o,p),max(q,r))),max(max(max(s,t),max(u,v)),max(max(w,x),max(y,z))))

#define HQAAmin3(x,y,z) min(min(x,y),z)
#define HQAAmin4(w,x,y,z) min(min(w,x),min(y,z))
#define HQAAmin5(v,w,x,y,z) min(min(min(v,w),x),min(y,z))
#define HQAAmin6(u,v,w,x,y,z) min(min(min(u,v),min(w,x)),min(y,z))
#define HQAAmin7(t,u,v,w,x,y,z) min(min(min(t,u),min(v,w)),min(min(x,y),z))
#define HQAAmin8(s,t,u,v,w,x,y,z) min(min(min(s,t),min(u,v)),min(min(w,x),min(y,z)))
#define HQAAmin9(r,s,t,u,v,w,x,y,z) min(min(min(min(r,s),t),min(u,v)),min(min(w,x),min(y,z)))
#define HQAAmin10(q,r,s,t,u,v,w,x,y,z) min(min(min(min(q,r),min(s,t)),min(u,v)),min(min(w,x),min(y,z)))
#define HQAAmin11(p,q,r,s,t,u,v,w,x,y,z) min(min(min(min(p,q),min(r,s)),min(min(t,u),v)),min(min(w,x),min(y,z)))
#define HQAAmin12(o,p,q,r,s,t,u,v,w,x,y,z) min(min(min(min(o,p),min(q,r)),min(min(s,t),min(u,v))),min(min(w,x),min(y,z)))
#define HQAAmin13(n,o,p,q,r,s,t,u,v,w,x,y,z) min(min(min(min(n,o),min(p,q)),min(min(r,s),min(t,u))),min(min(min(v,w),x),min(y,z)))
#define HQAAmin14(m,n,o,p,q,r,s,t,u,v,w,x,y,z) min(min(min(min(m,n),min(o,p)),min(min(q,r),min(s,t))),min(min(min(u,v),min(w,x)),min(y,z)))
#define HQAAmin15(l,m,n,o,p,q,r,s,t,u,v,w,x,y,z) min(min(min(min(l,m),min(n,o)),min(min(p,q),min(r,s))),min(min(min(t,u),min(v,w)),min(min(x,y),z)))
#define HQAAmin16(k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z) min(min(min(min(k,l),min(m,n)),min(min(o,p),min(q,r))),min(min(min(s,t),min(u,v)),min(min(w,x),min(y,z))))

#define HQAAdotmax(x) max(max((x).r, (x).g), (x).b)
#define HQAAdotmin(x) min(min((x).r, (x).g), (x).b)

/*****************************************************************************************************************************************/
/********************************************************* SYNTAX SETUP END **************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/******************************************************** SUPPORT CODE START *************************************************************/
/*****************************************************************************************************************************************/

//////////////////////////////////////////////////////// HELPER FUNCTIONS ////////////////////////////////////////////////////////////////

/*
Ey = 0.299R+0.587G+0.114B
Ecr = 0.713(R - Ey) = 0.500R-0.419G-0.081B
Ecb = 0.564(B - Ey) = -0.169R-0.331G+0.500B

where Ey, R, G and B are in the range [0,1] and Ecr and Ecb are in the range [-0.5,0.5]
*/
float3 RGBtoYUV(float3 input)
{
	float3 argb = saturate(input); // value must be between [0,1]
	float3 yuv;
	
	yuv.x = saturate((0.299 * argb.r) + (0.587 * argb.g) + (0.114 * argb.b));
	yuv.y = clamp(0.713 * (argb.r - yuv.x), -0.5, 0.5);
	yuv.z = clamp(0.564 * (argb.b - yuv.x), -0.5, 0.5);
	
	return yuv;
}
float4 RGBtoYUV(float4 input)
{
	return float4(RGBtoYUV(input.rgb), input.a);
}

/*
/* reverse transfer accomplished by solving original equations for R and B and then
/* using those channels to solve the luma equation for G
*/
float3 YUVtoRGB(float3 yuv)
{
	yuv.x = saturate(yuv.x);
	yuv.yz = clamp(yuv.yz, -0.5, 0.5);
	
	float3 argb;
	
	argb.r = (1.402525 * yuv.y) + yuv.x;
	argb.b = (1.77305 * yuv.z) + yuv.x;
	argb.g = (1.703578 * yuv.x) - (0.50937 * argb.r) - (0.194208 * argb.b);
	
	return argb;
}
float4 YUVtoRGB(float4 yuv)
{
	return float4(YUVtoRGB(yuv.xyz), yuv.a);
}

float dotweight(float3 middle, float3 neighbor, bool useluma, float3 weights)
{
	if (useluma) return dot(neighbor, weights);
	else return dot(abs(middle - neighbor), __HQAA_AVERAGE_REF);
}
float dotweight(float4 middle, float4 neighbor, bool useluma, float3 weights)
{
	return dotweight(middle.rgb, neighbor.rgb, useluma, weights);
}

float intpow(float x, float y)
{
	float result = x;
	uint basepower = 1;
	uint raisepower = round(abs(y));
	// power of zero override
	if (raisepower == 0) return 1.0;
	// compiler warning dodge
	else if (raisepower == 2) return x * x;
	while (basepower < raisepower)
	{
		result *= x;
		basepower++;
	}
	return result;
}
float2 intpow(float2 x, float y)
{
	float2 result = x;
	uint basepower = 1;
	uint raisepower = round(abs(y));
	// power of zero override
	if (raisepower == 0) return 1.0.xx;
	// compiler warning dodge
	else if (raisepower == 2) return x * x;
	while (basepower < raisepower)
	{
		result *= x;
		basepower++;
	}
	return result;
}
float3 intpow(float3 x, float y)
{
	float3 result = x;
	uint basepower = 1;
	uint raisepower = round(abs(y));
	// power of zero override
	if (raisepower == 0) return 1.0.xxx;
	// compiler warning dodge
	else if (raisepower == 2) return x * x;
	while (basepower < raisepower)
	{
		result *= x;
		basepower++;
	}
	return result;
}
float4 intpow(float4 x, float y)
{
	float4 result = x;
	uint basepower = 1;
	uint raisepower = round(abs(y));
	// power of zero override
	if (raisepower == 0) return 1.0.xxxx;
	// compiler warning dodge
	else if (raisepower == 2) return x * x;
	while (basepower < raisepower)
	{
		result *= x;
		basepower++;
	}
	return result;
}

float dotsat(float3 x)
{
	// trunc(xl) only = 1 when x = float3(1,1,1)
	// float3(1,1,1) produces 0/0 in the original calculation
	// this should change it to 0/1 to avoid the possible NaN out
	float xl = dot(x, __HQAA_LUMA_REF);
	return ((HQAAdotmax(x) - HQAAdotmin(x)) / (1.0 - (2.0 * xl - 1.0) + trunc(xl)));
}
float dotsat(float4 x)
{
	return dotsat(x.rgb);
}

float3 AdjustVibrance(float3 pixel, float satadjust)
{
	float3 outdot = pixel;
	float refsat = dotsat(pixel);
	float realadjustment = saturate(refsat + satadjust) - refsat;
	float2 highlow = float2(HQAAdotmax(pixel), HQAAdotmin(pixel));
	float maxpositive = 1.0 - highlow.x;
	float maxnegative = -highlow.y;
	[branch] if (abs(realadjustment) > __HQAA_SMALLEST_COLOR_STEP)
	{
		// there won't necessarily be a valid mid if eg. pixel.r == pixel.g > pixel.b
		float mid = -1.0;
		
		// figure out if the low needs to move up or down
		float lowadjust = clamp(((highlow.y - highlow.x / 2.0) / highlow.x) * realadjustment, maxnegative, maxpositive);
		
		// same calculation used with the high factors to this
		float highadjust = clamp(0.5 * realadjustment, maxnegative, maxpositive);
		
		// method = apply corrections based on matched high or low channel, assign mid if neither
		if (pixel.r == highlow.x) outdot.r = pow(abs(1.0 + highadjust) * 2.0, log2(pixel.r));
		else if (pixel.r == highlow.y) outdot.r = pow(abs(1.0 + lowadjust) * 2.0, log2(pixel.r));
		else mid = pixel.r;
		if (pixel.g == highlow.x) outdot.g = pow(abs(1.0 + highadjust) * 2.0, log2(pixel.g));
		else if (pixel.g == highlow.y) outdot.g = pow(abs(1.0 + lowadjust) * 2.0, log2(pixel.g));
		else mid = pixel.g;
		if (pixel.b == highlow.x) outdot.b = pow(abs(1.0 + highadjust) * 2.0, log2(pixel.b));
		else if (pixel.b == highlow.y) outdot.b = pow(abs(1.0 + lowadjust) * 2.0, log2(pixel.b));
		else mid = pixel.b;
		
		// perform mid channel calculations if a valid mid was found
		if (mid > 0.0)
		{
			// figure out whether it should move up or down
			float midadjust = clamp(((mid - highlow.x / 2.0) / highlow.x) * realadjustment, maxnegative, maxpositive);
			
			// determine which channel is mid and apply correction
			if (pixel.r == mid) outdot.r = pow(abs(1.0 + midadjust) * 2.0, log2(pixel.r));
			else if (pixel.g == mid) outdot.g = pow(abs(1.0 + midadjust) * 2.0, log2(pixel.g));
			else if (pixel.b == mid) outdot.b = pow(abs(1.0 + midadjust) * 2.0, log2(pixel.b));
		}
	}
	
	return outdot;
}
float4 AdjustVibrance(float4 pixel, float satadjust)
{
	return float4(AdjustVibrance(pixel.rgb, satadjust), pixel.a);
}

float3 AdjustSaturation(float3 input, float requestedadjustment)
{
	// change to YCrCb (component) color space
	// access: x=Y, y=Cr, z=Cb
	float3 yuv = RGBtoYUV(input);
	
	// convert absolute saturation to adjustment delta
	float adjustment = 2.0 * (saturate(requestedadjustment) - 0.5);
	
	// for a positive adjustment, determine ceiling and clamp if necessary
	if (adjustment > 0.0)
	{
		float maxboost = rcp(max(abs(yuv.y), abs(yuv.z)) / 0.5);
		if (adjustment > maxboost) adjustment = maxboost;
	}
	
	// compute delta Cr,Cb
	yuv.y = yuv.y > 0.0 ? clamp(yuv.y + (adjustment * yuv.y), 0.0, 0.5) : clamp(yuv.y - (adjustment * abs(yuv.y)), -0.5, 0.0);
	yuv.z = yuv.z > 0.0 ? clamp(yuv.z + (adjustment * yuv.z), 0.0, 0.5) : clamp(yuv.z - (adjustment * abs(yuv.z)), -0.5, 0.0);
	
	// change back to ARGB color space
	return YUVtoRGB(yuv);
}

/////////////////////////////////////////////////////// TRANSFER FUNCTIONS ////////////////////////////////////////////////////////////////

#if HQAA_OUTPUT_MODE == 2
float encodePQ(float x)
{
/*	float nits = 10000.0;
	float m2rcp = 0.012683; // 1 / (2523/32)
	float m1rcp = 6.277395; // 1 / (1305/8192)
	float c1 = 0.8359375; // 107 / 128
	float c2 = 18.8515625; // 2413 / 128
	float c3 = 18.6875; // 2392 / 128
*/
	float xpm2rcp = pow(saturate(x), 0.012683);
	float numerator = max(xpm2rcp - 0.8359375, 0.0);
	float denominator = 18.8515625 - (18.6875 * xpm2rcp);
	
	float output = pow(abs(numerator / denominator), 6.277395);
#if BUFFER_COLOR_BIT_DEPTH == 10
	output *= 500.0;
#else
	output *= 10000.0;
#endif
	return output;
}
float2 encodePQ(float2 x)
{
	float2 xpm2rcp = pow(saturate(x), 0.012683);
	float2 numerator = max(xpm2rcp - 0.8359375, 0.0);
	float2 denominator = 18.8515625 - (18.6875 * xpm2rcp);
	
	float2 output = pow(abs(numerator / denominator), 6.277395);
#if BUFFER_COLOR_BIT_DEPTH == 10
	output *= 500.0;
#else
	output *= 10000.0;
#endif
	return output;
}
float3 encodePQ(float3 x)
{
	float3 xpm2rcp = pow(saturate(x), 0.012683);
	float3 numerator = max(xpm2rcp - 0.8359375, 0.0);
	float3 denominator = 18.8515625 - (18.6875 * xpm2rcp);
	
	float3 output = pow(abs(numerator / denominator), 6.277395);
#if BUFFER_COLOR_BIT_DEPTH == 10
	output *= 500.0;
#else
	output *= 10000.0;
#endif
	return output;
}
float4 encodePQ(float4 x)
{
	float4 xpm2rcp = pow(saturate(x), 0.012683);
	float4 numerator = max(xpm2rcp - 0.8359375, 0.0);
	float4 denominator = 18.8515625 - (18.6875 * xpm2rcp);
	
	float4 output = pow(abs(numerator / denominator), 6.277395);
#if BUFFER_COLOR_BIT_DEPTH == 10
	output *= 500.0;
#else
	output *= 10000.0;
#endif
	return output;
}

float decodePQ(float x)
{
/*	float nits = 10000.0;
	float m2 = 78.84375 // 2523 / 32
	float m1 = 0.159302; // 1305 / 8192
	float c1 = 0.8359375; // 107 / 128
	float c2 = 18.8515625; // 2413 / 128
	float c3 = 18.6875; // 2392 / 128
*/
#if BUFFER_COLOR_BIT_DEPTH == 10
	float xpm1 = pow(saturate(x / 500.0), 0.159302);
#else
	float xpm1 = pow(saturate(x / 10000.0), 0.159302);
#endif
	float numerator = 0.8359375 + (18.8515625 * xpm1);
	float denominator = 1.0 + (18.6875 * xpm1);
	
	return saturate(pow(abs(numerator / denominator), 78.84375));
}
float2 decodePQ(float2 x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	float2 xpm1 = pow(saturate(x / 500.0), 0.159302);
#else
	float2 xpm1 = pow(saturate(x / 10000.0), 0.159302);
#endif
	float2 numerator = 0.8359375 + (18.8515625 * xpm1);
	float2 denominator = 1.0 + (18.6875 * xpm1);
	
	return saturate(pow(abs(numerator / denominator), 78.84375));
}
float3 decodePQ(float3 x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	float3 xpm1 = pow(saturate(x / 500.0), 0.159302);
#else
	float3 xpm1 = pow(saturate(x / 10000.0), 0.159302);
#endif
	float3 numerator = 0.8359375 + (18.8515625 * xpm1);
	float3 denominator = 1.0 + (18.6875 * xpm1);
	
	return saturate(pow(abs(numerator / denominator), 78.84375));
}
float4 decodePQ(float4 x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	float4 xpm1 = pow(saturate(x / 500.0), 0.159302);
#else
	float4 xpm1 = pow(saturate(x / 10000.0), 0.159302);
#endif
	float4 numerator = 0.8359375 + (18.8515625 * xpm1);
	float4 denominator = 1.0 + (18.6875 * xpm1);
	
	return saturate(pow(abs(numerator / denominator), 78.84375));
}
#endif //HQAA_OUTPUT_MODE == 2

#if HQAA_OUTPUT_MODE == 3
float fastencodePQ(float x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	float y = saturate(x) * 4.728708;
	float z = 500.0;
#else
	float y = saturate(x) * 10.0;
	float z = 10000.0;
#endif
	y *= y;
	y *= y;
	return clamp(y, 0.0, z);
}
float2 fastencodePQ(float2 x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	float2 y = saturate(x) * 4.728708;
	float z = 500.0;
#else
	float2 y = saturate(x) * 10.0;
	float z = 10000.0;
#endif
	y *= y;
	y *= y;
	return clamp(y, 0.0, z);
}
float3 fastencodePQ(float3 x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	float3 y = saturate(x) * 4.728708;
	float z = 500.0;
#else
	float3 y = saturate(x) * 10.0;
	float z = 10000.0;
#endif
	y *= y;
	y *= y;
	return clamp(y, 0.0, z);
}
float4 fastencodePQ(float4 x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	float4 y = saturate(x) * 4.728708;
	float z = 500.0;
#else
	float4 y = saturate(x) * 10.0;
	float z = 10000.0;
#endif
	y *= y;
	y *= y;
	return clamp(y, 0.0, z);
}

float fastdecodePQ(float x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	return saturate((sqrt(sqrt(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 500.0))) / 4.728708));
#else
	return saturate((sqrt(sqrt(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 10000.0))) / 10.0));
#endif
}
float2 fastdecodePQ(float2 x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	return saturate((sqrt(sqrt(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 500.0))) / 4.728708));
#else
	return saturate((sqrt(sqrt(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 10000.0))) / 10.0));
#endif
}
float3 fastdecodePQ(float3 x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	return saturate((sqrt(sqrt(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 500.0))) / 4.728708));
#else
	return saturate((sqrt(sqrt(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 10000.0))) / 10.0));
#endif
}
float4 fastdecodePQ(float4 x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	return saturate((sqrt(sqrt(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 500.0))) / 4.728708));
#else
	return saturate((sqrt(sqrt(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 10000.0))) / 10.0));
#endif
}
#endif //HQAA_OUTPUT_MODE == 3

#if HQAA_OUTPUT_MODE == 1
float encodeHDR(float x)
{
	return saturate(x) * HqaaHdrNits;
}
float2 encodeHDR(float2 x)
{
	return saturate(x) * HqaaHdrNits;
}
float3 encodeHDR(float3 x)
{
	return saturate(x) * HqaaHdrNits;
}
float4 encodeHDR(float4 x)
{
	return saturate(x) * HqaaHdrNits;
}

float decodeHDR(float x)
{
	return saturate(x / HqaaHdrNits);
}
float2 decodeHDR(float2 x)
{
	return saturate(x / HqaaHdrNits);
}
float3 decodeHDR(float3 x)
{
	return saturate(x / HqaaHdrNits);
}
float4 decodeHDR(float4 x)
{
	return saturate(x / HqaaHdrNits);
}
#endif //HQAA_OUTPUT_MODE == 1

float ConditionalEncode(float x)
{
#if HQAA_OUTPUT_MODE == 1
	return encodeHDR(x);
#elif HQAA_OUTPUT_MODE == 2
	return encodePQ(x);
#elif HQAA_OUTPUT_MODE == 3
	return fastencodePQ(x);
#else
	return x;
#endif
}
float2 ConditionalEncode(float2 x)
{
#if HQAA_OUTPUT_MODE == 1
	return encodeHDR(x);
#elif HQAA_OUTPUT_MODE == 2
	return encodePQ(x);
#elif HQAA_OUTPUT_MODE == 3
	return fastencodePQ(x);
#else
	return x;
#endif
}
float3 ConditionalEncode(float3 x)
{
#if HQAA_OUTPUT_MODE == 1
	return encodeHDR(x);
#elif HQAA_OUTPUT_MODE == 2
	return encodePQ(x);
#elif HQAA_OUTPUT_MODE == 3
	return fastencodePQ(x);
#else
	return x;
#endif
}
float4 ConditionalEncode(float4 x)
{
#if HQAA_OUTPUT_MODE == 1
	return encodeHDR(x);
#elif HQAA_OUTPUT_MODE == 2
	return encodePQ(x);
#elif HQAA_OUTPUT_MODE == 3
	return fastencodePQ(x);
#else
	return x;
#endif
}

float ConditionalDecode(float x)
{
#if HQAA_OUTPUT_MODE == 1
	return decodeHDR(x);
#elif HQAA_OUTPUT_MODE == 2
	return decodePQ(x);
#elif HQAA_OUTPUT_MODE == 3
	return fastdecodePQ(x);
#else
	return x;
#endif
}
float2 ConditionalDecode(float2 x)
{
#if HQAA_OUTPUT_MODE == 1
	return decodeHDR(x);
#elif HQAA_OUTPUT_MODE == 2
	return decodePQ(x);
#elif HQAA_OUTPUT_MODE == 3
	return fastdecodePQ(x);
#else
	return x;
#endif
}
float3 ConditionalDecode(float3 x)
{
#if HQAA_OUTPUT_MODE == 1
	return decodeHDR(x);
#elif HQAA_OUTPUT_MODE == 2
	return decodePQ(x);
#elif HQAA_OUTPUT_MODE == 3
	return fastdecodePQ(x);
#else
	return x;
#endif
}
float4 ConditionalDecode(float4 x)
{
#if HQAA_OUTPUT_MODE == 1
	return decodeHDR(x);
#elif HQAA_OUTPUT_MODE == 2
	return decodePQ(x);
#elif HQAA_OUTPUT_MODE == 3
	return fastdecodePQ(x);
#else
	return x;
#endif
}

///////////////////////////////////////////////////// SMAA HELPER FUNCTIONS ///////////////////////////////////////////////////////////////

void HQAAMovc(bool2 cond, inout float2 variable, float2 value)
{
    [flatten] if (cond.x) variable.x = value.x;
    [flatten] if (cond.y) variable.y = value.y;
}
void HQAAMovc(bool4 cond, inout float4 variable, float4 value)
{
    HQAAMovc(cond.xy, variable.xy, value.xy);
    HQAAMovc(cond.zw, variable.zw, value.zw);
}

float2 HQAADecodeDiagBilinearAccess(float2 e)
{
    e.r = e.r * abs(5.0 * e.r - 5.0 * 0.75);
    return round(e);
}
float4 HQAADecodeDiagBilinearAccess(float4 e)
{
    e.rb = e.rb * abs(5.0 * e.rb - 5.0 * 0.75);
    return round(e);
}

float2 HQAASearchDiag(sampler2D HQAAedgesTex, float2 texcoord, float2 dir, out float2 e)
{
    float4 coord = float4(texcoord, -1.0, 1.0);
    float3 t = float3(__HQAA_SM_BUFFERINFO.xy, 1.0);
    [loop] while (coord.z < 20.0) 
	{
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);
        e = tex2Dlod(HQAAedgesTex, coord.xyxy).rg;
        coord.w = dot(e, float(0.5).xx);
        if (coord.w < 0.9) break;
    }
    return coord.zw;
}

float2 HQAAAreaDiag(sampler2D HQAAareaTex, float2 dist, float2 e)
{
    float2 texcoord = mad(float(__HQAA_SM_AREATEX_RANGE_DIAG).xx, e, dist);

    texcoord = mad(__HQAA_SM_AREATEX_TEXEL, texcoord, 0.5 * __HQAA_SM_AREATEX_TEXEL);
    texcoord.x += 0.5;

    return tex2Dlod(HQAAareaTex, texcoord.xyxy).rg;
}

float2 HQAACalculateDiagWeights(sampler2D HQAAedgesTex, sampler2D HQAAareaTex, float2 texcoord, float2 e)
{
    float2 weights = float(0.0).xx;
    float2 end;
    float4 d;
    d.ywxz = float4(HQAASearchDiag(HQAAedgesTex, texcoord, float2(1.0, -1.0), end), 0.0, 0.0);
    
    if (e.r > 0.0) 
	{
        d.xz = HQAASearchDiag(HQAAedgesTex, texcoord, float2(-1.0,  1.0), end);
        d.x += float(end.y > 0.9);
    }
	
	if (d.x + d.y > 2.0) 
	{
        float4 coords = mad(float4(-d.x + 0.25, d.x, d.y, -d.y - 0.25), __HQAA_SM_BUFFERINFO.xyxy, texcoord.xyxy);
        float4 c;
        c.xy = tex2Dlodoffset(HQAAedgesTex, coords.xyxy, int2(-1,  0)).rg;
        c.zw = tex2Dlodoffset(HQAAedgesTex, coords.zwzw, int2( 1,  0)).rg;
        c.yxwz = HQAADecodeDiagBilinearAccess(c.xyzw);

        float2 cc = mad(float(2.0).xx, c.xz, c.yw);

        HQAAMovc(bool2(step(0.9, d.zw)), cc, float(0.0).xx);

        weights += HQAAAreaDiag(HQAAareaTex, d.xy, cc);
    }

    d.xz = HQAASearchDiag(HQAAedgesTex, texcoord, float2(-1.0, -1.0), end);
    d.yw = float(0.0).xx;
    
    if (HQAA_Tex2DOffset(HQAAedgesTex, texcoord, int2(1, 0)).r > 0.0) 
	{
        d.yw = HQAASearchDiag(HQAAedgesTex, texcoord, float(1.0).xx, end);
        d.y += float(end.y > 0.9);
    }
	
	if (d.x + d.y > 2.0) 
	{
        float4 coords = mad(float4(-d.x, -d.x, d.y, d.y), __HQAA_SM_BUFFERINFO.xyxy, texcoord.xyxy);
        float4 c;
        c.x  = tex2Dlodoffset(HQAAedgesTex, coords.xyxy, int2(-1,  0)).g;
        c.y  = tex2Dlodoffset(HQAAedgesTex, coords.xyxy, int2( 0, -1)).r;
        c.zw = tex2Dlodoffset(HQAAedgesTex, coords.zwzw, int2( 1,  0)).gr;
        float2 cc = mad(float(2.0).xx, c.xz, c.yw);

        HQAAMovc(bool2(step(0.9, d.zw)), cc, float(0.0).xx);

        weights += HQAAAreaDiag(HQAAareaTex, d.xy, cc).gr;
    }

    return weights;
}

float HQAASearchLength(sampler2D HQAAsearchTex, float2 e, float offset)
{
    float2 scale = __HQAA_SM_SEARCHTEX_SIZE * float2(0.5, -1.0);
    float2 bias = __HQAA_SM_SEARCHTEX_SIZE * float2(offset, 1.0);

    scale += float2(-1.0,  1.0);
    bias  += float2( 0.5, -0.5);

    scale *= 1.0 / __HQAA_SM_SEARCHTEX_SIZE_PACKED;
    bias *= 1.0 / __HQAA_SM_SEARCHTEX_SIZE_PACKED;

    return tex2Dlod(HQAAsearchTex, mad(scale, e, bias).xyxy).r;
}

float HQAASearchXLeft(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end)
{
    float2 e = float2(0.0, 1.0);
    [loop] while (texcoord.x > end) 
	{
        e = tex2Dlod(HQAAedgesTex, texcoord.xyxy).rg;
        texcoord = mad(-float2(2.0, 0.0), __HQAA_SM_BUFFERINFO.xy, texcoord);
        if (e.r > 0.0) break;
    }
    float offset = mad(-2.007874, HQAASearchLength(HQAAsearchTex, e, 0.0), 3.25); // -(255/127)
    return mad(__HQAA_SM_BUFFERINFO.x, offset, texcoord.x);
}
float HQAASearchXRight(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end)
{
    float2 e = float2(0.0, 1.0);
    [loop] while (texcoord.x < end) 
	{
        e = tex2Dlod(HQAAedgesTex, texcoord.xyxy).rg;
        texcoord = mad(float2(2.0, 0.0), __HQAA_SM_BUFFERINFO.xy, texcoord);
        if (e.r > 0.0) break;
    }
    float offset = mad(-2.007874, HQAASearchLength(HQAAsearchTex, e, 0.5), 3.25);
    return mad(-__HQAA_SM_BUFFERINFO.x, offset, texcoord.x);
}
float HQAASearchYUp(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end)
{
    float2 e = float2(1.0, 0.0);
    [loop] while (texcoord.y > end) 
	{
        e = tex2Dlod(HQAAedgesTex, texcoord.xyxy).rg;
        texcoord = mad(-float2(0.0, 2.0), __HQAA_SM_BUFFERINFO.xy, texcoord);
        if (e.g > 0.0) break;
    }
    float offset = mad(-2.007874, HQAASearchLength(HQAAsearchTex, e.gr, 0.0), 3.25);
    return mad(__HQAA_SM_BUFFERINFO.y, offset, texcoord.y);
}
float HQAASearchYDown(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end)
{
    float2 e = float2(1.0, 0.0);
    [loop] while (texcoord.y < end) 
	{
        e = tex2Dlod(HQAAedgesTex, texcoord.xyxy).rg;
        texcoord = mad(float2(0.0, 2.0), __HQAA_SM_BUFFERINFO.xy, texcoord);
        if (e.g > 0.0) break;
    }
    float offset = mad(-2.007874, HQAASearchLength(HQAAsearchTex, e.gr, 0.5), 3.25);
    return mad(-__HQAA_SM_BUFFERINFO.y, offset, texcoord.y);
}

float2 HQAAArea(sampler2D HQAAareaTex, float2 dist, float e1, float e2)
{
    float2 texcoord = mad(float(__HQAA_SM_AREATEX_RANGE).xx, 4.0 * float2(e1, e2), dist);
    
    texcoord = mad(__HQAA_SM_AREATEX_TEXEL, texcoord, 0.5 * __HQAA_SM_AREATEX_TEXEL);

    return tex2Dlod(HQAAareaTex, texcoord.xyxy).rg;
}

void HQAADetectHorizontalCornerPattern(sampler2D HQAAedgesTex, inout float2 weights, float4 texcoord, float2 d)
{
    float2 leftRight = step(d.xy, d.yx);
    float2 rounding = (1.0 - __HQAA_SM_CORNERS) * leftRight;

    float2 factor = float(1.0).xx;
    factor.x -= rounding.x * tex2Dlodoffset(HQAAedgesTex, texcoord.xyxy, int2(0,  1)).r;
    factor.x -= rounding.y * tex2Dlodoffset(HQAAedgesTex, texcoord.zwzw, int2(1,  1)).r;
    factor.y -= rounding.x * tex2Dlodoffset(HQAAedgesTex, texcoord.xyxy, int2(0, -2)).r;
    factor.y -= rounding.y * tex2Dlodoffset(HQAAedgesTex, texcoord.zwzw, int2(1, -2)).r;

    weights *= saturate(factor);
}
void HQAADetectVerticalCornerPattern(sampler2D HQAAedgesTex, inout float2 weights, float4 texcoord, float2 d)
{
    float2 leftRight = step(d.xy, d.yx);
    float2 rounding = (1.0 - __HQAA_SM_CORNERS) * leftRight;

    float2 factor = float(1.0).xx;
    factor.x -= rounding.x * tex2Dlodoffset(HQAAedgesTex, texcoord.xyxy, int2( 1, 0)).g;
    factor.x -= rounding.y * tex2Dlodoffset(HQAAedgesTex, texcoord.zwzw, int2( 1, 1)).g;
    factor.y -= rounding.x * tex2Dlodoffset(HQAAedgesTex, texcoord.xyxy, int2(-2, 0)).g;
    factor.y -= rounding.y * tex2Dlodoffset(HQAAedgesTex, texcoord.zwzw, int2(-2, 1)).g;

    weights *= saturate(factor);
}

/////////////////////////////////////////////////// OPTIONAL HELPER FUNCTIONS /////////////////////////////////////////////////////////////

#if HQAA_OPTIONAL_EFFECTS
#if HQAA_OPTIONAL__DEBANDING
float permute(float x)
{
    return ((34.0 * x + 1.0) * x) % 289.0;
}
float permute(float2 x)
{
	float factor = (x.x + x.y) / 2.0;
    return ((34.0 * factor + 1.0) * factor) % 289.0;
}
float permute(float3 x)
{
	float factor = (x.x + x.y + x.z) / 3.0;
    return ((34.0 * factor + 1.0) * factor) % 289.0;
}
#endif //HQAA_OPTIONAL__DEBANDING
#endif //HQAA_OPTIONAL_EFFECTS

////////////////////////////////////////////////////////// TONE MAPPERS ///////////////////////////////////////////////////////////////////

#if HQAA_OPTIONAL_EFFECTS
float3 tonemap_adjustluma(float3 x, float xl_out)
{
	float xl = dot(x, __HQAA_LUMA_REF);
	return x * (xl_out / xl);
}

float3 reinhard_jodie(float3 x)
{
	float xl = dot(x, __HQAA_LUMA_REF);
	float3 xv = x / (1.0 + x);
	return lerp(x / (1.0 + xl), xv, xv);
}

float3 reinhard(float3 x)
{
	return x / (1.0 + x);
}

float3 extended_reinhard(float3 x)
{
	float whitepoint = 1.0;
	float3 numerator = x * (1.0 + (x / (whitepoint * whitepoint)));
	return numerator / (1.0 + x);
}

float3 extended_reinhard_luma(float3 x)
{
	float whitepoint = 1.0;
	float xl = dot(x, __HQAA_LUMA_REF);
	float numerator = xl * (1.0 + (xl / (whitepoint * whitepoint)));
	float xl_shift = numerator / (1.0 + xl);
	return tonemap_adjustluma(x, xl_shift);
}

float3 uncharted2_partial(float3 x)
{
	float A = 0.15;
	float B = 0.5;
	float C = 0.1;
	float D = 0.2;
	float E = 0.02;
	float F = 0.3;
	
	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

float3 uncharted2_filmic(float3 x)
{
	float exposure_bias = 2.0;
	float3 curr = uncharted2_partial(x * exposure_bias);
	float3 whitescale = 1.0 / uncharted2_partial(float(11.2).xxx);
	return curr * whitescale;
}

float3 aces_approx(float3 x)
{
	float3 xout = x * 0.6;
	float A = 2.51;
	float B = 0.03;
	float C = 2.43;
	float D = 0.59;
	float E = 0.14;
	
	return saturate((xout*(A*xout+B))/(xout*(C*xout+D)+E));
}
#endif //HQAA_OPTIONAL_EFFECTS

/***************************************************************************************************************************************/
/******************************************************** SUPPORT CODE END *************************************************************/
/***************************************************************************************************************************************/

/***************************************************************************************************************************************/
/*********************************************************** SHADER SETUP START ********************************************************/
/***************************************************************************************************************************************/

#include "ReShade.fxh"


//////////////////////////////////////////////////////////// TEXTURES ///////////////////////////////////////////////////////////////////

texture HQAAedgesTex
#if __RESHADE__ >= 50000
< pooled = true; >
#endif
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA8;
};

texture HQAAlastedgesTex
#if __RESHADE__ < 50000
< pooled = false; >
#endif
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA8;
};

texture HQAAblendTex
#if __RESHADE__ >= 50000
< pooled = true; >
#endif
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;

#if BUFFER_COLOR_BIT_DEPTH == 10
	Format = RGB10A2;
#elif BUFFER_COLOR_BIT_DEPTH > 8
	Format = RGBA16F;
#else
	Format = RGBA8;
#endif
};

texture HQAAareaTex < source = "AreaTex.png"; >
{
	Width = 160;
	Height = 560;
	Format = RG8;
};

texture HQAAsearchTex < source = "SearchTex.png"; >
{
	Width = 64;
	Height = 16;
	Format = R8;
};

#if HQAA_OPTIONAL_EFFECTS
#if HQAA_OPTIONAL__TEMPORAL_STABILIZER
texture HQAAstabilizerTex
#if __RESHADE__ < 50000
< pooled = false; >
#endif
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
#if BUFFER_COLOR_BIT_DEPTH == 10
	Format = RGB10A2;
#elif BUFFER_COLOR_BIT_DEPTH > 8
	Format = RGBA16F;
#else
	Format = RGBA8;
#endif
};
#endif //HQAA_OPTIONAL__TEMPORAL_STABILIZER
#endif //HQAA_OPTIONAL_EFFECTS

#if HQAA_TAA_ASSIST_MODE
texture HQAApreviousLumaTex
#if __RESHADE__ >= 50000
< pooled = true; >
#endif
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = R16F;
};

texture HQAAlumaMaskTex
#if __RESHADE__ >= 50000
< pooled = true; >
#endif
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = R8;
};
#endif //HQAA_TAA_ASSIST_MODE

//////////////////////////////////////////////////////////// SAMPLERS ///////////////////////////////////////////////////////////////////

sampler HQAAsamplerAlphaEdges
{
	Texture = HQAAedgesTex;
};

sampler HQAAsamplerLastEdges
{
	Texture = HQAAlastedgesTex;
};

sampler HQAAsamplerSMweights
{
	Texture = HQAAblendTex;
};

sampler HQAAsamplerSMarea
{
	Texture = HQAAareaTex;
};

sampler HQAAsamplerSMsearch
{
	Texture = HQAAsearchTex;
	MipFilter = Point; MinFilter = Point; MagFilter = Point;
};

#if HQAA_OPTIONAL_EFFECTS
#if HQAA_OPTIONAL__TEMPORAL_STABILIZER
sampler HQAAsamplerLastFrame
{
	Texture = HQAAstabilizerTex;
};
#endif //HQAA_OPTIONAL__TEMPORAL_STABILIZER
#endif //HQAA_OPTIONAL_EFFECTS

#if HQAA_TAA_ASSIST_MODE
sampler HQAAsamplerPreviousLuma
{
	Texture = HQAApreviousLumaTex;
	MipFilter = Point; MinFilter = Point; MagFilter = Point;
};

sampler HQAAsamplerLumaMask
{
	Texture = HQAAlumaMaskTex;
	MipFilter = Point; MinFilter = Point; MagFilter = Point;
};
#endif //HQAA_TAA_ASSIST_MODE

//////////////////////////////////////////////////////////// VERTEX SHADERS /////////////////////////////////////////////////////////////

void HQAAEdgeDetectionVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0, out float4 offset[3] : TEXCOORD1)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    offset[0] = mad(__HQAA_SM_BUFFERINFO.xyxy, float4(-1.0, 0.0, 0.0, -1.0), texcoord.xyxy);
    offset[1] = mad(__HQAA_SM_BUFFERINFO.xyxy, float4( 1.0, 0.0, 0.0,  1.0), texcoord.xyxy);
    offset[2] = mad(__HQAA_SM_BUFFERINFO.xyxy, float4(-2.0, 0.0, 0.0, -2.0), texcoord.xyxy);
}

void HQAABlendingWeightCalculationVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0, out float2 pixcoord : TEXCOORD1, out float4 offset[3] : TEXCOORD2)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    pixcoord = texcoord * __HQAA_SM_BUFFERINFO.zw;

    offset[0] = mad(__HQAA_SM_BUFFERINFO.xyxy, float4(-0.25, -0.125,  1.25, -0.125), texcoord.xyxy);
    offset[1] = mad(__HQAA_SM_BUFFERINFO.xyxy, float4(-0.125, -0.25, -0.125,  1.25), texcoord.xyxy);
	
	float searchrange = __HQAA_SM_RADIUS;
	
    offset[2] = mad(__HQAA_SM_BUFFERINFO.xxyy,
                    float2(-2.0, 2.0).xyxy * searchrange,
                    float4(offset[0].xz, offset[1].yw));
}

void HQAANeighborhoodBlendingVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0, out float4 offset : TEXCOORD1)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    offset = mad(__HQAA_SM_BUFFERINFO.xyxy, float4( 1.0, 0.0, 0.0,  1.0), texcoord.xyxy);
}

/*****************************************************************************************************************************************/
/*********************************************************** SHADER SETUP END ************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/********************************************************** SMAA SHADER CODE START *******************************************************/
/*****************************************************************************************************************************************/

//////////////////////////////////////////////////////// EDGE DETECTION ///////////////////////////////////////////////////////////////////
float4 HQAAHybridEdgeDetectionPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float4 offset[3] : TEXCOORD1) : SV_Target
{
	if ((HqaaSourceInterpolation == 1) && __HQAA_ALT_FRAME) discard;
	if ((HqaaSourceInterpolation == 2) && !__HQAA_QUAD_FRAME) discard;
	
	float3 middle = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord).rgb;
	
#if HQAA_TAA_ASSIST_MODE
	bool lumachange = HQAA_Tex2D(HQAAsamplerLumaMask, texcoord).r > 0.0;
	if (!lumachange) return float(0.0).xxxx;
#endif //HQAA_TAA_ASSIST_MODE

    float L = dot(middle, __HQAA_LUMA_REF);
    bool useluma = L > dotsat(middle);
    
	float rangemult = 1.0 - log2(1.0 + clamp(sqrt(L), 0.0, HqaaLowLumaThreshold) * rcp(HqaaLowLumaThreshold));
	float edgethreshold = __HQAA_EDGE_THRESHOLD;
	edgethreshold = mad(rangemult, -(__HQAA_DYNAMIC_RANGE * edgethreshold), edgethreshold);
    if (!useluma) L = 0.0;
	
	float2 edges = float(0.0).xx;
	
	float3 neighbor = HQAA_DecodeTex2D(ReShade::BackBuffer, offset[0].xy).rgb;
	float3 Dleft = abs(middle - neighbor);
    float Lleft = dotweight(middle, neighbor, useluma, __HQAA_LUMA_REF);
    
	neighbor = HQAA_DecodeTex2D(ReShade::BackBuffer, offset[0].zw).rgb;
	float3 Dtop = abs(middle - neighbor);
    float Ltop = dotweight(middle, neighbor, useluma, __HQAA_LUMA_REF);
    
    neighbor = HQAA_DecodeTex2D(ReShade::BackBuffer, offset[1].xy).rgb;
	float3 Dright = abs(middle - neighbor);
    float Lright = dotweight(middle, neighbor, useluma, __HQAA_LUMA_REF);
	
	neighbor = HQAA_DecodeTex2D(ReShade::BackBuffer, offset[1].zw).rgb;
	float3 Dbottom = abs(middle - neighbor);
	float Lbottom = dotweight(middle, neighbor, useluma, __HQAA_LUMA_REF);
	
	float maxL = HQAAmax4(Lleft, Ltop, Lright, Lbottom);
	float4 delta = abs(L - float4(Lleft, Ltop, Lright, Lbottom));
	
	float3 adaptationaverage = (Dleft + Dtop + Dright + Dbottom - HQAAmax4(Dleft, Dtop, Dright, Dbottom)) / 3.0;
	
	// scale always has a range of 1 to e regardless of the bit depth.
	float scale = 0.5 + pow(clamp(log(rcp(dot(adaptationaverage, __HQAA_AVERAGE_REF))), 1.0, BUFFER_COLOR_BIT_DEPTH), rcp(log(BUFFER_COLOR_BIT_DEPTH)));
	
	edges = step(edgethreshold, scale * delta.xy);
	if (!any(edges)) return float4(edges, HQAA_Tex2D(HQAAsamplerLastEdges, texcoord).rg);
	
    float2 maxDelta = max(delta.xy, delta.zw);
	
	neighbor = HQAA_DecodeTex2D(ReShade::BackBuffer, offset[2].xy).rgb;
	float3 Dleftleft = abs(middle - neighbor);
	float Lleftleft = dotweight(middle, neighbor, useluma, __HQAA_LUMA_REF);
	
	neighbor = HQAA_DecodeTex2D(ReShade::BackBuffer, offset[2].zw).rgb;
	float3 Dtoptop = abs(middle - neighbor);
	float Ltoptop = dotweight(middle, neighbor, useluma, __HQAA_LUMA_REF);
	
	delta.zw = abs(float2(Lleft, Ltop) - float2(Lleftleft, Ltoptop));
	maxDelta = max(maxDelta, delta.zw);
	float finalDelta = max(maxDelta.x, maxDelta.y);
	
	adaptationaverage = (adaptationaverage + Dleftleft + Dtoptop - HQAAmin3(Dleftleft, Dtoptop, adaptationaverage)) / 2.0;
	
	// scale always has a range of 1 to e regardless of the bit depth.
	scale = 0.5 + pow(clamp(log(rcp(dot(adaptationaverage, __HQAA_AVERAGE_REF))), 1.0, BUFFER_COLOR_BIT_DEPTH), rcp(log(BUFFER_COLOR_BIT_DEPTH)));
	
	edges *= step(finalDelta, scale * delta.xy);
	return float4(edges, HQAA_Tex2D(HQAAsamplerLastEdges, texcoord).rg);
}

//////////////////////////////////////////////////// TEMPORAL AGGREGATION /////////////////////////////////////////////////////////////////
float4 HQAAEdgeTemporalAggregationPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	if ((HqaaSourceInterpolation == 1) && __HQAA_ALT_FRAME) discard;
	if ((HqaaSourceInterpolation == 2) && !__HQAA_QUAD_FRAME) discard;
	
	float3 pixel = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord).rgb;
	float2 bufferdata = float2(dot(pixel, __HQAA_LUMA_REF), 0.0);
	float2 edges;
	if (clamp(HqaaEdgeTemporalAggregation, 0, 1) == HqaaEdgeTemporalAggregation) edges = saturate(HQAA_Tex2D(HQAAsamplerSMweights, texcoord).rg + saturate(HQAA_Tex2D(HQAAsamplerSMweights, texcoord).ba + HQAA_Tex2D(HQAAsamplerLastEdges, texcoord).ba - HqaaEdgeTemporalAggregation));
	else edges = saturate(HQAA_Tex2D(HQAAsamplerSMweights, texcoord).rg + HQAA_Tex2D(HQAAsamplerSMweights, texcoord).ba + HQAA_Tex2D(HQAAsamplerLastEdges, texcoord).ba - HqaaEdgeTemporalAggregation);
	
	return float4(edges, bufferdata);
}

//////////////////////////////////////////////////////// N-1 EDGES COPY ///////////////////////////////////////////////////////////////////
float4 HQAASavePreviousEdgesPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	if ((HqaaSourceInterpolation == 1) && __HQAA_ALT_FRAME) discard;
	if ((HqaaSourceInterpolation == 2) && !__HQAA_QUAD_FRAME) discard;
	
	return HQAA_Tex2D(HQAAsamplerSMweights, texcoord);
}

/////////////////////////////////////////////////// BLEND WEIGHT CALCULATION //////////////////////////////////////////////////////////////

float4 HQAABlendingWeightCalculationPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float2 pixcoord : TEXCOORD1, float4 offset[3] : TEXCOORD2) : SV_Target
{
#if HQAA_TAA_ASSIST_MODE
	bool lumachange = HQAA_Tex2D(HQAAsamplerLumaMask, texcoord).r > 0.0;
	if (!lumachange) return float(0.0).xxxx;
#endif //HQAA_TAA_ASSIST_MODE

    float4 weights = float(0.0).xxxx;
    float2 e = HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord).rg;
	if (e.g > 0.0) 
	{
        weights.rg = HQAACalculateDiagWeights(HQAAsamplerAlphaEdges, HQAAsamplerSMarea, texcoord, e);
        if (weights.r == -weights.g)
        {
       	 float3 coords = float3(HQAASearchXLeft(HQAAsamplerAlphaEdges, HQAAsamplerSMsearch, offset[0].xy, offset[2].x), offset[1].y, HQAASearchXRight(HQAAsamplerAlphaEdges, HQAAsamplerSMsearch, offset[0].zw, offset[2].y));
      	  float e1 = HQAA_Tex2D(HQAAsamplerAlphaEdges, coords.xy).r;
			float2 d = coords.xz;
       	 d = abs((mad(__HQAA_SM_BUFFERINFO.zz, d, -pixcoord.xx)));
      	  float e2 = HQAA_Tex2DOffset(HQAAsamplerAlphaEdges, coords.zy, int2(1, 0)).r;
     	   weights.rg = HQAAArea(HQAAsamplerSMarea, sqrt(d), e1, e2);
      	  coords.y = texcoord.y;
     	   HQAADetectHorizontalCornerPattern(HQAAsamplerAlphaEdges, weights.rg, coords.xyzy, d);
        }
        else e.r = 0.0;
    }
	if (e.r > 0.0) 
	{
        float3 coords = float3(offset[0].x, HQAASearchYUp(HQAAsamplerAlphaEdges, HQAAsamplerSMsearch, offset[1].xy, offset[2].z), HQAASearchYDown(HQAAsamplerAlphaEdges, HQAAsamplerSMsearch, offset[1].zw, offset[2].w));
        float e1 = HQAA_Tex2D(HQAAsamplerAlphaEdges, coords.xy).g;
		float2 d = coords.yz;
        d = abs((mad(__HQAA_SM_BUFFERINFO.ww, d, -pixcoord.yy)));
        float e2 = HQAA_Tex2DOffset(HQAAsamplerAlphaEdges, coords.xz, int2(0, 1)).g;
        weights.ba = HQAAArea(HQAAsamplerSMarea, sqrt(d), e1, e2);
        coords.x = texcoord.x;
        HQAADetectVerticalCornerPattern(HQAAsamplerAlphaEdges, weights.ba, coords.xyxz, d);
    }
    return weights;
}

//////////////////////////////////////////////////// NEIGHBORHOOD BLENDING ////////////////////////////////////////////////////////////////

float3 HQAANeighborhoodBlendingPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float4 offset : TEXCOORD1) : SV_Target
{
    float4 m = float4(HQAA_Tex2D(HQAAsamplerSMweights, offset.xy).a, HQAA_Tex2D(HQAAsamplerSMweights, offset.zw).g, HQAA_Tex2D(HQAAsamplerSMweights, texcoord).zx);
	float3 resultAA = HQAA_Tex2D(ReShade::BackBuffer, texcoord).rgb;
	[branch] if (any(m))
	{
		resultAA = ConditionalDecode(resultAA);
        bool horiz = max(m.x, m.z) > max(m.y, m.w);
        float4 blendingOffset = float4(0.0, m.y, 0.0, m.w);
        float2 blendingWeight = m.yw;
        HQAAMovc(bool(horiz).xxxx, blendingOffset, float4(m.x, 0.0, m.z, 0.0));
        HQAAMovc(bool(horiz).xx, blendingWeight, m.xz);
        blendingWeight /= dot(blendingWeight, float(1.0).xx);
        float4 blendingCoord = mad(blendingOffset, float4(__HQAA_SM_BUFFERINFO.xy, -__HQAA_SM_BUFFERINFO.xy), texcoord.xyxy);
        resultAA = blendingWeight.x * HQAA_DecodeTex2D(ReShade::BackBuffer, blendingCoord.xy).rgb;
        resultAA += blendingWeight.y * HQAA_DecodeTex2D(ReShade::BackBuffer, blendingCoord.zw).rgb;
		resultAA = ConditionalEncode(resultAA);
    }
	return resultAA;
}

/***************************************************************************************************************************************/
/********************************************************** SMAA SHADER CODE END *******************************************************/
/***************************************************************************************************************************************/

/***************************************************************************************************************************************/
/********************************************************** FXAA SHADER CODE START *****************************************************/
/***************************************************************************************************************************************/

float3 HQAAFXPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
 {
    float3 original = HQAA_Tex2D(ReShade::BackBuffer, texcoord).rgb;
	
#if HQAA_TAA_ASSIST_MODE
	bool lumachange = HQAA_Tex2D(HQAAsamplerLumaMask, texcoord).r > 0.0;
	if (lumachange) {
#endif //HQAA_TAA_ASSIST_MODE

	float3 middle = ConditionalDecode(original);
	float lumaM = dot(middle, __HQAA_NORMAL_REF);
	float satM = dotsat(middle);
	bool useluma = lumaM > satM;
	float rangemult = 1.0 - log2(1.0 + clamp(sqrt(lumaM), 0.0, HqaaLowLumaThreshold) * rcp(HqaaLowLumaThreshold));
	float edgethreshold = __HQAA_EDGE_THRESHOLD;
	edgethreshold = mad(rangemult, -(__HQAA_DYNAMIC_RANGE * edgethreshold), edgethreshold);
	if (!useluma) lumaM = 0.0;
	
    float lumaS = dotweight(middle, HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 0, 1)).rgb, useluma, __HQAA_NORMAL_REF);
    float lumaE = dotweight(middle, HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 1, 0)).rgb, useluma, __HQAA_NORMAL_REF);
    float lumaN = dotweight(middle, HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 0,-1)).rgb, useluma, __HQAA_NORMAL_REF);
    float lumaW = dotweight(middle, HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, 0)).rgb, useluma, __HQAA_NORMAL_REF);
    
    float rangeMax = HQAAmax5(lumaS, lumaE, lumaN, lumaW, lumaM);
    float rangeMin = HQAAmin5(lumaS, lumaE, lumaN, lumaW, lumaM);
    float range = rangeMax - rangeMin;
    
	// early exit check
	if (HqaaFxEarlyExit && (!any(HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord).rg)) && (range < edgethreshold))
#if HQAA_DEBUG_MODE
		if (clamp(HqaaDebugMode, 3, 5) == HqaaDebugMode) return float(0.0).xxx;
		else
#endif //HQAA_DEBUG_MODE
		return original;
	
    float lumaNW = dotweight(middle, HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1,-1)).rgb, useluma, __HQAA_NORMAL_REF);
    float lumaSE = dotweight(middle, HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 1, 1)).rgb, useluma, __HQAA_NORMAL_REF);
    float lumaNE = dotweight(middle, HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 1,-1)).rgb, useluma, __HQAA_NORMAL_REF);
    float lumaSW = dotweight(middle, HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, 1)).rgb, useluma, __HQAA_NORMAL_REF);
	
    bool horzSpan = (abs(mad(-2.0, lumaW, lumaNW + lumaSW)) + mad(2.0, abs(mad(-2.0, lumaM, lumaN + lumaS)), abs(mad(-2.0, lumaE, lumaNE + lumaSE)))) >= (abs(mad(-2.0, lumaS, lumaSW + lumaSE)) + mad(2.0, abs(mad(-2.0, lumaM, lumaW + lumaE)), abs(mad(-2.0, lumaN, lumaNW + lumaNE))));	
    float lengthSign = horzSpan ? BUFFER_RCP_HEIGHT : BUFFER_RCP_WIDTH;
	
	float2 lumaNP = float2(lumaN, lumaS);
	HQAAMovc(bool(!horzSpan).xx, lumaNP, float2(lumaW, lumaE));
    float gradientN = abs(lumaNP.x - lumaM);
    float gradientS = abs(lumaNP.y - lumaM);
    float lumaNN = lumaNP.x + lumaM;
    if (gradientN >= gradientS) lengthSign = -lengthSign;
    else lumaNN = lumaNP.y + lumaM;
    float gradientScaled = max(gradientN, gradientS) * 0.25;
    bool lumaMLTZero = mad(0.5, -lumaNN, lumaM) < 0.0;
	
    float2 posB = texcoord;
	float texelsize = __HQAA_FX_TEXEL;
    float2 offNP = float2(0.0, BUFFER_RCP_HEIGHT * texelsize);
	HQAAMovc(bool(horzSpan).xx, offNP, float2(BUFFER_RCP_WIDTH * texelsize, 0.0));
	HQAAMovc(bool2(!horzSpan, horzSpan), posB, float2(posB.x + lengthSign / 2.0, posB.y + lengthSign / 2.0));
    float2 posN = posB - offNP;
    float2 posP = posB + offNP;
    float lumaEndN = dotweight(middle, HQAA_DecodeTex2D(ReShade::BackBuffer, posN).rgb, useluma, __HQAA_NORMAL_REF);
    float lumaEndP = dotweight(middle, HQAA_DecodeTex2D(ReShade::BackBuffer, posP).rgb, useluma, __HQAA_NORMAL_REF);
	
	lumaNN *= 0.5;
    lumaEndN -= lumaNN;
    lumaEndP -= lumaNN;
	
    bool doneN = abs(lumaEndN) >= gradientScaled;
    bool doneP = abs(lumaEndP) >= gradientScaled;
	uint iterations = 0;
	uint maxiterations = __HQAA_FX_QUALITY;
	
	[loop] while (iterations < maxiterations)
	{
		if (doneN && doneP) break;
		if (!doneN)
		{
			posN -= offNP;
			lumaEndN = dotweight(middle, HQAA_DecodeTex2D(ReShade::BackBuffer, posN).rgb, useluma, __HQAA_NORMAL_REF);
			lumaEndN -= lumaNN;
			doneN = abs(lumaEndN) >= gradientScaled;
		}
		if (!doneP)
		{
			posP += offNP;
			lumaEndP = dotweight(middle, HQAA_DecodeTex2D(ReShade::BackBuffer, posP).rgb, useluma, __HQAA_NORMAL_REF);
			lumaEndP -= lumaNN;
			doneP = abs(lumaEndP) >= gradientScaled;
		}
		iterations++;
    }
	
	float2 dstNP = float2(texcoord.y - posN.y, posP.y - texcoord.y);
	HQAAMovc(bool(horzSpan).xx, dstNP, float2(texcoord.x - posN.x, posP.x - texcoord.x));
    float pixelOffset = mad(-rcp(dstNP.y + dstNP.x), min(dstNP.x, dstNP.y), 0.5);
    float maxblending = __HQAA_FX_BLEND;
    float subpixOut;
    float endluma = (dstNP.x < dstNP.y) ? lumaEndN : lumaEndP;
	if (!(endluma < 0.0 != lumaMLTZero)) // bad span
	{
		subpixOut = mad(mad(2.0, lumaS + lumaE + lumaN + lumaW, lumaNW + lumaSE + lumaNE + lumaSW), 0.083333, -lumaM) * rcp(range); //ABC
		subpixOut = intpow(saturate(mad(-2.0, subpixOut, 3.0) * (subpixOut * subpixOut)), 2.0) * pixelOffset * maxblending * abs(endluma); // DEFGH
	}
	else subpixOut = pixelOffset * maxblending; // good span

    float2 posM = texcoord;
	HQAAMovc(bool2(!horzSpan, horzSpan), posM, float2(posM.x + lengthSign * subpixOut, posM.y + lengthSign * subpixOut));
    
	// output selection
#if HQAA_DEBUG_MODE
	if (HqaaDebugMode == 4)
	{
		return float3(useluma ? (lumaM * 0.75 + 0.25) : (satM * 0.75 + 0.25), lumaM * 0.75 + 0.25, lumaM * 0.75 + 0.25);
	}
	if (HqaaDebugMode == 5)
	{
		// metrics output
		float runtime = float(iterations / maxiterations) * 0.5;
		float3 FxaaMetrics = float3(runtime, 0.5 - runtime, 0.0);
		return FxaaMetrics;
	}
#endif //HQAA_DEBUG_MODE
	// normal output
	return HQAA_Tex2D(ReShade::BackBuffer, posM).rgb;
#if HQAA_TAA_ASSIST_MODE
	}
	else {
#if HQAA_DEBUG_MODE
		if (clamp(HqaaDebugMode, 3, 5) == HqaaDebugMode) return float(0.0).xxx;
		else
#endif
		return original;
	}
#endif //HQAA_TAA_ASSIST_MODE
}

/***************************************************************************************************************************************/
/********************************************************** FXAA SHADER CODE END *******************************************************/
/***************************************************************************************************************************************/

/***************************************************************************************************************************************/
/****************************************************** HYSTERESIS SHADER CODE START ***************************************************/
/***************************************************************************************************************************************/

float3 HQAAHysteresisPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 pixel = HQAA_Tex2D(ReShade::BackBuffer, texcoord).rgb;
	float4 edgedata = HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord);
	
#if HQAA_TAA_ASSIST_MODE
	bool lumachange = HQAA_Tex2D(HQAAsamplerLumaMask, texcoord).r > 0.0;
#endif //HQAA_TAA_ASSIST_MODE

	bool skiphysteresis = ( ((HqaaHysteresisStrength == 0.0) || (!HqaaDoLumaHysteresis)
#if HQAA_TAA_ASSIST_MODE
	|| (!lumachange)
#endif //HQAA_TAA_ASSIST_MODE
	)
#if HQAA_DEBUG_MODE
	&& (HqaaDebugMode == 0)
#endif //HQAA_DEBUG_MODE
	);
	
	if (skiphysteresis) return pixel;
	
	pixel = ConditionalDecode(pixel);

#if HQAA_DEBUG_MODE
	bool modifiedpixel = any(edgedata.rg);
	if (HqaaDebugMode == 6 && !modifiedpixel) return float(0.0).xxx;
	if (HqaaDebugMode == 1) return float3(HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord).rg, 0.0);
	if (HqaaDebugMode == 2) return HQAA_Tex2D(HQAAsamplerSMweights, texcoord).rgb;
	if (HqaaDebugMode == 7) { float alphachannel = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord).a; return saturate(abs(alphachannel)).xxx; }
	float3 AAdot = pixel;
#endif

	float hysteresis = (dot(pixel, __HQAA_LUMA_REF) - edgedata.b) * (HqaaHysteresisStrength / 100.0);
	[branch] if ((abs(hysteresis) > (HqaaHysteresisFudgeFactor / 100.0)) && HqaaDoLumaHysteresis)
	{
		pixel = pow(abs(1.0 + hysteresis) * 2.0, log2(pixel));
	}
	
	//output
#if HQAA_DEBUG_MODE
	if (HqaaDebugMode == 6)
	{
		// hysteresis pattern
		return sqrt(abs(pixel - AAdot));
	}
	else
#endif //HQAA_DEBUG_MODE
	return ConditionalEncode(pixel);
}

/***************************************************************************************************************************************/
/******************************************************* HYSTERESIS SHADER CODE END ****************************************************/
/***************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/****************************************************** SUPPORT SHADER CODE START ********************************************************/
/*****************************************************************************************************************************************/

/////////////////////////////////////////////////// TEMPORAL STABILIZER FRAME COPY ////////////////////////////////////////////////////////
#if HQAA_OPTIONAL_EFFECTS
#if HQAA_OPTIONAL__TEMPORAL_STABILIZER
// optional stabilizer - save previous frame
float3 HQAAGenerateImageCopyPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord).rgb;
}
// optional stabilizer - HFRAA enhancement
float4 HQAAFrameFlipPS(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float Shift = 0.0;
	if(__HQAA_ALT_FRAME && HqaaHighFramerateAssist) Shift = BUFFER_RCP_WIDTH * HqaaHFRJitterStrength;
    return HQAA_Tex2D(ReShade::BackBuffer, texcoord + float2(Shift, 0.0));
}
#endif //HQAA_OPTIONAL__TEMPORAL_STABILIZER
#endif //HQAA_OPTIONAL_EFFECTS

///////////////////////////////////////////////////// TAA ASSIST LUMA HISTOGRAM ///////////////////////////////////////////////////////////
#if HQAA_TAA_ASSIST_MODE
float HQAALumaSnapshotPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return dot(HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord).rgb, __HQAA_LUMA_REF);
}

float HQAALumaMaskingPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float previous = HQAA_Tex2D(HQAAsamplerPreviousLuma, texcoord).r;
	float current = dot(HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord).rgb, __HQAA_LUMA_REF);
	// for some reason this seems to be a good baseline difference
	float mindiff = __HQAA_SMALLEST_COLOR_STEP * BUFFER_COLOR_BIT_DEPTH;
	bool outdata = abs(current - previous) > mindiff;
	return float(outdata);
}
#endif //HQAA_TAA_ASSIST_MODE

/*****************************************************************************************************************************************/
/******************************************************* SUPPORT SHADER CODE END *********************************************************/
/*****************************************************************************************************************************************/

/***************************************************************************************************************************************/
/******************************************************* OPTIONAL SHADER CODE START ****************************************************/
/***************************************************************************************************************************************/

#if HQAA_OPTIONAL_EFFECTS

#if HQAA_OPTIONAL__DEBANDING
float3 HQAADebandPS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 ori = HQAA_Tex2D(ReShade::BackBuffer, texcoord).rgb; // Original pixel
#if HQAA_DEBUG_MODE
	// skip optional effect processing if a debug mode is enabled
	if (HqaaDebugMode == 0) {
#endif
	float3 encodedori = ori;
	ori = ConditionalDecode(ori);
	
	bool earlyExit = (dot(ori, __HQAA_AVERAGE_REF) < (__HQAA_EDGE_THRESHOLD * 0.5)) && (dotsat(ori) < 0.333333) && HqaaDebandIgnoreLowLuma;
	if (HqaaDebandUseSmaaData) earlyExit = earlyExit || any(HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord).rg);
	if (earlyExit) return encodedori;
	
    // Settings
	float pixstep = __HQAA_SMALLEST_COLOR_STEP;
	float edgethreshold = __HQAA_EDGE_THRESHOLD * (4.0 / BUFFER_COLOR_BIT_DEPTH);
#if (__RENDERER__ >= 0x10000 && __RENDERER__ < 0x20000) || (__RENDERER__ >= 0x09000 && __RENDERER__ < 0x0A000)
	float avgdiff, maxdiff, middiff;
	if (HqaaDebandPreset == 1) { avgdiff = 0.6 * pixstep; maxdiff = 1.9 * pixstep; middiff = 1.2 * pixstep; }
	else if (HqaaDebandPreset == 2) { avgdiff = 1.8 * pixstep; maxdiff = 4.0 * pixstep; middiff = 2.0 * pixstep; }
	else if (HqaaDebandPreset == 3) { avgdiff = 3.4 * pixstep; maxdiff = 6.8 * pixstep; middiff = 3.3 * pixstep; }
	else if (HqaaDebandPreset == 4) { avgdiff = 4.9 * pixstep; maxdiff = 9.5 * pixstep; middiff = 4.7 * pixstep; }
	else if (HqaaDebandPreset == 5) { avgdiff = 7.1 * pixstep; maxdiff = 13.3 * pixstep; middiff = 6.3 * pixstep; }
	else { avgdiff = edgethreshold * 0.26; maxdiff = edgethreshold * 0.5; middiff = edgethreshold * 0.24; }
#else
    float avgdiff[6] = {0.26 * edgethreshold, 1.1 * pixstep, 1.8 * pixstep, 3.4 * pixstep, 4.9 * pixstep, 7.1 * pixstep}; // 0.6/255, 1.8/255, 3.4/255
    float maxdiff[6] = {0.5 * edgethreshold, 2.5 * pixstep, 4.0 * pixstep, 6.8 * pixstep, 9.5 * pixstep, 13.3 * pixstep}; // 1.9/255, 4.0/255, 6.8/255
    float middiff[6] = {0.24 * edgethreshold, 1.5 * pixstep, 2.0 * pixstep, 3.3 * pixstep, 4.7 * pixstep, 6.3 * pixstep}; // 1.2/255, 2.0/255, 3.3/255
#endif

    float randomseed = HqaaDebandSeed / 32767.0;
    float h = permute(float2(permute(float2(texcoord.x, randomseed)), permute(float2(texcoord.y, randomseed))));

    float dir = frac(permute(h) / 41.0) * 6.2831853;
    float2 angle = float2(cos(dir), sin(dir));

    float2 dist = frac(h / 41.0) * HqaaDebandRange * BUFFER_PIXEL_SIZE;

    float3 ref = HQAA_DecodeTex2D(ReShade::BackBuffer, (texcoord + dist * angle)).rgb;
    float3 diff = abs(ori - ref);
    float3 ref_max_diff = diff;
    float3 ref_avg = ref;
    float3 ref_mid_diff1 = ref;

    ref = HQAA_DecodeTex2D(ReShade::BackBuffer, (texcoord + dist * -angle)).rgb;
    diff = abs(ori - ref);
    ref_max_diff = max(ref_max_diff, diff);
    ref_avg += ref;
    ref_mid_diff1 = abs(((ref_mid_diff1 + ref) * 0.5) - ori);

    ref = HQAA_DecodeTex2D(ReShade::BackBuffer, (texcoord + dist * float2(-angle.y, angle.x))).rgb;
    diff = abs(ori - ref);
    ref_max_diff = max(ref_max_diff, diff);
    ref_avg += ref;
    float3 ref_mid_diff2 = ref;

    ref = HQAA_DecodeTex2D(ReShade::BackBuffer, (texcoord + dist * float2(angle.y, -angle.x))).rgb;
    diff = abs(ori - ref);
    ref_max_diff = max(ref_max_diff, diff);
    ref_avg += ref;
    ref_mid_diff2 = abs(((ref_mid_diff2 + ref) * 0.5) - ori);

    ref_avg *= 0.25;
    float3 ref_avg_diff = abs(ori - ref_avg);
    
#if (__RENDERER__ >= 0x10000 && __RENDERER__ < 0x20000) || (__RENDERER__ >= 0x09000 && __RENDERER__ < 0x0A000)
    float3 factor = pow(saturate(3.0 * (1.0 - ref_avg_diff  / avgdiff)) *
                            saturate(3.0 * (1.0 - ref_max_diff  / maxdiff)) *
                            saturate(3.0 * (1.0 - ref_mid_diff1 / middiff)) *
                            saturate(3.0 * (1.0 - ref_mid_diff2 / middiff)), 0.1);
#else
    float3 factor = pow(saturate(3.0 * (1.0 - ref_avg_diff  / avgdiff[HqaaDebandPreset])) *
                            saturate(3.0 * (1.0 - ref_max_diff  / maxdiff[HqaaDebandPreset])) *
                            saturate(3.0 * (1.0 - ref_mid_diff1 / middiff[HqaaDebandPreset])) *
                            saturate(3.0 * (1.0 - ref_mid_diff2 / middiff[HqaaDebandPreset])), 0.1);
#endif

    return ConditionalEncode(lerp(ori, ref_avg, factor));
#if HQAA_DEBUG_MODE
	}
	else return ori;
#endif
}
#endif //HQAA_OPTIONAL__DEBANDING

float3 HQAAOptionalEffectPassPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 pixel = HQAA_Tex2D(ReShade::BackBuffer, texcoord).rgb;
#if HQAA_DEBUG_MODE
	// skip optional effect processing if a debug mode is enabled
	if (HqaaDebugMode == 0) {
#endif
	
	if (HqaaEnableSharpening)
	{
		float3 casdot = pixel;
	
		float sharpening = HqaaSharpenerStrength;
	
		if (any(HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord).rg)) sharpening *= (1.0 - HqaaSharpenerClamping);
	
		float3 a = HQAA_Tex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, -1)).rgb;
		float3 c = HQAA_Tex2DOffset(ReShade::BackBuffer, texcoord, int2(1, -1)).rgb;
		float3 g = HQAA_Tex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, 1)).rgb;
		float3 i = HQAA_Tex2DOffset(ReShade::BackBuffer, texcoord, int2(1, 1)).rgb;
		float3 b = HQAA_Tex2DOffset(ReShade::BackBuffer, texcoord, int2(0, -1)).rgb;
		float3 d = HQAA_Tex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, 0)).rgb;
		float3 f = HQAA_Tex2DOffset(ReShade::BackBuffer, texcoord, int2(1, 0)).rgb;
		float3 h = HQAA_Tex2DOffset(ReShade::BackBuffer, texcoord, int2(0, 1)).rgb;
	
		float3 mnRGB = HQAAmin5(d, casdot, f, b, h);
		float3 mnRGB2 = HQAAmin5(mnRGB, a, c, g, i);

		float3 mxRGB = HQAAmax5(d, casdot, f, b, h);
		float3 mxRGB2 = HQAAmax5(mxRGB,a,c,g,i);
	
		casdot = ConditionalDecode(casdot);
		mnRGB = ConditionalDecode(mnRGB);
		mnRGB2 = ConditionalDecode(mnRGB2);
		mxRGB = ConditionalDecode(mxRGB);
		mxRGB2 = ConditionalDecode(mxRGB2);
	
		mnRGB += mnRGB2;
		mxRGB += mxRGB2;
	
		float3 ampRGB = rsqrt(saturate(min(mnRGB, 2.0 - mxRGB) * rcp(mxRGB)));    
		float3 wRGB = -rcp(ampRGB * mad(-3.0, saturate(sharpening * 0.625), 8.0));
		float3 window = (b + d) + (f + h);
	
		float3 outColor = saturate(mad(window, wRGB, casdot) * rcp(mad(4.0, wRGB, 1.0)));
		casdot = lerp(casdot, outColor, sharpening);
	
		pixel = casdot;
	}
	else pixel = ConditionalDecode(pixel); // initially skipped for performance optimization

	if (HqaaEnableBrightnessGain || HqaaEnableColorPalette)
	{
		if ((HqaaGainStrength > 0.0) && HqaaEnableBrightnessGain)
		{
			float3 outdot = pixel;
			float presaturation = dotsat(outdot);
			float preluma = dot(outdot, __HQAA_LUMA_REF);
			float colorgain = 2.0 - log2(HqaaGainStrength + 1.0);
			float channelfloor = __HQAA_SMALLEST_COLOR_STEP;
			outdot = log2(clamp(outdot, channelfloor, 1.0 - channelfloor));
			outdot = pow(abs(colorgain), outdot);
			if (HqaaGainLowLumaCorrection)
			{
				// calculate new black level
				channelfloor = pow(abs(colorgain), log2(channelfloor));
				// calculate reduction strength to apply
				float contrastgain = log(rcp(dot(outdot, __HQAA_LUMA_REF) - channelfloor)) * pow(__HQAA_CONST_E, (1.0 + channelfloor) * __HQAA_CONST_E) * HqaaGainStrength * HqaaGainStrength;
				outdot = pow(abs(2.0 + contrastgain) * 5.0, log10(outdot));
				float lumadelta = dot(outdot, __HQAA_LUMA_REF) - preluma;
				outdot = RGBtoYUV(outdot);
				outdot.x = saturate(outdot.x - lumadelta * channelfloor);
				outdot = YUVtoRGB(outdot);
				float newsat = dotsat(outdot);
				float satadjust = abs(((newsat - presaturation) / 2.0) * (1.0 + HqaaGainStrength)); // compute difference in before/after saturation
				bool adjustsat = satadjust != 0.0;
				if (adjustsat) outdot = AdjustSaturation(outdot, 0.5 + satadjust);
			}
			pixel = outdot;
		}
	
		if ((HqaaVibranceStrength != 50.0) && HqaaEnableColorPalette)
		{
			float3 outdot = pixel;
			outdot = AdjustVibrance(outdot, -((HqaaVibranceStrength / 100.0) - 0.5));
			pixel = outdot;
		}
		
		if ((HqaaSaturationStrength != 0.5) && HqaaEnableColorPalette)
		{
			float3 outdot = AdjustSaturation(pixel, HqaaSaturationStrength);
			pixel = outdot;
		}
		
		if ((HqaaTonemapping > 0) && HqaaEnableColorPalette)
		{
			if (HqaaTonemapping == 1) pixel = reinhard(pixel);
			else if (HqaaTonemapping == 2) pixel = extended_reinhard(pixel);
			else if (HqaaTonemapping == 3) pixel = extended_reinhard_luma(pixel);
			else if (HqaaTonemapping == 4) pixel = reinhard_jodie(pixel);
			else if (HqaaTonemapping == 5) pixel = uncharted2_filmic(pixel);
			else if (HqaaTonemapping == 6) pixel = aces_approx(pixel);
		}
	}

#if HQAA_OPTIONAL__TEMPORAL_STABILIZER
	float3 current = pixel;
	float3 previous = HQAA_Tex2D(HQAAsamplerLastFrame, texcoord).rgb;
	
	// values above 0.9 can produce artifacts or halt frame advancement entirely
	float blendweight = HqaaPreviousFrameWeight;
	if (HqaaTemporalEdgeHinting)
	{
		float4 blendingdata = HQAA_Tex2D(HQAAsamplerSMweights, texcoord);
		blendweight = clamp(blendweight + ((-(1.0 - HqaaPreviousFrameWeight) + saturate(saturate(max(blendingdata.r + blendingdata.b, blendingdata.g + blendingdata.a)) / dot(current, __HQAA_AVERAGE_REF))) * HqaaPreviousFrameWeight), 0.0, 0.75);
	}
	if (HqaaTemporalClamp)
	{
		blendweight = clamp(blendweight * (0.5 + (1.0 + log2(1.0 + dotweight(current, previous, false, __HQAA_AVERAGE_REF)))), 0.0, 0.75);
	}
	pixel = lerp(current, previous, blendweight);
#endif //HQAA_OPTIONAL__TEMPORAL_STABILIZER

	return ConditionalEncode(pixel);
#if HQAA_DEBUG_MODE
	}
	else return pixel;
#endif
}

#if HQAA_OPTIONAL__SOFTENING
float3 HQAASofteningPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0, float4 offset : TEXCOORD1) : SV_Target
{
    float4 m = float4(HQAA_Tex2D(HQAAsamplerSMweights, offset.xy).a, HQAA_Tex2D(HQAAsamplerSMweights, offset.zw).g, HQAA_Tex2D(HQAAsamplerSMweights, texcoord).zx);
    bool horiz = max(m.x, m.z) > max(m.y, m.w);
    bool diag = any(m.xz) && any(m.yw);
	bool lowdetail = !any(m);
	float passdivisor = clamp(HQAA_OPTIONAL__SOFTENING_PASSES, 1.0, 4.0);
	float2 pixstep = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT) * (lowdetail ? (HqaaImageSoftenOffset * rcp(passdivisor)) : HqaaImageSoftenOffset);
	bool highdelta = false;
	
// pattern:
//  e f g
//  h a b
//  i c d
	
	float3 original = HQAA_Tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 a = ConditionalDecode(original);
	float3 b = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2( 1, 0) * pixstep).rgb;
	float3 c = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2( 0, 1) * pixstep).rgb;
	float3 d = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2( 1, 1) * pixstep).rgb;
	float3 e = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(-1,-1) * pixstep).rgb;
	float3 f = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2( 0,-1) * pixstep).rgb;
	float3 g = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2( 1,-1) * pixstep).rgb;
	float3 h = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(-1, 0) * pixstep).rgb;
	float3 i = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(-1, 1) * pixstep).rgb;
	
	if (HqaaSoftenerSpuriousDetection)
	{
		float3 surroundavg = (b + c + d + e + f + g + h + i) / 8.0;
		float middledelta = dotweight(a, surroundavg, false, __HQAA_AVERAGE_REF);
		highdelta = middledelta > HqaaSoftenerSpuriousThreshold;
	}
	
	float3 highterm = float3(0.0, 0.0, 0.0);
	float3 lowterm = float3(1.0, 1.0, 1.0);
	
	float3 diag1;
	float3 diag2;
	float3 square;
	if (diag)
	{
		square = (h + f + c + b) / 4.0;
		diag1 = (e + d) / 2.0;
		diag2 = (g + i) / 2.0;
		highterm = HQAAmax3(highterm, diag1, diag2);
		lowterm = HQAAmin3(lowterm, diag1, diag2);
	}
	else square = (e + g + i + d) / 4.0;
	
	float3 x1;
	float3 x2;
	float3 x3;
	float3 xy1;
	float3 xy2;
	float3 xy3;
	float3 xy4;
	float3 box = (e + f + g + h + b + i + c + d) / 8.0;
	
	if (lowdetail)
	{
		x1 = (f + c) / 2.0;
		x2 = (h + b) / 2.0;
		x3 = (a + e + f + g + h + b + i + c + d) / 9.0;
		xy1 = (e + f + g + b + d) / 5.0;
		xy2 = (g + b + d + c + i) / 5.0;
		xy3 = (d + c + i + h + e) / 5.0;
		xy4 = (i + h + e + f + g) / 5.0;
	}
	else if (!horiz)
	{
		x1 = (e + h + i) / 3.0;
		x2 = (f + c) / 2.0;
		x3 = (g + b + d) / 3.0;
		xy1 = (g + b + c) / 3.0;
		xy2 = (i + h + f) / 3.0;
		xy3 = (d + b + f) / 3.0;
		xy4 = (e + h + c) / 3.0;
	}
	else
	{
		x1 = (e + f + g) / 3.0;
		x2 = (h + b) / 2.0;
		x3 = (i + c + d) / 3.0;
		xy1 = (e + f + b) / 3.0;
		xy2 = (d + c + h) / 3.0;
		xy3 = (g + f + h) / 3.0;
		xy4 = (i + c + b) / 3.0;
	}
	
	highterm = HQAAmax10(x1, x2, x3, xy1, xy2, xy3, xy4, box, square, highterm);
	lowterm = HQAAmin10(x1, x2, x3, xy1, xy2, xy3, xy4, box, square, lowterm);
	
	float3 localavg;
	if (!diag) localavg = ((x1 + x2 + x3 + xy1 + xy2 + xy3 + xy4 + square + box) - (highterm + lowterm)) / 7.0;
	else localavg = ((x1 + x2 + x3 + xy1 + xy2 + xy3 + xy4 + square + box + diag1 + diag2) - (highterm + lowterm)) / 9.0;
	
	return lerp(original, ConditionalEncode(localavg), highdelta ? HqaaSoftenerSpuriousStrength : HqaaImageSoftenStrength);
}

#endif //HQAA_OPTIONAL__SOFTENING
#endif //HQAA_OPTIONAL_EFFECTS

/***************************************************************************************************************************************/
/******************************************************** OPTIONAL SHADER CODE END *****************************************************/
/***************************************************************************************************************************************/

technique HQAA <
	ui_tooltip = "============================================================\n"
				 "Hybrid high-Quality Anti-Aliasing combines techniques of\n"
				 "both SMAA and FXAA to produce best possible image quality\n"
				 "from using both. HQAA uses customized edge detection methods\n"
				 "designed for maximum possible aliasing detection.\n"
				 "============================================================";
>
{
#if HQAA_TAA_ASSIST_MODE
	pass CreateLumaMask
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAALumaMaskingPS;
		RenderTarget = HQAAlumaMaskTex;
		ClearRenderTargets = true;
	}
	pass SaveCurrentLumas
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAALumaSnapshotPS;
		RenderTarget = HQAApreviousLumaTex;
		ClearRenderTargets = true;
	}
#endif //HQAA_TAA_ASSIST_MODE
	pass EdgeDetection
	{
		VertexShader = HQAAEdgeDetectionVS;
		PixelShader = HQAAHybridEdgeDetectionPS;
		RenderTarget = HQAAblendTex;
	}
	pass EdgeTemporalAggregation
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAEdgeTemporalAggregationPS;
		RenderTarget = HQAAedgesTex;
	}
	pass SaveEdges
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAASavePreviousEdgesPS;
		RenderTarget = HQAAlastedgesTex;
	}
	pass SMAABlendCalculation
	{
		VertexShader = HQAABlendingWeightCalculationVS;
		PixelShader = HQAABlendingWeightCalculationPS;
		RenderTarget = HQAAblendTex;
		ClearRenderTargets = true;
	}
	pass SMAABlending
	{
		VertexShader = HQAANeighborhoodBlendingVS;
		PixelShader = HQAANeighborhoodBlendingPS;
	}
	pass FXAA
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAFXPS;
	}
#if HQAA_OPTIONAL_EFFECTS
#if HQAA_OPTIONAL__SOFTENING
	pass ImageSoftening
	{
		VertexShader = HQAANeighborhoodBlendingVS;
		PixelShader = HQAASofteningPS;
	}
#if HQAA_OPTIONAL__SOFTENING_PASSES > 1
	pass ImageSoftening
	{
		VertexShader = HQAANeighborhoodBlendingVS;
		PixelShader = HQAASofteningPS;
	}
#if HQAA_OPTIONAL__SOFTENING_PASSES > 2
	pass ImageSoftening
	{
		VertexShader = HQAANeighborhoodBlendingVS;
		PixelShader = HQAASofteningPS;
	}
#if HQAA_OPTIONAL__SOFTENING_PASSES > 3
	pass ImageSoftening
	{
		VertexShader = HQAANeighborhoodBlendingVS;
		PixelShader = HQAASofteningPS;
	}
#endif //HQAA_OPTIONAL__SOFTENING_PASSES 3
#endif //HQAA_OPTIONAL__SOFTENING_PASSES 2
#endif //HQAA_OPTIONAL__SOFTENING_PASSES 1
#endif //HQAA_OPTIONAL__SOFTENING
#endif //HQAA_OPTIONAL_EFFECTS
#if HQAA_FXAA_MULTISAMPLING > 1
	pass FXAA
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAFXPS;
	}
#if HQAA_FXAA_MULTISAMPLING > 2
	pass FXAA
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAFXPS;
	}
#if HQAA_FXAA_MULTISAMPLING > 3
	pass FXAA
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAFXPS;
	}
#endif //HQAA_USE_MULTISAMPLED_FXAA3
#endif //HQAA_USE_MULTISAMPLED_FXAA2
#endif //HQAA_USE_MULTISAMPLED_FXAA1
#if HQAA_OPTIONAL_EFFECTS
#if HQAA_OPTIONAL__DEBANDING
	pass Deband
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAADebandPS;
	}
#if HQAA_OPTIONAL__DEBANDING_PASSES > 1
	pass Deband
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAADebandPS;
	}
#if HQAA_OPTIONAL__DEBANDING_PASSES > 2
	pass Deband
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAADebandPS;
	}
#if HQAA_OPTIONAL__DEBANDING_PASSES > 3
	pass Deband
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAADebandPS;
	}
#endif //HQAA_OPTIONAL__DEBANDING_PASSES 3
#endif //HQAA_OPTIONAL__DEBANDING_PASSES 2
#endif //HQAA_OPTIONAL__DEBANDING_PASSES 1
#endif //HQAA_OPTIONAL__DEBANDING
#endif //HQAA_OPTIONAL_EFFECTS
	pass Hysteresis
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAHysteresisPS;
	}
#if HQAA_OPTIONAL_EFFECTS
	pass OptionalEffects
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAOptionalEffectPassPS;
	}
#if HQAA_OPTIONAL__TEMPORAL_STABILIZER
	pass HFRAA
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAFrameFlipPS;
	}
	pass SaveCurrentFrame
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAGenerateImageCopyPS;
		RenderTarget = HQAAstabilizerTex;
		ClearRenderTargets = true;
	}
#endif //HQAA_OPTIONAL__TEMPORAL_STABILIZER
#endif //HQAA_OPTIONAL_EFFECTS
}
