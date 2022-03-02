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
 *                        v20.2.2
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

#ifndef HQAA_TARGET_COLOR_SPACE
	#define HQAA_TARGET_COLOR_SPACE 0
#endif //HQAA_TARGET_COLOR_SPACE

#ifndef HQAA_ENABLE_FPS_TARGET
	#define HQAA_ENABLE_FPS_TARGET 0
#endif //HQAA_ENABLE_FPS_TARGET

#ifndef HQAA_COMPILE_DEBUG_CODE
	#define HQAA_COMPILE_DEBUG_CODE 0
#endif //HQAA_COMPILE_DEBUG_CODE

#ifndef HQAA_ENABLE_OPTIONAL_TECHNIQUES
	#define HQAA_ENABLE_OPTIONAL_TECHNIQUES 1
#endif //HQAA_ENABLE_OPTIONAL_TECHNIQUES

#if HQAA_ENABLE_OPTIONAL_TECHNIQUES
	#ifndef HQAA_OPTIONAL_CAS
		#define HQAA_OPTIONAL_CAS 1
	#endif //HQAA_OPTIONAL_CAS
	#ifndef HQAA_OPTIONAL_TEMPORAL_STABILIZER
		#define HQAA_OPTIONAL_TEMPORAL_STABILIZER 0
	#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER
	#ifndef HQAA_OPTIONAL_BRIGHTNESS_GAIN
		#define HQAA_OPTIONAL_BRIGHTNESS_GAIN 0
	#endif //HQAA_OPTIONAL_BRIGHTNESS_GAIN
	#ifndef HQAA_OPTIONAL_DEBAND
		#define HQAA_OPTIONAL_DEBAND 0
	#endif
#endif // HQAA_ENABLE_OPTIONAL_TECHNIQUES

#ifndef HQAA_SCREENSHOT_MODE
	#define HQAA_SCREENSHOT_MODE 0
#endif //HQAA_SCREENSHOT_MODE

#ifndef HQAA_USE_MULTISAMPLED_FXAA
	#define HQAA_USE_MULTISAMPLED_FXAA 1
#endif

#ifndef HQAA_TAA_ASSIST_MODE
	#define HQAA_TAA_ASSIST_MODE 0
#endif

/////////////////////////////////////////////////////// GLOBAL SETUP OPTIONS //////////////////////////////////////////////////////////////

uniform int HQAAintroduction <
	ui_type = "radio";
	ui_label = "Version: 20.2.2";
	ui_text = "-------------------------------------------------------------------------\n"
			"Hybrid high-Quality Anti-Aliasing, a shader by lordbean\n"
			"https://github.com/lordbean-git/HQAA/\n"
			"-------------------------------------------------------------------------\n\n"
			"Currently Compiled Configuration:\n\n"
			#if HQAA_TARGET_COLOR_SPACE == 1
				"Color Space:      HDR nits*\n"
			#elif HQAA_TARGET_COLOR_SPACE == 2
				"Color Space: HDR10 / scRGB*\n"
			#else
				"Color Space:      Gamma 2.2\n"
			#endif //HQAA_TARGET_COLOR_SPACE
			#if HQAA_ENABLE_FPS_TARGET
				"FPS Target Throttling:  ON*\n"
			#else
				"FPS Target Throttling:  off\n"
			#endif //HQAA_ENABLE_FPS_TARGET
			#if HQAA_SCREENSHOT_MODE
				"Screenshot Mode:        ON*\n"
			#else
				"Screenshot Mode:        off\n"
			#endif //HQAA_SCREENSHOT_MODE
			#if HQAA_USE_MULTISAMPLED_FXAA
				"FXAA Multisampling:      on\n"
			#else
				"FXAA Multisampling:    OFF*\n"
			#endif //HQAA_RUN_TWO_FXAA_PASSES
			#if HQAA_TAA_ASSIST_MODE
				"TAA Assist Mode:        ON*\n"
			#else
				"TAA Assist Mode:        off\n"
			#endif //HQAA_TAA_ASSIST_MODE
			#if HQAA_COMPILE_DEBUG_CODE
				"Debug Code:             ON*\n"
			#else
				"Debug Code:             off\n"
			#endif //HQAA_COMPILE_DEBUG_CODE
			#if HQAA_ENABLE_OPTIONAL_TECHNIQUES && (HQAA_OPTIONAL_CAS || HQAA_OPTIONAL_TEMPORAL_STABILIZER || HQAA_OPTIONAL_BRIGHTNESS_GAIN || HQAA_OPTIONAL_DEBAND)
				"Optional Effects:        on\n"
			#else
				"Optional Effects:      OFF*\n"
			#endif //HQAA_ENABLE_OPTIONAL_TECHNIQUES
			#if HQAA_ENABLE_OPTIONAL_TECHNIQUES && HQAA_OPTIONAL_CAS
				"Sharpening:              on\n"
			#elif HQAA_ENABLE_OPTIONAL_TECHNIQUES && !HQAA_OPTIONAL_CAS
				"Sharpening:            OFF*\n"
			#endif //HQAA_OPTIONAL_CAS
			#if HQAA_ENABLE_OPTIONAL_TECHNIQUES && HQAA_OPTIONAL_TEMPORAL_STABILIZER
				"Temporal Stabilizer:    ON*\n"
			#elif HQAA_ENABLE_OPTIONAL_TECHNIQUES && !HQAA_OPTIONAL_TEMPORAL_STABILIZER
				"Temporal Stabilizer:    off\n"
			#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER
			#if HQAA_ENABLE_OPTIONAL_TECHNIQUES && HQAA_OPTIONAL_BRIGHTNESS_GAIN
				"Brightness & Vibrance:  ON*\n"
			#elif HQAA_ENABLE_OPTIONAL_TECHNIQUES && !HQAA_OPTIONAL_BRIGHTNESS_GAIN
				"Brightness & Vibrance:  off\n"
			#endif //HQAA_OPTIONAL_BRIGHTNESS_GAIN
			#if HQAA_ENABLE_OPTIONAL_TECHNIQUES && HQAA_OPTIONAL_DEBAND
				"Debanding:              ON*\n"
			#elif HQAA_ENABLE_OPTIONAL_TECHNIQUES && !HQAA_OPTIONAL_DEBAND
				"Debanding:              off\n"
			#endif //HQAA_OPTIONAL_DEBAND
			
			"\nRemarks:\n"
			
			#if HQAA_SCREENSHOT_MODE
				"\nScreenshot Mode will impact performance and may blur UIs.\n"
			#endif
			#if HQAA_COMPILE_DEBUG_CODE
				"\nDebug code should be disabled when you are not using it\n"
				"because it has a small performance penalty while enabled.\n"
			#endif
			#if HQAA_ENABLE_OPTIONAL_TECHNIQUES && !(HQAA_OPTIONAL_CAS || HQAA_OPTIONAL_TEMPORAL_STABILIZER || HQAA_OPTIONAL_BRIGHTNESS_GAIN || HQAA_OPTIONAL_DEBAND)
				"\nOptional technique code is automatically disabled when the\n"
				"master toggle is enabled but all features are disabled.\n"
			#endif
			#if HQAA_ENABLE_OPTIONAL_TECHNIQUES && HQAA_OPTIONAL_DEBAND && (HQAA_TARGET_COLOR_SPACE == 1 || HQAA_TARGET_COLOR_SPACE == 2)
				"\nPerforming Debanding is not recommended when using\n"
				"an HDR color format because the randomized noise used\n"
				"to correct banding tends to be visible.\n"
			#endif
			#if HQAA_TAA_ASSIST_MODE
				"\nTAA Assist Mode is designed to help the game's internal\n"
				"Temporal Anti-Aliasing solution by performing corrections\n"
				"only on scenes that are in motion. This both helps to fix\n"
				"aliasing during high movement and conserves GPU power by\n"
				"skipping stationary objects.\n"
			#endif
			#if !HQAA_USE_MULTISAMPLED_FXAA
				"\nUsing one FXAA pass may not be sufficient to correct\n"
				"certain types of aliasing.\n"
			#else
				"\nHQAA uses multiple FXAA passes to correct certain kinds\n"
				"of compound aliasing (like tri-gradient edges, a common\n"
				"side effect of supersampling) that cannot be accurately\n"
				"corrected by a single pass. If the performance hit is\n"
				"too large for your system, you can set the preprocessor\n"
				"define 'HQAA_USE_MULTISAMPLED_FXAA' to 0 to revert to one\n"
				"FXAA pass only.\n"
			#endif
			"\n-------------------------------------------------------------------------"
			"\nSet HQAA_TARGET_COLOR_SPACE to 1 for HDR in Nits, 2 for HDR10/scRGB.\n"
			"See the 'Preprocessor definitions' section for color & feature toggles.\n"
			"-------------------------------------------------------------------------";
	ui_tooltip = "Let's just call it a never-ending release candidate";
	ui_category = "About";
	ui_category_closed = true;
>;

uniform uint HqaaPreset <
	ui_type = "combo";
	ui_spacing = 3;
	ui_label = "Quality Preset\n\n";
	ui_tooltip = "For quick start use, pick a preset. If you'd prefer to fine tune, select Custom.";
	ui_items = "Low\0Medium\0High\0Ultra\0Custom\0";
> = 2;

uniform float HqaaEdgeThresholdCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Edge Detection Threshold";
	ui_tooltip = "Local contrast (luma difference) required to be considered an edge";
    ui_category = "Custom Preset";
	ui_category_closed = true;
	ui_text = "------------------------------ Global Options ----------------------------------\n ";
> = 0.1;

uniform float HqaaDynamicThresholdCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "% Dynamic Reduction Range";
	ui_tooltip = "Maximum dynamic reduction of edge threshold (as percentage of base threshold)\n"
				 "permitted when detecting low-brightness edges.\n"
				 "Lower = faster, might miss low-contrast edges\n"
				 "Higher = slower, catches more edges in dark scenes";
    ui_category = "Custom Preset";
	ui_category_closed = true;
> = 75;

