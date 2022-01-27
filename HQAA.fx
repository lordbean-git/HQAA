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
 *                        v15.2
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
#endif

#ifndef HQAA_COMPILE_DEBUG_CODE
	#define HQAA_COMPILE_DEBUG_CODE 1
#endif

#ifndef HQAA_ENABLE_OPTIONAL_TECHNIQUES
	#define HQAA_ENABLE_OPTIONAL_TECHNIQUES 1
#endif

#ifndef HQAA_ENABLE_FPS_TARGET
#define HQAA_ENABLE_FPS_TARGET 1
#endif

#if HQAA_ENABLE_OPTIONAL_TECHNIQUES

#ifndef HQAA_OPTIONAL_CAS
#define HQAA_OPTIONAL_CAS 1
#endif

#ifndef HQAA_OPTIONAL_TEMPORAL_STABILIZER
#define HQAA_OPTIONAL_TEMPORAL_STABILIZER 1
#endif

#ifndef HQAA_OPTIONAL_BRIGHTNESS_GAIN
#define HQAA_OPTIONAL_BRIGHTNESS_GAIN 1
#endif

#endif // HQAA_ENABLE_OPTIONAL_TECHNIQUES

uniform int HQAAintroduction <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\nHybrid high-Quality Anti-Aliasing, a shader by lordbean\n"
	          "Version: 15.2\n"
			  "https://github.com/lordbean-git/HQAA/\n";
	ui_tooltip = "No 3090s were harmed in the making of this shader.";
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
	ui_tooltip = "Local contrast required to run shader";
    ui_category = "Custom Preset";
	ui_category_closed = true;
	ui_text = "\n------------------------------ Global Options ----------------------------------\n ";
> = 0.1;

uniform float SubpixCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Subpixel Effects Strength";
	ui_tooltip = "Lower = sharper image, Higher = more AA effect";
    ui_category = "Custom Preset";
	ui_category_closed = true;
> = 0.5;

uniform float SmaaCorneringCustom < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "SMAA Corner Rounding";
	ui_tooltip = "Affects the amount of blending performed when SMAA\ndetects crossing edges";
    ui_category = "Custom Preset";
	ui_category_closed = true;
	ui_text = "\n------------------------------- SMAA Options -----------------------------------\n ";
> = 20;

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
> = 0.5;

uniform uint debugmode <
	ui_type = "radio";
	ui_category = "Debug";
	ui_category_closed = true;
	ui_label = " ";
	ui_spacing = 1;
	ui_text = "Debug Mode:";
	ui_items = "Off\0Detected Edges\0SMAA Blend Weights\0Computed Alpha Normals\0FXAA Results:\0FXAA Lumas:\0FXAA Metrics:\0";
> = 0;

uniform uint debugFXAApass <
	ui_type = "radio";
	ui_category = "Debug";
	ui_category_closed = true;
	ui_label = " ";
	ui_text = "--------- FXAA PASS SELECT ----------";
	ui_items = "SMAA Positives\0SMAA Negatives\0";
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
			  "The Alpha Normals view represents the normalized luminance\n"
			  "data used to represent the alpha channel during edge detection.\n\n"
			  "Debug checks can optionally be excluded from the compiled shader\n"
			  "by setting HQAA_COMPILE_DEBUG_CODE to 0.\n"
	          "----------------------------------------------------------------";
	ui_category = "Debug";
	ui_category_closed = true;
>;

#if HQAA_ENABLE_FPS_TARGET
uniform float FramerateFloor < __UNIFORM_SLIDER_INT1
	ui_min = 30; ui_max = 150; ui_step = 1;
	ui_label = "Target Minimum Framerate";
	ui_tooltip = "HQAA will automatically reduce FXAA sampling quality if\nthe framerate drops below this number";
	ui_spacing = 3;
> = 60;
#endif

#if HQAA_ENABLE_HDR_OUTPUT
uniform float HdrNits < 
	ui_type = "combo";
	ui_min = 200.0; ui_max = 1000.0; ui_step = 200.0;
	ui_label = "HDR Nits";
	ui_spacing = 3;
	ui_tooltip = "Most DisplayHDR certified monitors calculate colors based on 1000 nits\n"
				 "even when the certification is for a lower value (like DisplayHDR400).";
> = 1000.0;
#endif

uniform int optionseof <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n------------------------------------------------------------";
>;

#if HQAA_ENABLE_OPTIONAL_TECHNIQUES
#if HQAA_OPTIONAL_CAS

uniform float HqaaSharpenerStrength < __UNIFORM_SLIDER_FLOAT1
	ui_spacing = 3;
	ui_min = 0; ui_max = 4; ui_step = 0.01;
	ui_label = "Sharpening Strength";
	ui_tooltip = "Amount of sharpening to apply";
	ui_category = "(HQAACAS) Optional Sharpening";
	ui_category_closed = true;
> = 1;

uniform float HqaaSharpenerClamping < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 1; ui_step = 0.001;
	ui_label = "Clamp Strength";
	ui_tooltip = "How much to clamp sharpening strength when the pixel had AA applied to it\n"
	             "Zero means no clamp applied, one means no sharpening applied";
	ui_category = "(HQAACAS) Optional Sharpening";
	ui_category_closed = true;
> = 0.5;

uniform bool HqaaSharpenerDebug <
    ui_text = "Debug:\n ";
	ui_label = "Show Sharpening Pattern";
	ui_category = "(HQAACAS) Optional Sharpening";
	ui_category_closed = true;
> = false;

uniform int sharpenerintro <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\nHQAA can optionally run Contrast-Adaptive Sharpening very similar to CAS.fx.\n"
	          "The advantage to using the technique built into HQAA is that it uses edge\n"
			  "data generated by the anti-aliasing technique to adjust the amount of sharpening\n"
			  "applied to areas that were processed to remove aliasing.\n\n"
			  "HQAA's implementation of CAS uses per-component interpolation and is far less\n"
	          "likely to generate oversharpening artifacts at high sharpen amounts compared to\n"
			  "traditional AMD contrast-adaptive sharpening.";
	ui_category = "(HQAACAS) Optional Sharpening";
	ui_category_closed = true;
>;
#endif // HQAA_OPTIONAL_CAS
#if HQAA_OPTIONAL_TEMPORAL_STABILIZER

uniform float HqaaPreviousFrameWeight < __UNIFORM_SLIDER_FLOAT1
	ui_spacing = 3;
	ui_min = 0; ui_max = 1.0; ui_step = 0.001;
	ui_label = "Previous Frame Weight";
	ui_category = "(HQAATemporalStabilizer) Optional Temporal Stabilizer";
	ui_category_closed = true;
	ui_tooltip = "Blends the previous frame with the current frame to stabilize results.";
> = 0.5;

uniform bool ClampMaximumWeight <
	ui_label = "Clamp Maximum Weight?";
	ui_spacing = 2;
	ui_category = "(HQAATemporalStabilizer) Optional Temporal Stabilizer";
	ui_category_closed = true;
	ui_tooltip = "When enabled the maximum amount of weight given to the previous\n"
				 "frame will be equal to the largest change in contrast in any\n"
				 "single color channel between the past frame and the current frame.";
> = true;

uniform int stabilizerintro <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\nWhen enabled, this effect will blend the previous frame with the\n"
	          "current frame at the specified weight to minimize overcorrection\n"
			  "errors such as crawling text or wiggling lines.";
	ui_category = "(HQAATemporalStabilizer) Optional Temporal Stabilizer";
	ui_category_closed = true;
>;
#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER
#if HQAA_OPTIONAL_BRIGHTNESS_GAIN

uniform float HqaaGainStrength < __UNIFORM_SLIDER_FLOAT1
	ui_min = -1.00; ui_max = 0.75; ui_step = 0.001;
	ui_spacing = 3;
	ui_label = "Brightness Gain";
	ui_category = "(HQAABrightnessGain) Optional Brightness Booster";
	ui_category_closed = true;
