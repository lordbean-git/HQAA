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
 *                        v18.0b
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
	#define HQAA_COMPILE_DEBUG_CODE 1
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
	#endif //HQAA_OPTIONAL_DEBAND
#endif // HQAA_ENABLE_OPTIONAL_TECHNIQUES

#ifndef HQAA_SCREENSHOT_MODE
	#define HQAA_SCREENSHOT_MODE 0
#endif //HQAA_SCREENSHOT_MODE

uniform int HQAAintroduction <
	ui_type = "radio";
	ui_label = "Version: 18.0b";
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
			  "-------------------------------------------------------------------------\n";
>;

uniform int preset <
	ui_type = "combo";
	ui_label = "Quality Preset\n\n";
	ui_tooltip = "For quick start use, pick a preset. If you'd prefer to fine tune, select Custom.";
	ui_category = "Presets";
	ui_items = "Potato\0Low\0Medium\0High\0Ultra\0GLaDOS\0Custom\0";
	ui_text = "\n";
> = 3;

uniform float EdgeThresholdCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Edge Detection Threshold";
	ui_tooltip = "Local contrast (luma difference) required to be considered an edge";
    ui_category = "Custom Preset";
	ui_category_closed = true;
	ui_text = "\n------------------------------ Global Options ----------------------------------\n ";
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
	ui_label = "Subpixel Effect Strength";
	ui_tooltip = "Percentage of blending FXAA will apply to long slopes.\n"
				 "Lower = sharper image, Higher = more AA effect";
    ui_category = "Custom Preset";
	ui_category_closed = true;
> = 50;

static const float HQAA_THRESHOLD_PRESET[7] = {0.2, 0.18, 0.16, 0.14, 0.12, 0.1, 1.0};
static const float HQAA_DYNAMIC_RANGE_PRESET[7] = {0.25, 0.333333, 0.5, 0.666667, 0.75, 0.833333, 0.0};
static const float HQAA_SMAA_CORNER_ROUNDING_PRESET[7] = {0.0, 0.1, 0.15, 0.25, 0.5, 1.0, 0.0};
static const float HQAA_FXAA_SCANNING_MULTIPLIER_PRESET[7] = {0.25, 0.375, 0.75, 1.0, 1.25, 2.5, 0.0};
static const float HQAA_FXAA_TEXEL_SIZE_PRESET[7] = {2.0, 2.0, 1.5, 1.0, 1.0, 0.5, 4.0};
static const float HQAA_SUBPIX_PRESET[7] = {0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 0.0};

uniform int presetbreakdown <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n"
			  "------------------------------------------------------------------\n"
			  "|        |       Global      |  SMAA  |           FXAA           |\n"
	          "|--Preset|-Threshold---Range-|-Corner-|-Quality---Texel---Subpix-|\n"
	          "|--------|-----------|-------|--------|---------|-------|--------|\n"
	          "|  Potato|   0.200   | 25.0% |    0%  |  0.250  |  2.0  |   0.0% |\n"
			  "|     Low|   0.180   | 33.3% |   10%  |  0.375  |  2.0  |  20.0% |\n"
			  "|  Medium|   0.160   | 50.0% |   15%  |  0.750  |  1.5  |  40.0% |\n"
			  "|    High|   0.140   | 66.6% |   25%  |  1.000  |  1.0  |  60.0% |\n"
			  "|   Ultra|   0.120   | 75.0% |   50%  |  1.250  |  1.0  |  80.0% |\n"
			  "|  GLaDOS|   0.100   | 83.3% |  100%  |  2.500  |  0.5  | 100.0% |\n"
			  "------------------------------------------------------------------";
	ui_category = "Click me to see what settings each preset uses!";
	ui_category_closed = true;
>;

#if HQAA_COMPILE_DEBUG_CODE
uniform uint debugmode <
	ui_type = "radio";
	ui_category = "Debug";
	ui_category_closed = true;
	ui_label = " ";
	ui_spacing = 1;
	ui_text = "Debug Mode:";
	ui_items = "Off\0Detected Edges\0SMAA Blend Weights\0Computed Saturation Hysteresis\0Computed Luma Hysteresis\0FXAA Results\0FXAA Lumas\0FXAA Metrics\0FXAA Luma Hysteresis\0FXAA Saturation Hysteresis\0";
> = 0;

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
			  "Saturation Hysteresis values are calculated sat levels before\n"
			  "any anti-aliasing is applied and used by FXAA to adjust its\n"
			  "output to reduce aggressiveness of artifacts.\n\n"
			  "Luma Hysteresis values are calculated pixel lumas before\n"
			  "any anti-aliasing is applied and used by FXAA to adjust its\n"
			  "output to reduce aggressiveness of artifacts.\n\n"
			  "FXAA Hysteresis displays the result of the FXAA hysteresis\n"
			  "calculation with blue pixels representing results that were\n"
			  "computed to be valid without adjustment, green pixels\n"
			  "representing results that were computed to require brightening,\n"
			  "and red pixels representing results that were computed to\n"
			  "require darkening.\n\n"
			  "Debug checks can optionally be excluded from the compiled shader\n"
			  "by setting HQAA_COMPILE_DEBUG_CODE to 0.\n"
	          "----------------------------------------------------------------";
	ui_category = "DEBUG README";
	ui_category_closed = true;
>;
#endif //HQAA_COMPILE_DEBUG_CODE