uniform float HqaaSmCorneringCustom < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "% Corner Rounding";
	ui_tooltip = "Affects the amount of blending performed when SMAA\ndetects crossing edges";
    ui_category = "Custom Preset";
	ui_category_closed = true;
	ui_text = "\n------------------------------- SMAA Options -----------------------------------\n ";
> = 25;

uniform float HqaaFxQualityCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 25; ui_max = 400; ui_step = 1;
	ui_label = "% Quality";
	ui_tooltip = "Affects the maximum radius FXAA will search\nalong an edge gradient";
    ui_category = "Custom Preset";
	ui_category_closed = true;
	ui_text = "\n------------------------------- FXAA Options -----------------------------------\n ";
> = 100;

uniform float HqaaFxTexelCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.25; ui_max = 4.0; ui_step = 0.01;
	ui_label = "Edge Gradient Texel Size";
	ui_tooltip = "Determines how far along an edge FXAA will move\nfrom one scan iteration to the next.\n\nLower = slower, more accurate\nHigher = faster, more artifacts";
	ui_category = "Custom Preset";
	ui_category_closed = true;
> = 1.0;

uniform float HqaaFxBlendCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "% Gradient Blending Strength\n\n";
	ui_tooltip = "Percentage of blending FXAA will apply to long slopes.\n"
				 "Lower = sharper image, Higher = more AA effect";
    ui_category = "Custom Preset";
	ui_category_closed = true;
> = 50;

uniform float HqaaHysteresisStrength <
	ui_type = "slider";
	ui_spacing = 3;
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "% Max Hysteresis";
	ui_tooltip = "Hysteresis correction adjusts the appearance of anti-aliased\npixels towards their original appearance, which helps\nto preserve detail in the final image.\n\n0% = Off (keep anti-aliasing result as-is)\n100% = Aggressive Correction";
	ui_category = "Hysteresis Pass Options";
	ui_category_closed = true;
> = 67;

uniform float HqaaHysteresisFudgeFactor <
	ui_type = "slider";
	ui_min = 0; ui_max = 25; ui_step = 0.1;
	ui_label = "% Fudge Factor";
	ui_tooltip = "Ignore up to this much difference between the original pixel\nand the anti-aliasing result";
	ui_category = "Hysteresis Pass Options";
	ui_category_closed = true;
> = 10;

uniform bool HqaaDoLumaHysteresis <
	ui_label = "Use Luma Difference Hysteresis?";
	ui_category = "Hysteresis Pass Options";
	ui_category_closed = true;
> = true;

uniform bool HqaaDoSaturationHysteresis <
	ui_label = "Use Saturation Difference Hysteresis?\n\n";
	ui_category = "Hysteresis Pass Options";
	ui_category_closed = true;
> = true;

/////////////////////////////////////////////////////// CONDITIONAL OPTIONS ///////////////////////////////////////////////////////////////

#if HQAA_COMPILE_DEBUG_CODE
uniform uint HqaaDebugMode <
	ui_type = "radio";
	ui_category = "Debug";
	ui_category_closed = true;
	ui_spacing = 2;
	ui_label = " ";
	ui_text = "Debug Mode:";
	ui_items = "Off\n\n\0Detected Edges\0SMAA Blend Weights\n\n\0FXAA Results\0FXAA Lumas\0FXAA Metrics\n\n\0Hysteresis Pattern\0";
> = 0;
#endif //HQAA_COMPILE_DEBUG_CODE

#if HQAA_ENABLE_FPS_TARGET || HQAA_COMPILE_DEBUG_CODE || (HQAA_TARGET_COLOR_SPACE == 1)
uniform int HqaaExtraDivider <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n-------------------------------------------------------------------------";
>;
#endif //(HQAA_ENABLE_FPS_TARGET || HQAA_COMPILE_DEBUG_CODE)

#if HQAA_ENABLE_FPS_TARGET
uniform float HqaaFramerateFloor < __UNIFORM_SLIDER_INT1
	ui_min = 30; ui_max = 240; ui_step = 1;
	ui_label = "Target Minimum Framerate";
	ui_tooltip = "HQAA will automatically reduce FXAA sampling quality if\nthe framerate drops below this number";
> = 60;
#endif //HQAA_ENABLE_FPS_TARGET

#if HQAA_TARGET_COLOR_SPACE == 1
uniform float HqaaHdrNits < 
	ui_type = "slider";
	ui_min = 500.0; ui_max = 10000.0; ui_step = 100.0;
	ui_label = "HDR Nits";
	ui_tooltip = "If the scene brightness changes after HQAA runs, try\n"
				 "adjusting this value up or down until it looks right.";
> = 1000.0;
#endif //HQAA_TARGET_COLOR_SPACE

#if HQAA_COMPILE_DEBUG_CODE
uniform int HqaaDebugExplainer <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "----------------------------------------------------------------\n"
			  "When viewing the detected edges, the colors shown in the texture\n"
			  "are not related to the image on the screen directly, rather they\n"
			  "are markers indicating the following:\n"
			  "- Green = Probable Horizontal Edge Here\n"
			  "- Red = Probable Vertical Edge Here\n"
			  "- Yellow = Probable Diagonal Edge Here\n\n"
			  "SMAA blending weights and FXAA results show what each related\n"
			  "pass is blending with the screen to produce its AA effect.\n\n"
			  "The FXAA luma view compresses its calculated range to 0.25-1.0\n"
			  "so that black pixels mean the shader didn't run in that area.\n\n"
			  "FXAA metrics draws a range of green to red where the selected\n"
			  "pass ran, with green representing not much execution time used\n"
			  "and red representing a lot of execution time used.\n\n"
			  "The Hysteresis pattern is a representation of where and how\n"
			  "strongly the hysteresis pass is performing corrections, but it\n"
			  "does not directly indicate the color that it is blending (it is\n"
			  "the absolute value of a difference calculation, meaning that\n"
			  "decreases are the visual inversion of the actual blend color).\n"
	          "----------------------------------------------------------------";
	ui_category = "DEBUG README";
	ui_category_closed = true;
>;
#endif //HQAA_COMPILE_DEBUG_CODE

uniform int HqaaOptionsEOF <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n-------------------------------------------------------------------------";
>;

#if HQAA_ENABLE_OPTIONAL_TECHNIQUES
#if HQAA_OPTIONAL_CAS
uniform float HqaaSharpenerStrength < __UNIFORM_SLIDER_FLOAT1
	ui_spacing = 3;
	ui_min = 0; ui_max = 5; ui_step = 0.01;
	ui_label = "Sharpening Strength";
	ui_tooltip = "Amount of sharpening to apply";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = 1;

uniform float HqaaSharpenerClamping < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 1; ui_step = 0.001;
	ui_label = "Clamp Strength";
	ui_tooltip = "How much to clamp sharpening strength when the pixel had AA applied to it\n"
	             "Zero means no clamp applied, one means no sharpening applied";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = 0.5;

uniform int HqaaSharpenerIntro <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\nHQAA can optionally run Contrast-Adaptive Sharpening very similar to CAS.fx.\n"
	          "The advantage to using the technique built into HQAA is that it uses edge\n"
			  "data generated by the anti-aliasing technique to adjust the amount of sharpening\n"
			  "applied to areas that were processed to remove aliasing.";
	ui_category = "Sharpening";
	ui_category_closed = true;
>;
#endif //HQAA_OPTIONAL_CAS

#if HQAA_OPTIONAL_TEMPORAL_STABILIZER
uniform float HqaaPreviousFrameWeight < __UNIFORM_SLIDER_FLOAT1
	ui_spacing = 3;
	ui_min = 0; ui_max = 1.0; ui_step = 0.001;
	ui_label = "Previous Frame Weight";
	ui_category = "Temporal Stabilizer";
	ui_category_closed = true;
	ui_tooltip = "Blends the previous frame with the current frame to stabilize results.";
> = 0.333333;

uniform bool HqaaTemporalClamp <
	ui_label = "Clamp Maximum Weight?";
	ui_spacing = 2;
	ui_category = "Temporal Stabilizer";
	ui_category_closed = true;
	ui_tooltip = "When enabled the maximum amount of weight given to the previous\n"
				 "frame will be equal to the largest change in contrast in any\n"
				 "single color channel between the past frame and the current frame.";
> = true;

uniform int HqaaStabilizerIntro <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\nWhen enabled, this effect will blend the previous frame with the\n"
	          "current frame at the specified weight to minimize overcorrection\n"
			  "errors such as crawling text or wiggling lines.";
	ui_category = "Temporal Stabilizer";
	ui_category_closed = true;
>;
#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER

#if HQAA_OPTIONAL_BRIGHTNESS_GAIN
uniform float HqaaGainStrength < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 1.0; ui_step = 0.001;
	ui_spacing = 3;
	ui_label = "Brightness Gain";
	ui_category = "Brightness & Vibrance";
	ui_category_closed = true;
> = 0.5;

uniform bool HqaaGainLowLumaCorrection <
	ui_label = "Contrast Washout Correction";
	ui_tooltip = "Normalizes contrast ratio of resulting pixels\n"
				 "to reduce perceived contrast washout.";
	ui_category = "Brightness & Vibrance";
	ui_category_closed = true;
> = true;

uniform float HqaaVibranceStrength < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_spacing = 2;
	ui_label = "% Vibrance";
	ui_tooltip = "50% means no modification is performed and this option is skipped.";
	ui_text = "-------------------------------------------------------------------------\n ";
	ui_category = "Brightness & Vibrance";
	ui_category_closed = true;
> = 50;

uniform int HqaaGainIntro <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\nWhen enabled, allows to raise overall image brightness\n"
			  "and/or vibrance as a quick fix for dark games or monitors.\n\n"
			  "Contrast washout correction dynamically adjusts the luma\n"
			  "and saturation of the result to approximate the look of\n"
			  "the original scene, removing most of the perceived loss\n"
			  "of contrast (or 'airy' look) after the gain is applied.";
	ui_category = "Brightness & Vibrance";
	ui_category_closed = true;