> = 0.0;

uniform int gainintro <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\nWhen enabled, allows to raise or lower overall image brightness\n"
			  "as a quick fix for dark games and/or monitors, or to increase\n"
			  "perceived contrast level.\n\n"
			  "This technique may produce odd or reversed results when used in\n"
			  "non-standard color spaces (eg. HDR or scRGB).";
	ui_category = "(HQAABrightnessGain) Optional Brightness Booster";
	ui_category_closed = true;
>;
#endif //HQAA_OPTIONAL_BRIGHTNESS_GAIN

uniform int optionalseof <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n------------------------------------------------------------";
>;

#endif

uniform int presetbreakdown <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n"
	          "|--Preset|-Threshold---Subpix---Corners---Quality---Texel-|\n"
	          "|--------|-----------|--------|---------|---------|-------|\n"
	          "|  Potato|   0.250   |  .125  |    0%   |  0.250  |  2.0  |\n"
			  "|     Low|   0.200   |  .250  |    0%   |  0.375  |  1.5  |\n"
			  "|  Medium|   0.150   |  .500  |   10%   |  0.750  |  1.0  |\n"
			  "|    High|   0.100   |  .750  |   15%   |  1.000  |  1.0  |\n"
			  "|   Ultra|   0.075   |  1.00  |   20%   |  1.500  |  0.5  |\n"
			  "|  GLaDOS|   0.050   |  1.00  |   25%   |  2.500  |  0.2  |\n"
			  "-----------------------------------------------------------";
	ui_category = "Click me to see what settings each preset uses!";
	ui_category_closed = true;
>;

uniform float frametime < source = "frametime"; >;
uniform uint framecount < source = "framecount"; >;

static const float HQAA_THRESHOLD_PRESET[7] = {0.25,0.2,0.15,0.1,0.075,0.05,1};
static const float HQAA_SUBPIX_PRESET[7] = {0.125,0.25,0.5,0.75,1.0,1.0,0};
static const float HQAA_SMAA_CORNER_ROUNDING_PRESET[7] = {0.0,0.0,10.0,15.0,20.0,25.0,0.0};
static const float HQAA_FXAA_SCANNING_MULTIPLIER_PRESET[7] = {0.25,0.375,0.75,1.0,1.5,2.5,0};
static const float HQAA_FXAA_TEXEL_SIZE_PRESET[7] = {2.0,1.5,1.0,1.0,0.5,0.2,4};

#define __HQAA_EDGE_THRESHOLD (preset == 6 ? (EdgeThresholdCustom) : (HQAA_THRESHOLD_PRESET[preset]))
#define __HQAA_SUBPIX (preset == 6 ? (SubpixCustom) : (HQAA_SUBPIX_PRESET[preset]))
#define __HQAA_SMAA_CORNERING (preset == 6 ? (SmaaCorneringCustom) : (HQAA_SMAA_CORNER_ROUNDING_PRESET[preset]))
#define __HQAA_FXAA_SCAN_MULTIPLIER (preset == 6 ? (FxaaIterationsCustom) : (HQAA_FXAA_SCANNING_MULTIPLIER_PRESET[preset]))
#define __HQAA_FXAA_SCAN_GRANULARITY (preset == 6 ? (FxaaTexelSizeCustom) : (HQAA_FXAA_TEXEL_SIZE_PRESET[preset]))

#define __HQAA_DISPLAY_DENOMINATOR min(BUFFER_HEIGHT, BUFFER_WIDTH)
#define __HQAA_DISPLAY_NUMERATOR max(BUFFER_HEIGHT, BUFFER_WIDTH)
#define __HQAA_BUFFER_MULTIPLIER saturate(__HQAA_DISPLAY_DENOMINATOR / 1440.0)
#define __HQAA_SMALLEST_COLOR_STEP rcp(pow(2, BUFFER_COLOR_BIT_DEPTH))
#define __HQAA_LUMA_REF float4(0.25,0.25,0.25,0.25)
#define __HQAA_GAMMA_REF float3(0.3333,0.3334,0.3333)

#if HQAA_ENABLE_FPS_TARGET
#define __HQAA_DESIRED_FRAMETIME float(1000.0 / FramerateFloor)
#define __HQAA_FPS_CLAMP_MULTIPLIER rcp(frametime - (__HQAA_DESIRED_FRAMETIME - 1.0))
#endif

#define __FXAA_THRESHOLD_FLOOR __HQAA_SMALLEST_COLOR_STEP
#define __FXAA_MINIMUM_SEARCH_STEPS (1.0 / __HQAA_FXAA_SCAN_GRANULARITY)
#define __FXAA_DEFAULT_SEARCH_STEPS (10.0 / __HQAA_FXAA_SCAN_GRANULARITY)
#define __FXAA_EDGE_THRESHOLD max(__HQAA_EDGE_THRESHOLD, __FXAA_THRESHOLD_FLOOR)
#define __FXAA_THRESHOLD_ADJUSTMENT_RANGE min((__FXAA_EDGE_THRESHOLD - __FXAA_THRESHOLD_FLOOR) * (__HQAA_SUBPIX * 0.5), 0.125)

#define __SMAA_THRESHOLD_FLOOR (__HQAA_SMALLEST_COLOR_STEP * 0.25)
#define __SMAA_EDGE_THRESHOLD max(__HQAA_EDGE_THRESHOLD, __SMAA_THRESHOLD_FLOOR)
#define __SMAA_THRESHOLD_ADJUSTMENT_RANGE min((__SMAA_EDGE_THRESHOLD - __SMAA_THRESHOLD_FLOOR) * (__HQAA_SUBPIX * 0.875), 0.25)
#define __SMAA_MAX_SEARCH_STEPS (__HQAA_DISPLAY_NUMERATOR * 0.125)
#define __SMAA_MINIMUM_SEARCH_STEPS 20

#define dotluma(x) ((__HQAA_LUMA_REF.r * x.r) + (__HQAA_LUMA_REF.g * x.g) + (__HQAA_LUMA_REF.b * x.b) + (__HQAA_LUMA_REF.a * x.a))
#define dotgamma(x) ((__HQAA_GAMMA_REF.r * x.r) + (__HQAA_GAMMA_REF.g * x.g) + (__HQAA_GAMMA_REF.b * x.b))
#define vec4add(x) (x.r + x.g + x.b + x.a)
#define vec3add(x) (x.r + x.g + x.b)

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

/*****************************************************************************************************************************************/
/*********************************************************** UI SETUP END ****************************************************************/
/*****************************************************************************************************************************************/


/////////////////////////////////////////////////////////// SUPPORT FUNCTIONS /////////////////////////////////////////////////////////////

// pixel luma calculators
float3 GetNormalizedLuma(float3 input)
{
	float3 normal = input * __HQAA_GAMMA_REF;
	normal *= rcp(vec3add(normal));
	return normal;
}
float4 GetNormalizedLuma(float4 input)
{
	float4 normal = input * __HQAA_LUMA_REF;
	normal *= rcp(vec4add(normal));
	return normal;
}

// alphachannel-delta calculator
float GetNewAlpha(float4 before, float4 after)
{
	float delta = (dotgamma(after.rgb) - dotgamma(before.rgb)) * before.a;
	return (before.a + delta);
}

