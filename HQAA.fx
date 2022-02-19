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
 *                        v18.5.1
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

#ifndef HQAA_ENABLE_HDR_OUTPUT
	#define HQAA_ENABLE_HDR_OUTPUT 0
#endif //HQAA_ENABLE_HDR_OUTPUT

#ifndef HQAA_ENABLE_FPS_TARGET
	#define HQAA_ENABLE_FPS_TARGET 1
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
		#define HQAA_OPTIONAL_TEMPORAL_STABILIZER 1
	#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER
	#ifndef HQAA_OPTIONAL_BRIGHTNESS_GAIN
		#define HQAA_OPTIONAL_BRIGHTNESS_GAIN 1
	#endif //HQAA_OPTIONAL_BRIGHTNESS_GAIN
	#ifndef HQAA_OPTIONAL_DEBAND
		#define HQAA_OPTIONAL_DEBAND 1
	#endif
#endif // HQAA_ENABLE_OPTIONAL_TECHNIQUES

#ifndef HQAA_SCREENSHOT_MODE
	#define HQAA_SCREENSHOT_MODE 0
#endif //HQAA_SCREENSHOT_MODE

uniform int HQAAintroduction <
	ui_type = "radio";
	ui_label = "Version: 18.5.1";
	ui_text = "-------------------------------------------------------------------------\n\n"
			  "Hybrid high-Quality Anti-Aliasing, a shader by lordbean\n"
			  "https://github.com/lordbean-git/HQAA/\n";
	ui_tooltip = "Overclocked Edition";
>;

uniform int introeof <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "-------------------------------------------------------------------------\n"
			  "See HQAA's Preprocessor definitions section for optional feature toggles.\n"
			  "-------------------------------------------------------------------------";
>;

uniform uint preset <
	ui_type = "combo";
	ui_label = "Quality Preset";
	ui_tooltip = "For quick start use, pick a preset. If you'd prefer to fine tune, select Custom.";
	ui_items = "Low\0Medium\0High\0Ultra\0Custom\0";
> = 3;

uniform float HqaaHysteresisStrength <
	ui_type = "slider";
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "% Max Hysteresis\n\n";
	ui_tooltip = "Hysteresis correction adjusts the appearance of anti-aliased\npixels towards their original appearance, which helps\nto preserve detail in the final image.\n\n0% = Off (keep anti-aliasing result as-is)\n100% = Aggressive Correction";
> = 20;

uniform float EdgeThresholdCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Edge Detection Threshold";
	ui_tooltip = "Local contrast (luma difference) required to be considered an edge";
    ui_category = "Custom Preset";
	ui_category_closed = true;
	ui_text = "------------------------------ Global Options ----------------------------------\n ";
> = 0.1;

uniform float DynamicThresholdCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "Dynamic Threshold Reduction Range";
	ui_tooltip = "Maximum dynamic reduction of edge threshold (as percentage of base threshold)\n"
				 "permitted when detecting low-brightness edges.\n"
				 "Lower = faster, might miss low-contrast edges\n"
				 "Higher = slower, catches more edges in dark scenes";
    ui_category = "Custom Preset";
	ui_category_closed = true;
> = 50;

uniform float SmaaCorneringCustom < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "SMAA Corner Rounding";
	ui_tooltip = "Affects the amount of blending performed when SMAA\ndetects crossing edges";
    ui_category = "Custom Preset";
	ui_category_closed = true;
	ui_text = "\n------------------------------- SMAA Options -----------------------------------\n ";
> = 50;

uniform float FxaaIterationsCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.25; ui_max = 5.0; ui_step = 0.01;
	ui_label = "Quality Multiplier";
	ui_tooltip = "Multiplies the maximum number of edge gradient\nscanning iterations that FXAA will perform";
    ui_category = "Custom Preset";
	ui_category_closed = true;
	ui_text = "\n------------------------------- FXAA Options -----------------------------------\n ";
> = 1.0;

uniform float FxaaTexelSizeCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.1; ui_max = 4.0; ui_step = 0.001;
	ui_label = "Edge Gradient Texel Size";
	ui_tooltip = "Determines how far along an edge FXAA will move\nfrom one scan iteration to the next.\n\nLower = slower, more accurate\nHigher = faster, more blurry";
	ui_category = "Custom Preset";
	ui_category_closed = true;
> = 1.0;

uniform float SubpixCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "Subpixel Effect Strength\n\n";
	ui_tooltip = "Percentage of blending FXAA will apply to long slopes.\n"
				 "Lower = sharper image, Higher = more AA effect";
    ui_category = "Custom Preset";
	ui_category_closed = true;
> = 50;

static const float HQAA_THRESHOLD_PRESET[5] = {0.2, 0.1, 0.075, 0.05, 1.0};
static const float HQAA_DYNAMIC_RANGE_PRESET[5] = {0.5, 0.666667, 0.8, 0.9, 0.0};
static const float HQAA_SMAA_CORNER_ROUNDING_PRESET[5] = {0.1, 0.25, 0.5, 1.0, 0.0};
static const float HQAA_FXAA_SCANNING_MULTIPLIER_PRESET[5] = {0.5, 1.0, 1.25, 2.5, 0.0};
static const float HQAA_FXAA_TEXEL_SIZE_PRESET[5] = {2.0, 1.5, 1.0, 0.5, 4.0};
static const float HQAA_SUBPIX_PRESET[5] = {0.2, 0.5, 0.8, 1.0, 0.0};

uniform int presetbreakdown <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n"
			  "------------------------------------------------------------------\n"
			  "|        |       Global      |  SMAA  |           FXAA           |\n"
	          "|--Preset|-Threshold---Range-|-Corner-|-Quality---Texel---Subpix-|\n"
	          "|--------|-----------|-------|--------|---------|-------|--------|\n"
			  "|     Low|   0.200   | 50.0% |   10%  |  0.500  |  2.0  |  20.0% |\n"
			  "|  Medium|   0.100   | 66.6% |   25%  |  1.000  |  1.5  |  50.0% |\n"
			  "|    High|   0.075   | 80.0% |   50%  |  1.250  |  1.0  |  80.0% |\n"
			  "|   Ultra|   0.050   | 90.0% |  100%  |  2.500  |  0.5  | 100.0% |\n"
			  "------------------------------------------------------------------";
	ui_category = "Click me to see what settings each preset uses!";
	ui_category_closed = true;
>;

#if HQAA_COMPILE_DEBUG_CODE
uniform uint debugmode <
	ui_type = "radio";
	ui_category = "Debug";
	ui_category_closed = true;
	ui_spacing = 2;
	ui_label = " ";
	ui_text = "Debug Mode:";
	ui_items = "Off\0Detected Edges\0SMAA Blend Weights\0FXAA Results\0FXAA Lumas\0FXAA Metrics\0Prepass Saturation Levels\0Prepass Luma Levels\0PostAA Saturation Levels\0PostAA Luma Levels\0Final Saturation Levels\0Final Luma Levels\0";
> = 0;
#endif //HQAA_COMPILE_DEBUG_CODE

#if (HQAA_ENABLE_FPS_TARGET || HQAA_ENABLE_HDR_OUTPUT || HQAA_COMPILE_DEBUG_CODE)
uniform int extradivider <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n-------------------------------------------------------------------------";
>;
#endif //(HQAA_ENABLE_FPS_TARGET || HQAA_ENABLE_HDR_OUTPUT || HQAA_COMPILE_DEBUG_CODE)