>;
#endif //HQAA_OPTIONAL_BRIGHTNESS_GAIN

#if HQAA_OPTIONAL_DEBAND
uniform uint HqaaDebandPreset <
	ui_type = "combo";
	ui_items = "Low\0Medium\0High\0";
	ui_spacing = 3;
    ui_label = "Strength";
	ui_category = "Debanding";
	ui_category_closed = true;
> = 0;

uniform float HqaaDebandRange < __UNIFORM_SLIDER_FLOAT1
    ui_min = 4.0;
    ui_max = 32.0;
    ui_step = 1.0;
    ui_label = "Scan Radius";
	ui_category = "Debanding";
	ui_category_closed = true;
> = 32.0;

uniform int HqaaDebandIntro <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\nWhen enabled, performs a fast debanding pass similar\n"
			  "to Deband.fx to mitigate color banding.\n\n"
			  "Please note that debanding will have a significant performance\n"
			  "impact compared to other optional features.";
	ui_category = "Debanding";
	ui_category_closed = true;
>;

uniform uint HqaaDebandSeed < source = "random"; min = 0; max = 32767; >;
#endif

uniform int HqaaOptionalsEOF <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n-------------------------------------------------------------------------";
>;
#endif //HQAA_ENABLE_OPTIONAL_TECHNIQUES

///////////////////////////////////////////////// HUMAN+MACHINE PRESET REFERENCE //////////////////////////////////////////////////////////

uniform int HqaaPresetBreakdown <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n"
			  "--------------------------------------------------------------\n"
			  "|        |       Global      |  SMAA  |        FXAA          |\n"
	          "|--Preset|-Threshold---Range-|-Corner-|-Qual---Texel---Blend-|\n"
	          "|--------|-----------|-------|--------|------|-------|-------|\n"
			  "|     Low|   0.200   | 25.0% |    0%  |  50% |  2.0  |   25% |\n"
			  "|  Medium|   0.100   | 33.3% |   15%  |  75% |  1.5  |   50% |\n"
			  "|    High|   0.060   | 50.0% |   25%  | 100% |  1.0  |   75% |\n"
			  "|   Ultra|   0.040   | 75.0% |   50%  | 150% |  0.5  |  100% |\n"
			  "--------------------------------------------------------------";
	ui_category = "Click me to see what settings each preset uses!";
	ui_category_closed = true;
>;

static const float HQAA_THRESHOLD_PRESET[5] = {0.2, 0.1, 0.06, 0.04, 1.0};
static const float HQAA_DYNAMIC_RANGE_PRESET[5] = {0.25, 0.333333, 0.5, 0.75, 0.0};
static const float HQAA_SMAA_CORNER_ROUNDING_PRESET[5] = {0.0, 0.15, 0.25, 0.5, 0.0};
static const float HQAA_FXAA_SCANNING_MULTIPLIER_PRESET[5] = {0.5, 0.75, 1.0, 1.5, 0.0};
static const float HQAA_FXAA_TEXEL_SIZE_PRESET[5] = {2.0, 1.5, 1.0, 0.5, 4.0};
static const float HQAA_SUBPIX_PRESET[5] = {0.25, 0.5, 0.75, 1.0, 0.0};

#if HQAA_ENABLE_FPS_TARGET
uniform float HqaaFrametime < source = "frametime"; >;
#endif //HQAA_ENABLE_FPS_TARGET

/*****************************************************************************************************************************************/
/*********************************************************** UI SETUP END ****************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/******************************************************** SYNTAX SETUP START *************************************************************/
/*****************************************************************************************************************************************/

#define __HQAA_EDGE_THRESHOLD (HqaaPreset == 4 ? (HqaaEdgeThresholdCustom) : (HQAA_THRESHOLD_PRESET[HqaaPreset]))
#define __HQAA_DYNAMIC_RANGE (HqaaPreset == 4 ? (HqaaDynamicThresholdCustom / 100.0) : HQAA_DYNAMIC_RANGE_PRESET[HqaaPreset])
#define __HQAA_SM_CORNERS (HqaaPreset == 4 ? (HqaaSmCorneringCustom / 100.0) : (HQAA_SMAA_CORNER_ROUNDING_PRESET[HqaaPreset]))
#define __HQAA_FX_QUALITY (HqaaPreset == 4 ? (HqaaFxQualityCustom / 100.0) : (HQAA_FXAA_SCANNING_MULTIPLIER_PRESET[HqaaPreset]))
#define __HQAA_FX_TEXEL (HqaaPreset == 4 ? (HqaaFxTexelCustom) : (HQAA_FXAA_TEXEL_SIZE_PRESET[HqaaPreset]))
#define __HQAA_FX_BLEND (HqaaPreset == 4 ? (HqaaFxBlendCustom / 100.0) : (HQAA_SUBPIX_PRESET[HqaaPreset]))

#define __HQAA_DISPLAY_NUMERATOR max(BUFFER_HEIGHT, BUFFER_WIDTH)
#define __HQAA_SMALLEST_COLOR_STEP rcp(pow(2, BUFFER_COLOR_BIT_DEPTH))
#define __HQAA_LUMA_REF (float(0.25).xxxx)
#define __HQAA_GAMMA_REF (float(0.333334).xxx)

#if HQAA_ENABLE_FPS_TARGET
#define __HQAA_DESIRED_FRAMETIME float(1000.0 / HqaaFramerateFloor)
#define __HQAA_FPS_CLAMP_MULTIPLIER rcp(HqaaFrametime - (__HQAA_DESIRED_FRAMETIME - 1.0))
#endif //HQAA_ENABLE_FPS_TARGET

#define __HQAA_FX_FLOOR (__HQAA_SMALLEST_COLOR_STEP * 0.5)
#define __HQAA_FX_THRESHOLD max(__HQAA_EDGE_THRESHOLD, __HQAA_FX_FLOOR)
#define __HQAA_FX_MIN_RADIUS (4.0 / __HQAA_FX_TEXEL)
#define __HQAA_FX_RADIUS (8.0 / __HQAA_FX_TEXEL)

#define __HQAA_SM_FLOOR (__HQAA_SMALLEST_COLOR_STEP * 0.25)
#define __HQAA_SM_THRESHOLD max(__HQAA_EDGE_THRESHOLD, __HQAA_SM_FLOOR)
#define __HQAA_SM_RADIUS (__HQAA_DISPLAY_NUMERATOR * 0.125)
#define __HQAA_SM_MIN_RADIUS 20
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
#define HQAAmax4(w,x,y,z) max(max(max(w,x),y),z)
#define HQAAmax5(v,w,x,y,z) max(max(max(max(v,w),x),y),z)
#define HQAAmax6(u,v,w,x,y,z) max(max(max(max(max(u,v),w),x),y),z)
#define HQAAmax7(t,u,v,w,x,y,z) max(max(max(max(max(max(t,u),v),w),x),y),z)
#define HQAAmax8(s,t,u,v,w,x,y,z) max(max(max(max(max(max(max(s,t),u),v),w),x),y),z)
#define HQAAmax9(r,s,t,u,v,w,x,y,z) max(max(max(max(max(max(max(max(r,s),t),u),v),w),x),y),z)

#define HQAAmin3(x,y,z) min(min(x,y),z)
#define HQAAmin4(w,x,y,z) min(min(min(w,x),y),z)
#define HQAAmin5(v,w,x,y,z) min(min(min(min(v,w),x),y),z)
#define HQAAmin6(u,v,w,x,y,z) min(min(min(min(min(u,v),w),x),y),z)
#define HQAAmin7(t,u,v,w,x,y,z) min(min(min(min(min(min(t,u),v),w),x),y),z)
#define HQAAmin8(s,t,u,v,w,x,y,z) min(min(min(min(min(min(min(s,t),u),v),w),x),y),z)
#define HQAAmin9(r,s,t,u,v,w,x,y,z) min(min(min(min(min(min(min(min(r,s),t),u),v),w),x),y),z)

#define HQAAdotluma(x) dot(x.rgba, __HQAA_LUMA_REF)
#define HQAAdotgamma(x) dot(x.rgb, __HQAA_GAMMA_REF)
#define HQAAvec4add(x) (x.r + x.g + x.b + x.a)
#define HQAAvec3add(x) (x.r + x.g + x.b)

#define __CONST_E 2.718282

/*****************************************************************************************************************************************/
/********************************************************* SYNTAX SETUP END **************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/******************************************************** SUPPORT CODE START *************************************************************/
/*****************************************************************************************************************************************/

/////////////////////////////////////////////////////// TRANSFER FUNCTIONS ////////////////////////////////////////////////////////////////