#if HQAA_ENABLE_OPTIONAL_TECHNIQUES
#if HQAA_OPTIONAL_CAS
// CAS standalone function
float4 HQAACASPS(float2 texcoord, sampler2D edgesTex, sampler2D sTexColor)
{
	float sharpenmultiplier = (1.0 - __HQAA_EDGE_THRESHOLD) * __HQAA_SUBPIX;
	
	// reduce strength if there were edges detected here
	float2 edgesdetected = tex2D(edgesTex, texcoord).rg;
	if (dot(edgesdetected, float2(1.0, 1.0)) != 0.0)
		sharpenmultiplier *= (1.0 - HqaaSharpenerClamping);
	
	// set sharpening amount
	float sharpening = HqaaSharpenerStrength * sharpenmultiplier;
	
	// proceed with CAS math.
	
    float3 a = tex2Doffset(sTexColor, texcoord, int2(-1, -1)).rgb;
    float3 b = tex2Doffset(sTexColor, texcoord, int2(0, -1)).rgb;
    float3 c = tex2Doffset(sTexColor, texcoord, int2(1, -1)).rgb;
    float3 d = tex2Doffset(sTexColor, texcoord, int2(-1, 0)).rgb;
    float4 e = tex2D(sTexColor, texcoord);
    float3 f = tex2Doffset(sTexColor, texcoord, int2(1, 0)).rgb;
    float3 g = tex2Doffset(sTexColor, texcoord, int2(-1, 1)).rgb;
    float3 h = tex2Doffset(sTexColor, texcoord, int2(0, 1)).rgb;
    float3 i = tex2Doffset(sTexColor, texcoord, int2(1, 1)).rgb;
	
	float3 mnRGB = min5(d, e.rgb, f, b, h);
	float3 mnRGB2 = min5(mnRGB, a, c, g, i);
    mnRGB += mnRGB2;

	float3 mxRGB = max5(d, e.rgb, f, b, h);
	float3 mxRGB2 = max5(mxRGB,a,c,g,i);
    mxRGB += mxRGB2;
	
	#if HQAA_ENABLE_HDR_OUTPUT
	mnRGB *= (1.0 / HdrNits);
	mxRGB *= (1.0 / HdrNits);
	e *= (1.0 / HdrNits);
	#endif

    float3 rcpMRGB = rcp(mxRGB);
    float3 ampRGB = saturate(min(mnRGB, 2.0 - mxRGB) * rcpMRGB);    
    
    ampRGB = rsqrt(ampRGB);
    
    float3 wRGB = -rcp(ampRGB * 8.0);

    float3 rcpWeightRGB = rcp(mad(4.0, wRGB, 1.0));

    float3 window = (b + d) + (f + h);
#if HQAA_ENABLE_HDR_OUTPUT
	window *= (1.0 / HdrNits);
#endif
	
    float4 outColor = float4(saturate(mad(window, wRGB, e.rgb) * rcpWeightRGB), e.a);
	
	float4 result = float4(lerp(e, outColor, sharpening).rgb, e.a);
    
#if HQAA_ENABLE_HDR_OUTPUT
	return result * HdrNits;
#else
	return result;
#endif
}
#endif //HQAA_OPTIONAL_CAS

#if HQAA_OPTIONAL_TEMPORAL_STABILIZER
// Temporal stabilizer function
float4 HQAATemporalStabilizerPS(sampler2D currentframe, sampler2D lastframe, float2 pos)
{
	float4 current = tex2D(currentframe, pos);
	float4 previous = tex2D(lastframe, pos);
	
	// values above 0.9 can produce artifacts or halt frame advancement entirely
	float blendweight = min(HqaaPreviousFrameWeight, 0.9);
	
	if (ClampMaximumWeight) {
		float contrastdelta = sqrt(dotluma(abs(current - previous)));
		blendweight = min(contrastdelta, blendweight);
	}
	
	return lerp(current, previous, blendweight);
}
#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER

#if HQAA_OPTIONAL_BRIGHTNESS_GAIN
// color channel experiment
float4 HQAAColorChannelCompressionPS(sampler2D tex, float2 pos)
{
	float4 dot = tex2D(tex, pos);
	float gain = 1.0 - HqaaGainStrength;
	dot.rgb = rcp(dot.rgb);
	dot.rgb = pow(abs(dot.rgb), gain);
	dot.rgb = rcp(dot.rgb);
	return dot;
}
#endif //HQAA_OPTIONAL_BRIGHTNESS_GAIN
#endif // HQAA_ENABLE_OPTIONAL_TECHNIQUES

/*****************************************************************************************************************************************/
/*********************************************************** SMAA CODE BLOCK START *******************************************************/
/*****************************************************************************************************************************************/

// DX11 optimization
#if (__RENDERER__ == 0xb000 || __RENDERER__ == 0xb100)
	#define SMAAGather(tex, coord) tex2Dgather(tex, coord, 0)
#endif

// Configurable
#define __SMAA_CORNER_ROUNDING (__HQAA_SMAA_CORNERING)
#define __SMAA_MAX_SEARCH_STEPS_DIAG 20
#define __SMAA_BRANCH [branch]
#define __SMAA_FLATTEN [flatten]
#define __SMAA_INCLUDE_VS 1
#define __SMAA_INCLUDE_PS 1

// Constants
#define __SMAA_RT_METRICS float4(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT, BUFFER_WIDTH, BUFFER_HEIGHT)
#define __SMAASampleLevelZero(tex, coord) tex2Dlod(tex, float4(coord, coord))
#define __SMAASampleLevelZeroOffset(tex, coord, offset) tex2Dlodoffset(tex, float4(coord, coord), offset)
#define __SMAA_AREATEX_MAX_DISTANCE 16
#define __SMAA_AREATEX_MAX_DISTANCE_DIAG 20
#define __SMAA_AREATEX_PIXEL_SIZE (1.0 / float2(160.0, 560.0))
#define __SMAA_AREATEX_SUBTEX_SIZE (1.0/ 7.0)
#define __SMAA_SEARCHTEX_SIZE float2(66.0, 33.0)
#define __SMAA_SEARCHTEX_PACKED_SIZE float2(64.0, 16.0)
#define __SMAA_CORNER_ROUNDING_NORM float((__SMAA_CORNER_ROUNDING) / 100.0)

/**
 * Conditional move:
 */
void HQAAMovc(bool2 cond, inout float2 variable, float2 value) {
    __SMAA_FLATTEN if (cond.x) variable.x = value.x;
    __SMAA_FLATTEN if (cond.y) variable.y = value.y;
}

void HQAAMovc(bool4 cond, inout float4 variable, float4 value) {
    HQAAMovc(cond.xy, variable.xy, value.xy);
    HQAAMovc(cond.zw, variable.zw, value.zw);
}

void HQAAEdgeDetectionVS(float2 texcoord,
                         out float4 offset[3]) {
    offset[0] = mad(__SMAA_RT_METRICS.xyxy, float4(-1.0, 0.0, 0.0, -1.0), texcoord.xyxy);
    offset[1] = mad(__SMAA_RT_METRICS.xyxy, float4( 1.0, 0.0, 0.0,  1.0), texcoord.xyxy);
    offset[2] = mad(__SMAA_RT_METRICS.xyxy, float4(-2.0, 0.0, 0.0, -2.0), texcoord.xyxy);
}


void HQAABlendingWeightCalculationVS(float2 texcoord,
                                     out float2 pixcoord,
                                     out float4 offset[3]) {
    pixcoord = texcoord * __SMAA_RT_METRICS.zw;

    offset[0] = mad(__SMAA_RT_METRICS.xyxy, float4(-0.25, -0.125,  1.25, -0.125), texcoord.xyxy);
    offset[1] = mad(__SMAA_RT_METRICS.xyxy, float4(-0.125, -0.25, -0.125,  1.25), texcoord.xyxy);
	
	float searchrange = trunc(__SMAA_MAX_SEARCH_STEPS);
	
	#if HQAA_ENABLE_FPS_TARGET
	if (frametime > __HQAA_DESIRED_FRAMETIME)
		searchrange = trunc(max(__SMAA_MINIMUM_SEARCH_STEPS, searchrange * __HQAA_FPS_CLAMP_MULTIPLIER));
	#endif

    offset[2] = mad(__SMAA_RT_METRICS.xxyy,
                    float4(-2.0, 2.0, -2.0, 2.0) * searchrange,
                    float4(offset[0].xz, offset[1].yw));
}


void HQAANeighborhoodBlendingVS(float2 texcoord,
                                out float4 offset) {
    offset = mad(__SMAA_RT_METRICS.xyxy, float4( 1.0, 0.0, 0.0,  1.0), texcoord.xyxy);
}