#if HQAA_ENABLE_FPS_TARGET
uniform float FramerateFloor < __UNIFORM_SLIDER_INT1
	ui_min = 30; ui_max = 240; ui_step = 1;
	ui_label = "Target Minimum Framerate";
	ui_tooltip = "HQAA will automatically reduce FXAA sampling quality if\nthe framerate drops below this number";
> = 60;
#endif //HQAA_ENABLE_FPS_TARGET

#if HQAA_ENABLE_HDR_OUTPUT
uniform float HdrNits < 
	ui_type = "combo";
	ui_min = 200.0; ui_max = 1000.0; ui_step = 200.0;
	ui_label = "HDR Nits";
	ui_tooltip = "Most DisplayHDR certified monitors calculate colors based on 1000 nits\n"
				 "even when the certification is for a lower value (like DisplayHDR400).";
> = 1000.0;
#endif //HQAA_ENABLE_HDR_OUTPUT

#if HQAA_COMPILE_DEBUG_CODE
uniform int debugexplainer <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "----------------------------------------------------------------\n"
	          "                 HOW TO READ DEBUG RESULTS\n"
              "----------------------------------------------------------------\n"
			  "When viewing the detected edges, the colors shown in the texture\n"
			  "are not related to the image on the screen directly, rather they\n"
			  "are markers indicating the following:\n"
			  "- Green = Probable Horizontal Edge Here\n"
			  "- Red = Probable Vertical Edge Here\n"
			  "- Yellow = Probable Diagonal Edge Here\n\n"
			  "SMAA blending weights and FXAA results show what each related\n"
			  "pass is blending with the screen to produce its AA effect.\n\n"
			  "FXAA lumas shows FXAA's estimation of the brightness of pixels\n"
			  "where the pass ran corrections.\n\n"
			  "FXAA metrics draws a range of green to red where the selected\n"
			  "pass ran, with green representing not much execution time used\n"
			  "and red representing a lot of execution time used.\n\n"
			  "Saturation and Luma calculations show a represenation of the\n"
			  "bespoke calculation onscreen. In both cases, black pixels are\n"
			  "areas where no edges were detected. Saturation is displayed as a\n"
			  "range from red to green, where red areas represent low\n"
			  "saturation and green areas represent high saturation.\n\n"
			  "Debug checks can optionally be excluded from the compiled shader\n"
			  "by setting HQAA_COMPILE_DEBUG_CODE to 0.\n"
	          "----------------------------------------------------------------";
	ui_category = "DEBUG README";
	ui_category_closed = true;
>;
#endif //HQAA_COMPILE_DEBUG_CODE

uniform int optionseof <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n-------------------------------------------------------------------------";
>;

#if HQAA_ENABLE_OPTIONAL_TECHNIQUES
#if HQAA_OPTIONAL_CAS
uniform float HqaaSharpenerStrength < __UNIFORM_SLIDER_FLOAT1
	ui_spacing = 3;
	ui_min = 0; ui_max = 10; ui_step = 0.01;
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

uniform int sharpenerintro <
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
> = 0.2;

uniform bool ClampMaximumWeight <
	ui_label = "Clamp Maximum Weight?";
	ui_spacing = 2;
	ui_category = "Temporal Stabilizer";
	ui_category_closed = true;
	ui_tooltip = "When enabled the maximum amount of weight given to the previous\n"
				 "frame will be equal to the largest change in contrast in any\n"
				 "single color channel between the past frame and the current frame.";
> = false;

uniform int stabilizerintro <
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
	ui_category = "Brightness Booster";
	ui_category_closed = true;
> = 0.0;

uniform bool HqaaGainLowLumaCorrection <
	ui_spacing = 2;
	ui_label = "Contrast Washout Correction";
	ui_tooltip = "Normalizes contrast ratio of resulting pixels\n"
				 "to reduce perceived contrast washout.";
	ui_category = "Brightness Booster";
	ui_category_closed = true;
> = false;
	
uniform int gainintro <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\nWhen enabled, allows to raise overall image brightness\n"
			  "as a quick fix for dark games and/or monitors.\n\n"
			  "Contrast washout correction dynamically adjusts the luma\n"
			  "and saturation of the result to approximate the look of\n"
			  "the original scene, removing most of the perceived loss\n"
			  "of contrast (or 'airy' look) after the gain is applied.";
	ui_category = "Brightness Booster";
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
> = 16.0;

uniform int debandintro <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\nWhen enabled, performs a fast debanding pass similar\n"
			  "to Deband.fx to mitigate color banding.\n\n"
			  "Please note that debanding will have a significant performance\n"
			  "impact compared to other optional features.";
	ui_category = "Debanding";
	ui_category_closed = true;
>;

uniform uint drandom < source = "random"; min = 0; max = 32767; >;
#endif

uniform int optionalseof <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n-------------------------------------------------------------------------";
>;
#endif //HQAA_ENABLE_OPTIONAL_TECHNIQUES

#if HQAA_ENABLE_FPS_TARGET
uniform float frametime < source = "frametime"; >;
#endif //HQAA_ENABLE_FPS_TARGET

/*****************************************************************************************************************************************/
/*********************************************************** UI SETUP END ****************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/******************************************************** SYNTAX SETUP START *************************************************************/
/*****************************************************************************************************************************************/

#define __HQAA_EDGE_THRESHOLD (preset == 4 ? (EdgeThresholdCustom) : (HQAA_THRESHOLD_PRESET[preset]))
#define __HQAA_DYNAMIC_RANGE (preset == 4 ? (DynamicThresholdCustom / 100.0) : HQAA_DYNAMIC_RANGE_PRESET[preset])
#define __HQAA_SMAA_CORNERING (preset == 4 ? (SmaaCorneringCustom / 100.0) : (HQAA_SMAA_CORNER_ROUNDING_PRESET[preset]))
#define __HQAA_FXAA_SCAN_MULTIPLIER (preset == 4 ? (FxaaIterationsCustom) : (HQAA_FXAA_SCANNING_MULTIPLIER_PRESET[preset]))
#define __HQAA_FXAA_SCAN_GRANULARITY (preset == 4 ? (FxaaTexelSizeCustom) : (HQAA_FXAA_TEXEL_SIZE_PRESET[preset]))
#define __HQAA_SUBPIX (preset == 4 ? (SubpixCustom / 100.0) : (HQAA_SUBPIX_PRESET[preset]))

#define __HQAA_DISPLAY_NUMERATOR max(BUFFER_HEIGHT, BUFFER_WIDTH)
#define __HQAA_SMALLEST_COLOR_STEP rcp(pow(2, BUFFER_COLOR_BIT_DEPTH))
#define __HQAA_LUMA_REF float(0.25).xxxx
#define __HQAA_GAMMA_REF float(0.333334).xxx

#define __HQAA_DESIRED_FRAMETIME float(1000.0 / FramerateFloor)
#define __HQAA_FPS_CLAMP_MULTIPLIER rcp(frametime - (__HQAA_DESIRED_FRAMETIME - 1.0))

#define __FXAA_THRESHOLD_FLOOR (__HQAA_SMALLEST_COLOR_STEP * 0.5)
#define __FXAA_EDGE_THRESHOLD max(__HQAA_EDGE_THRESHOLD, __FXAA_THRESHOLD_FLOOR)
#define __FXAA_MINIMUM_SEARCH_STEPS (2.0 / __HQAA_FXAA_SCAN_GRANULARITY)
#define __FXAA_DEFAULT_SEARCH_STEPS (8.0 / __HQAA_FXAA_SCAN_GRANULARITY)

