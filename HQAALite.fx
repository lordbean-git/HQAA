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
 **/
 
 // All original code not attributed to the above authors is copyright (c) Derek Brush aka "lordbean" (derekbrush@gmail.com)

/** Permission is hereby granted, free of charge, to any person obtaining a copy
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

#ifndef HQAAL_FXAA_MULTISAMPLING
	#define HQAAL_FXAA_MULTISAMPLING 2
#endif
#if HQAAL_FXAA_MULTISAMPLING > 6 || HQAAL_FXAA_MULTISAMPLING < 0
	#undef HQAAL_FXAA_MULTISAMPLING
	#define HQAAL_FXAA_MULTISAMPLING 2
#endif

#ifndef HQAAL_ADVANCED_MODE
	#define HQAAL_ADVANCED_MODE 0
#endif
#if HQAAL_ADVANCED_MODE > 1 || HQAAL_ADVANCED_MODE < 0
	#undef HQAAL_ADVANCED_MODE
	#define HQAAL_ADVANCED_MODE 0
#endif

uniform uint HqaaFramecounter < source = "framecount"; >;
#define __HQAAL_ALT_FRAME ((HqaaFramecounter + HqaaSourceInterpolationOffset) % 2 == 0)
#define __HQAAL_QUAD_FRAME ((HqaaFramecounter + HqaaSourceInterpolationOffset) % 4 == 1)
#define __HQAAL_THIRD_FRAME (HqaaFramecounter % 3 == 1)

/////////////////////////////////////////////////////// GLOBAL SETUP OPTIONS //////////////////////////////////////////////////////////////

uniform int HqaaAboutSTART <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n------------------------------- HQAA v28.19 Lite -------------------------------";
>;

uniform int HQAAintroduction <
	ui_spacing = 3;
	ui_type = "radio";
	ui_label = "Version: 28.19";
	ui_text = "--------------------------------------------------------------------------------\n"
			"Hybrid high-Quality Anti-Aliasing, a shader by lordbean\n"
			"https://github.com/lordbean-git/HQAA/\n"
			"--------------------------------------------------------------------------------\n\n"
			
			"Currently Compiled Configuration:\n"
			#if HQAAL_ADVANCED_MODE
			"Advanced Mode:                                                             on  *\n"
			#else
			"Advanced Mode:                                                            off\n"
			#endif
			#if HQAAL_FXAA_MULTISAMPLING < 2
			"FXAA Multisampling:                                                       off  *\n"
			#elif HQAAL_FXAA_MULTISAMPLING > 5
			"FXAA Multisampling:                                                   on (6x)  *\n"
			#elif HQAAL_FXAA_MULTISAMPLING > 4
			"FXAA Multisampling:                                                   on (5x)  *\n"
			#elif HQAAL_FXAA_MULTISAMPLING > 3
			"FXAA Multisampling:                                                   on (4x)  *\n"
			#elif HQAAL_FXAA_MULTISAMPLING > 2
			"FXAA Multisampling:                                                   on (3x)  *\n"
			#elif HQAAL_FXAA_MULTISAMPLING > 1
			"FXAA Multisampling:                                                   on (2x)\n"
			#endif //HQAAL_FXAA_MULTISAMPLING
			
			"\n--------------------------------------------------------------------------------\n\n"
			
			"Remarks:\n"
			
			"\nFXAA Multisampling can be used to increase correction strength in cases such\n"
			"as edges with more than one color gradient or along objects that have highly\n"
			"irregular geometry. Costs some performance for each extra pass.\n"
			"Valid range: 1 to 6. Higher values are ignored.\n"
			
			"\n--------------------------------------------------------------------------------"
			"\nSee the 'Preprocessor definitions' section for color, feature, and mode toggles.\n"
			"--------------------------------------------------------------------------------";
	ui_tooltip = "Lite Edition";
	ui_category = "About";
	ui_category_closed = true;
>;

uniform uint HqaaOutputMode <
	ui_type = "radio";
	ui_spacing = 3;
	ui_label = " ";
	ui_items = "Normal (sRGB)\0HDR, Direct Nits Scale\0Perceptual Quantizer, Accurate (HDR10, scRGB)\0Perceptual Quantizer, Fast Transcode (HDR10, scRGB)\0";
	ui_category = "Output Mode";
	ui_category_closed = true;
> = 0;

uniform float HqaaHdrNits < 
	ui_spacing = 3;
	ui_type = "slider";
	ui_min = 300.0; ui_max = 10000.0; ui_step = 100.0;
	ui_label = "HDR Nits\n\n";
	ui_tooltip = "If the scene brightness changes after HQAA runs, try\n"
				 "adjusting this value up or down until it looks right.\n"
				 "Only has effect when using the HDR Nits mode.";
	ui_category = "Output Mode";
	ui_category_closed = true;
> = 1000.0;

uniform bool HqaaEnableSharpening <
	ui_spacing = 3;
	ui_label = "Enable Sharpening";
	ui_tooltip = "Performs full-scene AMD Contrast-Adaptive Sharpening\n"
				"which uses SMAA edge data to reduce sharpen strength\n"
				"in regions containing edges. Automatically removed\n"
				"from the compiled shader when disabled and ReShade\n"
				"is in Performance Mode.";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = true;

uniform float HqaaSharpenerStrength <
	ui_type = "slider";
	ui_spacing = 3;
	ui_min = 0; ui_max = 1; ui_step = 0.01;
	ui_label = "Sharpening Strength";
	ui_tooltip = "Amount of sharpening to apply";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = 1.0;

uniform float HqaaSharpenerAdaptation <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
	ui_label = "Sharpening Contrast";
	ui_tooltip = "Affects how much the CAS math will cause\ncontrasting details to stand out.";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = 0.625;

uniform float HqaaSharpenOffset <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
	ui_label = "Sampling Offset";
	ui_tooltip = "Scales the sample pattern up or down\n"
				 "around the middle pixel. Helps to fine\n"
				 "tune the overall CAS effect.";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = 0.75;

uniform float HqaaSharpenerClamping <
	ui_spacing = 3;
	ui_type = "slider";
	ui_min = 0; ui_max = 1; ui_step = 0.001;
	ui_label = "Clamp Strength\n\n";
	ui_tooltip = "How much to clamp sharpening strength when the pixel had AA applied to it\n"
	             "Zero means no clamp applied, one means no sharpening applied";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = 0.5;

uniform uint HqaaDebugMode <
	ui_type = "radio";
	ui_category = "Debug";
	ui_category_closed = true;
	ui_spacing = 3;
	ui_label = "Mouseover for info";
	ui_text = "Debug Mode:";
	ui_items = "Off\n\n\0Detected Edges\0SMAA Blend Weights\n\n\0FXAA Results\0FXAA Lumas\0FXAA Metrics\n\n\0Hysteresis Pattern\n\n\0Dynamic Threshold Usage\n\n\0Disable SMAA\0Disable FXAA\0\n\n";
	ui_tooltip = "Useful primarily for learning what everything\n"
				 "does when using advanced mode setup. Debug\n"
				 "instructions are compiled out of the shader\n"
				 "when 'Off' is selected and ReShade is in\n"
				 "Performance Mode. You can find additional\n"
				 "info on how to read each debug mode in the\n"
				 "'DEBUG README' dropdown near the bottom.";
> = 0;

uniform int HqaaAboutEOF <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n--------------------------------------------------------------------------------";
>;

#if !HQAAL_ADVANCED_MODE
uniform uint HqaaPreset <
	ui_type = "combo";
	ui_label = "Quality Preset";
	ui_tooltip = "Quality of the Anti-Aliasing effect.\n"
				 "Higher presets look better but take more\n"
				 "GPU time to compute. Set HQAAL_ADVANCED_MODE\n"
				 "to 1 to customize all options.";
	ui_items = "Low\0Medium\0High\0Ultra\0";
> = 2;

static const float HqaaNoiseControlStrength = 20.;
static const float HqaaLowLumaThreshold = 0.25;
static const bool HqaaDoLumaHysteresis = true;
static const bool HqaaFxEarlyExit = true;
static const uint HqaaSourceInterpolation = 0;
static const uint HqaaSourceInterpolationOffset = 0;

#else
uniform float HqaaEdgeThresholdCustom <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_spacing = 3;
	ui_label = "Edge Detection Threshold";
	ui_tooltip = "Local contrast required to be considered an edge";
	ui_category = "Edge Detection";
	ui_category_closed = true;
> = 0.05;

uniform float HqaaLowLumaThreshold <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
	ui_label = "Low Luma Threshold";
	ui_tooltip = "Luma level below which dynamic thresholding activates";
	ui_spacing = 3;
	ui_category = "Edge Detection";
	ui_category_closed = true;
> = 0.25;

uniform float HqaaDynamicThresholdCustom <
	ui_type = "slider";
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "% Dynamic Range";
	ui_tooltip = "Maximum reduction of edge threshold (% base threshold)\n"
				 "permitted when detecting low-brightness edges.\n"
				 "Lower = faster, might miss low-contrast edges\n"
				 "Higher = slower, catches more edges in dark scenes";
	ui_category = "Edge Detection";
	ui_category_closed = true;
> = 75;

uniform uint HqaaFxQualityCustom <
	ui_spacing = 3;
	ui_type = "slider";
	ui_min = 5; ui_max = 100; ui_step = 1;
	ui_label = "Scan Distance";
	ui_tooltip = "Maximum radius from center dot\nthat SMAA and FXAA will scan.";
	ui_category = "Edge Detection";
	ui_category_closed = true;
> = 64;

uniform float HqaaNoiseControlStrength <
	ui_type = "slider";
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "Noise Control Strength";
	ui_tooltip = "Controls how strongly AA blending will be clamped when\n"
				 "the output would cause a high luma delta.";
	ui_category = "Edge Detection";
	ui_category_closed = true;
> = 20.;

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

uniform float HqaaSmCorneringCustom <
	ui_spacing = 3;
	ui_type = "slider";
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_spacing = 2;
	ui_label = "% Corner Rounding\n\n";
	ui_tooltip = "Affects the amount of blending performed when SMAA\ndetects crossing edges";
	ui_category = "SMAA";
	ui_category_closed = true;
> = 50;

uniform float HqaaFxTexelCustom <
	ui_type = "slider";
	ui_min = 0.1; ui_max = 2.0; ui_step = 0.01;
	ui_spacing = 3;
	ui_label = "Edge Gradient Texel Size";
	ui_tooltip = "Determines how far along an edge FXAA will move\nfrom one scan iteration to the next.\n\nLower = slower, more accurate\nHigher = faster, causes more blur";
	ui_category = "FXAA";
	ui_category_closed = true;
> = 0.5;

uniform float HqaaFxBlendCustom <
	ui_type = "slider";
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "% Blending Strength";
	ui_tooltip = "Percentage of blending FXAA will apply to edges.\n"
				 "Lower = sharper image, Higher = more AA effect";
	ui_category = "FXAA";
	ui_category_closed = true;
> = 100;

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
> = false;

uniform float HqaaHysteresisStrength <
	ui_type = "slider";
	ui_spacing = 3;
	ui_min = 0; ui_max = 100; ui_step = 0.1;
	ui_label = "% Strength";
	ui_tooltip = "0% = Off (keep anti-aliasing result as-is)\n100% = Aggressive Correction";
	ui_category = "Hysteresis";
	ui_category_closed = true;
> = 40.0;

uniform float HqaaHysteresisFudgeFactor <
	ui_type = "slider";
	ui_min = 0; ui_max = 25; ui_step = 0.01;
	ui_label = "% Fudge Factor\n\n";
	ui_tooltip = "Ignore up to this much difference between the\noriginal pixel and the anti-aliasing result";
	ui_category = "Hysteresis";
	ui_category_closed = true;
> = 0.0;
#endif //HQAAL_ADVANCED_MODE

uniform int HqaaOptionsEOF <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n--------------------------------------------------------------------------------";
>;

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
			  "Dynamic Threshold Usage displays black pixels if no reduction\n"
			  "was applied and green pixels representing a lowered threshold,\n"
			  "brighter dots indicating stronger reductions.\n"
	          "----------------------------------------------------------------";
	ui_category = "DEBUG README";
	ui_category_closed = true;
>;

///////////////////////////////////////////////// HUMAN+MACHINE PRESET REFERENCE //////////////////////////////////////////////////////////

#if HQAAL_ADVANCED_MODE
uniform int HqaaPresetBreakdown <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n"
			  "---------------------------------------------------------------------------------\n"
			  "|        |           Edges          |  SMAA  |     FXAA      |     Hysteresis   |\n"
	          "|--Preset|-Threshold---Range---Dist-|-Corner-|-Texel---Blend-|-Strength---Fudge-|\n"
	          "|--------|-----------|-------|------|--------|-------|-------|----------|-------|\n"
			  "|     Low|    .12    | 66.7% |  16  |    0%  |  1.0  |  75%  |    50%   |  6.0% |\n"
			  "|  Medium|    .08    | 75.0% |  32  |   12%  |  1/2  |  83%  |    33%   |  4.0% |\n"
			  "|    High|    .06    | 66.7% |  48  |   20%  |  1/3  |  87%  |    20%   |  3.0% |\n"
			  "|   Ultra|    .04    | 75.0% |  64  |   25%  |  1/4  |  90%  |    12%   |  2.0% |\n"
			  "---------------------------------------------------------------------------------";
	ui_category = "Click me to see what settings each preset uses!";
	ui_category_closed = true;
>;

#define __HQAAL_EDGE_THRESHOLD (HqaaEdgeThresholdCustom)
#define __HQAAL_DYNAMIC_RANGE (HqaaDynamicThresholdCustom / 100.0)
#define __HQAAL_SM_CORNERS (HqaaSmCorneringCustom / 100.0)
#define __HQAAL_FX_QUALITY (HqaaFxQualityCustom)
#define __HQAAL_FX_TEXEL (HqaaFxTexelCustom)
#define __HQAAL_FX_BLEND (HqaaFxBlendCustom / 100.0)
#define __HQAAL_HYSTERESIS_STRENGTH (HqaaHysteresisStrength / 100.0)
#define __HQAAL_HYSTERESIS_FUDGE (HqaaHysteresisFudgeFactor / 100.0)

#else

static const float HQAAL_THRESHOLD_PRESET[4] = {0.12, 0.08, 0.06, 0.04};
static const float HQAAL_DYNAMIC_RANGE_PRESET[4] = {0.666667, 0.75, 0.666667, 0.75};
static const uint HQAAL_FXAA_SCAN_ITERATIONS_PRESET[4] = {16, 32, 48, 64};
static const float HQAAL_SMAA_CORNER_ROUNDING_PRESET[4] = {0.0, 0.125, 0.2, 0.25};
static const float HQAAL_FXAA_TEXEL_SIZE_PRESET[4] = {1.0, 0.5, 0.333333, 0.25};
static const float HQAAL_SUBPIX_PRESET[4] = {0.75, 0.833333, 0.875, 0.9};
static const float HQAAL_HYSTERESIS_STRENGTH_PRESET[4] = {0.5, 0.333333, 0.2, 0.125};
static const float HQAAL_HYSTERESIS_FUDGE_PRESET[4] = {0.06, 0.04, 0.03, 0.02};

#define __HQAAL_EDGE_THRESHOLD (HQAAL_THRESHOLD_PRESET[HqaaPreset])
#define __HQAAL_DYNAMIC_RANGE (HQAAL_DYNAMIC_RANGE_PRESET[HqaaPreset])
#define __HQAAL_SM_CORNERS (HQAAL_SMAA_CORNER_ROUNDING_PRESET[HqaaPreset])
#define __HQAAL_FX_QUALITY (HQAAL_FXAA_SCAN_ITERATIONS_PRESET[HqaaPreset])
#define __HQAAL_FX_TEXEL (HQAAL_FXAA_TEXEL_SIZE_PRESET[HqaaPreset])
#define __HQAAL_FX_BLEND (HQAAL_SUBPIX_PRESET[HqaaPreset])
#define __HQAAL_HYSTERESIS_STRENGTH (HQAAL_HYSTERESIS_STRENGTH_PRESET[HqaaPreset])
#define __HQAAL_HYSTERESIS_FUDGE (HQAAL_HYSTERESIS_FUDGE_PRESET[HqaaPreset])

#endif //HQAAL_ADVANCED_MODE

#define __HQAAL_SM_RADIUS float(__HQAAL_FX_QUALITY)
#define __HQAAL_SM_AREATEX_RANGE_DIAG clamp(__HQAAL_SM_RADIUS, 0.0, 20.0)

/*****************************************************************************************************************************************/
/*********************************************************** UI SETUP END ****************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/******************************************************** SYNTAX SETUP START *************************************************************/
/*****************************************************************************************************************************************/