#if (HQAA_ENABLE_FPS_TARGET || HQAA_ENABLE_HDR_OUTPUT)
uniform int extradivider <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n-------------------------------------------------------------------------";
>;
#endif //(HQAA_ENABLE_FPS_TARGET || HQAA_ENABLE_HDR_OUTPUT)

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
	ui_label = "Debanding Strength";
	ui_category = "Debanding";
	ui_category_closed = true;
> = 0;

uniform int debandintro <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\nWhen enabled, performs a fast debanding pass very similar to\n"
			  "Deband.fx to reduce color banding in the scene.";
	ui_category = "Debanding";
	ui_category_closed = true;
>;

uniform int drandom < source = "random"; min = 0; max = 32767; >;
static const float HQAA_DEBAND_AVGDIFF_PRESET[3] = {0.005000, 0.010000, 0.020000};
static const float HQAA_DEBAND_MAXDIFF_PRESET[3] = {0.010000, 0.022000, 0.050000};
static const float HQAA_DEBAND_MIDDIFF_PRESET[3] = {0.004000, 0.010000, 0.022000};
#endif //HQAA_OPTIONAL_DEBAND

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

#define __HQAA_EDGE_THRESHOLD (preset == 6 ? (EdgeThresholdCustom) : (HQAA_THRESHOLD_PRESET[preset]))
#define __HQAA_DYNAMIC_RANGE (preset == 6 ? (DynamicThresholdCustom / 100.0) : HQAA_DYNAMIC_RANGE_PRESET[preset])
#define __HQAA_SMAA_CORNERING (preset == 6 ? (SmaaCorneringCustom / 100.0) : (HQAA_SMAA_CORNER_ROUNDING_PRESET[preset]))
#define __HQAA_FXAA_SCAN_MULTIPLIER (preset == 6 ? (FxaaIterationsCustom) : (HQAA_FXAA_SCANNING_MULTIPLIER_PRESET[preset]))
#define __HQAA_FXAA_SCAN_GRANULARITY (preset == 6 ? (FxaaTexelSizeCustom) : (HQAA_FXAA_TEXEL_SIZE_PRESET[preset]))
#define __HQAA_SUBPIX (preset == 6 ? (SubpixCustom / 100.0) : (HQAA_SUBPIX_PRESET[preset]))

#define __HQAA_DISPLAY_NUMERATOR max(BUFFER_HEIGHT, BUFFER_WIDTH)
#define __HQAA_SMALLEST_COLOR_STEP rcp(pow(2, BUFFER_COLOR_BIT_DEPTH))
#define __HQAA_LUMA_REF float4(0.25,0.25,0.25,0.25)
#define __HQAA_GAMMA_REF float3(0.333333,0.333334,0.333333)

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
#define __SMAASampleLevelZero(tex, coord) tex2Dlod(tex, float4(coord, coord))
#define __SMAASampleLevelZeroOffset(tex, coord, offset) tex2Dlodoffset(tex, float4(coord, coord), offset)
#define __SMAA_AREATEX_MAX_DISTANCE 16
#define __SMAA_AREATEX_MAX_DISTANCE_DIAG 20
#define __SMAA_AREATEX_PIXEL_SIZE (1.0 / float2(160.0, 560.0))
#define __SMAA_AREATEX_SUBTEX_SIZE (1.0/ 7.0)
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
#define dotsat(x) (dotgamma(x) == 1.0 ? 0.0 : ((max3(x.r, x.g, x.b) - min3(x.r, x.g, x.b)) / (1.0 - (2.0 * dotgamma(x) - 1.0))))

#define FxaaTex2D(t, p) tex2Dlod(t, float4(p, p))
#define FxaaTex2DOffset(t, p, o) tex2Dlod(t, float4(p.xyxy + o.xyxy * __SMAA_RT_METRICS.xyxy))

#define __CONST_E 2.718282

/*****************************************************************************************************************************************/
/********************************************************* SYNTAX SETUP END **************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/******************************************************** SUPPORT CODE START *************************************************************/
/*****************************************************************************************************************************************/

// Saturation adjuster
float3 AdjustSaturation(float3 pixel, float satadjust)
{
	float3 outdot = pixel;
	float2 highlow = float2(max3(outdot.r, outdot.g, outdot.b), min3(outdot.r, outdot.g, outdot.b));
	if (outdot.r == highlow.x) outdot.r = pow(abs(2.0 - satadjust), log2(outdot.r));
	else if (outdot.r == highlow.y) outdot.r = pow(abs(2.0 + satadjust), log2(outdot.r));
	if (outdot.g == highlow.x) outdot.g = pow(abs(2.0 - satadjust), log2(outdot.g));
	else if (outdot.g == highlow.y) outdot.g = pow(abs(2.0 + satadjust), log2(outdot.g));
	if (outdot.b == highlow.x) outdot.b = pow(abs(2.0 - satadjust), log2(outdot.b));
	else if (outdot.b == highlow.y) outdot.b = pow(abs(2.0 + satadjust), log2(outdot.b));
	float midadjust = dotgamma(outdot) - dotgamma(pixel);
	if (pixel.r == outdot.r) outdot.r += midadjust;
	else if (pixel.g == outdot.g) outdot.g += midadjust;
	else outdot.b += midadjust;
	return outdot;
}
float4 AdjustSaturation(float4 pixel, float satadjust)
{
	return float4(AdjustSaturation(pixel.rgb, satadjust), pixel.a);
}

