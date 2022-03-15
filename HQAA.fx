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
 *                        v25.2.1
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
	#define HQAA_OPTIONAL_EFFECTS 0
#endif //HQAA_ENABLE_OPTIONAL_TECHNIQUES

#if HQAA_OPTIONAL_EFFECTS
	#ifndef HQAA_OPTIONAL__TEMPORAL_STABILIZER
		#define HQAA_OPTIONAL__TEMPORAL_STABILIZER 0
	#endif //HQAA_OPTIONAL__TEMPORAL_STABILIZER
	#ifndef HQAA_OPTIONAL__DEBANDING
		#define HQAA_OPTIONAL__DEBANDING 0
	#endif
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
	ui_label = "Version: 25.2.1";
	ui_text = "-------------------------------------------------------------------------\n"
			"Hybrid high-Quality Anti-Aliasing, a shader by lordbean\n"
			"https://github.com/lordbean-git/HQAA/\n"
			"-------------------------------------------------------------------------\n\n"
			"Currently Compiled Configuration:\n\n"
			#if HQAA_ADVANCED_MODE
				"Advanced Mode:            on  *\n"
			#else
				"Advanced Mode:           off\n"
			#endif
			#if HQAA_OUTPUT_MODE == 1
				"Output Mode:        HDR nits  *\n"
			#elif HQAA_OUTPUT_MODE == 2
				"Output Mode:     PQ accurate  *\n"
			#elif HQAA_OUTPUT_MODE == 3
				"Output Mode:       PQ approx  *\n"
			#else
				"Output Mode:       Gamma 2.2\n"
			#endif //HQAA_TARGET_COLOR_SPACE
			#if HQAA_FXAA_MULTISAMPLING < 2
				"FXAA Multisampling:      off  *\n"
			#elif HQAA_FXAA_MULTISAMPLING > 3
				"FXAA Multisampling:       4x  *\n"
			#elif HQAA_FXAA_MULTISAMPLING > 2
				"FXAA Multisampling:       3x  *\n"
			#elif HQAA_FXAA_MULTISAMPLING > 1
				"FXAA Multisampling:       2x\n"
			#endif //HQAA_FXAA_MULTISAMPLING
			#if HQAA_TAA_ASSIST_MODE
				"TAA Assist Mode:          on  *\n"
			#else
				"TAA Assist Mode:         off\n"
			#endif //HQAA_TAA_ASSIST_MODE
			#if HQAA_DEBUG_MODE
				"Debug Code:               on  *\n"
			#else
				"Debug Code:              off\n"
			#endif //HQAA_DEBUG_MODE
			#if HQAA_OPTIONAL_EFFECTS
				"Optional Effects:         on  *\n"
			#else
				"Optional Effects:        off\n"
			#endif //HQAA_ENABLE_OPTIONAL_TECHNIQUES
			#if HQAA_OPTIONAL_EFFECTS && HQAA_OPTIONAL__TEMPORAL_STABILIZER
				"Temporal Stabilizer:      on  *\n"
			#elif HQAA_OPTIONAL_EFFECTS && !HQAA_OPTIONAL__TEMPORAL_STABILIZER
				"Temporal Stabilizer:     off\n"
			#endif //HQAA_OPTIONAL__TEMPORAL_STABILIZER
			#if HQAA_OPTIONAL_EFFECTS && HQAA_OPTIONAL__DEBANDING
				"Debanding:                on  *\n"
			#elif HQAA_OPTIONAL_EFFECTS && !HQAA_OPTIONAL__DEBANDING
				"Debanding:               off\n"
			#endif //HQAA_OPTIONAL__DEBANDING
			
			"\nRemarks:\n"
			
			#if HQAA_DEBUG_MODE
				"\nDebug code should be disabled when you are not using it\n"
				"because it has a small performance penalty while enabled.\n"
			#endif
			#if HQAA_OPTIONAL_EFFECTS
				"\nOptional Sharpening and Brightness/Vibrance Gain can be\n"
				"enabled and disabled using a UI toggle in their setup.\n"
				"The optional Temporal Stabilizer and Debanding effects\n"
				"must be enabled via pre-processor define because they use\n"
				"extra rendering passes when being performed.\n"
			#endif
			#if HQAA_OPTIONAL_EFFECTS && HQAA_OPTIONAL__DEBANDING && (HQAA_OUTPUT_MODE > 0)
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
			"\nFXAA Multisampling can be used to increase correction strength\n"
			"when encountering edges with more than one color gradient or\n"
			"irregular geometry. Costs some performance for each extra pass.\n"
			"Valid range: 1 to 4. Higher values are ignored.\n"
			"\nValid Output Modes (HQAA_OUTPUT_MODE):\n"
			"0: Gamma 2.2 (default)\n"
			"1: HDR, direct nits scale\n"
			"2: HDR10, accurate encoding\n"
			"3: HDR10, fast encoding\n"
			"\n-------------------------------------------------------------------------"
			"\nSee the 'Preprocessor definitions' section for color & feature toggles.\n"
			"-------------------------------------------------------------------------";
	ui_tooltip = "Let's just call it a never-ending release candidate";
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
	ui_items = "Off\n\n\0Detected Edges\0SMAA Blend Weights\n\n\0FXAA Results\0FXAA Lumas\0FXAA Metrics\n\n\0Hysteresis Pattern\0";
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
	ui_spacing = 3;
	ui_label = "Quality Preset\n\n";
	ui_tooltip = "Set HQAA_ADVANCED_MODE to 1 to customize all options";
	ui_items = "Low\0Medium\0High\0Ultra\0";