#define __SMAA_THRESHOLD_FLOOR (__HQAA_SMALLEST_COLOR_STEP * 0.25)
#define __SMAA_EDGE_THRESHOLD max(__HQAA_EDGE_THRESHOLD, __SMAA_THRESHOLD_FLOOR)
#define __SMAA_MAX_SEARCH_STEPS (__HQAA_DISPLAY_NUMERATOR * 0.125)
#define __SMAA_MINIMUM_SEARCH_STEPS 20
#define __SMAA_RT_METRICS float4(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT, BUFFER_WIDTH, BUFFER_HEIGHT)
#define __SMAASampleLevelZero(tex, coord) tex2Dlod(tex, coord.xyxy)
#define __SMAASampleLevelZeroOffset(tex, coord, offset) tex2Dlodoffset(tex, coord.xyxy, offset)
#define __SMAA_AREATEX_MAX_DISTANCE 16
#define __SMAA_AREATEX_MAX_DISTANCE_DIAG 20
#define __SMAA_AREATEX_PIXEL_SIZE float2(0.00625, 0.001786) // 1/{160,560}
#define __SMAA_AREATEX_SUBTEX_SIZE 0.142857 // 1/7
#define __SMAA_SEARCHTEX_SIZE float2(66.0, 33.0)
#define __SMAA_SEARCHTEX_PACKED_SIZE float2(64.0, 16.0)

#define max3(x,y,z) max(max(x,y),z)
#define max4(w,x,y,z) max(max(max(w,x),y),z)
#define max5(v,w,x,y,z) max(max(max(max(v,w),x),y),z)
#define max6(u,v,w,x,y,z) max(max(max(max(max(u,v),w),x),y),z)
#define max7(t,u,v,w,x,y,z) max(max(max(max(max(max(t,u),v),w),x),y),z)
#define max8(s,t,u,v,w,x,y,z) max(max(max(max(max(max(max(s,t),u),v),w),x),y),z)
#define max9(r,s,t,u,v,w,x,y,z) max(max(max(max(max(max(max(max(r,s),t),u),v),w),x),y),z)

#define min3(x,y,z) min(min(x,y),z)
#define min4(w,x,y,z) min(min(min(w,x),y),z)
#define min5(v,w,x,y,z) min(min(min(min(v,w),x),y),z)
#define min6(u,v,w,x,y,z) min(min(min(min(min(u,v),w),x),y),z)
#define min7(t,u,v,w,x,y,z) min(min(min(min(min(min(t,u),v),w),x),y),z)
#define min8(s,t,u,v,w,x,y,z) min(min(min(min(min(min(min(s,t),u),v),w),x),y),z)
#define min9(r,s,t,u,v,w,x,y,z) min(min(min(min(min(min(min(min(r,s),t),u),v),w),x),y),z)

#define dotluma(x) dot(x.rgba, __HQAA_LUMA_REF)
#define dotgamma(x) dot(x.rgb, __HQAA_GAMMA_REF)
#define vec4add(x) (x.r + x.g + x.b + x.a)
#define vec3add(x) (x.r + x.g + x.b)

#define FxaaTex2D(t, p) tex2Dlod(t, p.xyxy)
#define FxaaTex2DOffset(t, p, o) tex2Dlodoffset(t, p.xyxy, o)

#define __CONST_E 2.718282

/*****************************************************************************************************************************************/
/********************************************************* SYNTAX SETUP END **************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/******************************************************** SUPPORT CODE START *************************************************************/
/*****************************************************************************************************************************************/

// Saturation calculator
float dotsat(float3 x)
{
	float luma = dotgamma(x);
	return (max3(x.r, x.g, x.b) - min3(x.r, x.g, x.b)) / (1.0 - (2.0 * luma - 1.0));
}
float dotsat(float4 x)
{
	return dotsat(x.rgb);
}

// Alpha channel normalizer
float4 NormalizeAlpha(float4 pixel)
{
	float rgbluma = dotluma(pixel);
	pixel.a = lerp(rgbluma, pixel.a, rgbluma);
	return pixel;
}

// conditional move
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

// SMAA filtered sample decode
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

// SMAA diagonal search functions
float2 HQAASearchDiag1(sampler2D HQAAedgesTex, float2 texcoord, float2 dir, out float2 e)
{
    float4 coord = float4(texcoord, -1.0, 1.0);
    float3 t = float3(__SMAA_RT_METRICS.xy, 1.0);
    bool endloop = false;
    
    [loop] while (coord.z < 20.0) 
	{
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);
        e = __SMAASampleLevelZero(HQAAedgesTex, coord.xy).rg;
        coord.w = dot(e, float(0.5).xx);
        endloop = coord.w < 0.9;
        if (endloop) break;
    }
    return coord.zw;
}

float2 HQAASearchDiag2(sampler2D HQAAedgesTex, float2 texcoord, float2 dir, out float2 e)
{
    float4 coord = float4(texcoord, -1.0, 1.0);
    coord.x += 0.25 * __SMAA_RT_METRICS.x;
    float3 t = float3(__SMAA_RT_METRICS.xy, 1.0);
    bool endloop = false;
    
    [loop] while (coord.z < 20.0) 
	{
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);

        e = __SMAASampleLevelZero(HQAAedgesTex, coord.xy).rg;
        e = HQAADecodeDiagBilinearAccess(e);

        coord.w = dot(e, float(0.5).xx);
        endloop = coord.w < 0.9;
        if (endloop) break;
    }
    return coord.zw;
}

float2 HQAAAreaDiag(sampler2D HQAAareaTex, float2 dist, float2 e, float offset)
{
    float2 texcoord = mad(float(__SMAA_AREATEX_MAX_DISTANCE_DIAG).xx, e, dist);

    texcoord = mad(__SMAA_AREATEX_PIXEL_SIZE, texcoord, 0.5 * __SMAA_AREATEX_PIXEL_SIZE);
    texcoord.x += 0.5;
    texcoord.y += __SMAA_AREATEX_SUBTEX_SIZE * offset;

    return __SMAASampleLevelZero(HQAAareaTex, texcoord).rg;
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
        float4 coords = mad(float4(-d.x + 0.25, d.x, d.y, -d.y - 0.25), __SMAA_RT_METRICS.xyxy, texcoord.xyxy);
        float4 c;
        c.xy = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.xy, int2(-1,  0)).rg;
        c.zw = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.zw, int2( 1,  0)).rg;
        c.yxwz = HQAADecodeDiagBilinearAccess(c.xyzw);

        float2 cc = mad(float(2.0).xx, c.xz, c.yw);

        HQAAMovc(bool2(step(0.9, d.zw)), cc, float(0.0).xx);

        weights += HQAAAreaDiag(HQAAareaTex, d.xy, cc, subsampleIndices.z);
    }

    d.xz = HQAASearchDiag2(HQAAedgesTex, texcoord, float2(-1.0, -1.0), end);
    d.yw = float(0.0).xx;
    
    checkpassed = __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord, int2(1, 0)).r > 0.0;
    [branch] if (checkpassed) 
	{
        d.yw = HQAASearchDiag2(HQAAedgesTex, texcoord, float(1.0).xx, end);
        d.y += float(end.y > 0.9);
    }
	
	checkpassed = d.x + d.y > 2.0;
	[branch] if (checkpassed) 
	{
        float4 coords = mad(float4(-d.x, -d.x, d.y, d.y), __SMAA_RT_METRICS.xyxy, texcoord.xyxy);
        float4 c;
        c.x  = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.xy, int2(-1,  0)).g;
        c.y  = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.xy, int2( 0, -1)).r;
        c.zw = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.zw, int2( 1,  0)).gr;
        float2 cc = mad(float(2.0).xx, c.xz, c.yw);

        HQAAMovc(bool2(step(0.9, d.zw)), cc, float(0.0).xx);

        weights += HQAAAreaDiag(HQAAareaTex, d.xy, cc, subsampleIndices.w).gr;
    }

    return weights;
}