// Alpha channel normalizer
float4 NormalizeAlpha(float4 pixel)
{
#if HQAA_ENABLE_HDR_OUTPUT
	float rgbluma = dotluma(pixel);
#else
	float rgbluma = dotgamma(pixel);
#endif //HQAA_ENABLE_HDR_OUTPUT
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
    [loop] while (coord.z < 20.0 &&
           coord.w > 0.9) {
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);
        e = __SMAASampleLevelZero(HQAAedgesTex, coord.xy).rg;
        coord.w = dot(e, float2(0.5, 0.5));
    }
    return coord.zw;
}

float2 HQAASearchDiag2(sampler2D HQAAedgesTex, float2 texcoord, float2 dir, out float2 e)
{
    float4 coord = float4(texcoord, -1.0, 1.0);
    coord.x += 0.25 * __SMAA_RT_METRICS.x;
    float3 t = float3(__SMAA_RT_METRICS.xy, 1.0);
    [loop] while (coord.z < 20.0 &&
           coord.w > 0.9) {
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);

        e = __SMAASampleLevelZero(HQAAedgesTex, coord.xy).rg;
        e = HQAADecodeDiagBilinearAccess(e);

        coord.w = dot(e, float2(0.5, 0.5));
    }
    return coord.zw;
}

float2 HQAAAreaDiag(sampler2D HQAAareaTex, float2 dist, float2 e, float offset) {
    float2 texcoord = mad(float2(__SMAA_AREATEX_MAX_DISTANCE_DIAG, __SMAA_AREATEX_MAX_DISTANCE_DIAG), e, dist);

    texcoord = mad(__SMAA_AREATEX_PIXEL_SIZE, texcoord, 0.5 * __SMAA_AREATEX_PIXEL_SIZE);
    texcoord.x += 0.5;
    texcoord.y += __SMAA_AREATEX_SUBTEX_SIZE * offset;

    return __SMAASampleLevelZero(HQAAareaTex, texcoord).rg;
}

float2 HQAACalculateDiagWeights(sampler2D HQAAedgesTex, sampler2D HQAAareaTex, float2 texcoord, float2 e, float4 subsampleIndices) {
    float2 weights = float2(0.0, 0.0);
    float2 end;
    float4 d;
    d.ywxz = float4(HQAASearchDiag1(HQAAedgesTex, texcoord, float2(1.0, -1.0), end), 0.0, 0.0);
    
    [branch]
    if (e.r > 0.0) {
        d.xz = HQAASearchDiag1(HQAAedgesTex, texcoord, float2(-1.0,  1.0), end);
        d.x += float(end.y > 0.9);
    }

	[branch]
    if (d.x + d.y > 2.0) {
        float4 coords = mad(float4(-d.x + 0.25, d.x, d.y, -d.y - 0.25), __SMAA_RT_METRICS.xyxy, texcoord.xyxy);
        float4 c;
        c.xy = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.xy, int2(-1,  0)).rg;
        c.zw = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.zw, int2( 1,  0)).rg;
        c.yxwz = HQAADecodeDiagBilinearAccess(c.xyzw);

        float2 cc = mad(float2(2.0, 2.0), c.xz, c.yw);

        HQAAMovc(bool2(step(0.9, d.zw)), cc, float2(0.0, 0.0));

        weights += HQAAAreaDiag(HQAAareaTex, d.xy, cc, subsampleIndices.z);
    }

    d.xz = HQAASearchDiag2(HQAAedgesTex, texcoord, float2(-1.0, -1.0), end);
    d.yw = float2(0.0, 0.0);
    
    [branch]
    if (__SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord, int2(1, 0)).r > 0.0) {
        d.yw = HQAASearchDiag2(HQAAedgesTex, texcoord, float2(1.0, 1.0), end);
        d.y += float(end.y > 0.9);
    }

	[branch]
    if (d.x + d.y > 2.0) {
        float4 coords = mad(float4(-d.x, -d.x, d.y, d.y), __SMAA_RT_METRICS.xyxy, texcoord.xyxy);
        float4 c;
        c.x  = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.xy, int2(-1,  0)).g;
        c.y  = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.xy, int2( 0, -1)).r;
        c.zw = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.zw, int2( 1,  0)).gr;
        float2 cc = mad(float2(2.0, 2.0), c.xz, c.yw);

        HQAAMovc(bool2(step(0.9, d.zw)), cc, float2(0.0, 0.0));

        weights += HQAAAreaDiag(HQAAareaTex, d.xy, cc, subsampleIndices.w).gr;
    }

    return weights;
}

// SMAA horizontal / vertical search functions
float HQAASearchLength(sampler2D HQAAsearchTex, float2 e, float offset) {
    float2 scale = __SMAA_SEARCHTEX_SIZE * float2(0.5, -1.0);
    float2 bias = __SMAA_SEARCHTEX_SIZE * float2(offset, 1.0);

    scale += float2(-1.0,  1.0);
    bias  += float2( 0.5, -0.5);

    scale *= 1.0 / __SMAA_SEARCHTEX_PACKED_SIZE;
    bias *= 1.0 / __SMAA_SEARCHTEX_PACKED_SIZE;

    return __SMAASampleLevelZero(HQAAsearchTex, mad(scale, e, bias)).r;
}

float HQAASearchXLeft(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end) {
    float2 e = float2(0.0, 1.0);
    [loop] while (texcoord.x > end) 
	{
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(-float2(2.0, 0.0), __SMAA_RT_METRICS.xy, texcoord);
        if (e.r > 0.0 || e.g == 0.0) break;
    }

    float offset = mad(-(255.0 / 127.0), HQAASearchLength(HQAAsearchTex, e, 0.0), 3.25);
    return mad(__SMAA_RT_METRICS.x, offset, texcoord.x);
}