> = 2;

static const float HqaaHysteresisStrength = 12.5;
static const float HqaaHysteresisFudgeFactor = 1.0;
static const bool HqaaDoLumaHysteresis = true;
static const bool HqaaDoSaturationHysteresis = false;

#else
uniform float HqaaEdgeThresholdCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_spacing = 4;
	ui_label = "Edge Detection Threshold";
	ui_tooltip = "Local contrast (luma difference) required to be considered an edge";
	ui_category = "Edge Detection";
	ui_category_closed = true;
> = 0.1;

uniform float HqaaDynamicThresholdCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "% Dynamic Reduction Range\n\n";
	ui_tooltip = "Maximum dynamic reduction of edge threshold (as percentage of base threshold)\n"
				 "permitted when detecting low-brightness edges.\n"
				 "Lower = faster, might miss low-contrast edges\n"
				 "Higher = slower, catches more edges in dark scenes";
	ui_category = "Edge Detection";
	ui_category_closed = true;
> = 75;

uniform uint HqaaEdgeErrorMarginCustom <
	ui_type = "radio";
	ui_label = "Mouseover for description";
	ui_spacing = 3;
	ui_text = "Detected Edges Margin of Error:";
	ui_tooltip = "Determines maximum number of neighbor edges allowed before\n"
				"an edge is considered an erroneous detection. Low preserves\n"
				"detail, high increases amount of anti-aliasing applied.";
	ui_items = "Low\0Balanced\0High\0";
	ui_category = "SMAA";
	ui_category_closed = true;
> = 1;

static const float HQAA_ERRORMARGIN_CUSTOM[3] = {4.0, 5.0, 7.0};

uniform float HqaaSmCorneringCustom < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_spacing = 2;
	ui_label = "% Corner Rounding\n\n";
	ui_tooltip = "Affects the amount of blending performed when SMAA\ndetects crossing edges";
	ui_category = "SMAA";
	ui_category_closed = true;
> = 25;

uniform float HqaaFxQualityCustom < __UNIFORM_SLIDER_FLOAT1
	ui_spacing = 3;
	ui_min = 25; ui_max = 400; ui_step = 1;
	ui_label = "% Quality";
	ui_tooltip = "Affects the maximum radius FXAA will search\nalong an edge gradient";
	ui_category = "FXAA";
	ui_category_closed = true;
> = 100;

uniform float HqaaFxTexelCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.25; ui_max = 4.0; ui_step = 0.01;
	ui_label = "Edge Gradient Texel Size";
	ui_tooltip = "Determines how far along an edge FXAA will move\nfrom one scan iteration to the next.\n\nLower = slower, more accurate\nHigher = faster, more artifacts";
	ui_category = "FXAA";
	ui_category_closed = true;
> = 1.0;

uniform float HqaaFxBlendCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "% Gradient Blending Strength\n\n";
	ui_tooltip = "Percentage of blending FXAA will apply to long slopes.\n"
				 "Lower = sharper image, Higher = more AA effect";
	ui_category = "FXAA";
	ui_category_closed = true;
> = 50;

uniform float HqaaHysteresisStrength <
	ui_type = "slider";
	ui_spacing = 3;
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "% Max Hysteresis";
	ui_tooltip = "Hysteresis correction adjusts the appearance of anti-aliased\npixels towards their original appearance, which helps\nto preserve detail in the final image.\n\n0% = Off (keep anti-aliasing result as-is)\n100% = Aggressive Correction";
	ui_category = "Hysteresis";
	ui_category_closed = true;
> = 33;

uniform float HqaaHysteresisFudgeFactor <
	ui_type = "slider";
	ui_min = 0; ui_max = 25; ui_step = 0.1;
	ui_label = "% Fudge Factor";
	ui_tooltip = "Ignore up to this much difference between the original pixel\nand the anti-aliasing result";
	ui_category = "Hysteresis";
	ui_category_closed = true;
> = 1.0;

uniform bool HqaaDoLumaHysteresis <
	ui_label = "Use Luma Difference Hysteresis?";
	ui_category = "Hysteresis";
	ui_category_closed = true;
> = true;

uniform bool HqaaDoSaturationHysteresis <
	ui_label = "Use Saturation Difference Hysteresis?\n";
	ui_category = "Hysteresis";
	ui_category_closed = false;
> = true;
#endif //HQAA_ADVANCED_MODE

#if HQAA_OUTPUT_MODE == 1
uniform float HqaaHdrNits < 
	ui_spacing = 3;
	ui_type = "slider";
	ui_min = 500.0; ui_max = 10000.0; ui_step = 100.0;
	ui_label = "HDR Nits";
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
	ui_label = "Enable Sharpening Effect?";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = false;

uniform float HqaaSharpenerStrength < __UNIFORM_SLIDER_FLOAT1
	ui_spacing = 3;
	ui_min = 0; ui_max = 1; ui_step = 0.01;
	ui_label = "Sharpening Strength";
	ui_tooltip = "Amount of sharpening to apply";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = 0.8;