// SMAA horizontal / vertical search functions
float HQAASearchLength(sampler2D HQAAsearchTex, float2 e, float offset)
{
    float2 scale = __SMAA_SEARCHTEX_SIZE * float2(0.5, -1.0);
    float2 bias = __SMAA_SEARCHTEX_SIZE * float2(offset, 1.0);

    scale += float2(-1.0,  1.0);
    bias  += float2( 0.5, -0.5);

    scale *= 1.0 / __SMAA_SEARCHTEX_PACKED_SIZE;
    bias *= 1.0 / __SMAA_SEARCHTEX_PACKED_SIZE;

    return __SMAASampleLevelZero(HQAAsearchTex, mad(scale, e, bias)).r;
}

float HQAASearchXLeft(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end)
{
    float2 e = float2(0.0, 1.0);
    bool endedge = false;
    [loop] while (texcoord.x > end) 
	{
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(-float2(2.0, 0.0), __SMAA_RT_METRICS.xy, texcoord);
        endedge = e.r > 0.0 || e.g == 0.0;
        if (endedge) break;
    }
    float offset = mad(-2.007874, HQAASearchLength(HQAAsearchTex, e, 0.0), 3.25); // -(255/127)
    return mad(__SMAA_RT_METRICS.x, offset, texcoord.x);
}

float HQAASearchXRight(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end)
{
    float2 e = float2(0.0, 1.0);
    bool endedge = false;
    [loop] while (texcoord.x < end) 
	{
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(float2(2.0, 0.0), __SMAA_RT_METRICS.xy, texcoord);
        endedge = e.r > 0.0 || e.g == 0.0;
        if (endedge) break;
    }
    float offset = mad(-2.007874, HQAASearchLength(HQAAsearchTex, e, 0.5), 3.25);
    return mad(-__SMAA_RT_METRICS.x, offset, texcoord.x);
}

float HQAASearchYUp(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end)
{
    float2 e = float2(1.0, 0.0);
    bool endedge = false;
    [loop] while (texcoord.y > end) 
	{
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(-float2(0.0, 2.0), __SMAA_RT_METRICS.xy, texcoord);
        endedge = e.r == 0.0 || e.g > 0.0;
        if (endedge) break;
    }
    float offset = mad(-2.007874, HQAASearchLength(HQAAsearchTex, e.gr, 0.0), 3.25);
    return mad(__SMAA_RT_METRICS.y, offset, texcoord.y);
}

float HQAASearchYDown(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end)
{
    float2 e = float2(1.0, 0.0);
    bool endedge = false;
    [loop] while (texcoord.y < end) 
	{
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(float2(0.0, 2.0), __SMAA_RT_METRICS.xy, texcoord);
        endedge = e.r == 0.0 || e.g > 0.0;
        if (endedge) break;
    }
    float offset = mad(-2.007874, HQAASearchLength(HQAAsearchTex, e.gr, 0.5), 3.25);
    return mad(-__SMAA_RT_METRICS.y, offset, texcoord.y);
}

float2 HQAAArea(sampler2D HQAAareaTex, float2 dist, float e1, float e2, float offset)
{
    float2 texcoord = mad(float(__SMAA_AREATEX_MAX_DISTANCE).xx, round(4.0 * float2(e1, e2)), dist);
    
    texcoord = mad(__SMAA_AREATEX_PIXEL_SIZE, texcoord, 0.5 * __SMAA_AREATEX_PIXEL_SIZE);
    texcoord.y = mad(__SMAA_AREATEX_SUBTEX_SIZE, offset, texcoord.y);

    return __SMAASampleLevelZero(HQAAareaTex, texcoord).rg;
}

// SMAA corner detection functions
void HQAADetectHorizontalCornerPattern(sampler2D HQAAedgesTex, inout float2 weights, float4 texcoord, float2 d)
{
    float2 leftRight = step(d.xy, d.yx);
    float2 rounding = (1.0 - __HQAA_SMAA_CORNERING) * leftRight;

    float2 factor = float(1.0).xx;
    factor.x -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2(0,  1)).r;
    factor.x -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2(1,  1)).r;
    factor.y -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2(0, -2)).r;
    factor.y -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2(1, -2)).r;

    weights *= saturate(factor);
}

void HQAADetectVerticalCornerPattern(sampler2D HQAAedgesTex, inout float2 weights, float4 texcoord, float2 d)
{
    float2 leftRight = step(d.xy, d.yx);
    float2 rounding = (1.0 - __HQAA_SMAA_CORNERING) * leftRight;

    float2 factor = float(1.0).xx;
    factor.x -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2( 1, 0)).g;
    factor.x -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2( 1, 1)).g;
    factor.y -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2(-2, 0)).g;
    factor.y -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2(-2, 1)).g;

    weights *= saturate(factor);
}

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

// Saturation adjuster
float3 AdjustSaturation(float3 pixel, float satadjust)
{
	float3 outdot = pixel;
	float channelstep = __HQAA_SMALLEST_COLOR_STEP;
	bool grayscale = max3(abs(pixel.r - pixel.g), abs(pixel.r - pixel.b), abs(pixel.g - pixel.b)) < (2.0 * channelstep);
	bool runadjustment = (abs(satadjust) > __HQAA_SMALLEST_COLOR_STEP) && !grayscale;
	[branch] if (runadjustment)
	{
		float2 highlow = float2(max3(outdot.r, outdot.g, outdot.b), min3(outdot.r, outdot.g, outdot.b));
		float mid = -1.0;
		float adjustdown = (1.0 - satadjust) * 2.0;
		float adjustup = (1.0 + satadjust) * 2.0;
		if (outdot.r == highlow.x) outdot.r = pow(abs(adjustdown), log2(outdot.r));
		else if (outdot.r == highlow.y) outdot.r = pow(abs(adjustup), log2(outdot.r));
		else mid = outdot.r;
		if (outdot.g == highlow.x) outdot.g = pow(abs(adjustdown), log2(outdot.g));
		else if (outdot.g == highlow.y) outdot.g = pow(abs(adjustup), log2(outdot.g));
		else mid = outdot.g;
		if (outdot.b == highlow.x) outdot.b = pow(abs(adjustdown), log2(outdot.b));
		else if (outdot.b == highlow.y) outdot.b = pow(abs(adjustup), log2(outdot.b));
		else mid = outdot.b;
		float midadjust = (1.0 + dotgamma(outdot) - dotgamma(pixel)) * 2.0;
		if (pixel.r == mid) outdot.r = pow(abs(midadjust), log2(outdot.r));
		else if (pixel.g == mid) outdot.g = pow(abs(midadjust), log2(outdot.g));
		else if (pixel.b == mid) outdot.b = pow(abs(midadjust), log2(outdot.b));
	}
	return outdot;
}
float4 AdjustSaturation(float4 pixel, float satadjust)
{
	return float4(AdjustSaturation(pixel.rgb, satadjust), pixel.a);
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

texture HQAAblendTex
#if __RESHADE__ >= 50000
< pooled = true; >
#endif
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
#if HQAA_ENABLE_HDR_OUTPUT
	Format = RGBA16F;
#elif (BUFFER_COLOR_BIT_DEPTH == 10)
	Format = RGB10A2;
#else
	Format = RGBA8;
#endif //HQAA_ENABLE_HDR_OUTPUT
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
#if HQAA_ENABLE_HDR_OUTPUT
	Format = RGBA16F;
#elif (BUFFER_COLOR_BIT_DEPTH == 10)
	Format = RGB10A2;
#else
	Format = RGBA8;
#endif //HQAA_ENABLE_HDR_OUTPUT
};
#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER
#endif //HQAA_ENABLE_OPTIONAL_TECHNIQUES