float HQAASearchXRight(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end) {
    float2 e = float2(0.0, 1.0);
    [loop] while (texcoord.x < end) 
	{
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(float2(2.0, 0.0), __SMAA_RT_METRICS.xy, texcoord);
        if (e.r > 0.0 || e.g == 0.0) break;
    }
    float offset = mad(-(255.0 / 127.0), HQAASearchLength(HQAAsearchTex, e, 0.5), 3.25);
    return mad(-__SMAA_RT_METRICS.x, offset, texcoord.x);
}

float HQAASearchYUp(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end) {
    float2 e = float2(1.0, 0.0);
    [loop] while (texcoord.y > end) 
	{
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(-float2(0.0, 2.0), __SMAA_RT_METRICS.xy, texcoord);
        if (e.r == 0.0 || e.g > 0.0) break;
    }
    float offset = mad(-(255.0 / 127.0), HQAASearchLength(HQAAsearchTex, e.gr, 0.0), 3.25);
    return mad(__SMAA_RT_METRICS.y, offset, texcoord.y);
}

float HQAASearchYDown(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end) {
    float2 e = float2(1.0, 0.0);
    [loop] while (texcoord.y < end) 
	{
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(float2(0.0, 2.0), __SMAA_RT_METRICS.xy, texcoord);
        if (e.r == 0.0 || e.g > 0.0) break;
    }
    float offset = mad(-(255.0 / 127.0), HQAASearchLength(HQAAsearchTex, e.gr, 0.5), 3.25);
    return mad(-__SMAA_RT_METRICS.y, offset, texcoord.y);
}

float2 HQAAArea(sampler2D HQAAareaTex, float2 dist, float e1, float e2, float offset) {
    float2 texcoord = mad(float2(__SMAA_AREATEX_MAX_DISTANCE, __SMAA_AREATEX_MAX_DISTANCE), round(4.0 * float2(e1, e2)), dist);
    
    texcoord = mad(__SMAA_AREATEX_PIXEL_SIZE, texcoord, 0.5 * __SMAA_AREATEX_PIXEL_SIZE);
    texcoord.y = mad(__SMAA_AREATEX_SUBTEX_SIZE, offset, texcoord.y);

    return __SMAASampleLevelZero(HQAAareaTex, texcoord).rg;
}

// SMAA corner detection functions
void HQAADetectHorizontalCornerPattern(sampler2D HQAAedgesTex, inout float2 weights, float4 texcoord, float2 d) {
    float2 leftRight = step(d.xy, d.yx);
    float2 rounding = (1.0 - __HQAA_SMAA_CORNERING) * leftRight;

    float2 factor = float2(1.0, 1.0);
    factor.x -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2(0,  1)).r;
    factor.x -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2(1,  1)).r;
    factor.y -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2(0, -2)).r;
    factor.y -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2(1, -2)).r;

    weights *= saturate(factor);
}

void HQAADetectVerticalCornerPattern(sampler2D HQAAedgesTex, inout float2 weights, float4 texcoord, float2 d) {
    float2 leftRight = step(d.xy, d.yx);
    float2 rounding = (1.0 - __HQAA_SMAA_CORNERING) * leftRight;

    float2 factor = float2(1.0, 1.0);
    factor.x -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2( 1, 0)).g;
    factor.x -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2( 1, 1)).g;
    factor.y -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2(-2, 0)).g;
    factor.y -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2(-2, 1)).g;

    weights *= saturate(factor);
}

#if HQAA_ENABLE_OPTIONAL_TECHNIQUES
#if HQAA_OPTIONAL_DEBAND
float rand(float x)
{
    return frac(x / 41.0);
}

float permute(float x)
{
    return ((34.0 * x + 1.0) * x) % 289.0;
}

void analyze_pixels(float3 ori, float3 nw, float3 ne, float3 sw, float3 se, float2 dir, out float3 ref_avg, out float3 ref_avg_diff, out float3 ref_max_diff, out float3 ref_mid_diff1, out float3 ref_mid_diff2)
{
    float3 diff = abs(ori - se);
    ref_max_diff = diff;
    ref_avg = se;
    ref_mid_diff1 = se;

    diff = abs(ori - nw);
    ref_max_diff = max(ref_max_diff, diff);
    ref_avg += nw;
    ref_mid_diff1 = abs(((ref_mid_diff1 + nw) / 2.0) - ori);

    diff = abs(ori - ne);
    ref_max_diff = max(ref_max_diff, diff);
    ref_avg += ne;
    ref_mid_diff2 = ne;

    diff = abs(ori - sw);
    ref_max_diff = max(ref_max_diff, diff);
    ref_avg += sw;
    ref_mid_diff2 = abs(((ref_mid_diff2 + sw) / 2.0) - ori);

    ref_avg /= 4.0;
    ref_avg_diff = abs(ori - ref_avg);
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
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA8;
};

texture HQAAblendTex
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
                    float4(-2.0, 2.0, -2.0, 2.0) * searchrange,
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
	float2 hysteresisdata = float2(dotluma(middle), dotsat(middle));
	
	// Normalize the alpha channel
	middle = NormalizeAlpha(middle);
	
	// calculate the threshold
#if HQAA_SCREENSHOT_MODE
	float2 threshold = float2(0.0, 0.0);