uniform float HqaaSharpenerClamping < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 1; ui_step = 0.001;
	ui_label = "Clamp Strength";
	ui_tooltip = "How much to clamp sharpening strength when the pixel had AA applied to it\n"
	             "Zero means no clamp applied, one means no sharpening applied";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = 0.25;

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

uniform bool HqaaEnableBrightnessGain <
	ui_spacing = 3;
	ui_label = "Enable Brightness & Vibrance Gain?";
	ui_category = "Brightness & Vibrance";
	ui_category_closed = true;
> = false;

uniform float HqaaGainStrength < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 1.0; ui_step = 0.001;
	ui_spacing = 3;
	ui_label = "Brightness Gain";
	ui_category = "Brightness & Vibrance";
	ui_category_closed = true;
> = 0.0;

uniform bool HqaaGainLowLumaCorrection <
	ui_label = "Contrast Washout Correction";
	ui_tooltip = "Normalizes contrast ratio of resulting pixels\n"
				 "to reduce perceived contrast washout.";
	ui_category = "Brightness & Vibrance";
	ui_category_closed = true;
> = false;

uniform float HqaaVibranceStrength < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_spacing = 2;
	ui_label = "% Vibrance";
	ui_tooltip = "50% means no modification is performed and this option is skipped.";
	ui_text = "--------------------------------------------------------------------------------\n";
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

#if HQAA_OPTIONAL__TEMPORAL_STABILIZER
uniform float HqaaPreviousFrameWeight < __UNIFORM_SLIDER_FLOAT1
	ui_spacing = 3;
	ui_min = 0; ui_max = 1.0; ui_step = 0.001;
	ui_label = "Previous Frame Weight";
	ui_category = "Temporal Stabilizer";
	ui_category_closed = true;
	ui_tooltip = "Blends the previous frame with the current frame to stabilize results.";
> = 0.25;

uniform bool HqaaTemporalClamp <
	ui_label = "Clamp Maximum Weight?";
	ui_spacing = 2;
	ui_category = "Temporal Stabilizer";
	ui_category_closed = true;
	ui_tooltip = "When enabled the maximum amount of weight given to the previous\n"
				 "frame will be equal to the largest change in contrast in any\n"
				 "single color channel between the past frame and the current frame.";
> = false;

uniform int HqaaStabilizerIntro <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\nWhen enabled, this effect will blend the previous frame with the\n"
	          "current frame at the specified weight to minimize overcorrection\n"
			  "errors such as crawling text or wiggling lines.";
	ui_category = "Temporal Stabilizer";
	ui_category_closed = true;
>;
#endif //HQAA_OPTIONAL__TEMPORAL_STABILIZER

#if HQAA_OPTIONAL__DEBANDING
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
> = 16.0;

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
#endif //HQAA_OPTIONAL__DEBANDING

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
#endif //HQAA_DEBUG_MODE

///////////////////////////////////////////////// HUMAN+MACHINE PRESET REFERENCE //////////////////////////////////////////////////////////

#if HQAA_ADVANCED_MODE
uniform int HqaaPresetBreakdown <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n"
			  "-----------------------------------------------------------------------\n"
			  "|        |       Edges       |      SMAA       |        FXAA          |\n"
	          "|--Preset|-Threshold---Range-|-Corner---%Error-|-Qual---Texel---Blend-|\n"
	          "|--------|-----------|-------|--------|--------|------|-------|-------|\n"
			  "|     Low|   0.200   | 62.5% |   20%  |  Low   |  50% |  2.0  |  50%  |\n"
			  "|  Medium|   0.150   | 66.7% |   25%  |  Low   | 100% |  1.0  |  75%  |\n"
			  "|    High|   0.100   | 70.0% |   33%  |Balanced| 150% |  1.0  |  88%  |\n"
			  "|   Ultra|   0.075   | 75.0% |   50%  |  High  | 200% |  0.5  | 100%  |\n"
			  "-----------------------------------------------------------------------";
	ui_category = "Click me to see what settings each preset uses!";
	ui_category_closed = true;
>;

#define __HQAA_EDGE_THRESHOLD (HqaaEdgeThresholdCustom)
#define __HQAA_DYNAMIC_RANGE (HqaaDynamicThresholdCustom / 100.0)
#define __HQAA_SM_CORNERS (HqaaSmCorneringCustom / 100.0)
#define __HQAA_FX_QUALITY (HqaaFxQualityCustom / 100.0)
#define __HQAA_FX_TEXEL (HqaaFxTexelCustom)
#define __HQAA_FX_BLEND (HqaaFxBlendCustom / 100.0)
#define __HQAA_SM_ERRORMARGIN (HQAA_ERRORMARGIN_CUSTOM[HqaaEdgeErrorMarginCustom])

#else

static const float HQAA_THRESHOLD_PRESET[4] = {0.2, 0.15, 0.1, 0.075};
static const float HQAA_DYNAMIC_RANGE_PRESET[4] = {0.625, 0.666667, 0.7, 0.75};
static const float HQAA_SMAA_CORNER_ROUNDING_PRESET[4] = {0.2, 0.25, 0.333333, 0.5};
static const float HQAA_FXAA_SCANNING_MULTIPLIER_PRESET[4] = {0.5, 1.0, 1.5, 2.0};
static const float HQAA_FXAA_TEXEL_SIZE_PRESET[4] = {2.0, 1.0, 1.0, 0.5};
static const float HQAA_SUBPIX_PRESET[4] = {0.5, 0.75, 0.875, 1.0};
static const float HQAA_ERRORMARGIN_PRESET[4] = {4.0, 4.0, 5.0, 7.0};