#if HQAA_TARGET_COLOR_SPACE == 2
float encodePQ(float x)
{
/*	float nits = 10000.0;
	float m2rcp = 0.012683; // 1 / (2523/32)
	float m1rcp = 6.277395; // 1 / (1305/8192)
	float c1 = 0.8359375; // 107 / 128
	float c2 = 18.8515625; // 2413 / 128
	float c3 = 18.6875; // 2392 / 128
*/
	float xpm2rcp = pow(clamp(x, 0.0, 1.0), 0.012683);
	float numerator = max(xpm2rcp - 0.8359375, 0.0);
	float denominator = 18.8515625 - (18.6875 * xpm2rcp);
	
	return 10000.0 * pow(abs(numerator / denominator), 6.277395);
}
float2 encodePQ(float2 x)
{
/*	float nits = 10000.0;
	float m2rcp = 0.012683; // 1 / (2523/32)
	float m1rcp = 6.277395; // 1 / (1305/8192)
	float c1 = 0.8359375; // 107 / 128
	float c2 = 18.8515625; // 2413 / 128
	float c3 = 18.6875; // 2392 / 128
*/
	float2 xpm2rcp = pow(clamp(x, 0.0, 1.0), 0.012683);
	float2 numerator = max(xpm2rcp - 0.8359375, 0.0);
	float2 denominator = 18.8515625 - (18.6875 * xpm2rcp);
	
	return 10000.0 * pow(abs(numerator / denominator), 6.277395);
}
float3 encodePQ(float3 x)
{
/*	float nits = 10000.0;
	float m2rcp = 0.012683; // 1 / (2523/32)
	float m1rcp = 6.277395; // 1 / (1305/8192)
	float c1 = 0.8359375; // 107 / 128
	float c2 = 18.8515625; // 2413 / 128
	float c3 = 18.6875; // 2392 / 128
*/
	float3 xpm2rcp = pow(clamp(x, 0.0, 1.0), 0.012683);
	float3 numerator = max(xpm2rcp - 0.8359375, 0.0);
	float3 denominator = 18.8515625 - (18.6875 * xpm2rcp);
	
	return 10000.0 * pow(abs(numerator / denominator), 6.277395);
}
float4 encodePQ(float4 x)
{
	return float4(encodePQ(x.rgb), x.a);
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
	float xpm1 = pow(clamp(x / 10000.0, 0.0, 1.0), 0.159302);
	float numerator = 0.8359375 + (18.8515625 * xpm1);
	float denominator = 1.0 + (18.6875 * xpm1);
	
	return pow(abs(numerator / denominator), 78.84375);
}
float2 decodePQ(float2 x)
{
/*	float nits = 10000.0;
	float m2 = 78.84375 // 2523 / 32
	float m1 = 0.159302; // 1305 / 8192
	float c1 = 0.8359375; // 107 / 128
	float c2 = 18.8515625; // 2413 / 128
	float c3 = 18.6875; // 2392 / 128
*/
	float2 xpm1 = pow(clamp(x / 10000.0, 0.0, 1.0), 0.159302);
	float2 numerator = 0.8359375 + (18.8515625 * xpm1);
	float2 denominator = 1.0 + (18.6875 * xpm1);
	
	return pow(abs(numerator / denominator), 78.84375);
}
float3 decodePQ(float3 x)
{
/*	float nits = 10000.0;
	float m2 = 78.84375 // 2523 / 32
	float m1 = 0.159302; // 1305 / 8192
	float c1 = 0.8359375; // 107 / 128
	float c2 = 18.8515625; // 2413 / 128
	float c3 = 18.6875; // 2392 / 128
*/
	float3 xpm1 = pow(clamp(x / 10000.0, 0.0, 1.0), 0.159302);
	float3 numerator = 0.8359375 + (18.8515625 * xpm1);
	float3 denominator = 1.0 + (18.6875 * xpm1);
	
	return pow(abs(numerator / denominator), 78.84375);
}
float4 decodePQ(float4 x)
{
	return float4(decodePQ(x.rgb), x.a);
}
#endif //HQAA_TARGET_COLOR_SPACE

#if HQAA_TARGET_COLOR_SPACE == 1
float encodeHDR(float x)
{
	return x * HqaaHdrNits;
}
float2 encodeHDR(float2 x)
{
	return x * HqaaHdrNits;
}
float3 encodeHDR(float3 x)
{
	return x * HqaaHdrNits;
}
float4 encodeHDR(float4 x)
{
	return x * HqaaHdrNits;
}

float decodeHDR(float x)
{
	return clamp(x, 0.0, 497.0) / 497.0;
}
float2 decodeHDR(float2 x)
{
	return clamp(x, 0.0, 497.0) / 497.0;
}
float3 decodeHDR(float3 x)
{
	return clamp(x, 0.0, 497.0) / 497.0;
}
float4 decodeHDR(float4 x)
{
	return clamp(x, 0.0, 497.0) / 497.0;
}
#endif //HQAA_TARGET_COLOR_SPACE

float ConditionalEncode(float x)
{
#if HQAA_TARGET_COLOR_SPACE == 1
	return encodeHDR(x);
#elif HQAA_TARGET_COLOR_SPACE == 2
	return encodePQ(x);
#else
	return x;
#endif
}
float2 ConditionalEncode(float2 x)
{
#if HQAA_TARGET_COLOR_SPACE == 1
	return encodeHDR(x);
#elif HQAA_TARGET_COLOR_SPACE == 2
	return encodePQ(x);
#else
	return x;
#endif
}
float3 ConditionalEncode(float3 x)
{
#if HQAA_TARGET_COLOR_SPACE == 1
	return encodeHDR(x);
#elif HQAA_TARGET_COLOR_SPACE == 2
	return encodePQ(x);
#else
	return x;
#endif
}
float4 ConditionalEncode(float4 x)
{
#if HQAA_TARGET_COLOR_SPACE == 1
	return encodeHDR(x);
#elif HQAA_TARGET_COLOR_SPACE == 2
	return encodePQ(x);
#else
	return x;
#endif
}

float ConditionalDecode(float x)
{
#if HQAA_TARGET_COLOR_SPACE == 1
	return decodeHDR(x);
#elif HQAA_TARGET_COLOR_SPACE == 2
	return decodePQ(x);
#else
	return x;
#endif
}
float2 ConditionalDecode(float2 x)
{
#if HQAA_TARGET_COLOR_SPACE == 1
	return decodeHDR(x);
#elif HQAA_TARGET_COLOR_SPACE == 2
	return decodePQ(x);
#else
	return x;
#endif
}
float3 ConditionalDecode(float3 x)
{
#if HQAA_TARGET_COLOR_SPACE == 1
	return decodeHDR(x);
#elif HQAA_TARGET_COLOR_SPACE == 2
	return decodePQ(x);
#else
	return x;
#endif
}
float4 ConditionalDecode(float4 x)
{
#if HQAA_TARGET_COLOR_SPACE == 1
	return decodeHDR(x);
#elif HQAA_TARGET_COLOR_SPACE == 2
	return decodePQ(x);
#else
	return x;
#endif
}

//////////////////////////////////////////////////// SATURATION CALCULATIONS //////////////////////////////////////////////////////////////

float dotsat(float3 x)
{
	return (HQAAmax3(x.r, x.g, x.b) - HQAAmin3(x.r, x.g, x.b)) / (1.0 - (2.0 * HQAAdotgamma(x) - 1.0));
}
float dotsat(float4 x)
{
	return dotsat(x.rgb);
}

float3 AdjustSaturation(float3 pixel, float satadjust)
{
	float3 outdot = pixel;
	float refsat = dotsat(pixel);
	float realadjustment = saturate(refsat + satadjust) - refsat;
	float2 highlow = float2(HQAAmax3(outdot.r, outdot.g, outdot.b), HQAAmin3(outdot.r, outdot.g, outdot.b));
	bool runadjustment = abs(realadjustment) > __HQAA_SMALLEST_COLOR_STEP;
	[branch] if (runadjustment)
	{
		// there won't necessarily be a valid mid if eg. pixel.r == pixel.g > pixel.b
		float mid = -1.0;
		
		// figure out if the low needs to move up or down
		float lowadjust = ((highlow.y - highlow.x / 2.0) / highlow.x) * realadjustment;
		
		// same calculation used with the high factors to this
		float highadjust = 0.5 * realadjustment;
		
		// method = apply corrections based on matched high or low channel, assign mid if neither
		if (outdot.r == highlow.x) outdot.r = pow(abs(1.0 + highadjust) * 2.0, log2(outdot.r));
		else if (outdot.r == highlow.y) outdot.r = pow(abs(1.0 + lowadjust) * 2.0, log2(outdot.r));
		else mid = outdot.r;
		if (outdot.g == highlow.x) outdot.g = pow(abs(1.0 + highadjust) * 2.0, log2(outdot.g));
		else if (outdot.g == highlow.y) outdot.g = pow(abs(1.0 + lowadjust) * 2.0, log2(outdot.g));
		else mid = outdot.g;
		if (outdot.b == highlow.x) outdot.b = pow(abs(1.0 + highadjust) * 2.0, log2(outdot.b));
		else if (outdot.b == highlow.y) outdot.b = pow(abs(1.0 + lowadjust) * 2.0, log2(outdot.b));
		else mid = outdot.b;
		
		// perform mid channel calculations if a valid mid was found
		if (mid > 0.0)
		{
			// figure out whether it should move up or down
			float midadjust = ((mid - highlow.x / 2.0) / highlow.x) * realadjustment;
			
			// determine which channel is mid and apply correction
			if (pixel.r == mid) outdot.r = pow(abs(1.0 + midadjust) * 2.0, log2(outdot.r));
			else if (pixel.g == mid) outdot.g = pow(abs(1.0 + midadjust) * 2.0, log2(outdot.g));
			else if (pixel.b == mid) outdot.b = pow(abs(1.0 + midadjust) * 2.0, log2(outdot.b));
		}
	}
	
	return outdot;
}
float4 AdjustSaturation(float4 pixel, float satadjust)
{
	return float4(AdjustSaturation(pixel.rgb, satadjust), pixel.a);
}

float Unmaximize(float color)
{
	float channelstep = __HQAA_SMALLEST_COLOR_STEP;
	return clamp(color, channelstep, 1.0 - channelstep);
}
float2 Unmaximize(float2 color)
{
	float channelstep = __HQAA_SMALLEST_COLOR_STEP;
	return clamp(color, channelstep, 1.0 - channelstep);
}
float3 Unmaximize(float3 color)
{
	float channelstep = __HQAA_SMALLEST_COLOR_STEP;
	return clamp(color, channelstep, 1.0 - channelstep);
}
float4 Unmaximize(float4 color)
{
	float channelstep = __HQAA_SMALLEST_COLOR_STEP;
	return clamp(color, channelstep, 1.0 - channelstep);
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

float2 HQAASearchDiag1(sampler2D HQAAedgesTex, float2 texcoord, float2 dir, out float2 e)
{
    float4 coord = float4(texcoord, -1.0, 1.0);
    float3 t = float3(__HQAA_SM_BUFFERINFO.xy, 1.0);
    bool endloop = false;
    
    [loop] while (coord.z < 20.0) 
	{
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);
        e = tex2Dlod(HQAAedgesTex, coord.xyxy).rg;
        coord.w = dot(e, float(0.5).xx);
        endloop = coord.w < 0.9;
        if (endloop) break;
    }
    return coord.zw;
}
float2 HQAASearchDiag2(sampler2D HQAAedgesTex, float2 texcoord, float2 dir, out float2 e)
{
    float4 coord = float4(texcoord, -1.0, 1.0);
    coord.x += 0.25 * __HQAA_SM_BUFFERINFO.x;
    float3 t = float3(__HQAA_SM_BUFFERINFO.xy, 1.0);
    bool endloop = false;
    
    [loop] while (coord.z < 20.0) 
	{
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);

        e = tex2Dlod(HQAAedgesTex, coord.xyxy).rg;
        e = HQAADecodeDiagBilinearAccess(e);

        coord.w = dot(e, float(0.5).xx);
        endloop = coord.w < 0.9;
        if (endloop) break;
    }
    return coord.zw;
}