#elif HQAA_ENABLE_HDR_OUTPUT
	float2 threshold = float(__SMAA_EDGE_THRESHOLD * log2(HdrNits)).xx;
#else
	float adjustmentrange = __HQAA_DYNAMIC_RANGE * __SMAA_EDGE_THRESHOLD;
	float thresholdOffset = mad((dotgamma(middle) + middle.a) / 2.0, adjustmentrange, -adjustmentrange);
	
	float2 threshold = float(__SMAA_EDGE_THRESHOLD + thresholdOffset).xx;
#endif //HQAA_SCREENSHOT_MODE
	
	// calculate color channel weighting
	float4 weights = float4(0.3, 0.3, 0.3, 0.1);
	weights *= middle;
	float scale = rcp(vec4add(weights));
	weights *= scale;
	
	float2 edges = float2(0.0, 0.0);
	
    float L = dot(middle, weights);

    float Lleft = dot(NormalizeAlpha(tex2D(ReShade::BackBuffer, offset[0].xy)), weights);
    float Ltop  = dot(NormalizeAlpha(tex2D(ReShade::BackBuffer, offset[0].zw)), weights);

    float4 delta = float4(abs(L - float2(Lleft, Ltop)), 0.0, 0.0);
    edges = step(threshold, delta.xy);
	
	[branch] if (edges.r != -edges.g)
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
    float4 weights = float4(0.0, 0.0, 0.0, 0.0);
    float2 e = tex2D(HQAAsamplerAlphaEdges, texcoord).rg;
	
	[branch] if (e.g > 0.0) 
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
	
	[branch] if (e.r > 0.0) 
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
	
	[branch] if (any(m))
	{
        bool horiz = max(m.x, m.z) > max(m.y, m.w);
        float4 blendingOffset = float4(0.0, m.y, 0.0, m.w);
        float2 blendingWeight = m.yw;
        HQAAMovc(bool4(horiz, horiz, horiz, horiz), blendingOffset, float4(m.x, 0.0, m.z, 0.0));
        HQAAMovc(bool2(horiz, horiz), blendingWeight, m.xz);
        blendingWeight /= dot(blendingWeight, float2(1.0, 1.0));
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

float4 HQAAHysteresisBlendingPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
 {
    float4 rgbyM = FxaaTex2D(ReShade::BackBuffer, texcoord);
	
	// calculate the threshold
#if HQAA_SCREENSHOT_MODE
	float fxaaQualityEdgeThreshold = 0.0;
#elif HQAA_ENABLE_HDR_OUTPUT
	float fxaaQualityEdgeThreshold = __FXAA_EDGE_THRESHOLD * log2(HdrNits);
#else
	float adjustmentrange = __HQAA_DYNAMIC_RANGE * __FXAA_EDGE_THRESHOLD;
	float fxaaQualityEdgeThreshold = __FXAA_EDGE_THRESHOLD + mad((dotgamma(rgbyM) + rgbyM.a) / 2.0, adjustmentrange, -adjustmentrange);
#endif //HQAA_SCREENSHOT_MODE

	
	float lumaMa = dotgamma(rgbyM);
	
    float lumaS = dotgamma(FxaaTex2DOffset(ReShade::BackBuffer, texcoord, int2( 0, 1)));
    float lumaE = dotgamma(FxaaTex2DOffset(ReShade::BackBuffer, texcoord, int2( 1, 0)));
    float lumaN = dotgamma(FxaaTex2DOffset(ReShade::BackBuffer, texcoord, int2( 0,-1)));
    float lumaW = dotgamma(FxaaTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, 0)));
    float lumaNW = dotgamma(FxaaTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1,-1)));
    float lumaSE = dotgamma(FxaaTex2DOffset(ReShade::BackBuffer, texcoord, int2( 1, 1)));
    float lumaNE = dotgamma(FxaaTex2DOffset(ReShade::BackBuffer, texcoord, int2( 1,-1)));
    float lumaSW = dotgamma(FxaaTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, 1)));
	
    float rangeMax = max9(lumaS, lumaE, lumaN, lumaW, lumaNW, lumaSE, lumaNE, lumaSW, lumaMa);
    float rangeMin = min9(lumaS, lumaE, lumaN, lumaW, lumaNW, lumaSE, lumaNE, lumaSW, lumaMa);
	
    float range = rangeMax - rangeMin;
	
	if (range < fxaaQualityEdgeThreshold)
#if HQAA_COMPILE_DEBUG_CODE
		if (debugmode > 4) return float4(0.0, 0.0, 0.0, 0.0);
		else