/**
 * IMPORTANT NOTICE: luma edge detection requires gamma-corrected colors, and
 * thus 'colorTex' should be a non-sRGB texture.
 */
float2 HQAALumaEdgeDetectionPS(float2 texcoord, float4 offset[3], sampler2D colorTex) {
	float4 middle = tex2D(colorTex, texcoord);
	
	// calculate the threshold
	float adjustmentrange = __SMAA_THRESHOLD_ADJUSTMENT_RANGE;
	
	float estimatedbrightness = (dotgamma(middle) + max3(middle.r, middle.g, middle.b)) * 0.5;
	float thresholdOffset = mad(estimatedbrightness, adjustmentrange, -adjustmentrange);
	
	float weightedthreshold = __SMAA_EDGE_THRESHOLD + thresholdOffset;
	
	float2 threshold = float2(weightedthreshold, weightedthreshold);
	
	// calculate color channel weighting
	float4 weights = float4(0.3333, 0.3334, 0.3333, 0.0);
	weights *= middle;
	float scale = rcp(vec4add(weights));
	weights *= scale;
	
	float2 edges = float2(0.0, 0.0);
	
    float L = dot(middle, weights);

    float Lleft = dot(tex2D(colorTex, offset[0].xy), weights);
    float Ltop  = dot(tex2D(colorTex, offset[0].zw), weights);

    float4 delta;
    delta.xy = abs(L - float2(Lleft, Ltop));
    edges = step(threshold, delta.xy);
	
	if (dot(edges, float2(1.0, 1.0)) != 0.0) {
		
	// scale will always be some number >=1 with gamma 2.0 colors
	// the min comparison clamps the max possible multiplier for a dark pixel
	// the maximum possible value of the calculation in brackets should not exceed 7.0 as
	// SMAA was designed with a contrast adaptation ceiling of 8.0 in mind
	// the addition of the flat 1.0 outside brackets is a sanity measure that ensures
	// the value will contain a usable number in the event that the backbuffer color
	// format differs significantly from gamma 2.0 (eg HDR1000, scRGB)
	float adaptationscale = 1.0 + (0.1 * min(70.0, log(scale)));

    float Lright = dot(tex2D(colorTex, offset[1].xy), weights);
    float Lbottom  = dot(tex2D(colorTex, offset[1].zw), weights);
    delta.zw = abs(L - float2(Lright, Lbottom));

    float2 maxDelta = max(delta.xy, delta.zw);

    float Lleftleft = dot(tex2D(colorTex, offset[2].xy), weights);
    float Ltoptop = dot(tex2D(colorTex, offset[2].zw), weights);
    delta.zw = abs(float2(Lleft, Ltop) - float2(Lleftleft, Ltoptop));

    maxDelta = max(maxDelta.xy, delta.zw);
    float finalDelta = max(maxDelta.x, maxDelta.y);

	edges.xy *= step(finalDelta, adaptationscale * delta.xy);
	}
    return edges;
}

/**
 * Allows to decode two binary values from a bilinear-filtered access.
 */
float2 HQAADecodeDiagBilinearAccess(float2 e) {
    e.r = e.r * abs(5.0 * e.r - 5.0 * 0.75);
    return round(e);
}

float4 HQAADecodeDiagBilinearAccess(float4 e) {
    e.rb = e.rb * abs(5.0 * e.rb - 5.0 * 0.75);
    return round(e);
}


float2 HQAASearchDiag1(sampler2D HQAAedgesTex, float2 texcoord, float2 dir, out float2 e) {
    float4 coord = float4(texcoord, -1.0, 1.0);
    float3 t = float3(__SMAA_RT_METRICS.xy, 1.0);
    while (coord.z < float(__SMAA_MAX_SEARCH_STEPS_DIAG - 1) &&
           coord.w > 0.9) {
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);
        e = __SMAASampleLevelZero(HQAAedgesTex, coord.xy).rg;
        coord.w = dot(e, float2(0.5, 0.5));
    }
    return coord.zw;
}

float2 HQAASearchDiag2(sampler2D HQAAedgesTex, float2 texcoord, float2 dir, out float2 e) {
    float4 coord = float4(texcoord, -1.0, 1.0);
    coord.x += 0.25 * __SMAA_RT_METRICS.x;
    float3 t = float3(__SMAA_RT_METRICS.xy, 1.0);
    while (coord.z < float(__SMAA_MAX_SEARCH_STEPS_DIAG - 1) &&
           coord.w > 0.9) {
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);

        e = __SMAASampleLevelZero(HQAAedgesTex, coord.xy).rg;
        e = HQAADecodeDiagBilinearAccess(e);

        coord.w = dot(e, float2(0.5, 0.5));
    }
    return coord.zw;
}

/** 
 * Similar to HQAAArea, this calculates the area corresponding to a certain
 * diagonal distance and crossing edges 'e'.
 */
float2 HQAAAreaDiag(sampler2D HQAAareaTex, float2 dist, float2 e, float offset) {
    float2 texcoord = mad(float2(__SMAA_AREATEX_MAX_DISTANCE_DIAG, __SMAA_AREATEX_MAX_DISTANCE_DIAG), e, dist);

    texcoord = mad(__SMAA_AREATEX_PIXEL_SIZE, texcoord, 0.5 * __SMAA_AREATEX_PIXEL_SIZE);
    texcoord.x += 0.5;
    texcoord.y += __SMAA_AREATEX_SUBTEX_SIZE * offset;

    return __SMAASampleLevelZero(HQAAareaTex, texcoord).rg;
}

/**
 * This searches for diagonal patterns and returns the corresponding weights.
 */
float2 HQAACalculateDiagWeights(sampler2D HQAAedgesTex, sampler2D HQAAareaTex, float2 texcoord, float2 e, float4 subsampleIndices) {
    float2 weights = float2(0.0, 0.0);

    float4 d;
    float2 end;
    if (e.r > 0.0) {
        d.xz = HQAASearchDiag1(HQAAedgesTex, texcoord, float2(-1.0,  1.0), end);
        d.x += float(end.y > 0.9);
    } else
        d.xz = float2(0.0, 0.0);
    d.yw = HQAASearchDiag1(HQAAedgesTex, texcoord, float2(1.0, -1.0), end);

    __SMAA_BRANCH
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
    if (__SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord, int2(1, 0)).r > 0.0) {
        d.yw = HQAASearchDiag2(HQAAedgesTex, texcoord, float2(1.0, 1.0), end);
        d.y += float(end.y > 0.9);
    } else
        d.yw = float2(0.0, 0.0);

    __SMAA_BRANCH
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

/**
 * This allows to determine how much length should we add in the last step
 * of the searches. It takes the bilinearly interpolated edge (see 
 * @PSEUDO_GATHER4), and adds 0, 1 or 2, depending on which edges and
 * crossing edges are active.
 */
float HQAASearchLength(sampler2D HQAAsearchTex, float2 e, float offset) {
    float2 scale = __SMAA_SEARCHTEX_SIZE * float2(0.5, -1.0);
    float2 bias = __SMAA_SEARCHTEX_SIZE * float2(offset, 1.0);

    scale += float2(-1.0,  1.0);
    bias  += float2( 0.5, -0.5);

    scale *= 1.0 / __SMAA_SEARCHTEX_PACKED_SIZE;
    bias *= 1.0 / __SMAA_SEARCHTEX_PACKED_SIZE;

    return __SMAASampleLevelZero(HQAAsearchTex, mad(scale, e, bias)).r;
}

/**
 * Horizontal/vertical search functions for the 2nd pass.
 */
float HQAASearchXLeft(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end) {
    float2 e = float2(0.0, 1.0);
    while (texcoord.x > end && e.g > 0.0 && e.r == 0.0) 
	{
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(-float2(2.0, 0.0), __SMAA_RT_METRICS.xy, texcoord);
    }

    float offset = mad(-(255.0 / 127.0), HQAASearchLength(HQAAsearchTex, e, 0.0), 3.25);
    return mad(__SMAA_RT_METRICS.x, offset, texcoord.x);
}