float2 HQAAAreaDiag(sampler2D HQAAareaTex, float2 dist, float2 e, float offset)
{
    float2 texcoord = mad(float(__HQAA_SM_AREATEX_RANGE_DIAG).xx, e, dist);

    texcoord = mad(__HQAA_SM_AREATEX_TEXEL, texcoord, 0.5 * __HQAA_SM_AREATEX_TEXEL);
    texcoord.x += 0.5;
    texcoord.y += __HQAA_SM_AREATEX_SUBTEXEL * offset;

    return tex2Dlod(HQAAareaTex, texcoord.xyxy).rg;
}

float2 HQAACalculateDiagWeights(sampler2D HQAAedgesTex, sampler2D HQAAareaTex, float2 texcoord, float2 e, float4 subsampleIndices)
{
    float2 weights = float(0.0).xx;
    float2 end;
    float4 d;
    bool checkpassed;
    d.ywxz = float4(HQAASearchDiag1(HQAAedgesTex, texcoord, float2(1.0, -1.0), end), 0.0, 0.0);
    
    checkpassed = e.r > 0.0;
    [branch] if (checkpassed) 
	{
        d.xz = HQAASearchDiag1(HQAAedgesTex, texcoord, float2(-1.0,  1.0), end);
        d.x += float(end.y > 0.9);
    }
	
	checkpassed = d.x + d.y > 2.0;
	[branch] if (checkpassed) 
	{
        float4 coords = mad(float4(-d.x + 0.25, d.x, d.y, -d.y - 0.25), __HQAA_SM_BUFFERINFO.xyxy, texcoord.xyxy);
        float4 c;
        c.xy = tex2Dlodoffset(HQAAedgesTex, coords.xyxy, int2(-1,  0)).rg;
        c.zw = tex2Dlodoffset(HQAAedgesTex, coords.zwzw, int2( 1,  0)).rg;
        c.yxwz = HQAADecodeDiagBilinearAccess(c.xyzw);

        float2 cc = mad(float(2.0).xx, c.xz, c.yw);

        HQAAMovc(bool2(step(0.9, d.zw)), cc, float(0.0).xx);

        weights += HQAAAreaDiag(HQAAareaTex, d.xy, cc, subsampleIndices.z);
    }

    d.xz = HQAASearchDiag2(HQAAedgesTex, texcoord, float2(-1.0, -1.0), end);
    d.yw = float(0.0).xx;
    
    checkpassed = HQAA_Tex2DOffset(HQAAedgesTex, texcoord, int2(1, 0)).r > 0.0;
    [branch] if (checkpassed) 
	{
        d.yw = HQAASearchDiag2(HQAAedgesTex, texcoord, float(1.0).xx, end);
        d.y += float(end.y > 0.9);
    }
	
	checkpassed = d.x + d.y > 2.0;
	[branch] if (checkpassed) 
	{
        float4 coords = mad(float4(-d.x, -d.x, d.y, d.y), __HQAA_SM_BUFFERINFO.xyxy, texcoord.xyxy);
        float4 c;
        c.x  = tex2Dlodoffset(HQAAedgesTex, coords.xyxy, int2(-1,  0)).g;
        c.y  = tex2Dlodoffset(HQAAedgesTex, coords.xyxy, int2( 0, -1)).r;
        c.zw = tex2Dlodoffset(HQAAedgesTex, coords.zwzw, int2( 1,  0)).gr;
        float2 cc = mad(float(2.0).xx, c.xz, c.yw);

        HQAAMovc(bool2(step(0.9, d.zw)), cc, float(0.0).xx);

        weights += HQAAAreaDiag(HQAAareaTex, d.xy, cc, subsampleIndices.w).gr;
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
    bool endedge = false;
    [loop] while (texcoord.x > end) 
	{
        e = tex2Dlod(HQAAedgesTex, texcoord.xyxy).rg;
        texcoord = mad(-float2(2.0, 0.0), __HQAA_SM_BUFFERINFO.xy, texcoord);
        endedge = e.r > 0.0 || e.g == 0.0;
        if (endedge) break;
    }
    float offset = mad(-2.007874, HQAASearchLength(HQAAsearchTex, e, 0.0), 3.25); // -(255/127)
    return mad(__HQAA_SM_BUFFERINFO.x, offset, texcoord.x);
}
float HQAASearchXRight(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end)
{
    float2 e = float2(0.0, 1.0);
    bool endedge = false;
    [loop] while (texcoord.x < end) 
	{
        e = tex2Dlod(HQAAedgesTex, texcoord.xyxy).rg;
        texcoord = mad(float2(2.0, 0.0), __HQAA_SM_BUFFERINFO.xy, texcoord);
        endedge = e.r > 0.0 || e.g == 0.0;
        if (endedge) break;
    }
    float offset = mad(-2.007874, HQAASearchLength(HQAAsearchTex, e, 0.5), 3.25);
    return mad(-__HQAA_SM_BUFFERINFO.x, offset, texcoord.x);
}
float HQAASearchYUp(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end)
{
    float2 e = float2(1.0, 0.0);
    bool endedge = false;
    [loop] while (texcoord.y > end) 
	{
        e = tex2Dlod(HQAAedgesTex, texcoord.xyxy).rg;
        texcoord = mad(-float2(0.0, 2.0), __HQAA_SM_BUFFERINFO.xy, texcoord);
        endedge = e.r == 0.0 || e.g > 0.0;
        if (endedge) break;
    }
    float offset = mad(-2.007874, HQAASearchLength(HQAAsearchTex, e.gr, 0.0), 3.25);
    return mad(__HQAA_SM_BUFFERINFO.y, offset, texcoord.y);
}
float HQAASearchYDown(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end)
{
    float2 e = float2(1.0, 0.0);
    bool endedge = false;
    [loop] while (texcoord.y < end) 
	{
        e = tex2Dlod(HQAAedgesTex, texcoord.xyxy).rg;
        texcoord = mad(float2(0.0, 2.0), __HQAA_SM_BUFFERINFO.xy, texcoord);
        endedge = e.r == 0.0 || e.g > 0.0;
        if (endedge) break;
    }
    float offset = mad(-2.007874, HQAASearchLength(HQAAsearchTex, e.gr, 0.5), 3.25);
    return mad(-__HQAA_SM_BUFFERINFO.y, offset, texcoord.y);
}

float2 HQAAArea(sampler2D HQAAareaTex, float2 dist, float e1, float e2, float offset)
{
    float2 texcoord = mad(float(__HQAA_SM_AREATEX_RANGE).xx, round(4.0 * float2(e1, e2)), dist);
    
    texcoord = mad(__HQAA_SM_AREATEX_TEXEL, texcoord, 0.5 * __HQAA_SM_AREATEX_TEXEL);
    texcoord.y = mad(__HQAA_SM_AREATEX_SUBTEXEL, offset, texcoord.y);

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

#if HQAA_ENABLE_OPTIONAL_TECHNIQUES
#if HQAA_OPTIONAL_DEBAND
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
#endif //HQAA_OPTIONAL_DEBAND
#endif //HQAA_ENABLE_OPTIONAL_TECHNIQUES

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

#if HQAA_ENABLE_OPTIONAL_TECHNIQUES
#if HQAA_OPTIONAL_TEMPORAL_STABILIZER
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
#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER
#endif //HQAA_ENABLE_OPTIONAL_TECHNIQUES

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

#if HQAA_ENABLE_OPTIONAL_TECHNIQUES
#if HQAA_OPTIONAL_TEMPORAL_STABILIZER
sampler HQAAsamplerLastFrame
{
	Texture = HQAAstabilizerTex;
};
#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER
#endif //HQAA_ENABLE_OPTIONAL_TECHNIQUES

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
	
	float searchrange = trunc(__HQAA_SM_RADIUS);
	
#if HQAA_ENABLE_FPS_TARGET
	if (HqaaFrametime > __HQAA_DESIRED_FRAMETIME)
		searchrange = trunc(max(__HQAA_SM_MIN_RADIUS, searchrange * __HQAA_FPS_CLAMP_MULTIPLIER));
#endif //HQAA_ENABLE_FPS_TARGET

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
/****************************************************** SUPPORT SHADER CODE START ********************************************************/
/*****************************************************************************************************************************************/

/////////////////////////////////////////////////////////// CAS-TO-TEXTURE ////////////////////////////////////////////////////////////////
float4 HQAAPresharpenPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 casdot = HQAA_Tex2D(ReShade::BackBuffer, texcoord);
	
#if HQAA_TAA_ASSIST_MODE
	bool lumachange = HQAA_Tex2D(HQAAsamplerLumaMask, texcoord).r > 0.0;
	if (!lumachange) return casdot;
#endif

	casdot = ConditionalDecode(casdot);

    float3 a = HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, -1)).rgb;
    float3 c = HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(1, -1)).rgb;
    float3 g = HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, 1)).rgb;
    float3 i = HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(1, 1)).rgb;
    float3 b = HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(0, -1)).rgb;
    float3 d = HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, 0)).rgb;
    float3 f = HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(1, 0)).rgb;
    float3 h = HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(0, 1)).rgb;
	
	float3 mnRGB = HQAAmin5(d, casdot.rgb, f, b, h);
	float3 mnRGB2 = HQAAmin5(mnRGB, a, c, g, i);
    mnRGB += mnRGB2;

	float3 mxRGB = HQAAmax5(d, casdot.rgb, f, b, h);
	float3 mxRGB2 = HQAAmax5(mxRGB,a,c,g,i);
    mxRGB += mxRGB2;
	
    float3 ampRGB = rsqrt(saturate(min(mnRGB, 2.0 - mxRGB) * rcp(mxRGB)));    
    float3 wRGB = -rcp(ampRGB * 8.0);
    float3 window = (b + d) + (f + h);
	
    float4 outColor = float4(saturate(mad(window, wRGB, casdot.rgb) * rcp(mad(4.0, wRGB, 1.0))), casdot.a);

	return ConditionalEncode(outColor);
}