#define __HQAA_EDGE_THRESHOLD (HQAA_THRESHOLD_PRESET[HqaaPreset])
#define __HQAA_DYNAMIC_RANGE (HQAA_DYNAMIC_RANGE_PRESET[HqaaPreset])
#define __HQAA_SM_CORNERS (HQAA_SMAA_CORNER_ROUNDING_PRESET[HqaaPreset])
#define __HQAA_FX_QUALITY (HQAA_FXAA_SCANNING_MULTIPLIER_PRESET[HqaaPreset])
#define __HQAA_FX_TEXEL (HQAA_FXAA_TEXEL_SIZE_PRESET[HqaaPreset])
#define __HQAA_FX_BLEND (HQAA_SUBPIX_PRESET[HqaaPreset])
#define __HQAA_SM_ERRORMARGIN (HQAA_ERRORMARGIN_PRESET[HqaaPreset])

#endif //HQAA_ADVANCED_MODE

/*****************************************************************************************************************************************/
/*********************************************************** UI SETUP END ****************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/******************************************************** SYNTAX SETUP START *************************************************************/
/*****************************************************************************************************************************************/

#define __HQAA_DISPLAY_NUMERATOR max(BUFFER_HEIGHT, BUFFER_WIDTH)
#define __HQAA_SMALLEST_COLOR_STEP rcp(pow(2, BUFFER_COLOR_BIT_DEPTH))
#define __HQAA_CONST_E 2.718282
#define __HQAA_LUMA_REF float3(0.333333, 0.333334, 0.333333)
#define __HQAA_WEIGHT_M float3(0.33, 0.4, 0.27)
#define __HQAA_WEIGHT_L float3(0.1, 0.3, 0.6)
#define __HQAA_WEIGHT_R float3(0.6, 0.3, 0.1)

#if (__RENDERER__ >= 0x10000 && __RENDERER__ < 0x20000) || (__RENDERER__ >= 0x09000 && __RENDERER__ < 0x0A000)
#define __HQAA_FX_RADIUS 16.0
#else
#define __HQAA_FX_RADIUS (16.0 / __HQAA_FX_TEXEL)
#endif

#define __HQAA_FX_WEIGHT __HQAA_WEIGHT_M

#define __HQAA_SM_RADIUS (__HQAA_DISPLAY_NUMERATOR * 0.125)
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

#define HQAAdotmax(x) max(max((x).r, (x).g), (x).b)
#define HQAAdotmin(x) min(min((x).r, (x).g), (x).b)

#define HQAAvec3add(x) ((x).r + (x).g + (x).b)

/*****************************************************************************************************************************************/
/********************************************************* SYNTAX SETUP END **************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/******************************************************** SUPPORT CODE START *************************************************************/
/*****************************************************************************************************************************************/

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
	float xpm2rcp = pow(clamp(x, 0.0, 1.0), 0.012683);
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
	float2 xpm2rcp = pow(clamp(x, 0.0, 1.0), 0.012683);
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
	float3 xpm2rcp = pow(clamp(x, 0.0, 1.0), 0.012683);
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
	float4 xpm2rcp = pow(clamp(x, 0.0, 1.0), 0.012683);
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
	float xpm1 = pow(clamp(x / 500.0, 0.0, 1.0), 0.159302);
#else
	float xpm1 = pow(clamp(x / 10000.0, 0.0, 1.0), 0.159302);
#endif
	float numerator = 0.8359375 + (18.8515625 * xpm1);
	float denominator = 1.0 + (18.6875 * xpm1);
	
	return pow(abs(numerator / denominator), 78.84375);
}
float2 decodePQ(float2 x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	float2 xpm1 = pow(clamp(x / 500.0, 0.0, 1.0), 0.159302);
#else
	float2 xpm1 = pow(clamp(x / 10000.0, 0.0, 1.0), 0.159302);
#endif
	float2 numerator = 0.8359375 + (18.8515625 * xpm1);
	float2 denominator = 1.0 + (18.6875 * xpm1);
	
	return pow(abs(numerator / denominator), 78.84375);
}
float3 decodePQ(float3 x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	float3 xpm1 = pow(clamp(x / 500.0, 0.0, 1.0), 0.159302);
#else
	float3 xpm1 = pow(clamp(x / 10000.0, 0.0, 1.0), 0.159302);
#endif
	float3 numerator = 0.8359375 + (18.8515625 * xpm1);
	float3 denominator = 1.0 + (18.6875 * xpm1);
	
	return pow(abs(numerator / denominator), 78.84375);
}
float4 decodePQ(float4 x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	float4 xpm1 = pow(clamp(x / 500.0, 0.0, 1.0), 0.159302);
#else
	float4 xpm1 = pow(clamp(x / 10000.0, 0.0, 1.0), 0.159302);
#endif
	float4 numerator = 0.8359375 + (18.8515625 * xpm1);
	float4 denominator = 1.0 + (18.6875 * xpm1);
	
	return pow(abs(numerator / denominator), 78.84375);
}
#endif //HQAA_OUTPUT_MODE == 2