#define __HQAAL_SMALLEST_COLOR_STEP rcp(pow(2., BUFFER_COLOR_BIT_DEPTH))
#define __HQAAL_CONST_E 2.7182818284590452353602874713527
#define __HQAAL_CONST_HALFROOT2 (sqrt(2.)/2.)
#define __HQAAL_LUMA_REF float3(0.2126, 0.7152, 0.0722)
#define __HQAAL_AVERAGE_REF float3(0.333333, 0.333334, 0.333333)
#define __HQAAL_GREEN_LUMA float3(1./5., 7./10., 1./10.)
#define __HQAAL_RED_LUMA float3(5./8., 1./4., 1./8.)
#define __HQAAL_BLUE_LUMA float3(1./8., 3./8., 1./2.)

#define __HQAAL_SM_BUFFERINFO float4(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT, BUFFER_WIDTH, BUFFER_HEIGHT)
#define __HQAAL_SM_AREATEX_RANGE 16.
#define __HQAAL_SM_AREATEX_TEXEL (1./float2(160., 560.))
#define __HQAAL_SM_AREATEX_SUBTEXEL (1./7.)
#define __HQAAL_SM_SEARCHTEX_SIZE float2(66.0, 33.0)
#define __HQAAL_SM_SEARCHTEX_SIZE_PACKED float2(64.0, 16.0)

#define HQAAL_Tex2D(tex, coord) tex2Dlod(tex, (coord).xyxy)
#define HQAAL_DecodeTex2D(tex, coord) ConditionalDecode(tex2Dlod(tex, (coord).xyxy))

#define HQAALmax3(x,y,z) max(max(x,y),z)
#define HQAALmax4(w,x,y,z) max(max(w,x),max(y,z))
#define HQAALmax5(v,w,x,y,z) max(max(max(v,w),x),max(y,z))
#define HQAALmax6(u,v,w,x,y,z) max(max(max(u,v),max(w,x)),max(y,z))
#define HQAALmax7(t,u,v,w,x,y,z) max(max(max(t,u),max(v,w)),max(max(x,y),z))
#define HQAALmax8(s,t,u,v,w,x,y,z) max(max(max(s,t),max(u,v)),max(max(w,x),max(y,z)))
#define HQAALmax9(r,s,t,u,v,w,x,y,z) max(max(max(max(r,s),t),max(u,v)),max(max(w,x),max(y,z)))
#define HQAALmax10(q,r,s,t,u,v,w,x,y,z) max(max(max(max(q,r),max(s,t)),max(u,v)),max(max(w,x),max(y,z)))
#define HQAALmax11(p,q,r,s,t,u,v,w,x,y,z) max(max(max(max(p,q),max(r,s)),max(max(t,u),v)),max(max(w,x),max(y,z)))
#define HQAALmax12(o,p,q,r,s,t,u,v,w,x,y,z) max(max(max(max(o,p),max(q,r)),max(max(s,t),max(u,v))),max(max(w,x),max(y,z)))
#define HQAALmax13(n,o,p,q,r,s,t,u,v,w,x,y,z) max(max(max(max(n,o),max(p,q)),max(max(r,s),max(t,u))),max(max(max(v,w),x),max(y,z)))
#define HQAALmax14(m,n,o,p,q,r,s,t,u,v,w,x,y,z) max(max(max(max(m,n),max(o,p)),max(max(q,r),max(s,t))),max(max(max(u,v),max(w,x)),max(y,z)))