float HQAASearchXRight(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end) {
    float2 e = float2(0.0, 1.0);
    while (texcoord.x < end && e.g > 0.0 && e.r == 0.0) 
	{
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(float2(2.0, 0.0), __SMAA_RT_METRICS.xy, texcoord);
    }
    float offset = mad(-(255.0 / 127.0), HQAASearchLength(HQAAsearchTex, e, 0.5), 3.25);
    return mad(-__SMAA_RT_METRICS.x, offset, texcoord.x);
}

float HQAASearchYUp(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end) {
    float2 e = float2(1.0, 0.0);
    while (texcoord.y > end && e.r > 0.0 && e.g == 0.0) 
	{
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(-float2(0.0, 2.0), __SMAA_RT_METRICS.xy, texcoord);
    }
    float offset = mad(-(255.0 / 127.0), HQAASearchLength(HQAAsearchTex, e.gr, 0.0), 3.25);
    return mad(__SMAA_RT_METRICS.y, offset, texcoord.y);
}

float HQAASearchYDown(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end) {
    float2 e = float2(1.0, 0.0);
    while (texcoord.y < end && e.r > 0.0 && e.g == 0.0) 
	{
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(float2(0.0, 2.0), __SMAA_RT_METRICS.xy, texcoord);
    }
    float offset = mad(-(255.0 / 127.0), HQAASearchLength(HQAAsearchTex, e.gr, 0.5), 3.25);
    return mad(-__SMAA_RT_METRICS.y, offset, texcoord.y);
}

/** 
 * Ok, we have the distance and both crossing edges. So, what are the areas
 * at each side of current edge?
 */
float2 HQAAArea(sampler2D HQAAareaTex, float2 dist, float e1, float e2, float offset) {
    float2 texcoord = mad(float2(__SMAA_AREATEX_MAX_DISTANCE, __SMAA_AREATEX_MAX_DISTANCE), round(4.0 * float2(e1, e2)), dist);
    
    texcoord = mad(__SMAA_AREATEX_PIXEL_SIZE, texcoord, 0.5 * __SMAA_AREATEX_PIXEL_SIZE);
    texcoord.y = mad(__SMAA_AREATEX_SUBTEX_SIZE, offset, texcoord.y);

    return __SMAASampleLevelZero(HQAAareaTex, texcoord).rg;
}


void HQAADetectHorizontalCornerPattern(sampler2D HQAAedgesTex, inout float2 weights, float4 texcoord, float2 d) {
    float2 leftRight = step(d.xy, d.yx);
    float2 rounding = (1.0 - __SMAA_CORNER_ROUNDING_NORM) * leftRight;

    float2 factor = float2(1.0, 1.0);
    factor.x -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2(0,  1)).r;
    factor.x -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2(1,  1)).r;
    factor.y -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2(0, -2)).r;
    factor.y -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2(1, -2)).r;

    weights *= saturate(factor);
}

void HQAADetectVerticalCornerPattern(sampler2D HQAAedgesTex, inout float2 weights, float4 texcoord, float2 d) {
    float2 leftRight = step(d.xy, d.yx);
    float2 rounding = (1.0 - __SMAA_CORNER_ROUNDING_NORM) * leftRight;

    float2 factor = float2(1.0, 1.0);
    factor.x -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2( 1, 0)).g;
    factor.x -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2( 1, 1)).g;
    factor.y -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2(-2, 0)).g;
    factor.y -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2(-2, 1)).g;

    weights *= saturate(factor);
}


float4 HQAABlendingWeightCalculationPS(float2 texcoord,
                                       float2 pixcoord,
                                       float4 offset[3],
                                       sampler2D HQAAedgesTex,
                                       sampler2D HQAAareaTex,
                                       sampler2D HQAAsearchTex,
                                       float4 subsampleIndices) {
    float4 weights = float4(0.0, 0.0, 0.0, 0.0);

    float2 e = tex2D(HQAAedgesTex, texcoord).rg;

    __SMAA_BRANCH
    if (e.g > 0.0) 
	{

        float2 d;

        float3 coords;
        coords.x = HQAASearchXLeft(HQAAedgesTex, HQAAsearchTex, offset[0].xy, offset[2].x);
        coords.y = offset[1].y;
        d.x = coords.x;

        float e1 = __SMAASampleLevelZero(HQAAedgesTex, coords.xy).r;

        coords.z = HQAASearchXRight(HQAAedgesTex, HQAAsearchTex, offset[0].zw, offset[2].y);
        d.y = coords.z;

        d = abs(round(mad(__SMAA_RT_METRICS.zz, d, -pixcoord.xx)));

        float2 sqrt_d = sqrt(d);

        float e2 = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.zy, int2(1, 0)).r;

        weights.rg = HQAAArea(HQAAareaTex, sqrt_d, e1, e2, subsampleIndices.y);

        coords.y = texcoord.y;
        HQAADetectHorizontalCornerPattern(HQAAedgesTex, weights.rg, coords.xyzy, d);

    }

    __SMAA_BRANCH
    if (e.r > 0.0) {
        float2 d;

        float3 coords;
        coords.y = HQAASearchYUp(HQAAedgesTex, HQAAsearchTex, offset[1].xy, offset[2].z);
        coords.x = offset[0].x;
        d.x = coords.y;

        float e1 = __SMAASampleLevelZero(HQAAedgesTex, coords.xy).g;

        coords.z = HQAASearchYDown(HQAAedgesTex, HQAAsearchTex, offset[1].zw, offset[2].w);
        d.y = coords.z;

        d = abs(round(mad(__SMAA_RT_METRICS.ww, d, -pixcoord.yy)));

        float2 sqrt_d = sqrt(d);

        float e2 = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.xz, int2(0, 1)).g;

        weights.ba = HQAAArea(HQAAareaTex, sqrt_d, e1, e2, subsampleIndices.x);

        coords.x = texcoord.x;
        HQAADetectVerticalCornerPattern(HQAAedgesTex, weights.ba, coords.xyxz, d);
    }

    return weights;
}

float4 HQAANeighborhoodBlendingPS(float2 texcoord,
                                  float4 offset,
                                  sampler2D colorTex,
                                  sampler2D HQAAblendTex
                                  ) {
    float4 m;
    m.x = tex2D(HQAAblendTex, offset.xy).a;
    m.y = tex2D(HQAAblendTex, offset.zw).g;
    m.wz = tex2D(HQAAblendTex, texcoord).xz;
	
	float4 color = float4(0.0, 0.0, 0.0, 0.0);

    __SMAA_BRANCH
    if (dot(m, float4(1.0, 1.0, 1.0, 1.0)) < 1e-5) {
        color = __SMAASampleLevelZero(colorTex, texcoord);
    } else {
        bool horiz = max(m.x, m.z) > max(m.y, m.w);

        float4 blendingOffset = float4(0.0, m.y, 0.0, m.w);
        float2 blendingWeight = m.yw;
        HQAAMovc(bool4(horiz, horiz, horiz, horiz), blendingOffset, float4(m.x, 0.0, m.z, 0.0));
        HQAAMovc(bool2(horiz, horiz), blendingWeight, m.xz);
        blendingWeight /= dot(blendingWeight, float2(1.0, 1.0));

        float4 blendingCoord = mad(blendingOffset, float4(__SMAA_RT_METRICS.xy, -__SMAA_RT_METRICS.xy), texcoord.xyxy);

        color = blendingWeight.x * __SMAASampleLevelZero(colorTex, blendingCoord.xy);
        color += blendingWeight.y * __SMAASampleLevelZero(colorTex, blendingCoord.zw);
    }
	return color;
}