#if HQAA_OUTPUT_MODE == 3
float fastencodePQ(float x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	float y = saturate(x) * 4.728708;
#else
	float y = saturate(x) * 10.0;
#endif
	y *= y;
	y *= y;
	return y;
}
float2 fastencodePQ(float2 x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	float2 y = saturate(x) * 4.728708;
#else
	float2 y = saturate(x) * 10.0;
#endif
	y *= y;
	y *= y;
	return y;
}
float3 fastencodePQ(float3 x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	float3 y = saturate(x) * 4.728708;
#else
	float3 y = saturate(x) * 10.0;
#endif
	y *= y;
	y *= y;
	return y;
}
float4 fastencodePQ(float4 x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	float4 y = saturate(x) * 4.728708;
#else
	float4 y = saturate(x) * 10.0;
#endif
	y *= y;
	y *= y;
	return y;
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
	return clamp(x, 0.0, HqaaHdrNits) / HqaaHdrNits;
}
float2 decodeHDR(float2 x)
{
	return clamp(x, 0.0, HqaaHdrNits) / HqaaHdrNits;
}
float3 decodeHDR(float3 x)
{
	return clamp(x, 0.0, HqaaHdrNits) / HqaaHdrNits;
}
float4 decodeHDR(float4 x)
{
	return clamp(x, 0.0, HqaaHdrNits) / HqaaHdrNits;
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

//////////////////////////////////////////////////// SATURATION CALCULATIONS //////////////////////////////////////////////////////////////

float dotsat(float3 x)
{
	return ((HQAAdotmax(x) - HQAAdotmin(x)) / (1.0 - (2.0 * dot(x, __HQAA_LUMA_REF) - 1.0)));
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
	float2 highlow = float2(HQAAdotmax(outdot), HQAAdotmin(outdot));
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

float squared(float x)
{
	return x * x;
}

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
	
	float searchrange = trunc(__HQAA_SM_RADIUS);
	
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
	float3 middle = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord).rgb;
	
#if HQAA_TAA_ASSIST_MODE
	bool lumachange = HQAA_Tex2D(HQAAsamplerLumaMask, texcoord).r > 0.0;
	if (!lumachange) return float(0.0).xx;
#endif //HQAA_TAA_ASSIST_MODE

	float basethreshold = __HQAA_EDGE_THRESHOLD;
	
	float middlesat = abs(0.5 - dotsat(middle));
	float contrastmultiplier = middlesat + abs(0.5 - dot(middle, __HQAA_LUMA_REF));
	float2 threshold = mad(contrastmultiplier, -(__HQAA_DYNAMIC_RANGE * basethreshold), basethreshold).xx;
	
	float2 edges = float(0.0).xx;
	
    float L = dot(middle, __HQAA_WEIGHT_M);
	
	float3 dotscalar = HQAA_DecodeTex2D(ReShade::BackBuffer, offset[0].xy).rgb;
    float Lleft = abs(L - dot(dotscalar, __HQAA_WEIGHT_L));
    float Cleft = HQAAvec3add(abs(middle - dotscalar)) / 3.0;
    
	dotscalar = HQAA_DecodeTex2D(ReShade::BackBuffer, offset[0].zw).rgb;
    float Ltop = abs(L - dot(dotscalar, __HQAA_WEIGHT_M));
    float Ctop = HQAAvec3add(abs(middle - dotscalar)) / 3.0;
    
    dotscalar = HQAA_DecodeTex2D(ReShade::BackBuffer, offset[1].xy).rgb;
	float Lright = abs(L - dot(dotscalar, __HQAA_WEIGHT_R));
	float Cright = HQAAvec3add(abs(middle - dotscalar)) / 3.0;
	
	dotscalar = HQAA_DecodeTex2D(ReShade::BackBuffer, offset[1].zw).rgb;
	float Lbottom = abs(L - dot(dotscalar, __HQAA_WEIGHT_M));
	float Cbottom = HQAAvec3add(abs(middle - dotscalar)) / 3.0;
	
	bool useluma = max(max(Lleft, Ltop), max(Lright, Lbottom)) > max(max(Cleft, Ctop), max(Cright, Cbottom));
	float finalDelta;
	float4 delta;
	float scale;
	
	if (useluma)
	{
		// range effectively 1 to a bit under 3
		dotscalar = __HQAA_LUMA_REF * middle;
		scale = sqrt(clamp(log2(rcp(HQAAvec3add(dotscalar))), 1.0, 9.0));
		
    	delta = float4(Lleft, Ltop, Lright, Lbottom);
    
   	 edges = step(threshold, delta.xy);
    
		float2 maxDelta = max(delta.xy, delta.zw);
	
		dotscalar = HQAA_DecodeTex2D(ReShade::BackBuffer, offset[2].xy).rgb;
		float Lleftleft = abs(L - dot(dotscalar, __HQAA_WEIGHT_L));
	
		dotscalar = HQAA_DecodeTex2D(ReShade::BackBuffer, offset[2].zw).rgb;
		float Ltoptop = abs(L - dot(dotscalar, __HQAA_WEIGHT_M));
	
		delta.zw = abs(float2(Lleft, Ltop) - float2(Lleftleft, Ltoptop));

		maxDelta = max(maxDelta, delta.zw);
	
		finalDelta = max(maxDelta.x, maxDelta.y);
	}
	else
	{
		// range 1 to 3
		scale = 1.0 + (middlesat * 4.0);
		
 	   delta = float4(Cleft, Ctop, Cright, Cbottom);
    
	    edges = step(threshold, delta.xy);
    
		float2 maxDelta = max(delta.xy, delta.zw);
	
		dotscalar = HQAA_DecodeTex2D(ReShade::BackBuffer, offset[2].xy).rgb;
		float Cleftleft = HQAAvec3add(abs(middle - dotscalar)) / 3.0;
	
		dotscalar = HQAA_DecodeTex2D(ReShade::BackBuffer, offset[2].zw).rgb;
		float Ctoptop = HQAAvec3add(abs(middle - dotscalar)) / 3.0;
	
		delta.zw = abs(float2(Cleft, Ctop) - float2(Cleftleft, Ctoptop));

		maxDelta = max(maxDelta, delta.zw);
	
		finalDelta = max(maxDelta.x, maxDelta.y);
	}
	
	edges *= step(finalDelta, scale * delta.xy);
	return float4(edges, HQAA_Tex2D(HQAAsamplerLastEdges, texcoord).rg);
}