#define HQAALmin3(x,y,z) min(min(x,y),z)
#define HQAALmin4(w,x,y,z) min(min(w,x),min(y,z))
#define HQAALmin5(v,w,x,y,z) min(min(min(v,w),x),min(y,z))
#define HQAALmin6(u,v,w,x,y,z) min(min(min(u,v),min(w,x)),min(y,z))
#define HQAALmin7(t,u,v,w,x,y,z) min(min(min(t,u),min(v,w)),min(min(x,y),z))
#define HQAALmin8(s,t,u,v,w,x,y,z) min(min(min(s,t),min(u,v)),min(min(w,x),min(y,z)))
#define HQAALmin9(r,s,t,u,v,w,x,y,z) min(min(min(min(r,s),t),min(u,v)),min(min(w,x),min(y,z)))
#define HQAALmin10(q,r,s,t,u,v,w,x,y,z) min(min(min(min(q,r),min(s,t)),min(u,v)),min(min(w,x),min(y,z)))
#define HQAALmin11(p,q,r,s,t,u,v,w,x,y,z) min(min(min(min(p,q),min(r,s)),min(min(t,u),v)),min(min(w,x),min(y,z)))
#define HQAALmin12(o,p,q,r,s,t,u,v,w,x,y,z) min(min(min(min(o,p),min(q,r)),min(min(s,t),min(u,v))),min(min(w,x),min(y,z)))
#define HQAALmin13(n,o,p,q,r,s,t,u,v,w,x,y,z) min(min(min(min(n,o),min(p,q)),min(min(r,s),min(t,u))),min(min(min(v,w),x),min(y,z)))
#define HQAALmin14(m,n,o,p,q,r,s,t,u,v,w,x,y,z) min(min(min(min(m,n),min(o,p)),min(min(q,r),min(s,t))),min(min(min(u,v),min(w,x)),min(y,z)))

/*****************************************************************************************************************************************/
/********************************************************* SYNTAX SETUP END **************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/******************************************************** SUPPORT CODE START *************************************************************/
/*****************************************************************************************************************************************/

//////////////////////////////////////////////////////// HELPER FUNCTIONS ////////////////////////////////////////////////////////////////

// vectorized multiple single-component max operations
float max3(float a, float b, float c)
{
	return max(max(a,b),c);
}
float max4(float a, float b, float c, float d)
{
	float2 step1 = max(float2(a,b), float2(c,d));
	return max(step1.x, step1.y);
}
float max5(float a, float b, float c, float d, float e)
{
	float2 step1 = max(float2(a,b), float2(c,d));
	return max(max(step1.x, step1.y), e);
}
float max6(float a, float b, float c, float d, float e, float f)
{
	float2 step1 = max(max(float2(a,b), float2(c,d)), float2(e,f));
	return max(step1.x, step1.y);
}
float max7(float a, float b, float c, float d, float e, float f, float g)
{
	float2 step1 = max(max(float2(a,b), float2(c,d)), float2(e,f));
	return max(max(step1.x, step1.y), g);
}
float max8(float a, float b, float c, float d, float e, float f, float g, float h)
{
	float4 step1 = max(float4(a,b,c,d), float4(e,f,g,h));
	float2 step2 = max(step1.xy, step1.zw);
	return max(step2.x, step2.y);
}
float max9(float a, float b, float c, float d, float e, float f, float g, float h, float i)
{
	float4 step1 = max(float4(a,b,c,d), float4(e,f,g,h));
	float2 step2 = max(step1.xy, step1.zw);
	return max(max(step2.x, step2.y), i);
}
float max10(float a, float b, float c, float d, float e, float f, float g, float h, float i, float j)
{
	float4 step1 = max(float4(a,b,c,d), float4(e,f,g,h));
	float2 step2 = max(step1.xy, step1.zw);
	return max(max(step2.x, step2.y), max(i, j));
}
float max11(float a, float b, float c, float d, float e, float f, float g, float h, float i, float j, float k)
{
	float4 step1 = max(float4(a,b,c,d), float4(e,f,g,h));
	float2 step2 = max(step1.xy, step1.zw);
	return max(max(max(step2.x, step2.y), max(i, j)), k);
}
float max12(float a, float b, float c, float d, float e, float f, float g, float h, float i, float j, float k, float l)
{
	float4 step1 = max(float4(a,b,c,d), float4(e,f,g,h));
	float2 step2 = max(step1.xy, step1.zw);
	float2 step3 = max(float2(i,j), float2(k,l));
	float2 step4 = max(step2, step3);
	return max(step4.x, step4.y);
}
float max13(float a, float b, float c, float d, float e, float f, float g, float h, float i, float j, float k, float l, float m)
{
	float4 step1 = max(float4(a,b,c,d), float4(e,f,g,h));
	float2 step2 = max(step1.xy, step1.zw);
	float2 step3 = max(float2(i,j), float2(k,l));
	float2 step4 = max(step2, step3);
	return max(max(step4.x, step4.y), m);
}
float max14(float a, float b, float c, float d, float e, float f, float g, float h, float i, float j, float k, float l, float m, float n)
{
	float4 step1 = max(float4(a,b,c,d), float4(e,f,g,h));
	float2 step2 = max(step1.xy, step1.zw);
	float2 step3 = max(float2(i,j), float2(k,l));
	float2 step4 = max(step2, step3);
	return max(max(step4.x, step4.y), max(m, n));
}
float max15(float a, float b, float c, float d, float e, float f, float g, float h, float i, float j, float k, float l, float m, float n, float o)
{
	float4 step1 = max(float4(a,b,c,d), float4(e,f,g,h));
	float2 step2 = max(step1.xy, step1.zw);
	float2 step3 = max(float2(i,j), float2(k,l));
	float2 step4 = max(step2, step3);
	return max(max(step4.x, step4.y), max(m, max(n, o)));
}
float max16(float a, float b, float c, float d, float e, float f, float g, float h, float i, float j, float k, float l, float m, float n, float o, float p)
{
	float4 step1 = max(float4(a,b,c,d), float4(e,f,g,h));
	float4 step2 = max(float4(i,j,k,l), float4(m,n,o,p));
	float4 step3 = max(step1, step2);
	float2 step4 = max(step3.xy, step3.zw);
	return max(step4.x, step4.y);
}

// vectorized multiple single-component min operations
float min3(float a, float b, float c)
{
	return min(min(a,b),c);
}
float min4(float a, float b, float c, float d)
{
	float2 step1 = min(float2(a,b), float2(c,d));
	return min(step1.x, step1.y);
}
float min5(float a, float b, float c, float d, float e)
{
	float2 step1 = min(float2(a,b), float2(c,d));
	return min(min(step1.x, step1.y), e);
}
float min6(float a, float b, float c, float d, float e, float f)
{
	float2 step1 = min(min(float2(a,b), float2(c,d)), float2(e,f));
	return min(step1.x, step1.y);
}
float min7(float a, float b, float c, float d, float e, float f, float g)
{
	float2 step1 = min(min(float2(a,b), float2(c,d)), float2(e,f));
	return min(min(step1.x, step1.y), g);
}
float min8(float a, float b, float c, float d, float e, float f, float g, float h)
{
	float4 step1 = min(float4(a,b,c,d), float4(e,f,g,h));
	float2 step2 = min(step1.xy, step1.zw);
	return min(step2.x, step2.y);
}
float min9(float a, float b, float c, float d, float e, float f, float g, float h, float i)
{
	float4 step1 = min(float4(a,b,c,d), float4(e,f,g,h));
	float2 step2 = min(step1.xy, step1.zw);
	return min(min(step2.x, step2.y), i);
}
float min10(float a, float b, float c, float d, float e, float f, float g, float h, float i, float j)
{
	float4 step1 = min(float4(a,b,c,d), float4(e,f,g,h));
	float2 step2 = min(step1.xy, step1.zw);
	return min(min(step2.x, step2.y), min(i, j));
}
float min11(float a, float b, float c, float d, float e, float f, float g, float h, float i, float j, float k)
{
	float4 step1 = min(float4(a,b,c,d), float4(e,f,g,h));
	float2 step2 = min(step1.xy, step1.zw);
	return min(min(min(step2.x, step2.y), min(i, j)), k);
}
float min12(float a, float b, float c, float d, float e, float f, float g, float h, float i, float j, float k, float l)
{
	float4 step1 = min(float4(a,b,c,d), float4(e,f,g,h));
	float2 step2 = min(step1.xy, step1.zw);
	float2 step3 = min(float2(i,j), float2(k,l));
	float2 step4 = min(step2, step3);
	return min(step4.x, step4.y);
}
float min13(float a, float b, float c, float d, float e, float f, float g, float h, float i, float j, float k, float l, float m)
{
	float4 step1 = min(float4(a,b,c,d), float4(e,f,g,h));
	float2 step2 = min(step1.xy, step1.zw);
	float2 step3 = min(float2(i,j), float2(k,l));
	float2 step4 = min(step2, step3);
	return min(min(step4.x, step4.y), m);
}
float min14(float a, float b, float c, float d, float e, float f, float g, float h, float i, float j, float k, float l, float m, float n)
{
	float4 step1 = min(float4(a,b,c,d), float4(e,f,g,h));
	float2 step2 = min(step1.xy, step1.zw);
	float2 step3 = min(float2(i,j), float2(k,l));
	float2 step4 = min(step2, step3);
	return min(min(step4.x, step4.y), min(m, n));
}
float min15(float a, float b, float c, float d, float e, float f, float g, float h, float i, float j, float k, float l, float m, float n, float o)
{
	float4 step1 = min(float4(a,b,c,d), float4(e,f,g,h));
	float2 step2 = min(step1.xy, step1.zw);
	float2 step3 = min(float2(i,j), float2(k,l));
	float2 step4 = min(step2, step3);
	return min(min(step4.x, step4.y), min(m, min(n, o)));
}
float min16(float a, float b, float c, float d, float e, float f, float g, float h, float i, float j, float k, float l, float m, float n, float o, float p)
{
	float4 step1 = min(float4(a,b,c,d), float4(e,f,g,h));
	float4 step2 = min(float4(i,j,k,l), float4(m,n,o,p));
	float4 step3 = min(step1, step2);
	float2 step4 = min(step3.xy, step3.zw);
	return min(step4.x, step4.y);
}

// color delta calculator
float chromadelta(float3 pixel1, float3 pixel2)
{
	return dot(abs(pixel1 - pixel2), __HQAAL_AVERAGE_REF);
}