#endif //HQAA_COMPILE_DEBUG_CODE
		return rgbyM;
	
	float4 edgedata = tex2D(HQAAsamplerAlphaEdges, texcoord);
	
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
	
    offNP.x = (!horzSpan) ? 0.0 : BUFFER_RCP_WIDTH;
    offNP.y = ( horzSpan) ? 0.0 : BUFFER_RCP_HEIGHT;
	
    if(!horzSpan) posB.x = mad(0.5, lengthSign, posB.x);
    else posB.y = mad(0.5, lengthSign, posB.y);
	
    float2 posN = posB - offNP;
    float2 posP = posB + offNP;
    
    float lumaEndN = dotgamma(FxaaTex2D(ReShade::BackBuffer, posN));
    float lumaEndP = dotgamma(FxaaTex2D(ReShade::BackBuffer, posP));
	
    float gradientScaled = max(abs(gradientN), abs(gradientS)) * 1.0/4.0;
    bool lumaMLTZero = mad(0.5, -lumaNN, lumaMa) < 0.0;
	
	float2 granularity = float2(__HQAA_FXAA_SCAN_GRANULARITY, __HQAA_FXAA_SCAN_GRANULARITY);
	
    lumaEndN = mad(0.5, -lumaNN, lumaEndN);
    lumaEndP = mad(0.5, -lumaNN, lumaEndP);
	
    bool doneN = abs(lumaEndN) >= gradientScaled;
    bool doneP = abs(lumaEndP) >= gradientScaled;
    if(!doneN) posN = mad(granularity, -offNP, posN);
    if(!doneP) posP = mad(granularity, offNP, posP);
	
	uint iterations = 0;
	uint maxiterations = int(trunc(max(__FXAA_DEFAULT_SEARCH_STEPS * __HQAA_FXAA_SCAN_MULTIPLIER, __FXAA_MINIMUM_SEARCH_STEPS)));
	
#if HQAA_ENABLE_FPS_TARGET
	if (frametime > __HQAA_DESIRED_FRAMETIME) maxiterations = int(trunc(max(__FXAA_MINIMUM_SEARCH_STEPS, __HQAA_FPS_CLAMP_MULTIPLIER * maxiterations)));
#endif
	
	[loop] while (iterations < maxiterations)
	{
		if (!doneN)
		{
			lumaEndN = dotgamma(FxaaTex2D(ReShade::BackBuffer, posN.xy));
			lumaEndN = mad(0.5, -lumaNN, lumaEndN);
			doneN = abs(lumaEndN) >= gradientScaled;
			if (!doneN) posN = mad(granularity, -offNP, posN);
		}
		if (!doneP)
		{
			lumaEndP = dotgamma(FxaaTex2D(ReShade::BackBuffer, posP.xy));
			lumaEndP = mad(0.5, -lumaNN, lumaEndP);
			doneP = abs(lumaEndP) >= gradientScaled;
			if (!doneP) posP = mad(granularity, offNP, posP);
		}
		if (doneN && doneP) break;
		iterations++;
    }
	
    float dstN = texcoord.x - posN.x;
    float dstP = posP.x - texcoord.x;
	
	[branch]
    if(!horzSpan) {
		dstN = texcoord.y - posN.y;
		dstP = posP.y - texcoord.y;
	}
	
    bool goodSpan = (dstN < dstP) ? ((lumaEndN < 0.0) != lumaMLTZero) : ((lumaEndP < 0.0) != lumaMLTZero);
    float pixelOffset = mad(-rcp(dstP + dstN), min(dstN, dstP), 0.5);
	float subpixOut = pixelOffset;
	
	// calculating subpix quality is only necessary with a failed span
	[branch] if (!goodSpan) {
		float fxaaQualitySubpix = __HQAA_SUBPIX * __HQAA_FXAA_SCAN_GRANULARITY;
		subpixOut = mad(2.0, lumaS + lumaE + lumaN + lumaW, lumaNW + lumaSE + lumaNE + lumaSW); // A
		subpixOut = saturate(abs(mad((1.0/12.0), subpixOut, -lumaMa)) * rcp(range)); // BC
		subpixOut = mad(-2.0, subpixOut, 3.0) * (subpixOut * subpixOut); // DEF
		subpixOut = (subpixOut * subpixOut) * fxaaQualitySubpix; // GH
		subpixOut *= pixelOffset;
    }

    float2 posM = texcoord;
    if(!horzSpan) posM.x = mad(lengthSign, subpixOut, posM.x);
    else posM.y = mad(lengthSign, subpixOut, posM.y);
	
	// Establish result and compute luma hysteresis
	float4 resultAA = float4(FxaaTex2D(ReShade::BackBuffer, posM).rgb, rgbyM.a);
	
	float hysteresis = (dotluma(resultAA) - edgedata.b);
#if HQAA_ENABLE_HDR_OUTPUT
	hysteresis *= rcp(HdrNits);
#endif //HQAA_ENABLE_HDR_OUTPUT
	
	// perform result weighting using computed luma hysteresis
	hysteresis = clamp(hysteresis, -(0.5 - __HQAA_SMALLEST_COLOR_STEP / 2.0), 1.0 - __HQAA_SMALLEST_COLOR_STEP);
	resultAA = pow(abs((1.0 + hysteresis) * 2.0), log2(resultAA));
	float lumafinaldelta = abs(dotluma(resultAA) - edgedata.b);
	
	// compute saturation hysteresis and adjust to match
	float sathysteresis = clamp(dotsat(resultAA) - edgedata.a, -lumafinaldelta, lumafinaldelta);
	resultAA = AdjustSaturation(resultAA, sathysteresis);
	
	// output selection