/////////////////////////////////////////////////////// ERROR REDUCTION ///////////////////////////////////////////////////////////////////
float4 HQAAEdgeErrorReductionPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 pixel = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord).rgb;
	float2 bufferdata = float2(dot(pixel, __HQAA_LUMA_REF), dotsat(pixel));
	float2 edges = saturate(HQAA_Tex2D(HQAAsamplerSMweights, texcoord).rg + HQAA_Tex2D(HQAAsamplerSMweights, texcoord).ba + HQAA_Tex2D(HQAAsamplerLastEdges, texcoord).ba);
	
	// skip checking neighbors if there's already no detected edge
	if (!any(edges)) return float4(edges, bufferdata);
	
    float2 a = saturate(HQAA_Tex2DOffset(HQAAsamplerSMweights, texcoord, int2(-1, -1)).rg + HQAA_Tex2DOffset(HQAAsamplerSMweights, texcoord, int2(-1, -1)).ba + HQAA_Tex2DOffset(HQAAsamplerLastEdges, texcoord, int2(-1, -1)).ba);
    float2 c = saturate(HQAA_Tex2DOffset(HQAAsamplerSMweights, texcoord, int2(1, -1)).rg + HQAA_Tex2DOffset(HQAAsamplerSMweights, texcoord, int2(1, -1)).ba + HQAA_Tex2DOffset(HQAAsamplerLastEdges, texcoord, int2(1, -1)).ba);
    float2 g = saturate(HQAA_Tex2DOffset(HQAAsamplerSMweights, texcoord, int2(-1, 1)).rg + HQAA_Tex2DOffset(HQAAsamplerSMweights, texcoord, int2(-1, 1)).ba + HQAA_Tex2DOffset(HQAAsamplerLastEdges, texcoord, int2(-1, 1)).ba);
    float2 i = saturate(HQAA_Tex2DOffset(HQAAsamplerSMweights, texcoord, int2(1, 1)).rg + HQAA_Tex2DOffset(HQAAsamplerSMweights, texcoord, int2(1, 1)).ba + HQAA_Tex2DOffset(HQAAsamplerLastEdges, texcoord, int2(1, 1)).ba);
    float2 b = saturate(HQAA_Tex2DOffset(HQAAsamplerSMweights, texcoord, int2(0, -1)).rg + HQAA_Tex2DOffset(HQAAsamplerSMweights, texcoord, int2(0, -1)).ba + HQAA_Tex2DOffset(HQAAsamplerLastEdges, texcoord, int2(0, -1)).ba);
    float2 d = saturate(HQAA_Tex2DOffset(HQAAsamplerSMweights, texcoord, int2(-1, 0)).rg + HQAA_Tex2DOffset(HQAAsamplerSMweights, texcoord, int2(-1, 0)).ba + HQAA_Tex2DOffset(HQAAsamplerLastEdges, texcoord, int2(-1, 0)).ba);
    float2 f = saturate(HQAA_Tex2DOffset(HQAAsamplerSMweights, texcoord, int2(1, 0)).rg + HQAA_Tex2DOffset(HQAAsamplerSMweights, texcoord, int2(1, 0)).ba + HQAA_Tex2DOffset(HQAAsamplerLastEdges, texcoord, int2(1, 0)).ba);
    float2 h = saturate(HQAA_Tex2DOffset(HQAAsamplerSMweights, texcoord, int2(0, 1)).rg + HQAA_Tex2DOffset(HQAAsamplerSMweights, texcoord, int2(0, 1)).ba + HQAA_Tex2DOffset(HQAAsamplerLastEdges, texcoord, int2(0, 1)).ba);
    
	float2 adjacentsum = a + c + g + i + b + d + f + h;
	adjacentsum *= edges; // keep only neighbor count of same type

	bool validedge = any(saturate(adjacentsum - 1.0)) && !any(saturate(adjacentsum - __HQAA_SM_ERRORMARGIN));
	if (validedge) return float4(edges, bufferdata);
	else return float4(0.0, 0.0, bufferdata);
}