// non-bitwise logical operators
float lxor(float x, float y)
{
	bool valid = (x == 0.0) ? ((y == 0.0) ? false : true) : ((y == 0.0) ? true : false);
	if (valid) return x + y;
	else return 0.0;
}
float2 lxor(float2 x, float2 y)
{
	return float2(lxor(x.x, y.x), lxor(x.y, y.y));
}
float3 lxor(float3 x, float3 y)
{
	return float3(lxor(x.x, y.x), lxor(x.yz, y.yz));
}
float4 lxor(float4 x, float4 y)
{
	return float4(lxor(x.xy, y.xy), lxor(x.zw, y.zw));
}

float lnand(float x, float y)
{
	return y == 0.0 ? x : 0.0;
}
float2 lnand(float2 x, float2 y)
{
	return float2(lnand(x.x, y.x), lnand(x.y, y.y));
}
float3 lnand(float3 x, float3 y)
{
	return float3(lnand(x.x, y.x), lnand(x.yz, y.yz));
}
float4 lnand(float4 x, float4 y)
{
	return float4(lnand(x.xy, y.xy), lnand(x.zw, y.zw));
}

/////////////////////////////////////////////////////// TRANSFER FUNCTIONS ////////////////////////////////////////////////////////////////

float encodePQ(float x)
{
/*	float nits = 10000.0
	float m2rcp = rcp(2523/32)
	float m1rcp = rcp(1305/8192)
	float c1 = 107 / 128
	float c2 = 2413 / 128
	float c3 = 2392 / 128
*/
	float xpm2rcp = pow(saturate(x), rcp(2523./32.));
	float numerator = max(xpm2rcp - 107./128., 0.0);
	float denominator = 2413./128. - ((2392./128.) * xpm2rcp);
	
	float output = pow(abs(numerator / denominator), rcp(1305./8192.));
	if (BUFFER_COLOR_BIT_DEPTH == 10) output *= 500.0;
	else output *= 10000.0;
	return output;
}
float2 encodePQ(float2 x)
{
	float2 xpm2rcp = pow(saturate(x), rcp(2523./32.));
	float2 numerator = max(xpm2rcp - 107./128., 0.0);
	float2 denominator = 2413./128. - ((2392./128.) * xpm2rcp);
	
	float2 output = pow(abs(numerator / denominator), rcp(1305./8192.));
	if (BUFFER_COLOR_BIT_DEPTH == 10) output *= 500.0;
	else output *= 10000.0;
	return output;
}
float3 encodePQ(float3 x)
{
	float3 xpm2rcp = pow(saturate(x), rcp(2523./32.));
	float3 numerator = max(xpm2rcp - 107./128., 0.0);
	float3 denominator = 2413./128. - ((2392./128.) * xpm2rcp);
	
	float3 output = pow(abs(numerator / denominator), rcp(1305./8192.));
	if (BUFFER_COLOR_BIT_DEPTH == 10) output *= 500.0;
	else output *= 10000.0;
	return output;
}
float4 encodePQ(float4 x)
{
	float4 xpm2rcp = pow(saturate(x), rcp(2523./32.));
	float4 numerator = max(xpm2rcp - 107./128., 0.0);
	float4 denominator = 2413./128. - ((2392./128.) * xpm2rcp);
	
	float4 output = pow(abs(numerator / denominator), rcp(1305./8192.));
	if (BUFFER_COLOR_BIT_DEPTH == 10) output *= 500.0;
	else output *= 10000.0;
	return output;
}

float decodePQ(float x)
{
/*	float nits = 10000.0;
	float m2 = 2523 / 32
	float m1 = 1305 / 8192
	float c1 = 107 / 128
	float c2 = 2413 / 128
	float c3 = 2392 / 128
*/
	float xpm1;
	if (BUFFER_COLOR_BIT_DEPTH == 10) xpm1 = pow(saturate(x / 500.0), 1305./8192.);
	else xpm1 = pow(saturate(x / 10000.0), 1305./8192.);
	float numerator = 107./128. + ((2413./128.) * xpm1);
	float denominator = 1.0 + ((2392./128.) * xpm1);
	
	return saturate(pow(abs(numerator / denominator), 2523./32.));
}
float2 decodePQ(float2 x)
{
	float2 xpm1;
	if (BUFFER_COLOR_BIT_DEPTH == 10) xpm1 = pow(saturate(x / 500.0), 1305./8192.);
	else xpm1 = pow(saturate(x / 10000.0), 1305./8192.);
	float2 numerator = 107./128. + ((2413./128.) * xpm1);
	float2 denominator = 1.0 + ((2392./128.) * xpm1);
	
	return saturate(pow(abs(numerator / denominator), 2523./32.));
}
float3 decodePQ(float3 x)
{
	float3 xpm1;
	if (BUFFER_COLOR_BIT_DEPTH == 10) xpm1 = pow(saturate(x / 500.0), 1305./8192.);
	else xpm1 = pow(saturate(x / 10000.0), 1305./8192.);
	float3 numerator = 107./128. + ((2413./128.) * xpm1);
	float3 denominator = 1.0 + ((2392./128.) * xpm1);
	
	return saturate(pow(abs(numerator / denominator), 2523./32.));
}
float4 decodePQ(float4 x)
{
	float4 xpm1;
	if (BUFFER_COLOR_BIT_DEPTH == 10) xpm1 = pow(saturate(x / 500.0), 1305./8192.);
	else xpm1 = pow(saturate(x / 10000.0), 1305./8192.);
	float4 numerator = 107./128. + ((2413./128.) * xpm1);
	float4 denominator = 1.0 + ((2392./128.) * xpm1);
	
	return saturate(pow(abs(numerator / denominator), 2523./32.));
}

float fastencodePQ(float x)
{
	float y;
	float z;
	if (BUFFER_COLOR_BIT_DEPTH == 10) {y = saturate(x) * 4.728708; z = 500.0;}
	else {y = saturate(x) * 10.0; z = 10000.0;}
	y *= y;
	y *= y;
	return clamp(y, 0.0, z);
}
float2 fastencodePQ(float2 x)
{
	float2 y;
	float z;
	if (BUFFER_COLOR_BIT_DEPTH == 10) {y = saturate(x) * 4.728708; z = 500.0;}
	else {y = saturate(x) * 10.0; z = 10000.0;}
	y *= y;
	y *= y;
	return clamp(y, 0.0, z);
}
float3 fastencodePQ(float3 x)
{
	float3 y;
	float z;
	if (BUFFER_COLOR_BIT_DEPTH == 10) {y = saturate(x) * 4.728708; z = 500.0;}
	else {y = saturate(x) * 10.0; z = 10000.0;}
	y *= y;
	y *= y;
	return clamp(y, 0.0, z);
}
float4 fastencodePQ(float4 x)
{
	float4 y;
	float z;
	if (BUFFER_COLOR_BIT_DEPTH == 10) {y = saturate(x) * 4.728708; z = 500.0;}
	else {y = saturate(x) * 10.0; z = 10000.0;}
	y *= y;
	y *= y;
	return clamp(y, 0.0, z);
}

float fastdecodePQ(float x)
{
	return BUFFER_COLOR_BIT_DEPTH == 10 ? saturate((sqrt(sqrt(clamp(x, __HQAAL_SMALLEST_COLOR_STEP, 500.0))) / 4.7287080450158790665084805994361)) : saturate((sqrt(sqrt(clamp(x, __HQAAL_SMALLEST_COLOR_STEP, 10000.0))) / 10.0));
}
float2 fastdecodePQ(float2 x)
{
	return BUFFER_COLOR_BIT_DEPTH == 10 ? saturate((sqrt(sqrt(clamp(x, __HQAAL_SMALLEST_COLOR_STEP, 500.0))) / 4.7287080450158790665084805994361)) : saturate((sqrt(sqrt(clamp(x, __HQAAL_SMALLEST_COLOR_STEP, 10000.0))) / 10.0));
}
float3 fastdecodePQ(float3 x)
{
	return BUFFER_COLOR_BIT_DEPTH == 10 ? saturate((sqrt(sqrt(clamp(x, __HQAAL_SMALLEST_COLOR_STEP, 500.0))) / 4.7287080450158790665084805994361)) : saturate((sqrt(sqrt(clamp(x, __HQAAL_SMALLEST_COLOR_STEP, 10000.0))) / 10.0));
}
float4 fastdecodePQ(float4 x)
{
	return BUFFER_COLOR_BIT_DEPTH == 10 ? saturate((sqrt(sqrt(clamp(x, __HQAAL_SMALLEST_COLOR_STEP, 500.0))) / 4.7287080450158790665084805994361)) : saturate((sqrt(sqrt(clamp(x, __HQAAL_SMALLEST_COLOR_STEP, 10000.0))) / 10.0));
}

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

float ConditionalEncode(float x)
{
	if (HqaaOutputMode == 1) return encodeHDR(x);
	if (HqaaOutputMode == 2) return encodePQ(x);
	if (HqaaOutputMode == 3) return fastencodePQ(x);
	return x;
}
float2 ConditionalEncode(float2 x)
{
	if (HqaaOutputMode == 1) return encodeHDR(x);
	if (HqaaOutputMode == 2) return encodePQ(x);
	if (HqaaOutputMode == 3) return fastencodePQ(x);
	return x;
}
float3 ConditionalEncode(float3 x)
{
	if (HqaaOutputMode == 1) return encodeHDR(x);
	if (HqaaOutputMode == 2) return encodePQ(x);
	if (HqaaOutputMode == 3) return fastencodePQ(x);
	return x;
}
float4 ConditionalEncode(float4 x)
{
	if (HqaaOutputMode == 1) return encodeHDR(x);
	if (HqaaOutputMode == 2) return encodePQ(x);
	if (HqaaOutputMode == 3) return fastencodePQ(x);
	return x;
}