//////////////////////////////////////////////////////////// SAMPLERS ///////////////////////////////////////////////////////////////////

sampler HQAAsamplerBufferSRGB
{
	Texture = ReShade::BackBufferTex;
#if !HQAA_ENABLE_HDR_OUTPUT
	SRGBTexture = true;
#endif //HQAA_ENABLE_HDR_OUTPUT
};

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

//////////////////////////////////////////////////////////// VERTEX SHADERS /////////////////////////////////////////////////////////////

void HQAAEdgeDetectionVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0, out float4 offset[3] : TEXCOORD1)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    offset[0] = mad(__SMAA_RT_METRICS.xyxy, float4(-1.0, 0.0, 0.0, -1.0), texcoord.xyxy);
    offset[1] = mad(__SMAA_RT_METRICS.xyxy, float4( 1.0, 0.0, 0.0,  1.0), texcoord.xyxy);
    offset[2] = mad(__SMAA_RT_METRICS.xyxy, float4(-2.0, 0.0, 0.0, -2.0), texcoord.xyxy);
}


void HQAABlendingWeightCalculationVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0, out float2 pixcoord : TEXCOORD1, out float4 offset[3] : TEXCOORD2)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    pixcoord = texcoord * __SMAA_RT_METRICS.zw;

    offset[0] = mad(__SMAA_RT_METRICS.xyxy, float4(-0.25, -0.125,  1.25, -0.125), texcoord.xyxy);
    offset[1] = mad(__SMAA_RT_METRICS.xyxy, float4(-0.125, -0.25, -0.125,  1.25), texcoord.xyxy);
	
	float searchrange = trunc(__SMAA_MAX_SEARCH_STEPS);
	
#if HQAA_ENABLE_FPS_TARGET
	if (frametime > __HQAA_DESIRED_FRAMETIME)
		searchrange = trunc(max(__SMAA_MINIMUM_SEARCH_STEPS, searchrange * __HQAA_FPS_CLAMP_MULTIPLIER));
#endif //HQAA_ENABLE_FPS_TARGET

    offset[2] = mad(__SMAA_RT_METRICS.xxyy,
                    float2(-2.0, 2.0).xyxy * searchrange,
                    float4(offset[0].xz, offset[1].yw));
}


void HQAANeighborhoodBlendingVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0, out float4 offset : TEXCOORD1)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    offset = mad(__SMAA_RT_METRICS.xyxy, float4( 1.0, 0.0, 0.0,  1.0), texcoord.xyxy);
}

/*****************************************************************************************************************************************/
/*********************************************************** SHADER SETUP END ************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/********************************************************** SMAA SHADER CODE START *******************************************************/
/*****************************************************************************************************************************************/

float4 HQAALumaEdgeDetectionPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float4 offset[3] : TEXCOORD1) : SV_Target
{
	float4 middle = tex2D(ReShade::BackBuffer, texcoord);
	
	// calculate data for FXAA hysteresis (needs to be done before alpha normalize)
	float2 hysteresisdata = float2(dotgamma(middle), dotsat(middle));
	
	// Normalize the alpha channel
	middle = NormalizeAlpha(middle);
	
	// calculate the threshold
#if HQAA_SCREENSHOT_MODE
	float2 threshold = float(0.0).xx;
#elif HQAA_ENABLE_HDR_OUTPUT
	float2 threshold = float(__SMAA_EDGE_THRESHOLD * log2(HdrNits)).xx;
#else
	float adjustmentrange = __HQAA_DYNAMIC_RANGE * __SMAA_EDGE_THRESHOLD;
	float thresholdOffset = mad(pow(abs((dotgamma(middle) + middle.a) / 2.0), 1.0 + __HQAA_DYNAMIC_RANGE), adjustmentrange, -adjustmentrange);
	
	float2 threshold = float(__SMAA_EDGE_THRESHOLD + thresholdOffset).xx;
#endif //HQAA_SCREENSHOT_MODE
	
	// calculate color channel weighting
	float4 weights = __HQAA_LUMA_REF;
	weights *= middle;
	float scale = rcp(vec4add(weights));
	weights *= scale;
	
	float2 edges = float2(0.0, 0.0);
	
    float L = dot(middle, weights);

    float Lleft = dot(NormalizeAlpha(tex2D(ReShade::BackBuffer, offset[0].xy)), weights);
    float Ltop  = dot(NormalizeAlpha(tex2D(ReShade::BackBuffer, offset[0].zw)), weights);

    float4 delta = float4(abs(L - float2(Lleft, Ltop)), 0.0, 0.0);
    edges = step(threshold, delta.xy);
    bool edgedetected = edges.r != -edges.g;
	
	[branch] if (edgedetected)
	{
		float Lright = dot(NormalizeAlpha(tex2D(ReShade::BackBuffer, offset[1].xy)), weights);
		float Lbottom  = dot(NormalizeAlpha(tex2D(ReShade::BackBuffer, offset[1].zw)), weights);

		delta.zw = abs(L - float2(Lright, Lbottom));

		float2 maxDelta = max(delta.xy, delta.zw);

		float Lleftleft = dot(NormalizeAlpha(tex2D(ReShade::BackBuffer, offset[2].xy)), weights);
		float Ltoptop = dot(NormalizeAlpha(tex2D(ReShade::BackBuffer, offset[2].zw)), weights);
	
		delta.zw = abs(float2(Lleft, Ltop) - float2(Lleftleft, Ltoptop));

		maxDelta = max(maxDelta.xy, delta.zw);
		float finalDelta = max(maxDelta.x, maxDelta.y);

		edges.xy *= step(finalDelta, clamp(1.0 + log10(scale), 1.0, 8.0) * delta.xy);
	}
	
	// pass packed result (edges + hysteresis data)
	return float4(edges, hysteresisdata);
}

float4 HQAABlendingWeightCalculationPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float2 pixcoord : TEXCOORD1, float4 offset[3] : TEXCOORD2) : SV_Target
{
    float4 weights = float(0.0).xxxx;
    float2 e = tex2D(HQAAsamplerAlphaEdges, texcoord).rg;
    bool2 edges = bool2(e.r > 0.0, e.g > 0.0);
	
	[branch] if (edges.g) 
	{
        float3 coords = float3(HQAASearchXLeft(HQAAsamplerAlphaEdges, HQAAsamplerSMsearch, offset[0].xy, offset[2].x), offset[1].y, HQAASearchXRight(HQAAsamplerAlphaEdges, HQAAsamplerSMsearch, offset[0].zw, offset[2].y));
        float e1 = __SMAASampleLevelZero(HQAAsamplerAlphaEdges, coords.xy).r;
		float2 d = coords.xz;
        d = abs(round(mad(__SMAA_RT_METRICS.zz, d, -pixcoord.xx)));
        float e2 = __SMAASampleLevelZeroOffset(HQAAsamplerAlphaEdges, coords.zy, int2(1, 0)).r;
        weights.rg = HQAAArea(HQAAsamplerSMarea, sqrt(d), e1, e2, 0.0);
        coords.y = texcoord.y;
        HQAADetectHorizontalCornerPattern(HQAAsamplerAlphaEdges, weights.rg, coords.xyzy, d);
    }
	
	[branch] if (edges.r) 
	{
        float3 coords = float3(offset[0].x, HQAASearchYUp(HQAAsamplerAlphaEdges, HQAAsamplerSMsearch, offset[1].xy, offset[2].z), HQAASearchYDown(HQAAsamplerAlphaEdges, HQAAsamplerSMsearch, offset[1].zw, offset[2].w));
        float e1 = __SMAASampleLevelZero(HQAAsamplerAlphaEdges, coords.xy).g;
		float2 d = coords.yz;
        d = abs(round(mad(__SMAA_RT_METRICS.ww, d, -pixcoord.yy)));
        float e2 = __SMAASampleLevelZeroOffset(HQAAsamplerAlphaEdges, coords.xz, int2(0, 1)).g;
        weights.ba = HQAAArea(HQAAsamplerSMarea, sqrt(d), e1, e2, 0.0);
        coords.x = texcoord.x;
        HQAADetectVerticalCornerPattern(HQAAsamplerAlphaEdges, weights.ba, coords.xyxz, d);
    }

    return weights;
}

float4 HQAANeighborhoodBlendingPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float4 offset : TEXCOORD1) : SV_Target
{
    float4 m = float4(tex2D(HQAAsamplerSMweights, offset.xy).a, tex2D(HQAAsamplerSMweights, offset.zw).g, tex2D(HQAAsamplerSMweights, texcoord).zx);
	float4 resultAA = __SMAASampleLevelZero(HQAAsamplerBufferSRGB, texcoord);
	bool modifypixel = any(m);
	
	[branch] if (modifypixel)
	{
        bool horiz = max(m.x, m.z) > max(m.y, m.w);
        float4 blendingOffset = float4(0.0, m.y, 0.0, m.w);
        float2 blendingWeight = m.yw;
        HQAAMovc(bool(horiz).xxxx, blendingOffset, float4(m.x, 0.0, m.z, 0.0));
        HQAAMovc(bool(horiz).xx, blendingWeight, m.xz);
        blendingWeight /= dot(blendingWeight, float(1.0).xx);
        float4 blendingCoord = mad(blendingOffset, float4(__SMAA_RT_METRICS.xy, -__SMAA_RT_METRICS.xy), texcoord.xyxy);
        resultAA = blendingWeight.x * __SMAASampleLevelZero(HQAAsamplerBufferSRGB, blendingCoord.xy);
        resultAA += blendingWeight.y * __SMAASampleLevelZero(HQAAsamplerBufferSRGB, blendingCoord.zw);
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
    float4 rgbyM = tex2D(ReShade::BackBuffer, texcoord);
    float basethreshold = __FXAA_EDGE_THRESHOLD;
    float maximumreduction = __HQAA_DYNAMIC_RANGE;
	
	// calculate the threshold
#if HQAA_SCREENSHOT_MODE
	float fxaaQualityEdgeThreshold = 0.0;
#elif HQAA_ENABLE_HDR_OUTPUT
	float fxaaQualityEdgeThreshold = basethreshold * log2(HdrNits);
#else
	float adjustmentrange = maximumreduction * basethreshold;
	float fxaaQualityEdgeThreshold = basethreshold + mad(pow(abs((dotgamma(rgbyM) + rgbyM.a) / 2.0), 1.0 + maximumreduction), adjustmentrange, -adjustmentrange);
#endif //HQAA_SCREENSHOT_MODE

	
	float lumaMa = dotgamma(rgbyM);
	
    float lumaS = dotgamma(FxaaTex2DOffset(ReShade::BackBuffer, texcoord, int2( 0, 1)));
    float lumaE = dotgamma(FxaaTex2DOffset(ReShade::BackBuffer, texcoord, int2( 1, 0)));
    float lumaN = dotgamma(FxaaTex2DOffset(ReShade::BackBuffer, texcoord, int2( 0,-1)));
    float lumaW = dotgamma(FxaaTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, 0)));
	
    float rangeMax = max5(lumaS, lumaE, lumaN, lumaW, lumaMa);
    float rangeMin = min5(lumaS, lumaE, lumaN, lumaW, lumaMa);
	
    float range = rangeMax - rangeMin;
    
	// early exit check
    bool earlyExit = range < fxaaQualityEdgeThreshold;
	if (earlyExit)
#if HQAA_COMPILE_DEBUG_CODE
		if (clamp(debugmode, 3, 5) == debugmode) return float(0.0).xxx;
		else
#endif //HQAA_COMPILE_DEBUG_CODE
		return rgbyM.rgb;
	
    float lumaNW = dotgamma(FxaaTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1,-1)));
    float lumaSE = dotgamma(FxaaTex2DOffset(ReShade::BackBuffer, texcoord, int2( 1, 1)));
    float lumaNE = dotgamma(FxaaTex2DOffset(ReShade::BackBuffer, texcoord, int2( 1,-1)));
    float lumaSW = dotgamma(FxaaTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, 1)));
	
    float edgeHorz = abs(mad(-2.0, lumaW, lumaNW + lumaSW)) + mad(2.0, abs(mad(-2.0, lumaMa, lumaN + lumaS)), abs(mad(-2.0, lumaE, lumaNE + lumaSE)));
    float edgeVert = abs(mad(-2.0, lumaS, lumaSW + lumaSE)) + mad(2.0, abs(mad(-2.0, lumaMa, lumaW + lumaE)), abs(mad(-2.0, lumaN, lumaNW + lumaNE)));
	
    float lengthSign = BUFFER_RCP_WIDTH;
    bool horzSpan = edgeHorz >= edgeVert;
    if(!horzSpan) {
		lumaN = lumaW;
		lumaS = lumaE;
	}
    else lengthSign = BUFFER_RCP_HEIGHT;
	
    float gradientN = lumaN - lumaMa;
    float gradientS = lumaS - lumaMa;
    float lumaNN = lumaN + lumaMa;
	
    if (abs(gradientN) >= abs(gradientS)) lengthSign = -lengthSign;
    else lumaNN = lumaS + lumaMa;
	
    float2 posB = texcoord;
    float2 offNP;
	float texelsize = __HQAA_FXAA_SCAN_GRANULARITY;
	
	if (horzSpan) offNP = float2(BUFFER_RCP_WIDTH * texelsize, 0.0);
	else offNP = float2(0.0, BUFFER_RCP_HEIGHT * texelsize);
	
    if(!horzSpan) posB.x += lengthSign / 2.0;
    else posB.y += lengthSign / 2.0;
	
    float2 posN = posB - offNP;
    float2 posP = posB + offNP;
    
    float lumaEndN = dotgamma(FxaaTex2D(ReShade::BackBuffer, posN));
    float lumaEndP = dotgamma(FxaaTex2D(ReShade::BackBuffer, posP));
	
    float gradientScaled = max(abs(gradientN), abs(gradientS)) * 0.25;
    bool lumaMLTZero = mad(0.5, -lumaNN, lumaMa) < 0.0;
	
	lumaNN *= 0.5;
	
    lumaEndN -= lumaNN;
    lumaEndP -= lumaNN;
	
    bool doneN = abs(lumaEndN) >= gradientScaled;
    bool doneP = abs(lumaEndP) >= gradientScaled;
    bool doneNP;
	
	uint iterations = 0;
	uint maxiterations = trunc(max(__FXAA_DEFAULT_SEARCH_STEPS * __HQAA_FXAA_SCAN_MULTIPLIER, __FXAA_MINIMUM_SEARCH_STEPS));
	
#if HQAA_ENABLE_FPS_TARGET
	if (frametime > __HQAA_DESIRED_FRAMETIME) maxiterations = trunc(max(__FXAA_MINIMUM_SEARCH_STEPS, __HQAA_FPS_CLAMP_MULTIPLIER * maxiterations));