/***************************************************************************************************************************************/
/*********************************************************** SMAA CODE BLOCK END *******************************************************/
/***************************************************************************************************************************************/
// I'm a nested comment!
/***************************************************************************************************************************************/
/*********************************************************** FXAA CODE BLOCK START *****************************************************/
/***************************************************************************************************************************************/

#define FxaaAdaptiveLuma(t) dotgamma(t)

#define FxaaTex2D(t, p) float4(tex2Dlod(t, float4(p, p)).rgb, tex2Dlod(edgestex, float4(p, p)).a)
#define FxaaTex2DOffset(t, p, o) float4(tex2Dlod(t, float4(p + o * __SMAA_RT_METRICS.xy, p + o * __SMAA_RT_METRICS.xy)).rgb, tex2Dlod(edgestex, float4(p + o * __SMAA_RT_METRICS.xy, p + o * __SMAA_RT_METRICS.xy)).a)

#define __FXAA_MODE_NORMAL int(0)
#define __FXAA_MODE_SMAA_DETECTION_POSITIVES int(3)
#define __FXAA_MODE_SMAA_DETECTION_NEGATIVES int(4)

float4 FxaaAdaptiveLumaPixelShader(float2 pos, sampler2D tex, sampler2D edgestex, int pixelmode)
 {
	float4 SmaaPixel = tex2D(tex, pos);
    float4 rgbyM = FxaaTex2D(tex, pos);
	
	float2 edgedata = tex2D(edgestex, pos).rg;
	bool SMAAedge = (edgedata.r + edgedata.g) > 0.0;
	
	if ( SMAAedge && (pixelmode == __FXAA_MODE_SMAA_DETECTION_NEGATIVES)) return SmaaPixel;
	if (!SMAAedge && (pixelmode == __FXAA_MODE_SMAA_DETECTION_POSITIVES)) return SmaaPixel;
	
	// calculate the threshold
	float adjustmentrange = __FXAA_THRESHOLD_ADJUSTMENT_RANGE;
	
	float estimatedbrightness = (dotgamma(rgbyM) + max3(rgbyM.r, rgbyM.g, rgbyM.b)) * 0.5;
	float thresholdOffset = mad(estimatedbrightness, adjustmentrange, -adjustmentrange);
	
    float2 posM = pos;
	float lumaMa = FxaaAdaptiveLuma(rgbyM);
	float fxaaQualitySubpix = __HQAA_SUBPIX * sqrt(__HQAA_FXAA_SCAN_GRANULARITY) * __HQAA_BUFFER_MULTIPLIER;
	float fxaaQualityEdgeThreshold = __FXAA_EDGE_THRESHOLD + thresholdOffset;
	
    float lumaS = FxaaAdaptiveLuma(FxaaTex2DOffset(tex, posM, int2( 0, 1)));
    float lumaE = FxaaAdaptiveLuma(FxaaTex2DOffset(tex, posM, int2( 1, 0)));
    float lumaN = FxaaAdaptiveLuma(FxaaTex2DOffset(tex, posM, int2( 0,-1)));
    float lumaW = FxaaAdaptiveLuma(FxaaTex2DOffset(tex, posM, int2(-1, 0)));
    float lumaNW = FxaaAdaptiveLuma(FxaaTex2DOffset(tex, posM, int2(-1,-1)));
    float lumaSE = FxaaAdaptiveLuma(FxaaTex2DOffset(tex, posM, int2( 1, 1)));
    float lumaNE = FxaaAdaptiveLuma(FxaaTex2DOffset(tex, posM, int2( 1,-1)));
    float lumaSW = FxaaAdaptiveLuma(FxaaTex2DOffset(tex, posM, int2(-1, 1)));
	
    float rangeMax = max9(lumaS, lumaE, lumaN, lumaW, lumaNW, lumaSE, lumaNE, lumaSW, lumaMa);
    float rangeMin = min9(lumaS, lumaE, lumaN, lumaW, lumaNW, lumaSE, lumaNE, lumaSW, lumaMa);
	
    float range = rangeMax - rangeMin;
	
	bool earlyExit = (pixelmode != __FXAA_MODE_SMAA_DETECTION_POSITIVES) * (range < fxaaQualityEdgeThreshold);
	
	[branch]
	if (earlyExit)
		return SmaaPixel;
	else {
	
    float edgeHorz = abs(mad(-2.0, lumaW, lumaNW + lumaSW)) + mad(2.0, abs(mad(-2.0, lumaMa, lumaN + lumaS)), abs(mad(-2.0, lumaE, lumaNE + lumaSE)));
    float edgeVert = abs(mad(-2.0, lumaS, lumaSW + lumaSE)) + mad(2.0, abs(mad(-2.0, lumaMa, lumaW + lumaE)), abs(mad(-2.0, lumaN, lumaNW + lumaNE)));
	
    float lengthSign = BUFFER_RCP_WIDTH;
    bool horzSpan = edgeHorz >= edgeVert;
	
    float subpixOut = mad(2.0, lumaS + lumaE + lumaN + lumaW, lumaNW + lumaSE + lumaNE + lumaSW); // A
    subpixOut = saturate(abs(mad((1.0/12.0), subpixOut, -lumaMa)) * rcp(range)); // BC
    subpixOut = mad(-2.0, subpixOut, 3.0) * (subpixOut * subpixOut); // DEF
	subpixOut = (subpixOut * subpixOut) * fxaaQualitySubpix; // GH
	
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
	
    float2 posB = posM;
    float2 offNP;
	
    offNP.x = (!horzSpan) ? 0.0 : BUFFER_RCP_WIDTH;
    offNP.y = ( horzSpan) ? 0.0 : BUFFER_RCP_HEIGHT;
    if(!horzSpan) posB.x = mad(0.5, lengthSign, posB.x);
    else posB.y = mad(0.5, lengthSign, posB.y);
	
    float2 posN = posB - offNP;
    float2 posP = posB + offNP;
    
    float lumaEndN = FxaaAdaptiveLuma(FxaaTex2D(tex, posN));
    float lumaEndP = FxaaAdaptiveLuma(FxaaTex2D(tex, posP));
	
    float gradientScaled = max(abs(gradientN), abs(gradientS)) * 1.0/4.0;
    bool lumaMLTZero = mad(0.5, -lumaNN, lumaMa) < 0.0;
	
	float2 granularity = float2(__HQAA_FXAA_SCAN_GRANULARITY, __HQAA_FXAA_SCAN_GRANULARITY);
	
    lumaEndN = mad(0.5, -lumaNN, lumaEndN);
    lumaEndP = mad(0.5, -lumaNN, lumaEndP);
	
    bool doneN = abs(lumaEndN) >= gradientScaled;
    bool doneP = abs(lumaEndP) >= gradientScaled;
	
    if(!doneN) posN = mad(granularity, -offNP, posN);
    if(!doneP) posP = mad(granularity, offNP, posP);
	
	uint iterationsN = 0;
	uint iterationsP = 0;
	
	uint maxiterations = int(trunc(max(__FXAA_DEFAULT_SEARCH_STEPS * __HQAA_FXAA_SCAN_MULTIPLIER, __FXAA_MINIMUM_SEARCH_STEPS)));
	
	#if HQAA_ENABLE_FPS_TARGET
	if (frametime > __HQAA_DESIRED_FRAMETIME)
		maxiterations = int(trunc(max(__FXAA_MINIMUM_SEARCH_STEPS, __HQAA_FPS_CLAMP_MULTIPLIER * maxiterations)));
	#endif
	
	[fastopt] while (iterationsN < maxiterations && !doneN)
	{
		lumaEndN = FxaaAdaptiveLuma(FxaaTex2D(tex, posN.xy));
		lumaEndN = mad(0.5, -lumaNN, lumaEndN);
		doneN = abs(lumaEndN) >= gradientScaled;
        if (!doneN) posN = mad(granularity, -offNP, posN);
		iterationsN++;
    }
	
	[fastopt] while (iterationsP < maxiterations && !doneP)
	{
		lumaEndP = FxaaAdaptiveLuma(FxaaTex2D(tex, posP.xy));
		lumaEndP = mad(0.5, -lumaNN, lumaEndP);
		doneP = abs(lumaEndP) >= gradientScaled;
        if (!doneP) posP = mad(granularity, offNP, posP);
		iterationsP++;
    }
	
    float dstN = posM.x - posN.x;
    float dstP = posP.x - posM.x;
	
    if(!horzSpan) {
		dstN = posM.y - posN.y;
		dstP = posP.y - posM.y;
	}
	
    bool goodSpan = (dstN < dstP) ? ((lumaEndN < 0.0) != lumaMLTZero) : ((lumaEndP < 0.0) != lumaMLTZero);
    float pixelOffset = mad(-rcp(dstP + dstN), min(dstN, dstP), 0.5);
	
    float pixelOffsetGood = goodSpan ? pixelOffset : 0.0;

    float pixelOffsetSubpix = max(pixelOffsetGood, subpixOut);
	
    if(!horzSpan) posM.x = mad(lengthSign, pixelOffsetSubpix, posM.x);
    else posM.y = mad(lengthSign, pixelOffsetSubpix, posM.y);
	
	// Establish result
	float4 resultAA = float4(tex2D(tex, posM).rgb, lumaMa);
	resultAA.a = GetNewAlpha(SmaaPixel, resultAA);
	
	// fart the result
#if HQAA_COMPILE_DEBUG_CODE
	if (debugmode < 5)
	{
#endif
	return resultAA;
#if HQAA_COMPILE_DEBUG_CODE
	}
	else if (debugmode == 5) {
		return float4(lumaMa, lumaMa, lumaMa, lumaMa);
	}
	else {
		float runtime = (float(iterationsN / maxiterations) + float(iterationsP / maxiterations)) / 2.0;
		float4 FxaaMetrics = float4(runtime, 1.0 - runtime, 0.0, 1.0);
		return FxaaMetrics;
	}
#endif
	}
}