/////////////////////////////////////////////////// TEMPORAL STABILIZER FRAME COPY ////////////////////////////////////////////////////////
#if HQAA_ENABLE_OPTIONAL_TECHNIQUES
#if HQAA_OPTIONAL_TEMPORAL_STABILIZER
// optional stabilizer - save previous frame
float4 HQAAGenerateImageCopyPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord);
}
#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER
#endif //HQAA_ENABLE_OPTIONAL_TECHNIQUES

///////////////////////////////////////////////////// TAA ASSIST LUMA HISTOGRAM ///////////////////////////////////////////////////////////
#if HQAA_TAA_ASSIST_MODE
float HQAALumaSnapshotPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return HQAAdotgamma(HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord).rgb);
}

float HQAALumaMaskingPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float previous = HQAA_Tex2D(HQAAsamplerPreviousLuma, texcoord).r;
	float current = HQAAdotgamma(HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord).rgb);
	// for some reason this seems to be a good baseline difference
	float mindiff = __HQAA_SMALLEST_COLOR_STEP * BUFFER_COLOR_BIT_DEPTH;
	bool outdata = abs(current - previous) > mindiff;
	return float(outdata);
}
#endif //HQAA_TAA_ASSIST_MODE

/*****************************************************************************************************************************************/
/******************************************************* SUPPORT SHADER CODE END *********************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/********************************************************** SMAA SHADER CODE START *******************************************************/
/*****************************************************************************************************************************************/

//////////////////////////////////////////////////////// EDGE DETECTION ///////////////////////////////////////////////////////////////////

float4 HQAALumaEdgeDetectionPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float4 offset[3] : TEXCOORD1) : SV_Target
{
	float4 middle = HQAA_DecodeTex2D(HQAAsamplerSMweights, texcoord);
	
#if HQAA_TAA_ASSIST_MODE
	bool lumachange = HQAA_Tex2D(HQAAsamplerLumaMask, texcoord).r > 0.0;
	if (!lumachange) return float(0.0).xxxx;
#endif //HQAA_TAA_ASSIST_MODE

	// calculate the threshold
#if HQAA_SCREENSHOT_MODE
	float2 threshold = float(0.0).xx;
#else
	float basethreshold = __HQAA_SM_THRESHOLD;
	// contrast between pixels becomes low at both the high and low ranges of luma
	float contrastmultiplier = abs(0.5 - HQAAdotgamma(middle)) * 2.0;
	contrastmultiplier *= contrastmultiplier;
	float2 threshold = mad(contrastmultiplier, -(__HQAA_DYNAMIC_RANGE * basethreshold), basethreshold).xx;
#endif //HQAA_SCREENSHOT_MODE
	
	// calculate color channel weighting
	float4 weights = float4(__HQAA_GAMMA_REF, 0.0);
	weights *= middle;
	float scale = rcp(HQAAvec4add(weights));
	weights *= scale;
	
	float2 edges = float(0.0).xx;
	
    float L = dot(middle, weights);

    float Lleft = dot(HQAA_DecodeTex2D(HQAAsamplerSMweights, offset[0].xy), weights);
    float Ltop  = dot(HQAA_DecodeTex2D(HQAAsamplerSMweights, offset[0].zw), weights);

    float4 delta = float4(abs(L - float2(Lleft, Ltop)), 0.0, 0.0);
    edges = step(threshold, delta.xy);
    
	float Lright = dot(HQAA_DecodeTex2D(HQAAsamplerSMweights, offset[1].xy), weights);
	float Lbottom  = dot(HQAA_DecodeTex2D(HQAAsamplerSMweights, offset[1].zw), weights);

	delta.zw = abs(L - float2(Lright, Lbottom));

	float2 maxDelta = max(delta.xy, delta.zw);

	float Lleftleft = dot(HQAA_DecodeTex2D(HQAAsamplerSMweights, offset[2].xy), weights);
	float Ltoptop = dot(HQAA_DecodeTex2D(HQAAsamplerSMweights, offset[2].zw), weights);
	
	delta.zw = abs(float2(Lleft, Ltop) - float2(Lleftleft, Ltoptop));

	maxDelta = max(maxDelta.xy, delta.zw);
	float finalDelta = max(maxDelta.x, maxDelta.y);
	edges.xy *= step(finalDelta, log2(scale) * (1.0 + contrastmultiplier) * delta.xy);
	
	float4 bufferdot = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord);
	
	// pass packed result (edges + hysteresis data)
	return float4(edges, HQAAdotgamma(bufferdot), dotsat(bufferdot));
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
    bool2 edges = bool2(e.r > 0.0, e.g > 0.0);
	
	[branch] if (edges.g) 
	{
        float3 coords = float3(HQAASearchXLeft(HQAAsamplerAlphaEdges, HQAAsamplerSMsearch, offset[0].xy, offset[2].x), offset[1].y, HQAASearchXRight(HQAAsamplerAlphaEdges, HQAAsamplerSMsearch, offset[0].zw, offset[2].y));
        float e1 = HQAA_Tex2D(HQAAsamplerAlphaEdges, coords.xy).r;
		float2 d = coords.xz;
        d = abs(round(mad(__HQAA_SM_BUFFERINFO.zz, d, -pixcoord.xx)));
        float e2 = HQAA_Tex2DOffset(HQAAsamplerAlphaEdges, coords.zy, int2(1, 0)).r;
        weights.rg = HQAAArea(HQAAsamplerSMarea, sqrt(d), e1, e2, 0.0);
        coords.y = texcoord.y;
        HQAADetectHorizontalCornerPattern(HQAAsamplerAlphaEdges, weights.rg, coords.xyzy, d);
    }
	
	[branch] if (edges.r) 
	{
        float3 coords = float3(offset[0].x, HQAASearchYUp(HQAAsamplerAlphaEdges, HQAAsamplerSMsearch, offset[1].xy, offset[2].z), HQAASearchYDown(HQAAsamplerAlphaEdges, HQAAsamplerSMsearch, offset[1].zw, offset[2].w));
        float e1 = HQAA_Tex2D(HQAAsamplerAlphaEdges, coords.xy).g;
		float2 d = coords.yz;
        d = abs(round(mad(__HQAA_SM_BUFFERINFO.ww, d, -pixcoord.yy)));
        float e2 = HQAA_Tex2DOffset(HQAAsamplerAlphaEdges, coords.xz, int2(0, 1)).g;
        weights.ba = HQAAArea(HQAAsamplerSMarea, sqrt(d), e1, e2, 0.0);
        coords.x = texcoord.x;
        HQAADetectVerticalCornerPattern(HQAAsamplerAlphaEdges, weights.ba, coords.xyxz, d);
    }

    return weights;
}

//////////////////////////////////////////////////// NEIGHBORHOOD BLENDING ////////////////////////////////////////////////////////////////

float4 HQAANeighborhoodBlendingPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float4 offset : TEXCOORD1) : SV_Target
{
    float4 m = float4(HQAA_Tex2D(HQAAsamplerSMweights, offset.xy).a, HQAA_Tex2D(HQAAsamplerSMweights, offset.zw).g, HQAA_Tex2D(HQAAsamplerSMweights, texcoord).zx);
	float4 resultAA = HQAA_Tex2D(ReShade::BackBuffer, texcoord);
	bool modifypixel = any(m);
	
	[branch] if (modifypixel)
	{
		resultAA = ConditionalDecode(resultAA);
        bool horiz = max(m.x, m.z) > max(m.y, m.w);
        float4 blendingOffset = float4(0.0, m.y, 0.0, m.w);
        float2 blendingWeight = m.yw;
        HQAAMovc(bool(horiz).xxxx, blendingOffset, float4(m.x, 0.0, m.z, 0.0));
        HQAAMovc(bool(horiz).xx, blendingWeight, m.xz);
        blendingWeight /= dot(blendingWeight, float(1.0).xx);
        float4 blendingCoord = mad(blendingOffset, float4(__HQAA_SM_BUFFERINFO.xy, -__HQAA_SM_BUFFERINFO.xy), texcoord.xyxy);
        resultAA = blendingWeight.x * HQAA_DecodeTex2D(ReShade::BackBuffer, blendingCoord.xy);
        resultAA += blendingWeight.y * HQAA_DecodeTex2D(ReShade::BackBuffer, blendingCoord.zw);
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
    float4 rgbyM = HQAA_Tex2D(ReShade::BackBuffer, texcoord);
	
#if HQAA_TAA_ASSIST_MODE
	bool lumachange = HQAA_Tex2D(HQAAsamplerLumaMask, texcoord).r > 0.0;
	if (!lumachange) return rgbyM.rgb;
#endif //HQAA_TAA_ASSIST_MODE

	rgbyM = ConditionalDecode(rgbyM);
	float lumaMa = HQAAdotgamma(Unmaximize(rgbyM));
    float basethreshold = __HQAA_FX_THRESHOLD;
	
	// calculate the threshold
#if HQAA_SCREENSHOT_MODE
	float fxaaQualityEdgeThreshold = 0.0;
#else
	// contrast between pixels becomes low at both the high and low ranges of luma
	float contrastmultiplier = abs(0.5 - lumaMa) * 2.0;
	contrastmultiplier *= contrastmultiplier;
	float fxaaQualityEdgeThreshold = mad(contrastmultiplier, -(__HQAA_DYNAMIC_RANGE * basethreshold), basethreshold);
#endif //HQAA_SCREENSHOT_MODE

    float lumaS = HQAAdotgamma(Unmaximize(HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 0, 1))));
    float lumaE = HQAAdotgamma(Unmaximize(HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 1, 0))));
    float lumaN = HQAAdotgamma(Unmaximize(HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 0,-1))));
    float lumaW = HQAAdotgamma(Unmaximize(HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, 0))));
	
    float rangeMax = HQAAmax5(lumaS, lumaE, lumaN, lumaW, lumaMa);
    float rangeMin = HQAAmin5(lumaS, lumaE, lumaN, lumaW, lumaMa);
	
    float range = rangeMax - rangeMin;
    
	// early exit check
    bool earlyExit = range < fxaaQualityEdgeThreshold;
	if (earlyExit)