float ConditionalDecode(float x)
{
	if (HqaaOutputMode == 1) return decodeHDR(x);
	if (HqaaOutputMode == 2) return decodePQ(x);
	if (HqaaOutputMode == 3) return fastdecodePQ(x);
	return x;
}
float2 ConditionalDecode(float2 x)
{
	if (HqaaOutputMode == 1) return decodeHDR(x);
	if (HqaaOutputMode == 2) return decodePQ(x);
	if (HqaaOutputMode == 3) return fastdecodePQ(x);
	return x;
}
float3 ConditionalDecode(float3 x)
{
	if (HqaaOutputMode == 1) return decodeHDR(x);
	if (HqaaOutputMode == 2) return decodePQ(x);
	if (HqaaOutputMode == 3) return fastdecodePQ(x);
	return x;
}
float4 ConditionalDecode(float4 x)
{
	if (HqaaOutputMode == 1) return decodeHDR(x);
	if (HqaaOutputMode == 2) return decodePQ(x);
	if (HqaaOutputMode == 3) return fastdecodePQ(x);
	return x;
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

float2 HQAASearchDiag(sampler2D HQAALedgesTex, float2 texcoord, float2 dir, out float2 e)
{
    float4 coord = float4(texcoord, -1.0, 1.0);
    float3 t = float3(__HQAAL_SM_BUFFERINFO.xy, 1.0);
    [loop] while (coord.z < 20.0) 
	{
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);
        e = tex2Dlod(HQAALedgesTex, coord.xyxy).rg;
        coord.w = dot(e, float(0.5).xx);
        if (coord.w < 0.9) break;
    }
    return coord.zw;
}

float2 HQAAAreaDiag(sampler2D HQAALareaTex, float2 dist, float2 e)
{
    float2 texcoord = mad(float(__HQAAL_SM_AREATEX_RANGE_DIAG).xx, e, dist);

    texcoord = mad(__HQAAL_SM_AREATEX_TEXEL, texcoord, 0.5 * __HQAAL_SM_AREATEX_TEXEL);
    texcoord.x += 0.5;

    return tex2Dlod(HQAALareaTex, texcoord.xyxy).rg;
}

float2 HQAACalculateDiagWeights(sampler2D HQAALedgesTex, sampler2D HQAALareaTex, float2 texcoord, float2 e)
{
    float2 weights = float(0.0).xx;
    float2 end;
    float4 d;
    d.ywxz = float4(HQAASearchDiag(HQAALedgesTex, texcoord, float2(1.0, -1.0), end), 0.0, 0.0);
    
    if (e.r > 0.0) 
	{
        d.xz = HQAASearchDiag(HQAALedgesTex, texcoord, float2(-1.0,  1.0), end);
        d.x += float(end.y > 0.9);
    }
	
	if (d.x + d.y > 2.0) 
	{
        float4 coords = mad(float4(-d.x + 0.25, d.x, d.y, -d.y - 0.25), __HQAAL_SM_BUFFERINFO.xyxy, texcoord.xyxy);
        float4 c;
        c.xy = tex2Dlodoffset(HQAALedgesTex, coords.xyxy, int2(-1,  0)).rg;
        c.zw = tex2Dlodoffset(HQAALedgesTex, coords.zwzw, int2( 1,  0)).rg;
        c.yxwz = HQAADecodeDiagBilinearAccess(c.xyzw);

        float2 cc = mad(float(2.0).xx, c.xz, c.yw);

        HQAAMovc(bool2(step(0.9, d.zw)), cc, float(0.0).xx);

        weights += HQAAAreaDiag(HQAALareaTex, d.xy, cc);
    }

    d.xz = HQAASearchDiag(HQAALedgesTex, texcoord, float2(-1.0, -1.0), end);
    d.yw = float(0.0).xx;
    
    if (HQAAL_Tex2D(HQAALedgesTex, texcoord + float2(BUFFER_RCP_WIDTH, 0)).r > 0.0) 
	{
        d.yw = HQAASearchDiag(HQAALedgesTex, texcoord, float(1.0).xx, end);
        d.y += float(end.y > 0.9);
    }
	
	if (d.x + d.y > 2.0) 
	{
        float4 coords = mad(float4(-d.x, -d.x, d.y, d.y), __HQAAL_SM_BUFFERINFO.xyxy, texcoord.xyxy);
        float4 c;
        c.x  = tex2Dlodoffset(HQAALedgesTex, coords.xyxy, int2(-1,  0)).g;
        c.y  = tex2Dlodoffset(HQAALedgesTex, coords.xyxy, int2( 0, -1)).r;
        c.zw = tex2Dlodoffset(HQAALedgesTex, coords.zwzw, int2( 1,  0)).gr;
        float2 cc = mad(float(2.0).xx, c.xz, c.yw);

        HQAAMovc(bool2(step(0.9, d.zw)), cc, float(0.0).xx);

        weights += HQAAAreaDiag(HQAALareaTex, d.xy, cc).gr;
    }

    return weights;
}

float HQAASearchLength(sampler2D HQAALsearchTex, float2 e, float offset)
{
    float2 scale = __HQAAL_SM_SEARCHTEX_SIZE * float2(0.5, -1.0);
    float2 bias = __HQAAL_SM_SEARCHTEX_SIZE * float2(offset, 1.0);

    scale += float2(-1.0,  1.0);
    bias  += float2( 0.5, -0.5);

    scale *= 1.0 / __HQAAL_SM_SEARCHTEX_SIZE_PACKED;
    bias *= 1.0 / __HQAAL_SM_SEARCHTEX_SIZE_PACKED;

    return tex2Dlod(HQAALsearchTex, mad(scale, e, bias).xyxy).r;
}

float HQAASearchXLeft(sampler2D HQAALedgesTex, sampler2D HQAALsearchTex, float2 texcoord, float end)
{
    float2 e = float2(0.0, 1.0);
    [loop] while (texcoord.x > end) 
	{
        e = tex2Dlod(HQAALedgesTex, texcoord.xyxy).rg;
        texcoord = mad(-float2(2.0, 0.0), __HQAAL_SM_BUFFERINFO.xy, texcoord);
        if (e.r > 0.0) break;
    }
    float offset = mad(-(255./127.), HQAASearchLength(HQAALsearchTex, e, 0.0), 3.25);
    return mad(__HQAAL_SM_BUFFERINFO.x, offset, texcoord.x);
}
float HQAASearchXRight(sampler2D HQAALedgesTex, sampler2D HQAALsearchTex, float2 texcoord, float end)
{
    float2 e = float2(0.0, 1.0);
    [loop] while (texcoord.x < end) 
	{
        e = tex2Dlod(HQAALedgesTex, texcoord.xyxy).rg;
        texcoord = mad(float2(2.0, 0.0), __HQAAL_SM_BUFFERINFO.xy, texcoord);
        if (e.r > 0.0) break;
    }
    float offset = mad(-(255./127.), HQAASearchLength(HQAALsearchTex, e, 0.5), 3.25);
    return mad(-__HQAAL_SM_BUFFERINFO.x, offset, texcoord.x);
}
float HQAASearchYUp(sampler2D HQAALedgesTex, sampler2D HQAALsearchTex, float2 texcoord, float end)
{
    float2 e = float2(1.0, 0.0);
    [loop] while (texcoord.y > end) 
	{
        e = tex2Dlod(HQAALedgesTex, texcoord.xyxy).rg;
        texcoord = mad(-float2(0.0, 2.0), __HQAAL_SM_BUFFERINFO.xy, texcoord);
        if (e.g > 0.0) break;
    }
    float offset = mad(-(255./127.), HQAASearchLength(HQAALsearchTex, e.gr, 0.0), 3.25);
    return mad(__HQAAL_SM_BUFFERINFO.y, offset, texcoord.y);
}
float HQAASearchYDown(sampler2D HQAALedgesTex, sampler2D HQAALsearchTex, float2 texcoord, float end)
{
    float2 e = float2(1.0, 0.0);
    [loop] while (texcoord.y < end) 
	{
        e = tex2Dlod(HQAALedgesTex, texcoord.xyxy).rg;
        texcoord = mad(float2(0.0, 2.0), __HQAAL_SM_BUFFERINFO.xy, texcoord);
        if (e.g > 0.0) break;
    }
    float offset = mad(-(255./127.), HQAASearchLength(HQAALsearchTex, e.gr, 0.5), 3.25);
    return mad(-__HQAAL_SM_BUFFERINFO.y, offset, texcoord.y);
}

float2 HQAAArea(sampler2D HQAALareaTex, float2 dist, float e1, float e2)
{
    float2 texcoord = mad(float(__HQAAL_SM_AREATEX_RANGE).xx, 4.0 * float2(e1, e2), dist);
    
    texcoord = mad(__HQAAL_SM_AREATEX_TEXEL, texcoord, 0.5 * __HQAAL_SM_AREATEX_TEXEL);

    return tex2Dlod(HQAALareaTex, texcoord.xyxy).rg;
}

void HQAADetectHorizontalCornerPattern(sampler2D HQAALedgesTex, inout float2 weights, float4 texcoord, float2 d)
{
    float2 leftRight = step(d.xy, d.yx);
    float2 rounding = (1.0 - __HQAAL_SM_CORNERS) * leftRight;

    float2 factor = float(1.0).xx;
    factor.x -= rounding.x * tex2Dlodoffset(HQAALedgesTex, texcoord.xyxy, int2(0,  1)).r;
    factor.x -= rounding.y * tex2Dlodoffset(HQAALedgesTex, texcoord.zwzw, int2(1,  1)).r;
    factor.y -= rounding.x * tex2Dlodoffset(HQAALedgesTex, texcoord.xyxy, int2(0, -2)).r;
    factor.y -= rounding.y * tex2Dlodoffset(HQAALedgesTex, texcoord.zwzw, int2(1, -2)).r;

    weights *= saturate(factor);
}
void HQAADetectVerticalCornerPattern(sampler2D HQAALedgesTex, inout float2 weights, float4 texcoord, float2 d)
{
    float2 leftRight = step(d.xy, d.yx);
    float2 rounding = (1.0 - __HQAAL_SM_CORNERS) * leftRight;

    float2 factor = float(1.0).xx;
    factor.x -= rounding.x * tex2Dlodoffset(HQAALedgesTex, texcoord.xyxy, int2( 1, 0)).g;
    factor.x -= rounding.y * tex2Dlodoffset(HQAALedgesTex, texcoord.zwzw, int2( 1, 1)).g;
    factor.y -= rounding.x * tex2Dlodoffset(HQAALedgesTex, texcoord.xyxy, int2(-2, 0)).g;
    factor.y -= rounding.y * tex2Dlodoffset(HQAALedgesTex, texcoord.zwzw, int2(-2, 1)).g;

    weights *= saturate(factor);
}