#endif
	
	[loop] while (iterations < maxiterations)
	{
		doneNP = doneN && doneP;
		if (doneNP) break;
		if (!doneN)
		{
			posN -= offNP;
			lumaEndN = dotgamma(FxaaTex2D(ReShade::BackBuffer, posN));
			lumaEndN -= lumaNN;
			doneN = abs(lumaEndN) >= gradientScaled;
		}
		if (!doneP)
		{
			posP += offNP;
			lumaEndP = dotgamma(FxaaTex2D(ReShade::BackBuffer, posP));
			lumaEndP -= lumaNN;
			doneP = abs(lumaEndP) >= gradientScaled;
		}
		iterations++;
    }
	
	float dstN, dstP;
	if (horzSpan)
	{
		dstN = texcoord.x - posN.x;
		dstP = posP.x - texcoord.x;
	}
	else 
	{
		dstN = texcoord.y - posN.y;
		dstP = posP.y - texcoord.y;
	}
	
    bool goodSpan = (dstN < dstP) ? ((lumaEndN < 0.0) != lumaMLTZero) : ((lumaEndP < 0.0) != lumaMLTZero);
    float pixelOffset = mad(-rcp(dstP + dstN), min(dstN, dstP), 0.5);
	float subpixOut = pixelOffset;
	
	// calculating subpix quality is only necessary with a failed span
	[branch] if (!goodSpan) {
		float fxaaQualitySubpix = __HQAA_SUBPIX * texelsize;
		subpixOut = mad(2.0, lumaS + lumaE + lumaN + lumaW, lumaNW + lumaSE + lumaNE + lumaSW); // A
		subpixOut = saturate(abs(mad((1.0/12.0), subpixOut, -lumaMa)) * rcp(range)); // BC
		subpixOut = mad(-2.0, subpixOut, 3.0) * (subpixOut * subpixOut); // DEF
		subpixOut = (subpixOut * subpixOut) * fxaaQualitySubpix; // GH
		subpixOut *= pixelOffset;
    }

    float2 posM = texcoord;
    if(!horzSpan) posM.x += lengthSign * subpixOut;
    else posM.y += lengthSign * subpixOut;
    
	// Establish result
	float3 resultAA = FxaaTex2D(ReShade::BackBuffer, posM).rgb;
	
	// output selection
#if HQAA_COMPILE_DEBUG_CODE
	if (clamp(debugmode, 4, 5) != debugmode)
	{
#endif //HQAA_COMPILE_DEBUG_CODE
	// normal output (valid for debug 5, its check happens with early-exit path)
	return resultAA;
#if HQAA_COMPILE_DEBUG_CODE
	}
	else if (debugmode == 4) {
		// luminance output
		return float(lumaMa).xxx;
	}
	else {
		// metrics output
		float runtime = float(iterations / maxiterations) * 0.5;
		float3 FxaaMetrics = float3(runtime, 0.5 - runtime, 0.0);
		return FxaaMetrics;
	}
#endif //HQAA_COMPILE_DEBUG_CODE
}

/***************************************************************************************************************************************/
/********************************************************** FXAA SHADER CODE END *******************************************************/
/***************************************************************************************************************************************/

/***************************************************************************************************************************************/
/****************************************************** HYSTERESIS SHADER CODE START ***************************************************/
/***************************************************************************************************************************************/

float3 HQAAHysteresisPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 pixel = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float4 edgedata = tex2D(HQAAsamplerAlphaEdges, texcoord);
	
#if HQAA_COMPILE_DEBUG_CODE
	bool modifiedpixel = any(edgedata.rg);
	if (debugmode != 0 && !modifiedpixel) return float(0.0).xxx;
	if (debugmode == 1) return float3(tex2D(HQAAsamplerAlphaEdges, texcoord).rg, 0.0);
	if (debugmode == 2) return tex2D(HQAAsamplerSMweights, texcoord).rgb;
	if (debugmode == 6) { float presatlevel = tex2D(HQAAsamplerAlphaEdges, texcoord).a; return float3((1.0 - presatlevel) / 2.0, presatlevel / 2.0, 0.0); }
	if (debugmode == 7) { float prelumalevel = tex2D(HQAAsamplerAlphaEdges, texcoord).b; return float(prelumalevel).xxx; }
	float3 postAAdot = pixel;
	if (debugmode == 0) {
#endif

	float channelstep = __HQAA_SMALLEST_COLOR_STEP;
	float multiplier = HqaaHysteresisStrength / 100.0;
	
	float hysteresis = (dotgamma(pixel) - edgedata.b) * multiplier;
	bool runcorrection = abs(hysteresis) > channelstep;
	[branch] if (runcorrection)
	{
#if HQAA_ENABLE_HDR_OUTPUT
		hysteresis *= rcp(HdrNits);
#endif //HQAA_ENABLE_HDR_OUTPUT
	
		// perform weighting using computed hysteresis
		pixel = pow(abs(1.0 + hysteresis) * 2.0, log2(pixel));
	}
	
	float sathysteresis = (dotsat(pixel) - edgedata.a) * multiplier;
	runcorrection = abs(sathysteresis) > channelstep;
	[branch] if (runcorrection)
	{
#if HQAA_ENABLE_HDR_OUTPUT
		sathysteresis *= rcp(HdrNits);
#endif //HQAA_ENABLE_HDR_OUTPUT
	
		// perform weighting using computed hysteresis
		pixel = AdjustSaturation(pixel, -sathysteresis);
	}
	
	//output
#if HQAA_COMPILE_DEBUG_CODE
	}
	if (debugmode < 8)
	{
#endif //HQAA_COMPILE_DEBUG_CODE
	return pixel;
#if HQAA_COMPILE_DEBUG_CODE
	}
	else if (debugmode == 8) {
		// postAA saturation
		float postAAsat = dotsat(postAAdot);
		return float3((1.0 - postAAsat) / 2.0, postAAsat / 2.0, 0.0);
	}
	else if (debugmode == 9) {
		// postAA luma
		float postAAluma = dotgamma(postAAdot);
		return float(postAAluma).xxx;
	}
	else if (debugmode == 10) {
		// final saturation
		float finalsat = dotsat(pixel);
		return float3((1.0 - finalsat) / 2.0, finalsat / 2.0, 0.0);
	}
	else {
		// final luma
		float finalluma = dotgamma(pixel);
		return float(finalluma).xxx;
	}
#endif //HQAA_COMPILE_DEBUG_CODE
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
    float3 ori = tex2Dlod(ReShade::BackBuffer, texcoord.xyxy).rgb; // Original pixel