#if HQAA_COMPILE_DEBUG_CODE
		if (clamp(HqaaDebugMode, 3, 5) == HqaaDebugMode) return float(0.0).xxx;
		else
#endif //HQAA_COMPILE_DEBUG_CODE
		return ConditionalEncode(rgbyM.rgb);
	
    float lumaNW = HQAAdotgamma(Unmaximize(HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1,-1))));
    float lumaSE = HQAAdotgamma(Unmaximize(HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 1, 1))));
    float lumaNE = HQAAdotgamma(Unmaximize(HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 1,-1))));
    float lumaSW = HQAAdotgamma(Unmaximize(HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, 1))));
	
    bool horzSpan = (abs(mad(-2.0, lumaW, lumaNW + lumaSW)) + mad(2.0, abs(mad(-2.0, lumaMa, lumaN + lumaS)), abs(mad(-2.0, lumaE, lumaNE + lumaSE)))) >= (abs(mad(-2.0, lumaS, lumaSW + lumaSE)) + mad(2.0, abs(mad(-2.0, lumaMa, lumaW + lumaE)), abs(mad(-2.0, lumaN, lumaNW + lumaNE))));	
    float lengthSign = horzSpan ? BUFFER_RCP_HEIGHT : BUFFER_RCP_WIDTH;
	
	float2 lumaNP = float2(lumaN, lumaS);
	HQAAMovc(bool(!horzSpan).xx, lumaNP, float2(lumaW, lumaE));
	
    float gradientN = lumaNP.x - lumaMa;
    float gradientS = lumaNP.y - lumaMa;
    float lumaNN = lumaNP.x + lumaMa;
	
    if (abs(gradientN) >= abs(gradientS)) lengthSign = -lengthSign;
    else lumaNN = lumaNP.y + lumaMa;
	
    float2 posB = texcoord;
	
	float texelsize = __HQAA_FX_TEXEL;

    float2 offNP = float2(0.0, BUFFER_RCP_HEIGHT * texelsize);
	HQAAMovc(bool(horzSpan).xx, offNP, float2(BUFFER_RCP_WIDTH * texelsize, 0.0));
	
	HQAAMovc(bool2(!horzSpan, horzSpan), posB, float2(posB.x + lengthSign / 2.0, posB.y + lengthSign / 2.0));
	
    float2 posN = posB - offNP;
    float2 posP = posB + offNP;
    
    float lumaEndN = HQAAdotgamma(Unmaximize(HQAA_DecodeTex2D(ReShade::BackBuffer, posN)));
    float lumaEndP = HQAAdotgamma(Unmaximize(HQAA_DecodeTex2D(ReShade::BackBuffer, posP)));
	
    float gradientScaled = max(abs(gradientN), abs(gradientS)) * 0.25;
    bool lumaMLTZero = mad(0.5, -lumaNN, lumaMa) < 0.0;
	
	lumaNN *= 0.5;
	
    lumaEndN -= lumaNN;
    lumaEndP -= lumaNN;
	
    bool doneN = abs(lumaEndN) >= gradientScaled;
    bool doneP = abs(lumaEndP) >= gradientScaled;
    bool doneNP;
	
	uint iterations = 0;
	
	uint maxiterations = trunc(max(__HQAA_FX_RADIUS * __HQAA_FX_QUALITY, __HQAA_FX_MIN_RADIUS));
	
#if HQAA_ENABLE_FPS_TARGET
	if (HqaaFrametime > __HQAA_DESIRED_FRAMETIME) maxiterations = trunc(max(__HQAA_FX_MIN_RADIUS, __HQAA_FPS_CLAMP_MULTIPLIER * maxiterations));
#endif
	
	[loop] while (iterations < maxiterations)
	{
		doneNP = doneN && doneP;
		if (doneNP) break;
		if (!doneN)
		{
			posN -= offNP;
			lumaEndN = HQAAdotgamma(Unmaximize(HQAA_DecodeTex2D(ReShade::BackBuffer, posN)));
			lumaEndN -= lumaNN;
			doneN = abs(lumaEndN) >= gradientScaled;
		}
		if (!doneP)
		{
			posP += offNP;
			lumaEndP = HQAAdotgamma(Unmaximize(HQAA_DecodeTex2D(ReShade::BackBuffer, posP)));
			lumaEndP -= lumaNN;
			doneP = abs(lumaEndP) >= gradientScaled;
		}
		iterations++;
    }
	
	//float dstN, dstP;
	float2 dstNP = float2(texcoord.y - posN.y, posP.y - texcoord.y);
	HQAAMovc(bool(horzSpan).xx, dstNP, float2(texcoord.x - posN.x, posP.x - texcoord.x));
	
    bool goodSpan = (dstNP.x < dstNP.y) ? ((lumaEndN < 0.0) != lumaMLTZero) : ((lumaEndP < 0.0) != lumaMLTZero);
    float pixelOffset = mad(-rcp(dstNP.y + dstNP.x), min(dstNP.x, dstNP.y), 0.5);
	float subpixOut = pixelOffset;
	
	// calculating subpix quality is only necessary with a failed span
	[branch] if (!goodSpan) {
		// ABC - saturate and abs in original code for entire statement
		subpixOut = mad(mad(2.0, lumaS + lumaE + lumaN + lumaW, lumaNW + lumaSE + lumaNE + lumaSW), 0.083333, -lumaMa) * rcp(range);
		subpixOut = pow(abs(mad(-2.0, subpixOut, 3.0) * (subpixOut * subpixOut)), 2.0) * __HQAA_FX_BLEND * texelsize * pixelOffset * range; // DEFGH
    }

    float2 posM = texcoord;
	HQAAMovc(bool2(!horzSpan, horzSpan), posM, float2(posM.x + lengthSign * subpixOut, posM.y + lengthSign * subpixOut));
    
	// Establish result
	float3 resultAA = HQAA_DecodeTex2D(ReShade::BackBuffer, posM).rgb;
	
	// output selection
#if HQAA_COMPILE_DEBUG_CODE
	if (HqaaDebugMode == 4)
	{
		// luminance output
		return float(lumaMa * 0.75 + 0.25).xxx;
	}
	if (HqaaDebugMode == 5)
	{
		// metrics output
		float runtime = float(iterations / maxiterations) * 0.5;
		float3 FxaaMetrics = float3(runtime, 0.5 - runtime, 0.0);
		return FxaaMetrics;
	}
#endif //HQAA_COMPILE_DEBUG_CODE
	// normal output
	return ConditionalEncode(resultAA);
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
	
	bool skiphysteresis = (HqaaHysteresisStrength == 0.0) || ((!HqaaDoLumaHysteresis) && (!HqaaDoSaturationHysteresis));
	if (skiphysteresis) return pixel;
	
#if HQAA_TAA_ASSIST_MODE
	bool lumachange = HQAA_Tex2D(HQAAsamplerLumaMask, texcoord).r > 0.0;
	if (!lumachange) return pixel;
#endif //HQAA_TAA_ASSIST_MODE

	pixel = ConditionalDecode(pixel);

#if HQAA_COMPILE_DEBUG_CODE
	bool modifiedpixel = any(edgedata.rg);
	float3 AAdot = pixel;
	if (HqaaDebugMode == 6 && !modifiedpixel) return float(0.0).xxx;
	if (HqaaDebugMode == 1) return float3(HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord).rg, 0.0);
	if (HqaaDebugMode == 2) return HQAA_Tex2D(HQAAsamplerSMweights, texcoord).rgb;
	if (HqaaDebugMode == 0 || HqaaDebugMode == 6) {
#endif

	float channelstep = __HQAA_SMALLEST_COLOR_STEP;
	float multiplier = HqaaHysteresisStrength / 100.0;
	float fudgefactor = HqaaHysteresisFudgeFactor / 100.0;
	
	float hysteresis = (HQAAdotgamma(pixel) - edgedata.b) * multiplier;
	bool runcorrection = abs(hysteresis) > max(channelstep, fudgefactor) && HqaaDoLumaHysteresis;
	[branch] if (runcorrection)
	{
		// perform weighting using computed hysteresis
		pixel = pow(abs(1.0 + hysteresis) * 2.0, log2(pixel));
	}
	
	float sathysteresis = (dotsat(pixel) - edgedata.a) * multiplier;
	runcorrection = abs(sathysteresis) > max(channelstep, fudgefactor) && HqaaDoSaturationHysteresis;
	[branch] if (runcorrection)
	{
		// perform weighting using computed hysteresis
		pixel = AdjustSaturation(pixel, -sathysteresis);
	}
	
	//output
#if HQAA_COMPILE_DEBUG_CODE
	}
	if (HqaaDebugMode == 6)
	{
		// hysteresis pattern
		return sqrt(abs(pixel - AAdot));
	}
#endif //HQAA_COMPILE_DEBUG_CODE
	return ConditionalEncode(pixel);
}

/***************************************************************************************************************************************/
/******************************************************* HYSTERESIS SHADER CODE END ****************************************************/
/***************************************************************************************************************************************/

/***************************************************************************************************************************************/
/******************************************************* OPTIONAL SHADER CODE START ****************************************************/
/***************************************************************************************************************************************/