/***************************************************************************************************************************************/
/******************************************************** SUPPORT CODE END *************************************************************/
/***************************************************************************************************************************************/

/***************************************************************************************************************************************/
/*********************************************************** SHADER SETUP START ********************************************************/
/***************************************************************************************************************************************/

#include "ReShade.fxh"


//////////////////////////////////////////////////////////// TEXTURES ///////////////////////////////////////////////////////////////////

texture HQAALedgesTex
#if __RESHADE__ >= 50000
< pooled = true; >
#endif
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA16F;
};

texture HQAALblendTex
#if __RESHADE__ >= 50000
< pooled = true; >
#endif
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA16F;
};

texture HQAALareaTex < source = "AreaTex.png"; >
{
	Width = 160;
	Height = 560;
	Format = RG8;
};

texture HQAALsearchTex < source = "SearchTex.png"; >
{
	Width = 64;
	Height = 16;
	Format = R8;
};

//////////////////////////////////////////////////////////// SAMPLERS ///////////////////////////////////////////////////////////////////

sampler HQAALsamplerAlphaEdges
{
	Texture = HQAALedgesTex;
};

sampler HQAALsamplerSMweights
{
	Texture = HQAALblendTex;
};

sampler HQAALsamplerSMarea
{
	Texture = HQAALareaTex;
};

sampler HQAALsamplerSMsearch
{
	Texture = HQAALsearchTex;
};

//////////////////////////////////////////////////////////// VERTEX SHADERS /////////////////////////////////////////////////////////////
void HQAALBlendingWeightCalculationVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0, out float2 pixcoord : TEXCOORD1, out float4 offset[3] : TEXCOORD2)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    pixcoord = texcoord * __HQAAL_SM_BUFFERINFO.zw;

    offset[0] = mad(__HQAAL_SM_BUFFERINFO.xyxy, float4(-0.25, -0.125,  1.25, -0.125), texcoord.xyxy);
    offset[1] = mad(__HQAAL_SM_BUFFERINFO.xyxy, float4(-0.125, -0.25, -0.125,  1.25), texcoord.xyxy);
	
	float searchrange = __HQAAL_SM_RADIUS;
	
    offset[2] = mad(__HQAAL_SM_BUFFERINFO.xxyy,
                    float2(-2.0, 2.0).xyxy * searchrange,
                    float4(offset[0].xz, offset[1].yw));
}

void HQAALNeighborhoodBlendingVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0, out float4 offset : TEXCOORD1)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    offset = mad(__HQAAL_SM_BUFFERINFO.xyxy, float4( 1.0, 0.0, 0.0,  1.0), texcoord.xyxy);
}

/*****************************************************************************************************************************************/
/*********************************************************** SHADER SETUP END ************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/********************************************************** SMAA SHADER CODE START *******************************************************/
/*****************************************************************************************************************************************/

//////////////////////////////////////////////////////// EDGE DETECTION ///////////////////////////////////////////////////////////////////
float4 HQAALHybridEdgeDetectionPS(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	if ((HqaaSourceInterpolation == 1) && __HQAAL_ALT_FRAME) discard;
	if ((HqaaSourceInterpolation == 2) && !__HQAAL_QUAD_FRAME) discard;
	
	float3 middle = HQAAL_DecodeTex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 ref = __HQAAL_LUMA_REF;
	float2 hvstep = __HQAAL_SM_BUFFERINFO.xy;
	float2 diagstep = hvstep * __HQAAL_CONST_HALFROOT2;
	
    float L = dot(middle, ref);
    float3 scan = HQAAL_DecodeTex2D(ReShade::BackBuffer, texcoord - float2(0, hvstep.y)).rgb;
    float Dtop = chromadelta(middle, scan);
    float Ltop = dot(scan, ref);
    scan = HQAAL_DecodeTex2D(ReShade::BackBuffer, texcoord - float2(hvstep.x, 0)).rgb;
    float Dleft = chromadelta(middle, scan);
    float Lleft = dot(scan, ref);
    scan = HQAAL_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(hvstep.x, 0)).rgb;
    float Dright = chromadelta(middle, scan);
    float Lright = dot(scan, ref);
    scan = HQAAL_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(0, hvstep.y)).rgb;
    float Dbottom = chromadelta(middle, scan);
	float Lbottom = dot(scan, ref);
	scan = HQAAL_DecodeTex2D(ReShade::BackBuffer, texcoord - diagstep).rgb;
	float Dtopleft = chromadelta(middle, scan);
	float Ltopleft = dot(scan, ref);
	scan = HQAAL_DecodeTex2D(ReShade::BackBuffer, texcoord + diagstep).rgb;
	float Dbottomright = chromadelta(middle, scan);
	float Lbottomright = dot(scan, ref);
	scan = HQAAL_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(diagstep.x, -diagstep.y)).rgb;
	float Dtopright = chromadelta(middle, scan);
	float Ltopright = dot(scan, ref);
	scan = HQAAL_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(-diagstep.x, diagstep.y)).rgb;
	float Dbottomleft = chromadelta(middle, scan);
	float Lbottomleft = dot(scan, ref);
	
	float Lavg = sqrt(L * clamp(((Lleft + Ltop + Lright + Lbottom + Ltopleft + Ltopright + Lbottomleft + Lbottomright) / 8.0), __HQAAL_SMALLEST_COLOR_STEP, 1.0));
	float rangemult = 1.0 - log2(1.0 + clamp(log2(1.0 + Lavg), 0.0, HqaaLowLumaThreshold) * rcp(HqaaLowLumaThreshold));
	float edgethreshold = __HQAAL_EDGE_THRESHOLD;
	edgethreshold = mad(rangemult, -(__HQAAL_DYNAMIC_RANGE * edgethreshold), edgethreshold);
	float2 bufferdata = float2(L, edgethreshold);
    
    // delta
    // * y *
    // x * z
    // * w *
    
    // diagdelta
    // r * b
    // * * *
    // g * a
    
	float4 delta = step(edgethreshold, float4(Dleft, Dtop, Dright, Dbottom));
	float4 diagdelta = step(edgethreshold, float4(Dtopleft, Dbottomleft, Dtopright, Dbottomright));
	
	float2 fulldiag = lxor(diagdelta.r * diagdelta.a, diagdelta.g * diagdelta.b).xx;
	
	float neardiag1 = saturate(lnand(diagdelta.b * delta.z * delta.w, diagdelta.a) + lnand(diagdelta.g * delta.x * delta.y, diagdelta.r));
	float neardiag2 = saturate(lnand(diagdelta.a * delta.z * delta.y, diagdelta.b) + lnand(diagdelta.r * delta.x * delta.w, diagdelta.g));
	float neardiag3 = saturate(lnand(diagdelta.b * delta.y * delta.x, diagdelta.r) + lnand(diagdelta.g * delta.w * delta.z, diagdelta.a));
	float neardiag4 = saturate(lnand(diagdelta.r * delta.y * delta.z, diagdelta.b) + lnand(diagdelta.a * delta.w * delta.x, diagdelta.g));
	float2 neardiag = lxor(lxor(neardiag1, neardiag2), lxor(neardiag3, neardiag4)).xx;
	
	/*
	float2 hvedges = float2(delta.x * delta.z, delta.y * delta.w);
	if (lxor(hvedges.x, hvedges.y) == 0.0) hvedges = 0.0.xx;
	*/
	float2 hvedges = saturate(float2(delta.x + delta.z, delta.y + delta.w));
	
	float2 edges = 0.0.xx;
	edges = neardiag;
	if (!any(edges)) edges = hvedges;
	if (!any(edges)) edges = fulldiag;
	
	return float4(edges, bufferdata);
}

/////////////////////////////////////////////////// BLEND WEIGHT CALCULATION //////////////////////////////////////////////////////////////
float4 HQAALBlendingWeightCalculationPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float2 pixcoord : TEXCOORD1, float4 offset[3] : TEXCOORD2) : SV_Target
{
    float4 weights = float(0.0).xxxx;
    float2 e = HQAAL_Tex2D(HQAALsamplerAlphaEdges, texcoord).rg;
    float2 diagweights;
    if (all(e)) { diagweights = HQAACalculateDiagWeights(HQAALsamplerAlphaEdges, HQAALsamplerSMarea, texcoord, e); weights.rg = diagweights; }
	[branch] if (e.g > 0.0)
	{
		float3 coords = float3(HQAASearchXLeft(HQAALsamplerAlphaEdges, HQAALsamplerSMsearch, offset[0].xy, offset[2].x), offset[1].y, HQAASearchXRight(HQAALsamplerAlphaEdges, HQAALsamplerSMsearch, offset[0].zw, offset[2].y));
		float e1 = HQAAL_Tex2D(HQAALsamplerAlphaEdges, coords.xy).r;
		float2 d = coords.xz;
		d = abs((mad(__HQAAL_SM_BUFFERINFO.zz, d, -pixcoord.xx)));
		float e2 = HQAAL_Tex2D(HQAALsamplerAlphaEdges, coords.zy + float2(BUFFER_RCP_WIDTH, 0)).r;
		weights.rg = max(HQAAArea(HQAALsamplerSMarea, sqrt(d), e1, e2), diagweights);
		coords.y = texcoord.y;
		HQAADetectHorizontalCornerPattern(HQAALsamplerAlphaEdges, weights.rg, coords.xyzy, d);
    }
	[branch] if (e.r > 0.0) 
	{
        float3 coords = float3(offset[0].x, HQAASearchYUp(HQAALsamplerAlphaEdges, HQAALsamplerSMsearch, offset[1].xy, offset[2].z), HQAASearchYDown(HQAALsamplerAlphaEdges, HQAALsamplerSMsearch, offset[1].zw, offset[2].w));
        float e1 = HQAAL_Tex2D(HQAALsamplerAlphaEdges, coords.xy).g;
		float2 d = coords.yz;
        d = abs((mad(__HQAAL_SM_BUFFERINFO.ww, d, -pixcoord.yy)));
        float e2 = HQAAL_Tex2D(HQAALsamplerAlphaEdges, coords.xz + float2(0, BUFFER_RCP_HEIGHT)).g;
        weights.ba = HQAAArea(HQAALsamplerSMarea, sqrt(d), e1, e2);
        coords.x = texcoord.x;
        HQAADetectVerticalCornerPattern(HQAALsamplerAlphaEdges, weights.ba, coords.xyxz, d);
    }
    return weights;
}