#if HQAA_COMPILE_DEBUG_CODE
	if (debugmode < 6)
	{
#endif //HQAA_COMPILE_DEBUG_CODE
	// normal output (valid for debug 5, its check happens with early-exit path)
	return resultAA;
#if HQAA_COMPILE_DEBUG_CODE
	}
	else if (debugmode == 6) {
		// luminance output
		return float4(lumaMa, lumaMa, lumaMa, lumaMa);
	}
	else if (debugmode == 7) {
		// metrics output
		float runtime = float(iterations / maxiterations);
		float4 FxaaMetrics = float4(runtime, 1.0 - runtime, 0.0, 0.0);
		return FxaaMetrics;
	}
	else if (debugmode == 8) {
		// hysteresis output
		float lowclamp = -(0.5 - __HQAA_SMALLEST_COLOR_STEP / 2.0);
		float highclamp = 1.0 - __HQAA_SMALLEST_COLOR_STEP;
		float downshift = hysteresis < 0.0 ? (hysteresis / lowclamp) : 0.0;
		float upshift = hysteresis > 0.0 ? (hysteresis / highclamp) : 0.0;
		float4 FxaaHysteresisDebug = float4(downshift, upshift, downshift == -upshift ? 0.05 : 0.0, 0.0);
		return FxaaHysteresisDebug;
	}
	else {
		float4 FxaaSatHysteresisDebug = float4(sathysteresis > 0.0 ? sathysteresis : 0.0, sathysteresis < 0.0 ? abs(sathysteresis) : 0.0, sathysteresis == 0.0 ? 0.05 : 0.0, 0.0);
		return FxaaSatHysteresisDebug;
	}
#endif //HQAA_COMPILE_DEBUG_CODE
}

/***************************************************************************************************************************************/
/********************************************************** FXAA SHADER CODE END *******************************************************/
/***************************************************************************************************************************************/

/***************************************************************************************************************************************/
/******************************************************* OPTIONAL SHADER CODE START ****************************************************/
/***************************************************************************************************************************************/

#if HQAA_COMPILE_DEBUG_CODE
float4 HQAADebugOutputPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	if (debugmode == 1) return float4(tex2D(HQAAsamplerAlphaEdges, texcoord).rg, 0.0, 0.0);
	if (debugmode == 2) return tex2D(HQAAsamplerSMweights, texcoord);
	if (debugmode == 3) return float4(tex2D(HQAAsamplerAlphaEdges, texcoord).a, 0.0, 0.0, 0.0);
	if (debugmode == 4) return float4(tex2D(HQAAsamplerAlphaEdges, texcoord).b, 0.0, 0.0, 0.0);
	return tex2D(ReShade::BackBuffer, texcoord);
}
#endif //HQAA_COMPILE_DEBUG_CODE

#if HQAA_ENABLE_OPTIONAL_TECHNIQUES 
#if (HQAA_OPTIONAL_CAS || HQAA_OPTIONAL_DEBAND || HQAA_OPTIONAL_BRIGHTNESS_GAIN || HQAA_OPTIONAL_TEMPORAL_STABILIZER)
// Optional effects main pass. These are sorted in an order that they won't
// interfere with each other when they're all enabled
float4 HQAAOptionalEffectPassPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 pixel = tex2D(ReShade::BackBuffer, texcoord);
	
#if (HQAA_OPTIONAL_DEBAND || HQAA_OPTIONAL_CAS)
    float3 a = tex2Doffset(ReShade::BackBuffer, texcoord, int2(-1, -1)).rgb;
    float3 c = tex2Doffset(ReShade::BackBuffer, texcoord, int2(1, -1)).rgb;
    float3 g = tex2Doffset(ReShade::BackBuffer, texcoord, int2(-1, 1)).rgb;
    float3 i = tex2Doffset(ReShade::BackBuffer, texcoord, int2(1, 1)).rgb;
#endif //(HQAA_OPTIONAL_DEBAND || HQAA_OPTIONAL_CAS)

#if HQAA_OPTIONAL_DEBAND
    float hash = permute(permute(permute(texcoord.x) + texcoord.y) + drandom / 32767.0);

    float3 ref_avg;
    float3 ref_avg_diff;
    float3 ref_max_diff;
    float3 ref_mid_diff1;
    float3 ref_mid_diff2;

    float3 ori = pixel.rgb;
    float3 res;

    float dir = rand(permute(hash)) * 6.2831853;
    float2 angle = float2(cos(dir), sin(dir));

    analyze_pixels(ori, a, c, g, i, angle, ref_avg, ref_avg_diff, ref_max_diff, ref_mid_diff1, ref_mid_diff2);

    float3 factor = pow(saturate(3.0 * (1.0 - ref_avg_diff  / HQAA_DEBAND_AVGDIFF_PRESET[HqaaDebandPreset])) *
                        saturate(3.0 * (1.0 - ref_max_diff  / HQAA_DEBAND_MAXDIFF_PRESET[HqaaDebandPreset])) *
                        saturate(3.0 * (1.0 - ref_mid_diff1 / HQAA_DEBAND_MIDDIFF_PRESET[HqaaDebandPreset])) *
                        saturate(3.0 * (1.0 - ref_mid_diff2 / HQAA_DEBAND_MIDDIFF_PRESET[HqaaDebandPreset])), 0.1);

    res = lerp(ori, ref_avg, factor);
	
    dir = rand(permute(hash)) * 6.2831853;
    angle = float2(cos(dir), sin(dir));

    analyze_pixels(ori, a, c, g, i, angle, ref_avg, ref_avg_diff, ref_max_diff, ref_mid_diff1, ref_mid_diff2);

    factor = pow(saturate(3.0 * (1.0 - ref_avg_diff  / HQAA_DEBAND_AVGDIFF_PRESET[HqaaDebandPreset])) *
                 saturate(3.0 * (1.0 - ref_max_diff  / HQAA_DEBAND_MAXDIFF_PRESET[HqaaDebandPreset])) *
                 saturate(3.0 * (1.0 - ref_mid_diff1 / HQAA_DEBAND_MIDDIFF_PRESET[HqaaDebandPreset])) *
                 saturate(3.0 * (1.0 - ref_mid_diff2 / HQAA_DEBAND_MIDDIFF_PRESET[HqaaDebandPreset])), 0.1);

    res = lerp(ori, ref_avg, factor);
	
    dir = rand(permute(hash)) * 6.2831853;
    angle = float2(cos(dir), sin(dir));

    analyze_pixels(ori, a, c, g, i, angle, ref_avg, ref_avg_diff, ref_max_diff, ref_mid_diff1, ref_mid_diff2);

    factor = pow(saturate(3.0 * (1.0 - ref_avg_diff  / HQAA_DEBAND_AVGDIFF_PRESET[HqaaDebandPreset])) *
                 saturate(3.0 * (1.0 - ref_max_diff  / HQAA_DEBAND_MAXDIFF_PRESET[HqaaDebandPreset])) *
                 saturate(3.0 * (1.0 - ref_mid_diff1 / HQAA_DEBAND_MIDDIFF_PRESET[HqaaDebandPreset])) *
                 saturate(3.0 * (1.0 - ref_mid_diff2 / HQAA_DEBAND_MIDDIFF_PRESET[HqaaDebandPreset])), 0.1);

    res = lerp(ori, ref_avg, factor);

	float dither_shift = 0.25 * (1.0 / (pow(2, BUFFER_COLOR_BIT_DEPTH) - 1.0));
	float3 dither_shift_RGB = float3(dither_shift, -dither_shift, dither_shift);
	dither_shift_RGB = lerp(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, frac(dot(texcoord, (BUFFER_SCREEN_SIZE * float2(1.0 / 16.0, 10.0 / 36.0)) + 0.25)));
	res += dither_shift_RGB;

    pixel.rgb = res;