//////////////////////////////////////////////////////// N-1 EDGES COPY ///////////////////////////////////////////////////////////////////
float4 HQAASavePreviousEdgesPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
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
float3 HQAANeighborhoodBlendingPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float4 offset : TEXCOORD1) : SV_Target
{
    float4 m = float4(HQAA_Tex2D(HQAAsamplerSMweights, offset.xy).a, HQAA_Tex2D(HQAAsamplerSMweights, offset.zw).g, HQAA_Tex2D(HQAAsamplerSMweights, texcoord).zx);
	float3 resultAA = HQAA_Tex2D(ReShade::BackBuffer, texcoord).rgb;
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
    float3 rgbyM = HQAA_Tex2D(ReShade::BackBuffer, texcoord).rgb;
	
#if HQAA_TAA_ASSIST_MODE
	bool lumachange = HQAA_Tex2D(HQAAsamplerLumaMask, texcoord).r > 0.0;
	if (lumachange) {
#endif //HQAA_TAA_ASSIST_MODE

	rgbyM = ConditionalDecode(rgbyM);
	float lumaMa = dot(rgbyM, __HQAA_WEIGHT_M);
	
    float basethreshold = __HQAA_EDGE_THRESHOLD;
	
	float contrastmultiplier = abs(0.5 - dotsat(rgbyM)) + abs(0.5 - dot(rgbyM, __HQAA_LUMA_REF));
	contrastmultiplier *= contrastmultiplier;
	float fxaaQualityEdgeThreshold = mad(contrastmultiplier, -(__HQAA_DYNAMIC_RANGE * basethreshold), basethreshold);

    float lumaS = dot(HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 0, 1)).rgb, __HQAA_FX_WEIGHT);
    float lumaE = dot(HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 1, 0)).rgb, __HQAA_FX_WEIGHT);
    float lumaN = dot(HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 0,-1)).rgb, __HQAA_FX_WEIGHT);
    float lumaW = dot(HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, 0)).rgb, __HQAA_FX_WEIGHT);
	
    float rangeMax = HQAAmax5(lumaS, lumaE, lumaN, lumaW, lumaMa);
    float rangeMin = HQAAmin5(lumaS, lumaE, lumaN, lumaW, lumaMa);
	
    float range = rangeMax - rangeMin;
    
	// early exit check
	bool SMAAedge = any(HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord).rg);
    bool earlyExit = range < fxaaQualityEdgeThreshold && !SMAAedge;
	if (earlyExit)
#if HQAA_DEBUG_MODE
		if (clamp(HqaaDebugMode, 3, 5) == HqaaDebugMode) return float(0.0).xxx;
		else