#if HQAA_COMPILE_DEBUG_CODE
	if (debugmode == 0) {
#endif
    // Settings
    float avgdiff[3] = {0.002353, 0.007059, 0.013333}; // 0.6/255, 1.8/255, 3.4/255
    float maxdiff[3] = {0.007451, 0.015686, 0.026667}; // 1.9/255, 4.0/255, 6.8/255
    float middiff[3] = {0.004706, 0.007843, 0.012941}; // 1.2/255, 2.0/255, 3.3/255

    // Initialize the PRNG
    float randomseed = drandom / 32767.0;
    float h = permute(float2(permute(float2(texcoord.x, randomseed)), permute(float2(texcoord.y, randomseed))));

    // Compute a random angle
    float dir = frac(permute(h) / 41.0) * 6.2831853;
    float2 angle = float2(cos(dir), sin(dir));

    // Compute a random distance
    float2 dist = frac(h / 41.0) * HqaaDebandRange * BUFFER_PIXEL_SIZE;

    // Sample at quarter-turn intervals around the source pixel

    // South-east
    float3 ref = tex2Dlod(ReShade::BackBuffer, float2(texcoord + dist * angle).xyxy).rgb;
    float3 diff = abs(ori - ref);
    float3 ref_max_diff = diff;
    float3 ref_avg = ref;
    float3 ref_mid_diff1 = ref;

    // North-west
    ref = tex2Dlod(ReShade::BackBuffer, float2(texcoord + dist * -angle).xyxy).rgb;
    diff = abs(ori - ref);
    ref_max_diff = max(ref_max_diff, diff);
    ref_avg += ref;
    ref_mid_diff1 = abs(((ref_mid_diff1 + ref) * 0.5) - ori);

    // North-east
    ref = tex2Dlod(ReShade::BackBuffer, float2(texcoord + dist * float2(-angle.y, angle.x)).xyxy).rgb;
    diff = abs(ori - ref);
    ref_max_diff = max(ref_max_diff, diff);
    ref_avg += ref;
    float3 ref_mid_diff2 = ref;

    // South-west
    ref = tex2Dlod(ReShade::BackBuffer, float2(texcoord + dist * float2(angle.y, -angle.x)).xyxy).rgb;
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

    return lerp(ori, ref_avg, factor);
#if HQAA_COMPILE_DEBUG_CODE
	}
	else return ori;
#endif
}
#endif //HQAA_OPTIONAL_DEBAND

#if (HQAA_OPTIONAL_CAS || HQAA_OPTIONAL_BRIGHTNESS_GAIN || HQAA_OPTIONAL_TEMPORAL_STABILIZER)
// Optional effects main pass. These are sorted in an order that they won't
// interfere with each other when they're all enabled
float3 HQAAOptionalEffectPassPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 pixel = tex2D(ReShade::BackBuffer, texcoord).rgb;
	
#if HQAA_COMPILE_DEBUG_CODE
	if (debugmode == 0) {
#endif
	
#if HQAA_OPTIONAL_CAS
	float3 casdot = pixel;
	
	float sharpening = HqaaSharpenerStrength;
	
	if (any(tex2D(HQAAsamplerAlphaEdges, texcoord).rg))
		sharpening *= (1.0 - HqaaSharpenerClamping);
	
    float3 a = tex2Doffset(ReShade::BackBuffer, texcoord, int2(-1, -1)).rgb;
    float3 c = tex2Doffset(ReShade::BackBuffer, texcoord, int2(1, -1)).rgb;
    float3 g = tex2Doffset(ReShade::BackBuffer, texcoord, int2(-1, 1)).rgb;
    float3 i = tex2Doffset(ReShade::BackBuffer, texcoord, int2(1, 1)).rgb;
    float3 b = tex2Doffset(ReShade::BackBuffer, texcoord, int2(0, -1)).rgb;
    float3 d = tex2Doffset(ReShade::BackBuffer, texcoord, int2(-1, 0)).rgb;
    float3 f = tex2Doffset(ReShade::BackBuffer, texcoord, int2(1, 0)).rgb;
    float3 h = tex2Doffset(ReShade::BackBuffer, texcoord, int2(0, 1)).rgb;
	
	float3 mnRGB = min5(d, casdot, f, b, h);
	float3 mnRGB2 = min5(mnRGB, a, c, g, i);
    mnRGB += mnRGB2;

	float3 mxRGB = max5(d, casdot, f, b, h);
	float3 mxRGB2 = max5(mxRGB,a,c,g,i);
    mxRGB += mxRGB2;
	
#if HQAA_ENABLE_HDR_OUTPUT
	mnRGB *= (1.0 / HdrNits);
	mxRGB *= (1.0 / HdrNits);
	casdot *= (1.0 / HdrNits);
#endif //HQAA_ENABLE_HDR_OUTPUT

    float3 ampRGB = rsqrt(saturate(min(mnRGB, 2.0 - mxRGB) * rcp(mxRGB)));    
    float3 wRGB = -rcp(ampRGB * 8.0);
    float3 window = (b + d) + (f + h);
	
#if HQAA_ENABLE_HDR_OUTPUT
	window *= (1.0 / HdrNits);
#endif //HQAA_ENABLE_HDR_OUTPUT
	
    float3 outColor = saturate(mad(window, wRGB, casdot) * rcp(mad(4.0, wRGB, 1.0)));
	casdot = lerp(casdot, outColor, sharpening);
#if HQAA_ENABLE_HDR_OUTPUT
	 casdot *= HdrNits;
#endif //HQAA_ENABLE_HDR_OUTPUT
	pixel = casdot;
#endif //HQAA_OPTIONAL_CAS

#if HQAA_OPTIONAL_BRIGHTNESS_GAIN
	bool applygain = HqaaGainStrength > 0.0;
	[branch] if (applygain)
	{
		float3 outdot = pixel;
#if HQAA_ENABLE_HDR_OUTPUT
		outdot *= (1.0 / HdrNits);
#endif //HQAA_ENABLE_HDR_OUTPUT
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
			float contrastgain = log(rcp(dotgamma(outdot) - channelfloor)) * pow(__CONST_E, (1.0 + channelfloor) * __CONST_E) * HqaaGainStrength;
			outdot = pow(abs(10.0 + contrastgain * (1.0 + HqaaGainStrength)), log10(outdot));
			float newsat = dotsat(outdot);
			float satadjust = newsat - presaturation; // compute difference in before/after saturation
			bool adjustsat = abs(satadjust) > channelfloor;
			if (adjustsat) outdot = AdjustSaturation(outdot, satadjust);
		}
#if HQAA_ENABLE_HDR_OUTPUT
		outdot *= HdrNits;
#else
		outdot = saturate(outdot);
#endif //HQAA_ENABLE_HDR_OUTPUT
		pixel = outdot;
	}
#endif //HQAA_OPTIONAL_BRIGHTNESS_GAIN

#if HQAA_OPTIONAL_TEMPORAL_STABILIZER
	float3 current = pixel;
	float3 previous = tex2D(HQAAsamplerLastFrame, texcoord).rgb;
	
	// values above 0.9 can produce artifacts or halt frame advancement entirely
	float blendweight = min(HqaaPreviousFrameWeight, 0.9);
	
	if (ClampMaximumWeight) {
		float contrastdelta = sqrt(dotgamma(abs(current - previous)));
		blendweight = min(contrastdelta, blendweight);
	}
	
	pixel = lerp(current, previous, blendweight);
#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER

#if HQAA_COMPILE_DEBUG_CODE
	}
#endif
	
	return pixel;
}
#endif //(HQAA_OPTIONAL_CAS || HQAA_OPTIONAL_BRIGHTNESS_GAIN || HQAA_OPTIONAL_TEMPORAL_STABILIZER)

#if HQAA_OPTIONAL_TEMPORAL_STABILIZER
// optional stabilizer - save previous frame
float4 GenerateImageCopyPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return tex2D(ReShade::BackBuffer, texcoord);
}
#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER
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
#if !HQAA_ENABLE_HDR_OUTPUT
		SRGBWriteEnable = true;
#endif //HQAA_ENABLE_HDR_OUTPUT
	}
	pass FXAA
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAFXPS;
	}
#if !HQAA_SCREENSHOT_MODE
	pass Hysteresis
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAHysteresisPS;
	}
#endif
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
		PixelShader = GenerateImageCopyPS;
		RenderTarget = HQAAstabilizerTex;
		ClearRenderTargets = true;
	}
#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER
#endif //HQAA_ENABLE_OPTIONAL_TECHNIQUES
}