#if HQAA_ENABLE_OPTIONAL_TECHNIQUES

#if HQAA_OPTIONAL_DEBAND
float3 HQAADebandPS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 ori = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord).rgb; // Original pixel
#if HQAA_COMPILE_DEBUG_CODE
	if (HqaaDebugMode == 0) {
#endif
    // Settings
    float avgdiff[3] = {0.002353, 0.007059, 0.013333}; // 0.6/255, 1.8/255, 3.4/255
    float maxdiff[3] = {0.007451, 0.015686, 0.026667}; // 1.9/255, 4.0/255, 6.8/255
    float middiff[3] = {0.004706, 0.007843, 0.012941}; // 1.2/255, 2.0/255, 3.3/255

    // Initialize the PRNG
    float randomseed = HqaaDebandSeed / 32767.0;
    float h = permute(float2(permute(float2(texcoord.x, randomseed)), permute(float2(texcoord.y, randomseed))));

    // Compute a random angle
    float dir = frac(permute(h) / 41.0) * 6.2831853;
    float2 angle = float2(cos(dir), sin(dir));

    // Compute a random distance
    float2 dist = frac(h / 41.0) * HqaaDebandRange * BUFFER_PIXEL_SIZE;

    // Sample at quarter-turn intervals around the source pixel

    // South-east
    float3 ref = HQAA_DecodeTex2D(ReShade::BackBuffer, (texcoord + dist * angle)).rgb;
    float3 diff = abs(ori - ref);
    float3 ref_max_diff = diff;
    float3 ref_avg = ref;
    float3 ref_mid_diff1 = ref;

    // North-west
    ref = HQAA_DecodeTex2D(ReShade::BackBuffer, (texcoord + dist * -angle)).rgb;
    diff = abs(ori - ref);
    ref_max_diff = max(ref_max_diff, diff);
    ref_avg += ref;
    ref_mid_diff1 = abs(((ref_mid_diff1 + ref) * 0.5) - ori);

    // North-east
    ref = HQAA_DecodeTex2D(ReShade::BackBuffer, (texcoord + dist * float2(-angle.y, angle.x))).rgb;
    diff = abs(ori - ref);
    ref_max_diff = max(ref_max_diff, diff);
    ref_avg += ref;
    float3 ref_mid_diff2 = ref;

    // South-west
    ref = HQAA_DecodeTex2D(ReShade::BackBuffer, (texcoord + dist * float2(angle.y, -angle.x))).rgb;
    diff = abs(ori - ref);
    ref_max_diff = max(ref_max_diff, diff);
    ref_avg += ref;
    ref_mid_diff2 = abs(((ref_mid_diff2 + ref) * 0.5) - ori);

    ref_avg *= 0.25; // Normalize avg
    float3 ref_avg_diff = abs(ori - ref_avg);
    
    // Fuzzy logic based pixel selection
    float3 factor = pow(saturate(3.0 * (1.0 - ref_avg_diff  / avgdiff[HqaaDebandPreset])) *
                            saturate(3.0 * (1.0 - ref_max_diff  / maxdiff[HqaaDebandPreset])) *
                            saturate(3.0 * (1.0 - ref_mid_diff1 / middiff[HqaaDebandPreset])) *
                            saturate(3.0 * (1.0 - ref_mid_diff2 / middiff[HqaaDebandPreset])), 0.1);

    return ConditionalEncode(lerp(ori, ref_avg, factor));
#if HQAA_COMPILE_DEBUG_CODE
	}
	else return ConditionalEncode(ori);
#endif
}
#endif //HQAA_OPTIONAL_DEBAND

#if (HQAA_OPTIONAL_CAS || HQAA_OPTIONAL_BRIGHTNESS_GAIN || HQAA_OPTIONAL_TEMPORAL_STABILIZER)
// Optional effects main pass. These are sorted in an order that they won't
// interfere with each other when they're all enabled
float3 HQAAOptionalEffectPassPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 pixel = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord).rgb;
	
#if HQAA_COMPILE_DEBUG_CODE
	if (HqaaDebugMode == 0) {
#endif
	
#if HQAA_OPTIONAL_CAS
	float3 casdot = pixel;
	
	float sharpening = HqaaSharpenerStrength;
	
	if (any(HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord).rg))
		sharpening *= (1.0 - HqaaSharpenerClamping);
	
    float3 a = HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, -1)).rgb;
    float3 c = HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(1, -1)).rgb;
    float3 g = HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, 1)).rgb;
    float3 i = HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(1, 1)).rgb;
    float3 b = HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(0, -1)).rgb;
    float3 d = HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, 0)).rgb;
    float3 f = HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(1, 0)).rgb;
    float3 h = HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(0, 1)).rgb;
	
	float3 mnRGB = HQAAmin5(d, casdot, f, b, h);
	float3 mnRGB2 = HQAAmin5(mnRGB, a, c, g, i);
    mnRGB += mnRGB2;

	float3 mxRGB = HQAAmax5(d, casdot, f, b, h);
	float3 mxRGB2 = HQAAmax5(mxRGB,a,c,g,i);
    mxRGB += mxRGB2;
	
    float3 ampRGB = rsqrt(saturate(min(mnRGB, 2.0 - mxRGB) * rcp(mxRGB)));    
    float3 wRGB = -rcp(ampRGB * 8.0);
    float3 window = (b + d) + (f + h);
	
    float3 outColor = saturate(mad(window, wRGB, casdot) * rcp(mad(4.0, wRGB, 1.0)));
	casdot = lerp(casdot, outColor, sharpening);
	
	pixel = casdot;
#endif //HQAA_OPTIONAL_CAS

#if HQAA_OPTIONAL_BRIGHTNESS_GAIN
	bool applygain = HqaaGainStrength > 0.0;
	[branch] if (applygain)
	{
		float3 outdot = pixel;
		float presaturation = dotsat(outdot);
		float colorgain = 2.0 - log2(HqaaGainStrength + 1.0);
		float channelfloor = __HQAA_SMALLEST_COLOR_STEP;
		outdot = log2(clamp(outdot, channelfloor, 1.0 - channelfloor));
		outdot = pow(abs(colorgain), outdot);
		if (HqaaGainLowLumaCorrection)
		{
			// calculate new black level
			channelfloor = pow(abs(colorgain), log2(channelfloor));
			// calculate reduction strength to apply
			float contrastgain = log(rcp(HQAAdotgamma(outdot) - channelfloor)) * pow(__CONST_E, (1.0 + channelfloor) * __CONST_E) * HqaaGainStrength;
			outdot = pow(abs(10.0 + contrastgain * (1.0 + HqaaGainStrength)), log10(outdot));
			float newsat = dotsat(outdot);
			float satadjust = newsat - presaturation; // compute difference in before/after saturation
			bool adjustsat = abs(satadjust) > channelfloor;
			if (adjustsat) outdot = AdjustSaturation(outdot, -satadjust);
		}
		pixel = outdot;
	}
	
	applygain = HqaaVibranceStrength != 50.0;
	[branch] if (applygain)
	{
		float3 outdot = pixel;
		outdot = AdjustSaturation(outdot, -((HqaaVibranceStrength / 100.0) - 0.5));
		pixel = outdot;
	}
#endif //HQAA_OPTIONAL_BRIGHTNESS_GAIN

#if HQAA_OPTIONAL_TEMPORAL_STABILIZER
	float3 current = pixel;
	float3 previous = HQAA_Tex2D(HQAAsamplerLastFrame, texcoord).rgb;
	
	// values above 0.9 can produce artifacts or halt frame advancement entirely
	float blendweight = min(HqaaPreviousFrameWeight, 0.9);
	
	if (HqaaTemporalClamp) {
		float contrastdelta = sqrt(HQAAdotgamma(abs(current - previous)));
		blendweight = min(contrastdelta, blendweight);
	}
	
	pixel = lerp(current, previous, blendweight);
#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER

#if HQAA_COMPILE_DEBUG_CODE
	}
#endif
	
	return ConditionalEncode(pixel);
}
#endif //(HQAA_OPTIONAL_CAS || HQAA_OPTIONAL_BRIGHTNESS_GAIN || HQAA_OPTIONAL_TEMPORAL_STABILIZER)
#endif //HQAA_ENABLE_OPTIONAL_TECHNIQUES

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
	pass GenerateTemporarySharpen
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAPresharpenPS;
		RenderTarget = HQAAblendTex;
		ClearRenderTargets = true;
	}
	pass EdgeDetection
	{
		VertexShader = HQAAEdgeDetectionVS;
		PixelShader = HQAALumaEdgeDetectionPS;
		RenderTarget = HQAAedgesTex;
		ClearRenderTargets = true;
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
#if HQAA_USE_MULTISAMPLED_FXAA
	pass FXAA
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAFXPS;
	}
	pass FXAA
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAFXPS;
	}
#endif //HQAA_USE_MULTISAMPLED_FXAA
	pass Hysteresis
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAHysteresisPS;
	}
#if HQAA_ENABLE_OPTIONAL_TECHNIQUES
#if HQAA_OPTIONAL_DEBAND
	pass Deband
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAADebandPS;
	}
	pass Deband
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAADebandPS;
	}
#endif //HQAA_OPTIONAL_DEBAND
#if (HQAA_OPTIONAL_CAS || HQAA_OPTIONAL_TEMPORAL_STABILIZER || HQAA_OPTIONAL_BRIGHTNESS_GAIN)
	pass OptionalEffects
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAOptionalEffectPassPS;
	}
#endif //(HQAA_OPTIONAL_CAS || HQAA_OPTIONAL_TEMPORAL_STABILIZER || HQAA_OPTIONAL_BRIGHTNESS_GAIN)
#if HQAA_OPTIONAL_TEMPORAL_STABILIZER
	pass SaveCurrentFrame
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAGenerateImageCopyPS;
		RenderTarget = HQAAstabilizerTex;
		ClearRenderTargets = true;
	}
#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER
#endif //HQAA_ENABLE_OPTIONAL_TECHNIQUES
}