#endif //HQAA_DEBUG_MODE
		return ConditionalEncode(rgbyM.rgb);
	
    float lumaNW = dot(HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1,-1)).rgb, __HQAA_FX_WEIGHT);
    float lumaSE = dot(HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 1, 1)).rgb, __HQAA_FX_WEIGHT);
    float lumaNE = dot(HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 1,-1)).rgb, __HQAA_FX_WEIGHT);
    float lumaSW = dot(HQAA_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, 1)).rgb, __HQAA_FX_WEIGHT);
	
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
    
    float lumaEndN = dot(HQAA_DecodeTex2D(ReShade::BackBuffer, posN).rgb, __HQAA_FX_WEIGHT);
    float lumaEndP = dot(HQAA_DecodeTex2D(ReShade::BackBuffer, posP).rgb, __HQAA_FX_WEIGHT);
	
    float gradientScaled = max(abs(gradientN), abs(gradientS)) * 0.25;
    bool lumaMLTZero = mad(0.5, -lumaNN, lumaMa) < 0.0;
	
	lumaNN *= 0.5;
	
    lumaEndN -= lumaNN;
    lumaEndP -= lumaNN;
	
    bool doneN = abs(lumaEndN) >= gradientScaled;
    bool doneP = abs(lumaEndP) >= gradientScaled;
    bool doneNP;
	
	uint iterations = 0;
	
	uint maxiterations = trunc(__HQAA_FX_RADIUS * __HQAA_FX_QUALITY);
	
	[loop] while (iterations < maxiterations)
	{
		doneNP = doneN && doneP;
		if (doneNP) break;
		if (!doneN)
		{
			posN -= offNP;
			lumaEndN = dot(HQAA_DecodeTex2D(ReShade::BackBuffer, posN).rgb, __HQAA_FX_WEIGHT);
			lumaEndN -= lumaNN;
			doneN = abs(lumaEndN) >= gradientScaled;
		}
		if (!doneP)
		{
			posP += offNP;
			lumaEndP = dot(HQAA_DecodeTex2D(ReShade::BackBuffer, posP).rgb, __HQAA_FX_WEIGHT);
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
    float maxblending = __HQAA_FX_BLEND;
    float subpixOut = pixelOffset * maxblending;
	
	[branch] if (!goodSpan)
	{
		subpixOut = mad(mad(2.0, lumaS + lumaE + lumaN + lumaW, lumaNW + lumaSE + lumaNE + lumaSW), 0.083333, -lumaMa) * rcp(range); //ABC
		subpixOut = squared(saturate(mad(-2.0, subpixOut, 3.0) * (subpixOut * subpixOut))) * maxblending * pixelOffset; // DEFGH
	}

    float2 posM = texcoord;
	HQAAMovc(bool2(!horzSpan, horzSpan), posM, float2(posM.x + lengthSign * subpixOut, posM.y + lengthSign * subpixOut));
    
	// Establish result
	float3 resultAA = HQAA_DecodeTex2D(ReShade::BackBuffer, posM).rgb;
	
	// output selection
#if HQAA_DEBUG_MODE
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
#endif //HQAA_DEBUG_MODE
	// normal output
	return ConditionalEncode(resultAA);
#if HQAA_TAA_ASSIST_MODE
	}
	else {
#if HQAA_DEBUG_MODE
		if (clamp(HqaaDebugMode, 3, 5) == HqaaDebugMode) return float(0.0).xxx;
		else
#endif
		return rgbyM.rgb;
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

	bool skiphysteresis = ( (HqaaHysteresisStrength == 0.0) || ((!HqaaDoLumaHysteresis) && (!HqaaDoSaturationHysteresis))
#if HQAA_TAA_ASSIST_MODE
	|| (!lumachange)
#endif //HQAA_TAA_ASSIST_MODE
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
	float3 AAdot = pixel;
#endif

	float multiplier = HqaaHysteresisStrength / 100.0;
	float fudgefactor = HqaaHysteresisFudgeFactor / 100.0;
	
	float hysteresis = (dot(pixel, __HQAA_LUMA_REF) - edgedata.b) * multiplier;
	bool runcorrection = (abs(hysteresis) > fudgefactor) && HqaaDoLumaHysteresis;
	[branch] if (runcorrection)
	{
		// perform weighting using computed hysteresis
		pixel = pow(abs(1.0 + hysteresis) * 2.0, log2(pixel));
	}
	
	float sathysteresis = (dotsat(pixel) - edgedata.a) * multiplier;
	runcorrection = (abs(sathysteresis) > fudgefactor) && HqaaDoSaturationHysteresis;
	[branch] if (runcorrection)
	{
		// perform weighting using computed hysteresis
		pixel = AdjustSaturation(pixel, -sathysteresis);
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
	ori = ConditionalDecode(ori);
	
    // Settings
#if (__RENDERER__ >= 0x10000 && __RENDERER__ < 0x20000) || (__RENDERER__ >= 0x09000 && __RENDERER__ < 0x0A000)
	float avgdiff, maxdiff, middiff;
	if (HqaaDebandPreset == 0) { avgdiff = 0.002353; maxdiff = 0.007451; middiff = 0.004706; }
	else if (HqaaDebandPreset == 1) { avgdiff = 0.007059; maxdiff = 0.015686; middiff = 0.007843; }
	else { avgdiff = 0.013333; maxdiff = 0.026667; middiff = 0.012941; }
#else
    float avgdiff[3] = {0.002353, 0.007059, 0.013333}; // 0.6/255, 1.8/255, 3.4/255
    float maxdiff[3] = {0.007451, 0.015686, 0.026667}; // 1.9/255, 4.0/255, 6.8/255
    float middiff[3] = {0.004706, 0.007843, 0.012941}; // 1.2/255, 2.0/255, 3.3/255
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
	
		if (any(HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord).rg))
			sharpening *= (1.0 - HqaaSharpenerClamping);
	
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
		float3 wRGB = -rcp(ampRGB * mad(-3.0, saturate(sharpening), 8.0));
		float3 window = (b + d) + (f + h);
	
		float3 outColor = saturate(mad(window, wRGB, casdot) * rcp(mad(4.0, wRGB, 1.0)));
		casdot = lerp(casdot, outColor, sharpening);
	
		pixel = casdot;
	}
	else pixel = ConditionalDecode(pixel); // initially skipped for performance optimization

	if (HqaaEnableBrightnessGain)
	{
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
				float contrastgain = log(rcp(dot(outdot, __HQAA_LUMA_REF) - channelfloor)) * pow(__HQAA_CONST_E, (1.0 + channelfloor) * __HQAA_CONST_E) * HqaaGainStrength;
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
	}

#if HQAA_OPTIONAL__TEMPORAL_STABILIZER
	float3 current = pixel;
	float3 previous = HQAA_Tex2D(HQAAsamplerLastFrame, texcoord).rgb;
	
	// values above 0.9 can produce artifacts or halt frame advancement entirely
	float blendweight = min(HqaaPreviousFrameWeight, 0.9);
	
	if (HqaaTemporalClamp) {
		float contrastdelta = sqrt(dot(abs(current - previous), __HQAA_LUMA_REF));
		blendweight = min(contrastdelta, blendweight);
	}
	
	pixel = lerp(current, previous, blendweight);
#endif //HQAA_OPTIONAL__TEMPORAL_STABILIZER

	return ConditionalEncode(pixel);
#if HQAA_DEBUG_MODE
	}
	else return pixel;
#endif
}
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
		ClearRenderTargets = true;
	}
	pass EdgeErrorReduction
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAEdgeErrorReductionPS;
		RenderTarget = HQAAedgesTex;
		ClearRenderTargets = true;
	}
	pass SaveEdges
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAASavePreviousEdgesPS;
		RenderTarget = HQAAlastedgesTex;
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
	pass Hysteresis
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAHysteresisPS;
	}
#if HQAA_OPTIONAL_EFFECTS
#if HQAA_OPTIONAL__DEBANDING
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
#endif //HQAA_OPTIONAL__DEBANDING
	pass OptionalEffects
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAOptionalEffectPassPS;
	}
#if HQAA_OPTIONAL__TEMPORAL_STABILIZER
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