#endif //HQAA_OPTIONAL_DEBAND

#if HQAA_OPTIONAL_CAS
	float4 casdot = pixel;
	
	float sharpening = HqaaSharpenerStrength;
	
	if (any(tex2D(HQAAsamplerAlphaEdges, texcoord).rg))
		sharpening *= (1.0 - HqaaSharpenerClamping);
	
    float3 b = tex2Doffset(ReShade::BackBuffer, texcoord, int2(0, -1)).rgb;
    float3 d = tex2Doffset(ReShade::BackBuffer, texcoord, int2(-1, 0)).rgb;
    float3 f = tex2Doffset(ReShade::BackBuffer, texcoord, int2(1, 0)).rgb;
    float3 h = tex2Doffset(ReShade::BackBuffer, texcoord, int2(0, 1)).rgb;
	
	float3 mnRGB = min5(d, casdot.rgb, f, b, h);
	float3 mnRGB2 = min5(mnRGB, a, c, g, i);
    mnRGB += mnRGB2;

	float3 mxRGB = max5(d, casdot.rgb, f, b, h);
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
	
    float4 outColor = float4(saturate(mad(window, wRGB, casdot.rgb) * rcp(mad(4.0, wRGB, 1.0))), casdot.a);
	casdot = float4(lerp(casdot, outColor, sharpening).rgb, casdot.a);
#if HQAA_ENABLE_HDR_OUTPUT
	 casdot *= HdrNits;
#endif //HQAA_ENABLE_HDR_OUTPUT
	pixel = casdot;

#endif //HQAA_OPTIONAL_CAS

#if HQAA_OPTIONAL_BRIGHTNESS_GAIN
	[branch] if (HqaaGainStrength > 0.0)
	{
		float4 outdot = pixel;
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
			outdot = pow(abs((HqaaGainStrength + 1.0) * (10.0 / (HqaaGainStrength + 1.0) + contrastgain)), log10(outdot));
			float newsat = dotsat(outdot);
			float satadjust = newsat - presaturation; // compute difference in before/after saturation
			outdot = AdjustSaturation(outdot, satadjust);
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
	float4 current = pixel;
	float4 previous = tex2D(HQAAsamplerLastFrame, texcoord);
	
	// values above 0.9 can produce artifacts or halt frame advancement entirely
	float blendweight = min(HqaaPreviousFrameWeight, 0.9);
	
	if (ClampMaximumWeight) {
		float contrastdelta = sqrt(dotgamma(abs(current - previous)));
		blendweight = min(contrastdelta, blendweight);
	}
	
	pixel = lerp(current, previous, blendweight);
#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER

	return pixel;
}
#endif //(HQAA_OPTIONAL_CAS || HQAA_OPTIONAL_DEBAND || HQAA_OPTIONAL_BRIGHTNESS_GAIN || HQAA_OPTIONAL_TEMPORAL_STABILIZER)

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
		PixelShader = HQAAHysteresisBlendingPS;
	}
#if HQAA_ENABLE_OPTIONAL_TECHNIQUES
#if (HQAA_OPTIONAL_CAS || HQAA_OPTIONAL_DEBAND || HQAA_OPTIONAL_TEMPORAL_STABILIZER || HQAA_OPTIONAL_BRIGHTNESS_GAIN)
	pass OptionalEffects
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAOptionalEffectPassPS;
	}
#endif //(HQAA_OPTIONAL_CAS || HQAA_OPTIONAL_DEBAND || HQAA_OPTIONAL_TEMPORAL_STABILIZER || HQAA_OPTIONAL_BRIGHTNESS_GAIN)
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
#if HQAA_COMPILE_DEBUG_CODE
	pass DebugOutput
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAADebugOutputPS;
	}
#endif //HQAA_COMPILE_DEBUG_CODE
}