//////////////////////////////////////////////////// NEIGHBORHOOD BLENDING ////////////////////////////////////////////////////////////////

float3 HQAALNeighborhoodBlendingPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float4 offset : TEXCOORD1) : SV_Target
{
	float3 resultAA = HQAAL_Tex2D(ReShade::BackBuffer, texcoord).rgb;
	if (HqaaDebugMode == 8) return resultAA;
    float4 m = float4(HQAAL_Tex2D(HQAALsamplerSMweights, offset.xy).a, HQAAL_Tex2D(HQAALsamplerSMweights, offset.zw).g, HQAAL_Tex2D(HQAALsamplerSMweights, texcoord).zx);

	[branch] if (any(m))
	{
		resultAA = ConditionalDecode(resultAA);
		float3 original = resultAA;
		float Lpre = dot(resultAA, __HQAAL_LUMA_REF);
		float maxweight = max(m.x + m.z, m.y + m.w);
		float minweight = min(m.x + m.z, m.y + m.w);
		float maxratio = maxweight / (minweight + maxweight);
		float minratio = minweight / (minweight + maxweight);
        bool horiz = (m.x + m.z) > (m.y + m.w);
        
        float4 blendingOffset = 0.0.xxxx;
        float2 blendingWeight;
        
        HQAAMovc(bool4(horiz, !horiz, horiz, !horiz), blendingOffset, float4(m.x, m.y, m.z, m.w));
        HQAAMovc(bool(horiz).xx, blendingWeight, m.xz);
        HQAAMovc(bool(!horiz).xx, blendingWeight, m.yw);
        blendingWeight /= dot(blendingWeight, float(1.0).xx);
        float4 blendingCoord = mad(blendingOffset, float4(__HQAAL_SM_BUFFERINFO.xy, -__HQAAL_SM_BUFFERINFO.xy), texcoord.xyxy);
        resultAA = maxratio * blendingWeight.x * HQAAL_DecodeTex2D(ReShade::BackBuffer, blendingCoord.xy).rgb;
        resultAA += maxratio * blendingWeight.y * HQAAL_DecodeTex2D(ReShade::BackBuffer, blendingCoord.zw).rgb;
        
        [branch] if (minratio != 0.0)
        {
        	blendingOffset = 0.0.xxxx;
        	HQAAMovc(bool4(!horiz, horiz, !horiz, horiz), blendingOffset, float4(m.x, m.y, m.z, m.w));
	        HQAAMovc(bool(!horiz).xx, blendingWeight, m.xz);
	        HQAAMovc(bool(horiz).xx, blendingWeight, m.yw);
	        blendingWeight /= dot(blendingWeight, float(1.0).xx);
	        blendingCoord = mad(blendingOffset, float4(__HQAAL_SM_BUFFERINFO.xy, -__HQAAL_SM_BUFFERINFO.xy), texcoord.xyxy);
	        resultAA += minratio * blendingWeight.x * HQAAL_DecodeTex2D(ReShade::BackBuffer, blendingCoord.xy).rgb;
	        resultAA += minratio * blendingWeight.y * HQAAL_DecodeTex2D(ReShade::BackBuffer, blendingCoord.zw).rgb;
 	   }
        
        float Lpost = dot(resultAA, __HQAAL_LUMA_REF);
        float resultingdelta = saturate(1.0 - abs(Lpost - Lpre) * (HqaaNoiseControlStrength / 100.));
        resultAA = lerp(original, resultAA, resultingdelta);
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

float3 HQAALFXPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float4 offset : TEXCOORD1) : SV_Target
 {
    float3 original = HQAAL_Tex2D(ReShade::BackBuffer, texcoord).rgb;
	if (HqaaDebugMode == 9) return original;
	
	float4 smaadata = HQAAL_Tex2D(HQAALsamplerAlphaEdges, texcoord);
	float edgethreshold = smaadata.a;
	float3 middle = ConditionalDecode(original);
	float maxchannel = max3(middle.r, middle.g, middle.b);
    float3 ref;
	if (middle.g == maxchannel) ref = __HQAAL_GREEN_LUMA;
	else if (middle.r == maxchannel) ref = __HQAAL_RED_LUMA;
	else ref = __HQAAL_BLUE_LUMA;
	float lumaM = dot(middle, ref);
	float2 lengthSign = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	
    float lumaS = dot(HQAAL_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(0, lengthSign.y)).rgb, ref);
    float lumaE = dot(HQAAL_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(lengthSign.x, 0)).rgb, ref);
    float lumaN = dot(HQAAL_DecodeTex2D(ReShade::BackBuffer, texcoord - float2(0, lengthSign.y)).rgb, ref);
    float lumaW = dot(HQAAL_DecodeTex2D(ReShade::BackBuffer, texcoord - float2(lengthSign.x, 0)).rgb, ref);
    float4 crossdelta = abs(lumaM - float4(lumaS, lumaE, lumaN, lumaW));
	float2 weightsHV = float2(crossdelta.x + crossdelta.z, crossdelta.y + crossdelta.w);
    
    // pattern
    // * z *
    // w * y
    // * x *
    
    float2 diagstep = lengthSign * __HQAAL_CONST_HALFROOT2;
    float lumaNW = dot(HQAAL_DecodeTex2D(ReShade::BackBuffer, texcoord - diagstep).rgb, ref);
    float lumaSE = dot(HQAAL_DecodeTex2D(ReShade::BackBuffer, texcoord + diagstep).rgb, ref);
    float lumaNE = dot(HQAAL_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(diagstep.x, -diagstep.y)).rgb, ref);
    float lumaSW = dot(HQAAL_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(-diagstep.x, diagstep.y)).rgb, ref);
    float4 diagdelta = abs(lumaM - float4(lumaNW, lumaSE, lumaNE, lumaSW));
	float2 weightsDI = float2(diagdelta.w + diagdelta.z, diagdelta.x + diagdelta.y);
    
    // pattern
    // x * z
    // * * *
    // w * y
    
	//detect edge pattern
	bool diagSpan = max(weightsDI.x, weightsDI.y) * float(bool(lxor(weightsDI.x, weightsDI.y))) > max(weightsHV.x, weightsHV.y);
	bool inverseDiag = diagSpan && (weightsDI.y > weightsDI.x);
	bool horzSpan = weightsHV.x > weightsHV.y;
	
	// early exit check
    float range = max8(crossdelta.x, crossdelta.y, crossdelta.z, crossdelta.w, diagdelta.x, diagdelta.y, diagdelta.z, diagdelta.w);
	if (HqaaFxEarlyExit && (range < edgethreshold))
		if (clamp(HqaaDebugMode, 3, 5) == HqaaDebugMode) return float(0.0).xxx;
		else return original;
	
	float2 lumaNP = float2(lumaN, lumaS);
	HQAAMovc(!horzSpan.xx, lumaNP, float2(lumaW, lumaE));
	HQAAMovc(diagSpan.xx, lumaNP, float2(lumaNW, lumaSE));
	HQAAMovc((diagSpan && inverseDiag).xx, lumaNP, float2(lumaSW, lumaNE));
    float gradientN = abs(lumaNP.x - lumaM);
    float gradientP = abs(lumaNP.y - lumaM);
    float lumaNN = lumaNP.x + lumaM;
    if (gradientN >= gradientP && !diagSpan) lengthSign = -lengthSign;
    if (diagSpan && inverseDiag) lengthSign.y = -lengthSign.y;
    if (gradientP > gradientN) lumaNN = lumaNP.y + lumaM;
    float gradientScaled = max(gradientN, gradientP) * 0.25;
    bool lumaMLTZero = mad(0.5, -lumaNN, lumaM) < 0.0;
	
    float2 posB = texcoord;
	float texelsize = __HQAAL_FX_TEXEL;
    float2 offNP = float2(0.0, BUFFER_RCP_HEIGHT * texelsize);
	HQAAMovc(bool(horzSpan).xx, offNP, float2(BUFFER_RCP_WIDTH * texelsize, 0.0));
	HQAAMovc(bool(diagSpan).xx, offNP, float2(BUFFER_RCP_WIDTH * texelsize, BUFFER_RCP_HEIGHT * texelsize));
	if (diagSpan && inverseDiag) offNP.y = -offNP.y;
	HQAAMovc(bool2(!horzSpan || diagSpan, horzSpan || diagSpan), posB, float2(posB.x + lengthSign.x * 0.333333, posB.y + lengthSign.y * 0.333333));
    float2 posN = posB - offNP;
    float2 posP = posB + offNP;
    float lumaEndN = dot(HQAAL_DecodeTex2D(ReShade::BackBuffer, posN).rgb, ref);
    float lumaEndP = dot(HQAAL_DecodeTex2D(ReShade::BackBuffer, posP).rgb, ref);
	
	lumaNN *= 0.5;
    lumaEndN -= lumaNN;
    lumaEndP -= lumaNN;
	
    bool doneN = abs(lumaEndN) >= gradientScaled;
    bool doneP = abs(lumaEndP) >= gradientScaled;
	uint iterations = 0;
	uint maxiterations = __HQAAL_FX_QUALITY;
	
	[loop] while (iterations < maxiterations)
	{
		if (doneN && doneP) break;
		if (!doneN)
		{
			posN -= offNP;
			lumaEndN = dot(HQAAL_DecodeTex2D(ReShade::BackBuffer, posN).rgb, ref);
			lumaEndN -= lumaNN;
			doneN = abs(lumaEndN) >= gradientScaled;
		}
		if (!doneP)
		{
			posP += offNP;
			lumaEndP = dot(HQAAL_DecodeTex2D(ReShade::BackBuffer, posP).rgb, ref);
			lumaEndP -= lumaNN;
			doneP = abs(lumaEndP) >= gradientScaled;
		}
		iterations++;
    }
	
	float2 dstNP = float2(texcoord.y - posN.y, posP.y - texcoord.y);
	HQAAMovc(bool(horzSpan).xx, dstNP, float2(texcoord.x - posN.x, posP.x - texcoord.x));
	HQAAMovc(bool(diagSpan).xx, dstNP, float2(sqrt(pow(abs(texcoord.y - posN.y), 2.0) + pow(abs(texcoord.x - posN.x), 2.0)), sqrt(pow(abs(posP.y - texcoord.y), 2.0) + pow(abs(posP.x - texcoord.x), 2.0))));
    float endluma = (dstNP.x < dstNP.y) ? lumaEndN : lumaEndP;
    bool goodSpan = endluma < 0.0 != lumaMLTZero;
    float blendclamp = goodSpan ? 1.0 : (1.0 - abs(endluma - lumaM) * (HqaaNoiseControlStrength / 100.));
    float pixelOffset = abs(mad(-rcp(dstNP.y + dstNP.x), min(dstNP.x, dstNP.y), 0.5)) * clamp(__HQAAL_FX_BLEND, 0.0, blendclamp);
    float subpixOut = 1.0;
    
	if (!goodSpan) // bad span
	{
		subpixOut = mad(mad(2.0, lumaS + lumaE + lumaN + lumaW, lumaNW + lumaSE + lumaNE + lumaSW), 0.083333, -lumaM) * rcp(range); //ABC
		subpixOut = pow(saturate(mad(-2.0, subpixOut, 3.0) * (subpixOut * subpixOut)), 2.0); // DEFGH
	}
	subpixOut *= pixelOffset;

    float2 posM = texcoord;
	HQAAMovc(bool2(!horzSpan || diagSpan, horzSpan || diagSpan), posM, float2(posM.x + lengthSign.x * subpixOut, posM.y + lengthSign.y * subpixOut));
    
	// output selection
	if (HqaaDebugMode == 4)
	{
		float3 debugout = ref * lumaM * 0.75 + 0.25;
		return debugout;
	}
	if (HqaaDebugMode == 5)
	{
		// metrics output
		float runtime = float(iterations / maxiterations) * 0.5;
		float3 FxaaMetrics = float3(runtime, 0.5 - runtime, 0.0);
		return FxaaMetrics;
	}
	
	// normal output
	return HQAAL_Tex2D(ReShade::BackBuffer, posM).rgb;
}