/***************************************************************************************************************************************/
/*********************************************************** FXAA CODE BLOCK END *******************************************************/
/***************************************************************************************************************************************/

/***************************************************************************************************************************************/
/*********************************************************** SHADER CODE START *********************************************************/
/***************************************************************************************************************************************/

#include "ReShade.fxh"


//////////////////////////////////////////////////////////// TEXTURES ///////////////////////////////////////////////////////////////////

texture HQAAedgesTex
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = BUFFER_COLOR_BIT_DEPTH;
};

texture HQAAblendTex
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = BUFFER_COLOR_BIT_DEPTH;
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
	Format = BUFFER_COLOR_BIT_DEPTH;
};
#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER
#endif

//////////////////////////////////////////////////////////// SAMPLERS ///////////////////////////////////////////////////////////////////

sampler HQAAsamplerBufferGamma
{
	Texture = ReShade::BackBufferTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};

sampler HQAAsamplerBufferSRGB
{
	Texture = ReShade::BackBufferTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
#if HQAA_ENABLE_HDR_OUTPUT
	SRGBTexture = false;
#else
	SRGBTexture = true;
#endif
};

sampler HQAAsamplerAlphaEdges
{
	Texture = HQAAedgesTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};

sampler HQAAsamplerSMweights
{
	Texture = HQAAblendTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};

sampler HQAAsamplerSMarea
{
	Texture = HQAAareaTex;
	AddressU = Clamp; AddressV = Clamp; AddressW = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};

sampler HQAAsamplerSMsearch
{
	Texture = HQAAsearchTex;
	AddressU = Clamp; AddressV = Clamp; AddressW = Clamp;
	MipFilter = Point; MinFilter = Point; MagFilter = Point;
	SRGBTexture = false;
};

#if HQAA_ENABLE_OPTIONAL_TECHNIQUES
#if HQAA_OPTIONAL_TEMPORAL_STABILIZER
sampler HQAAsamplerLastFrame
{
	Texture = HQAAstabilizerTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER
#endif

//////////////////////////////////////////////////////////// VERTEX SHADERS /////////////////////////////////////////////////////////////

void HQAAEdgeDetectionWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float4 offset[3] : TEXCOORD1)
{
	PostProcessVS(id, position, texcoord);
	HQAAEdgeDetectionVS(texcoord, offset);
}


void HQAABlendingWeightCalculationWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float2 pixcoord : TEXCOORD1,
	out float4 offset[3] : TEXCOORD2)
{
	PostProcessVS(id, position, texcoord);
	HQAABlendingWeightCalculationVS(texcoord, pixcoord, offset);
}


void HQAANeighborhoodBlendingWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float4 offset : TEXCOORD1)
{
	PostProcessVS(id, position, texcoord);
	HQAANeighborhoodBlendingVS(texcoord, offset);
}

//////////////////////////////////////////////////////////// PIXEL SHADERS //////////////////////////////////////////////////////////////

float4 GenerateNormalizedLumaDataPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 pixel = tex2D(HQAAsamplerBufferGamma, texcoord);
	float rgbluma = dotgamma(pixel);
	pixel.a = lerp(rgbluma, pixel.a, rgbluma);
	return float4(0.0, 0.0, 0.0, pixel.a);
}


float4 GenerateBufferNormalizedAlphaPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 pixel = tex2D(HQAAsamplerBufferGamma, texcoord);
	float rgbluma = dotgamma(pixel);
	pixel.a = lerp(rgbluma, pixel.a, rgbluma);
	return pixel;
}


float4 GenerateImageColorShiftLeftPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 input = tex2D(HQAAsamplerBufferGamma, texcoord);
	float4 output = float4(input.g, input.b, input.r, input.a);
	input.a = dotgamma(output);
	output.a = lerp(input.a, output.a, input.a);
	return output;
}


float4 GenerateImageColorShiftRightPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 input = tex2D(HQAAsamplerBufferGamma, texcoord);
	float4 output = float4(input.b, input.r, input.g, input.a);
	input.a = dotgamma(output);
	output.a = lerp(input.a, output.a, input.a);
	return output;
}

float4 GenerateImageCopyPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return tex2D(HQAAsamplerBufferGamma, texcoord);
}

float2 HQAAEdgeDetectionPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float4 offset[3] : TEXCOORD1) : SV_Target
{
	return HQAALumaEdgeDetectionPS(texcoord, offset, HQAAsamplerSMweights);
}

float2 HQAABufferDetectionPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float4 offset[3] : TEXCOORD1) : SV_Target
{
	return HQAALumaEdgeDetectionPS(texcoord, offset, HQAAsamplerBufferGamma);
}


float4 HQAABlendingWeightCalculationWrapPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float2 pixcoord : TEXCOORD1,
	float4 offset[3] : TEXCOORD2) : SV_Target
{
	return HQAABlendingWeightCalculationPS(texcoord, pixcoord, offset, HQAAsamplerAlphaEdges, HQAAsamplerSMarea, HQAAsamplerSMsearch, 0.0);
}


float4 HQAANeighborhoodBlendingWrapPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float4 offset : TEXCOORD1) : SV_Target
{
	float4 result = HQAANeighborhoodBlendingPS(texcoord, offset, HQAAsamplerBufferSRGB, HQAAsamplerSMweights);
	
#if !HQAA_ENABLE_HDR_OUTPUT
	result = saturate(result);
#endif
	return result;
}


float4 FXAADetectionPositivesPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 result = FxaaAdaptiveLumaPixelShader(texcoord, HQAAsamplerBufferGamma, HQAAsamplerAlphaEdges, __FXAA_MODE_SMAA_DETECTION_POSITIVES);
	
#if HQAA_COMPILE_DEBUG_CODE
	if (debugmode > 3 && debugFXAApass == 0) {
		bool validResult = dot(abs(result - tex2D(HQAAsamplerBufferGamma, texcoord)), float4(1.0, 1.0, 1.0, 1.0)) > 1e-5;
		if (!validResult)
			return float4(0.0, 0.0, 0.0, 0.0);
	}
#endif
#if !HQAA_ENABLE_HDR_OUTPUT
	result = saturate(result);
#endif
	return result;
}


float4 FXAADetectionNegativesPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	// debugs 1, 2, 3, 4 need to output from the last pass in the technique
#if HQAA_COMPILE_DEBUG_CODE
	if (debugmode != 0) {
	if (debugmode == 1)
		return float4(tex2D(HQAAsamplerAlphaEdges, texcoord).rg, 0.0, 1.0);
	if (debugmode == 2)
		return tex2D(HQAAsamplerSMweights, texcoord);
	if (debugmode == 3)
		return float4(tex2D(HQAAsamplerAlphaEdges, texcoord).a, 0.0, 0.0, 1.0);
	}
#endif
		
	float4 result = FxaaAdaptiveLumaPixelShader(texcoord, HQAAsamplerBufferGamma, HQAAsamplerAlphaEdges, __FXAA_MODE_SMAA_DETECTION_NEGATIVES);
	
#if HQAA_COMPILE_DEBUG_CODE
	if (debugmode > 3 && debugFXAApass == 1) {
		bool validResult = dot(abs(result - tex2D(HQAAsamplerBufferGamma, texcoord)), float4(1.0, 1.0, 1.0, 1.0)) > 1e-5;
		if (!validResult)
			return float4(0.0, 0.0, 0.0, 0.0);
	}
#endif
#if !HQAA_ENABLE_HDR_OUTPUT
	result = saturate(result);
#endif
	return result;
}


#if HQAA_ENABLE_OPTIONAL_TECHNIQUES

#if HQAA_OPTIONAL_CAS
float4 HQAACASOptionalPS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 result = HQAACASPS(texcoord, HQAAsamplerAlphaEdges, HQAAsamplerBufferSRGB);
#if HQAA_COMPILE_DEBUG_CODE
    if (HqaaSharpenerDebug) result = abs(result - tex2D(HQAAsamplerBufferSRGB, texcoord));
#endif
#if !HQAA_ENABLE_HDR_OUTPUT
	result = saturate(result);
#endif
	return result;
}
#endif //HQAA_OPTIONAL_CAS

#if HQAA_OPTIONAL_TEMPORAL_STABILIZER
float4 HQAATemporalStabilizerWrapPS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 result = HQAATemporalStabilizerPS(HQAAsamplerBufferGamma, HQAAsamplerLastFrame, texcoord);
#if !HQAA_ENABLE_HDR_OUTPUT
	result = saturate(result);
#endif
	return result;
}
#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER

#if HQAA_OPTIONAL_BRIGHTNESS_GAIN
float4 HQAAColorChannelCompressionWrapPS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 result = HQAAColorChannelCompressionPS(HQAAsamplerBufferGamma, texcoord);
#if !HQAA_ENABLE_HDR_OUTPUT
	result = saturate(result);
#endif
	return result;
}
#endif //HQAA_OPTIONAL_BRIGHTNESS_GAIN
#endif // HQAA_ENABLE_OPTIONAL_TECHNIQUES

/***************************************************************************************************************************************/
/*********************************************************** SHADER CODE END ***********************************************************/
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
	pass BufferDetection
	{
		VertexShader = HQAAEdgeDetectionWrapVS;
		PixelShader = HQAABufferDetectionPS;
		RenderTarget = HQAAedgesTex;
		ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = REPLACE;
		StencilRef = 1;
	}
	pass CreateBufferAlphaNormal
	{
		VertexShader = PostProcessVS;
		PixelShader = GenerateBufferNormalizedAlphaPS;
		RenderTarget = HQAAblendTex;
		ClearRenderTargets = true;
	}
	pass NormalizedBufferEdgeDetection
	{
		VertexShader = HQAAEdgeDetectionWrapVS;
		PixelShader = HQAAEdgeDetectionPS;
		RenderTarget = HQAAedgesTex;
		ClearRenderTargets = false;
		BlendEnable = true;
		BlendOp = MAX;
		BlendOpAlpha = MAX;
		StencilEnable = true;
		StencilPass = REPLACE;
		StencilRef = 1;
	}
	pass CreateBufferColorShiftRight
	{
		VertexShader = PostProcessVS;
		PixelShader = GenerateImageColorShiftRightPS;
		RenderTarget = HQAAblendTex;
		ClearRenderTargets = true;
	}
	pass RightShiftEdgeDetection
	{
		VertexShader = HQAAEdgeDetectionWrapVS;
		PixelShader = HQAAEdgeDetectionPS;
		RenderTarget = HQAAedgesTex;
		ClearRenderTargets = false;
		BlendEnable = true;
		BlendOp = MAX;
		BlendOpAlpha = MAX;
		StencilEnable = true;
		StencilPass = REPLACE;
		StencilRef = 1;
	}
	pass CreateBufferColorShiftLeft
	{
		VertexShader = PostProcessVS;
		PixelShader = GenerateImageColorShiftLeftPS;
		RenderTarget = HQAAblendTex;
		ClearRenderTargets = true;
	}
	pass LeftShiftEdgeDetection
	{
		VertexShader = HQAAEdgeDetectionWrapVS;
		PixelShader = HQAAEdgeDetectionPS;
		RenderTarget = HQAAedgesTex;
		ClearRenderTargets = false;
		BlendEnable = true;
		BlendOp = MAX;
		BlendOpAlpha = MAX;
		StencilEnable = true;
		StencilPass = REPLACE;
		StencilRef = 1;
	}
	pass SMAABlendCalculation
	{
		VertexShader = HQAABlendingWeightCalculationWrapVS;
		PixelShader = HQAABlendingWeightCalculationWrapPS;
		RenderTarget = HQAAblendTex;
		ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = KEEP;
		StencilFunc = EQUAL;
		StencilRef = 1;
	}
	pass SMAABlending
	{
		VertexShader = HQAANeighborhoodBlendingWrapVS;
		PixelShader = HQAANeighborhoodBlendingWrapPS;
		StencilEnable = false;
#if HQAA_ENABLE_HDR_OUTPUT
		SRGBWriteEnable = false;
#else
		SRGBWriteEnable = true;
#endif
	}
	pass GenerateFXAALumaData
	{
		VertexShader = PostProcessVS;
		PixelShader = GenerateNormalizedLumaDataPS;
		RenderTarget = HQAAedgesTex;
		ClearRenderTargets = false;
		BlendEnable = true;
		SrcBlend = ZERO;
		SrcBlendAlpha = ONE;
		DestBlend = ONE;
		DestBlendAlpha = ZERO;
	}
	pass FXAAPositives
	{
		VertexShader = PostProcessVS;
		PixelShader = FXAADetectionPositivesPS;
	}
	pass FXAANegatives
	{
		VertexShader = PostProcessVS;
		PixelShader = FXAADetectionNegativesPS;
	}
#if HQAA_ENABLE_OPTIONAL_TECHNIQUES

#if HQAA_OPTIONAL_CAS
	pass CAS
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAACASOptionalPS;
#if HQAA_ENABLE_HDR_OUTPUT
		SRGBWriteEnable = false;
#else
		SRGBWriteEnable = true;
#endif
	}
#endif //HQAA_OPTIONAL_CAS

#if HQAA_OPTIONAL_TEMPORAL_STABILIZER
	pass StabilizeResults
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAATemporalStabilizerWrapPS;
	}
	pass SaveBuffer
	{
		VertexShader = PostProcessVS;
		PixelShader = GenerateImageCopyPS;
		RenderTarget = HQAAstabilizerTex;
		ClearRenderTargets = true;
	}
#endif //HQAA_OPTIONAL_TEMPORAL_STABILIZER

#if HQAA_OPTIONAL_BRIGHTNESS_GAIN
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAColorChannelCompressionWrapPS;
	}
#endif //HQAA_OPTIONAL_BRIGHTNESS_GAIN
#endif // HQAA_ENABLE_OPTIONAL_TECHNIQUES
}