/***************************************************************************************************************************************/
/********************************************************** FXAA SHADER CODE END *******************************************************/
/***************************************************************************************************************************************/

/***************************************************************************************************************************************/
/****************************************************** HYSTERESIS SHADER CODE START ***************************************************/
/***************************************************************************************************************************************/

float3 HQAALHysteresisPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float4 offset : TEXCOORD1) : SV_Target
{
	float3 pixel = HQAAL_Tex2D(ReShade::BackBuffer, texcoord).rgb;
	float4 edgedata = HQAAL_Tex2D(HQAALsamplerAlphaEdges, texcoord);
	float4 blendingdata = float4(HQAAL_Tex2D(HQAALsamplerSMweights, offset.xy).a, HQAAL_Tex2D(HQAALsamplerSMweights, offset.zw).g, HQAAL_Tex2D(HQAALsamplerSMweights, texcoord).zx);
	
	if (HqaaEnableSharpening && (HqaaDebugMode == 0))
	{
		float3 casdot = pixel;
	
		float sharpening = HqaaSharpenerStrength;
	
		if (any(blendingdata)) sharpening *= (1.0 - HqaaSharpenerClamping);
		
		float2 hvstep = __HQAAL_SM_BUFFERINFO.xy * HqaaSharpenOffset;
		float2 diagstep = hvstep * __HQAAL_CONST_HALFROOT2;
	
		float3 a = HQAAL_Tex2D(ReShade::BackBuffer, texcoord - diagstep).rgb;
		float3 c = HQAAL_Tex2D(ReShade::BackBuffer, texcoord + float2(diagstep.x, -diagstep.y)).rgb;
		float3 g = HQAAL_Tex2D(ReShade::BackBuffer, texcoord + float2(-diagstep.x, diagstep.y)).rgb;
		float3 i = HQAAL_Tex2D(ReShade::BackBuffer, texcoord + diagstep).rgb;
		float3 b = HQAAL_Tex2D(ReShade::BackBuffer, texcoord - float2(0.0, hvstep.y)).rgb;
		float3 d = HQAAL_Tex2D(ReShade::BackBuffer, texcoord - float2(hvstep.x, 0.0)).rgb;
		float3 f = HQAAL_Tex2D(ReShade::BackBuffer, texcoord + float2(hvstep.x, 0.0)).rgb;
		float3 h = HQAAL_Tex2D(ReShade::BackBuffer, texcoord + float2(0.0, hvstep.y)).rgb;
	
		float3 mnRGB = HQAALmin5(d, casdot, f, b, h);
		float3 mnRGB2 = HQAALmin5(mnRGB, a, c, g, i);

		float3 mxRGB = HQAALmax5(d, casdot, f, b, h);
		float3 mxRGB2 = HQAALmax5(mxRGB, a, c, g, i);
	
		casdot = ConditionalDecode(casdot);
		mnRGB = ConditionalDecode(mnRGB);
		mnRGB2 = ConditionalDecode(mnRGB2);
		mxRGB = ConditionalDecode(mxRGB);
		mxRGB2 = ConditionalDecode(mxRGB2);
	
		mnRGB += mnRGB2;
		mxRGB += mxRGB2;
	
		float3 ampRGB = 1.0 / sqrt(saturate(min(mnRGB, 2.0 - mxRGB) * (1.0 / mxRGB)));    
		float3 wRGB = -(1.0 / (ampRGB * mad(-3.0, HqaaSharpenerAdaptation, 8.0)));
		float3 window = (b + d) + (f + h);
	
		float3 outColor = saturate(mad(window, wRGB, casdot) * (1.0 / mad(4.0, wRGB, 1.0)));
		casdot = lerp(casdot, outColor, sharpening);
	
		pixel = ConditionalEncode(casdot);
	}
	
	bool skiphysteresis = ((HqaaDebugMode == 0) && (!HqaaDoLumaHysteresis));
	if (skiphysteresis) return pixel;
	
	float safethreshold = max(__HQAAL_EDGE_THRESHOLD, __HQAAL_SMALLEST_COLOR_STEP);
	
	bool modifiedpixel = any(edgedata.rg);
	if (HqaaDebugMode == 6 && !modifiedpixel) return float(0.0).xxx;
	if (HqaaDebugMode == 1) return float3(edgedata.rg, 0.0);
	if (HqaaDebugMode == 2) return blendingdata.rgb;
	if (HqaaDebugMode == 7) { float usedthreshold = 1.0 - (edgedata.a / safethreshold); return float3(0.0, saturate(usedthreshold), 0.0); }

	float3 original = pixel;
	bool altered = false;
	pixel = ConditionalDecode(pixel);
	bool3 truezero = lnand(1.0.xxx, pixel);
	float3 AAdot = pixel;
	
	float blendweight = 1.0 - saturate(blendingdata.x + blendingdata.y + blendingdata.z + blendingdata.w);
	float blendclamp = any(blendingdata) ? blendweight : 1.0;
	float lowlumaclamp = min(edgedata.a, safethreshold) / safethreshold;
	float blendstrength = __HQAAL_HYSTERESIS_STRENGTH * min(blendclamp, lowlumaclamp);

	float hysteresis = (dot(pixel, __HQAAL_LUMA_REF) - edgedata.b) * blendstrength;
	if (abs(hysteresis) > __HQAAL_HYSTERESIS_FUDGE)
	{
		pixel = pow(abs(1.0 + hysteresis) * 2.0, log2(pixel));
		pixel = lnand(pixel, truezero);
		altered = true;
	}
	
	//output
	if (HqaaDebugMode == 6)
	{
		// hysteresis pattern
		return sqrt(abs(pixel - AAdot));
	}
	else if (altered) return ConditionalEncode(pixel);
	else return original;
}

/***************************************************************************************************************************************/
/******************************************************* HYSTERESIS SHADER CODE END ****************************************************/
/***************************************************************************************************************************************/

technique HQAAL <
	ui_tooltip = "============================================================\n"
				 "Hybrid high-Quality Anti-Aliasing combines techniques of\n"
				 "both SMAA and FXAA to produce best possible image quality\n"
				 "from using both. HQAA uses customized edge detection methods\n"
				 "designed for maximum possible aliasing detection.\n"
				 "============================================================";
	ui_label = "HQAA Lite";
>
{
	pass EdgeDetection
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAALHybridEdgeDetectionPS;
		RenderTarget = HQAALedgesTex;
	}
	pass SMAABlendCalculation
	{
		VertexShader = HQAALBlendingWeightCalculationVS;
		PixelShader = HQAALBlendingWeightCalculationPS;
		RenderTarget = HQAALblendTex;
		ClearRenderTargets = true;
	}
	pass FXAA
	{
		VertexShader = HQAALNeighborhoodBlendingVS;
		PixelShader = HQAALFXPS;
	}
	pass SMAABlending
	{
		VertexShader = HQAALNeighborhoodBlendingVS;
		PixelShader = HQAALNeighborhoodBlendingPS;
	}
#if HQAAL_FXAA_MULTISAMPLING > 1
	pass FXAA
	{
		VertexShader = HQAALNeighborhoodBlendingVS;
		PixelShader = HQAALFXPS;
	}
#endif
#if HQAAL_FXAA_MULTISAMPLING > 2
	pass FXAA
	{
		VertexShader = HQAALNeighborhoodBlendingVS;
		PixelShader = HQAALFXPS;
	}
#endif
#if HQAAL_FXAA_MULTISAMPLING > 3
	pass FXAA
	{
		VertexShader = HQAALNeighborhoodBlendingVS;
		PixelShader = HQAALFXPS;
	}
#endif
#if HQAAL_FXAA_MULTISAMPLING > 4
	pass FXAA
	{
		VertexShader = HQAALNeighborhoodBlendingVS;
		PixelShader = HQAALFXPS;
	}
#endif
#if HQAAL_FXAA_MULTISAMPLING > 5
	pass FXAA
	{
		VertexShader = HQAALNeighborhoodBlendingVS;
		PixelShader = HQAALFXPS;
	}
#endif
	pass Hysteresis
	{
		VertexShader = HQAALNeighborhoodBlendingVS;
		PixelShader = HQAALHysteresisPS;
	}
}
