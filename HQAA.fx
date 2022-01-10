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
 *                        v10.0
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

uniform int HQAAintroduction <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\nHybrid high-Quality Anti-Aliasing, a shader by lordbean\n"
	          "Version: 10.0\n"
			  "https://github.com/lordbean-git/HQAA/\n";
	ui_tooltip = "No 3090s were harmed in the making of this shader.";
>;

uniform uint FramerateFloor < __UNIFORM_SLIDER_INT1
	ui_min = 30; ui_max = 120; ui_step = 1;
	ui_label = "Target Minimum Framerate";
	ui_tooltip = "HQAA will automatically reduce FXAA sampling quality if\nthe framerate drops below this number";
> = 75;

uniform int preset <
	ui_type = "combo";
	ui_label = "Quality Preset\n\n";
	ui_tooltip = "For quick start use, pick a preset. If you'd prefer to fine tune, select Custom.";
	ui_category = "Presets";
	ui_items = "Potato\0Low\0Medium\0High\0Ultra\0GLaDOS\0Custom\0";
	ui_text = "\n";
> = 3;

uniform int presetbreakdown <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n"
	          "|--Preset|-Threshold---Subpix---Sharpen?---Corners---Quality---Texel-|\n"
	          "|--------|-----------|--------|----------|---------|---------|-------|\n"
	          "|  Potato|   0.400   |  .125  |    No    |    0%   |   0.1   |  4.0  |\n"
			  "|     Low|   0.250   |  .250  |    No    |    0%   |   0.2   |  2.0  |\n"
			  "|  Medium|   0.150   |  .375  |    No    |    0%   |   0.5   |  1.0  |\n"
			  "|    High|   0.100   |  .625  |   Auto   |    0%   |   1.0   |  0.5  |\n"
			  "|   Ultra|   0.063   |  .875  |   Auto   |    0%   |   1.2   |  0.2  |\n"
			  "|  GLaDOS|   0.031   |  1.00  |   Auto   |    0%   |   1.5   |  0.1  |\n"
			  "-----------------------------------------------------------------------------";
	ui_category = "Click me to see what settings each preset uses!";
	ui_category_closed = true;
>;

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

uniform bool SharpenEnableCustom <
	ui_label = "Enable sharpening of anti-aliasing results?";
	ui_tooltip = "When enabled, HQAA will run CAS on FXAA and SMAA outputs";
	ui_category = "Custom Preset";
	ui_category_closed = true;
> = true;

uniform int SharpenAdaptiveCustom <
	ui_type = "radio";
	ui_items = "Automatic\0Manual\0";
	ui_label = "Sharpening Mode";
	ui_tooltip = "Automatic sharpening = HQAA will try to guess what amount\nof sharpening will look good on a per-pixel basis.\n\nManual sharpening = HQAA will always apply the\nsame amount of sharpening.";
	ui_category = "Custom Preset";
	ui_category_closed = true;
> = 0;

uniform float SharpenAmountCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.000; ui_max = 1.000; ui_step = 0.005;
	ui_label = "Sharpening Amount";
	ui_tooltip = "Set the amount of manual sharpening to apply to anti-aliasing results";
	ui_category = "Custom Preset";
	ui_category_closed = true;
> = 0;

uniform float SmaaCorneringCustom < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "SMAA Corner Rounding";
	ui_tooltip = "Affects the amount of blending performed when SMAA\ndetects crossing edges";
    ui_category = "Custom Preset";
	ui_category_closed = true;
	ui_text = "\n------------------------------- SMAA Options -----------------------------------\n ";
> = 20;

uniform float FxaaIterationsCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 5; ui_step = 0.01;
	ui_label = "Quality Multiplier";
	ui_tooltip = "Multiplies the maximum number of edge gradient\nscanning iterations that FXAA will perform";
    ui_category = "Custom Preset";
	ui_category_closed = true;
	ui_text = "\n------------------------------- FXAA Options -----------------------------------\n ";
> = 0.5;

uniform float FxaaTexelSizeCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.025; ui_max = 4.0; ui_step = 0.005;
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
	ui_text = "\nDebug Mode:";
	ui_items = "Off\0Detected Edges\0SMAA Blend Weights\0FXAA results:\0FXAA lumas:\0";
> = 0;

uniform uint debugFXAApass <
	ui_type = "radio";
	ui_category = "Debug";
	ui_category_closed = true;
	ui_label = " ";
	ui_text = "-----------------";
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
			  "FXAA lumas shows which color channel FXAA decided to use to\n"
			  "represent the brightness of the pixel.\n\n"
			  "Debug checks can optionally be excluded from the compiled shader\n"
			  "by setting HQAA_INCLUDE_DEBUG_CODE to 0.\n"
	          "----------------------------------------------------------------";
	ui_category = "Debug";
	ui_category_closed = true;
>;

uniform float HqaaSharpenerStrength < __UNIFORM_SLIDER_FLOAT1
	ui_spacing = 5;
	ui_min = 0; ui_max = 10; ui_step = 0.1;
	ui_label = "Sharpening Strength";
	ui_tooltip = "Amount of sharpening to apply";
	ui_category = "Optional Sharpening (HQAACAS)";
	ui_category_closed = true;
> = 1.5;

uniform int sharpenerintro <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\nHQAA can optionally run Contrast-Adaptive Sharpening very similar to CAS.fx.\n"
	          "The advantage to using the technique built into HQAA is that it uses edge\n"
			  "data generated by the anti-aliasing technique to adjust the amount of sharpening\n"
			  "applied to areas that were processed to remove aliasing.\n\n"
			  "This feature is enabled or disabled in the ReShade effects list.";
	ui_category = "Optional Sharpening (HQAACAS)";
	ui_category_closed = true;
>;

uniform float frametime < source = "frametime"; >;

static const float HQAA_THRESHOLD_PRESET[7] = {0.4,0.25,0.15,0.1,0.0625,0.03125,1};
static const float HQAA_SUBPIX_PRESET[7] = {0.125,0.25,0.375,0.625,0.875,1.0,0};
static const bool HQAA_SHARPEN_ENABLE_PRESET[7] = {false,false,false,true,true,true,false};
static const float HQAA_SHARPEN_STRENGTH_PRESET[7] = {0,0,0,0,0,0,0};
static const int HQAA_SHARPEN_MODE_PRESET[7] = {0,0,0,0,0,0,0};
static const float HQAA_SMAA_CORNER_ROUNDING_PRESET[7] = {0,0,0,0,0,0,0};
static const float HQAA_FXAA_SCANNING_MULTIPLIER_PRESET[7] = {0.1,0.2,0.5,1.0,1.2,1.5,0};
static const float HQAA_FXAA_TEXEL_SIZE_PRESET[7] = {4,2,1,0.5,0.2,0.1,4};

#define __HQAA_EDGE_THRESHOLD (preset == 6 ? (EdgeThresholdCustom) : (HQAA_THRESHOLD_PRESET[preset]))
#define __HQAA_SUBPIX (preset == 6 ? (SubpixCustom) : (HQAA_SUBPIX_PRESET[preset]))
#define __HQAA_SHARPEN_ENABLE (preset == 6 ? (SharpenEnableCustom) : (HQAA_SHARPEN_ENABLE_PRESET[preset]))
#define __HQAA_SHARPEN_AMOUNT (preset == 6 ? (SharpenAmountCustom) : (HQAA_SHARPEN_STRENGTH_PRESET[preset]))
#define __HQAA_SHARPEN_MODE (preset == 6 ? (SharpenAdaptiveCustom) : (HQAA_SHARPEN_MODE_PRESET[preset]))
#define __HQAA_SMAA_CORNERING (preset == 6 ? (SmaaCorneringCustom) : (HQAA_SMAA_CORNER_ROUNDING_PRESET[preset]))
#define __HQAA_FXAA_SCAN_MULTIPLIER (preset == 6 ? (FxaaIterationsCustom) : (HQAA_FXAA_SCANNING_MULTIPLIER_PRESET[preset]))
#define __HQAA_FXAA_SCAN_GRANULARITY (preset == 6 ? (FxaaTexelSizeCustom) : (HQAA_FXAA_TEXEL_SIZE_PRESET[preset]))
#define __FXAA_THRESHOLD_FLOOR 0.0050
#define __SMAA_THRESHOLD_FLOOR 0.0025
#define __HQAA_DISPLAY_DENOMINATOR min(BUFFER_HEIGHT, BUFFER_WIDTH)
#define __HQAA_DISPLAY_NUMERATOR max(BUFFER_HEIGHT, BUFFER_WIDTH)
#define __HQAA_BUFFER_MULTIPLIER (__HQAA_DISPLAY_DENOMINATOR / 2160)
#define __HQAA_DESIRED_FRAMETIME float(1000 / FramerateFloor)

#define __HQAA_LUMA_REFERENCE float4(0.3,0.3,0.3,0.1)

#define dotluma(x) ((0.3 * x.r) + (0.3 * x.g) + (0.3 * x.b) + (0.1 * x.a))
#define vec4add(x) (x.r + x.g + x.b + x.a)

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


#ifndef HDR_BACKBUFFER_IS_LINEAR
	#define HDR_BACKBUFFER_IS_LINEAR 0
#endif

#ifndef HDR_DISPLAY_NITS
	#define HDR_DISPLAY_NITS 1000.0f
#endif

#ifndef HQAA_INCLUDE_DEBUG_CODE
	#define HQAA_INCLUDE_DEBUG_CODE 1
#endif


/*****************************************************************************************************************************************/
/*********************************************************** UI SETUP END ****************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/********************************************************* RESULT SHARPENER START ********************************************************/
/*****************************************************************************************************************************************/

float3 Sharpen(float2 texcoord, sampler2D sTexColor, float4 AAresult, float threshold, float subpix)
{
	// calculate sharpening parameters
	float sharpening = __HQAA_SHARPEN_AMOUNT;
	#if HDR_BACKBUFFER_IS_LINEAR
		float4 e = AAresult * (1 / HDR_DISPLAY_NITS);
	#else
		float4 e = AAresult;
	#endif
	
	if (__HQAA_SHARPEN_MODE == 0) {
		float strongestcolor = max3(e.r, e.g, e.b);
		#if HDR_BACKBUFFER_IS_LINEAR
			strongestcolor *= (1 / HDR_DISPLAY_NITS);
		#endif
		float brightness = mad(strongestcolor, e.a, -0.375);
		sharpening = brightness * (1 - threshold);
	}
	
	// exit if the pixel doesn't seem to warrant sharpening
	if (sharpening <= 0)
		return AAresult.rgb;
	else {
	
	// proceed with CAS math
	// we're doing a fast version that only uses immediate neighbors
	
    float3 b = tex2Doffset(sTexColor, texcoord, int2(0, -1)).rgb;
    float3 d = tex2Doffset(sTexColor, texcoord, int2(-1, 0)).rgb;
    float3 f = tex2Doffset(sTexColor, texcoord, int2(1, 0)).rgb;
    float3 h = tex2Doffset(sTexColor, texcoord, int2(0, 1)).rgb;

	float3 mnRGB = min5(d, AAresult.rgb, f, b, h);
	float3 mxRGB = max5(d, AAresult.rgb, f, b, h);
	#if HDR_BACKBUFFER_IS_LINEAR
	mnRGB *= (1 / HDR_DISPLAY_NITS);
	mxRGB *= (1 / HDR_DISPLAY_NITS);
	#endif

    float3 rcpMRGB = rcp(mxRGB);
    float3 ampRGB = saturate(min(mnRGB, 2.0 - mxRGB) * rcpMRGB);
    
    ampRGB = rsqrt(ampRGB);
    
    float3 wRGB = -rcp(ampRGB * 8);

    float3 rcpWeightRGB = rcp(mad(4, wRGB, 1));

    float3 window = (b + d) + (f + h);
	#if HDR_BACKBUFFER_IS_LINEAR
	window *= (1 / HDR_DISPLAY_NITS);
	#endif
    float3 outColor = saturate(mad(window, wRGB, e.rgb) * rcpWeightRGB);
    
	#if HDR_BACKBUFFER_IS_LINEAR
	return lerp(AAresult.rgb, outColor, sharpening) * HDR_DISPLAY_NITS;
	#else
	return lerp(AAresult.rgb, outColor, sharpening);
	#endif
	}
}

/*****************************************************************************************************************************************/
/******************************************************* RESULT SHARPENER END ************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/******************************************************* OPTIONAL CAS START **************************************************************/
/*****************************************************************************************************************************************/

float3 HQAACASPS(float2 texcoord, sampler2D edgesTex, sampler2D sTexColor)
{
	float sharpenmultiplier = (1 - sqrt(__HQAA_EDGE_THRESHOLD)) * (sqrt(__HQAA_SUBPIX));
	
	if (__HQAA_SHARPEN_ENABLE == true) {
		float2 edgesdetected = tex2D(edgesTex, texcoord).rg;
		if (dot(edgesdetected, float2(1.0, 1.0)) != 0)
			sharpenmultiplier *= 0.25;
	}
	
	// set sharpening amount
	float sharpening = HqaaSharpenerStrength * sharpenmultiplier;
	
	// proceed with CAS math.
	
    float3 a = tex2Doffset(sTexColor, texcoord, int2(-1, -1)).rgb;
    float3 b = tex2Doffset(sTexColor, texcoord, int2(0, -1)).rgb;
    float3 c = tex2Doffset(sTexColor, texcoord, int2(1, -1)).rgb;
    float3 d = tex2Doffset(sTexColor, texcoord, int2(-1, 0)).rgb;
    float3 e = tex2D(sTexColor, texcoord).rgb;
    float3 f = tex2Doffset(sTexColor, texcoord, int2(1, 0)).rgb;
    float3 g = tex2Doffset(sTexColor, texcoord, int2(-1, 1)).rgb;
    float3 h = tex2Doffset(sTexColor, texcoord, int2(0, 1)).rgb;
    float3 i = tex2Doffset(sTexColor, texcoord, int2(1, 1)).rgb;

	float3 mnRGB = min5(d, e, f, b, h);
	float3 mnRGB2 = min5(mnRGB, a, c, g, i);
    mnRGB += mnRGB2;

	float3 mxRGB = max5(d,e,f,b,h);
	float3 mxRGB2 = max5(mxRGB,a,c,g,i);
    mxRGB += mxRGB2;
	
	#if HDR_BACKBUFFER_IS_LINEAR
	mnRGB *= (1 / HDR_DISPLAY_NITS);
	mxRGB *= (1 / HDR_DISPLAY_NITS);
	e *= (1 / HDR_DISPLAY_NITS);
	#endif

    float3 rcpMRGB = rcp(mxRGB);
    float3 ampRGB = saturate(min(mnRGB, 2.0 - mxRGB) * rcpMRGB);    
    
    ampRGB = rsqrt(ampRGB);
    
    float3 wRGB = -rcp(ampRGB * 8);

    float3 rcpWeightRGB = rcp(mad(4, wRGB, 1));

    float3 window = (b + d) + (f + h);
	#if HDR_BACKBUFFER_IS_LINEAR
	window *= (1 / HDR_DISPLAY_NITS);
	#endif
	
    float3 outColor = saturate(mad(window, wRGB, e) * rcpWeightRGB);
    
	#if HDR_BACKBUFFER_IS_LINEAR
	return lerp(e, outColor, sharpening) * HDR_DISPLAY_NITS;
	#else
	return lerp(e, outColor, sharpening);
	#endif
}

/*****************************************************************************************************************************************/
/********************************************************** OPTIONAL CAS END *************************************************************/
/*****************************************************************************************************************************************/


/*****************************************************************************************************************************************/
/*********************************************************** SMAA CODE BLOCK START *******************************************************/
/*****************************************************************************************************************************************/

// DX11 optimization
#if (__RENDERER__ == 0xb000 || __RENDERER__ == 0xb100)
	#define SMAAGather(tex, coord) tex2Dgather(tex, coord, 0)
#endif

// Configurable
#define __SMAA_MAX_SEARCH_STEPS 112
#define __SMAA_CORNER_ROUNDING (__HQAA_SMAA_CORNERING)
#define __SMAA_EDGE_THRESHOLD max(__HQAA_EDGE_THRESHOLD, __SMAA_THRESHOLD_FLOOR)
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
#define __SMAA_AREATEX_SUBTEX_SIZE (1.0 / 7.0)
#define __SMAA_SEARCHTEX_SIZE float2(66.0, 33.0)
#define __SMAA_SEARCHTEX_PACKED_SIZE float2(64.0, 16.0)
#define __SMAA_CORNER_ROUNDING_NORM (float(__SMAA_CORNER_ROUNDING) / 100.0)

/**
 * Conditional move:
 */
void SMAAMovc(bool2 cond, inout float2 variable, float2 value) {
    __SMAA_FLATTEN if (cond.x) variable.x = value.x;
    __SMAA_FLATTEN if (cond.y) variable.y = value.y;
}

void SMAAMovc(bool4 cond, inout float4 variable, float4 value) {
    SMAAMovc(cond.xy, variable.xy, value.xy);
    SMAAMovc(cond.zw, variable.zw, value.zw);
}

void SMAAEdgeDetectionVS(float2 texcoord,
                         out float4 offset[3]) {
    offset[0] = mad(__SMAA_RT_METRICS.xyxy, float4(-1.0, 0.0, 0.0, -1.0), texcoord.xyxy);
    offset[1] = mad(__SMAA_RT_METRICS.xyxy, float4( 1.0, 0.0, 0.0,  1.0), texcoord.xyxy);
    offset[2] = mad(__SMAA_RT_METRICS.xyxy, float4(-2.0, 0.0, 0.0, -2.0), texcoord.xyxy);
}


void SMAABlendingWeightCalculationVS(float2 texcoord,
                                     out float2 pixcoord,
                                     out float4 offset[3]) {
    pixcoord = texcoord * __SMAA_RT_METRICS.zw;

    offset[0] = mad(__SMAA_RT_METRICS.xyxy, float4(-0.25, -0.125,  1.25, -0.125), texcoord.xyxy);
    offset[1] = mad(__SMAA_RT_METRICS.xyxy, float4(-0.125, -0.25, -0.125,  1.25), texcoord.xyxy);

    offset[2] = mad(__SMAA_RT_METRICS.xxyy,
                    float4(-2.0, 2.0, -2.0, 2.0) * float(__SMAA_MAX_SEARCH_STEPS),
                    float4(offset[0].xz, offset[1].yw));
}


void SMAANeighborhoodBlendingVS(float2 texcoord,
                                out float4 offset) {
    offset = mad(__SMAA_RT_METRICS.xyxy, float4( 1.0, 0.0, 0.0,  1.0), texcoord.xyxy);
}

/**
 * IMPORTANT NOTICE: luma edge detection requires gamma-corrected colors, and
 * thus 'colorTex' should be a non-sRGB texture.
 */
float2 SMAALumaEdgeDetectionPS(float2 texcoord,
                               float4 offset[3],
                               sampler2D colorTex
                               ) {
	float4 middle = tex2D(colorTex, texcoord);
	
	// calculate the threshold
	float adjustmentrange = (__SMAA_EDGE_THRESHOLD - __SMAA_THRESHOLD_FLOOR) * __HQAA_SUBPIX * 0.875;
	
	float4 middlenormal = middle * __HQAA_LUMA_REFERENCE;
	middlenormal *= rcp(vec4add(middlenormal));
	
	float strongestcolor = max3(middle.r,middle.g,middle.b);
	float estimatedgamma = dotluma(middlenormal);
	float estimatedbrightness = (strongestcolor + estimatedgamma) * 0.5;
	float thresholdOffset = mad(estimatedbrightness, adjustmentrange, -adjustmentrange);
	
	float weightedthreshold = __SMAA_EDGE_THRESHOLD + thresholdOffset;
	
	float2 threshold = float2(weightedthreshold, weightedthreshold);
	
	// calculate color channel weighting
	float4 weights = float4(0.26, 0.39, 0.24, 0.11);
	weights *= middle;
	float scale = rcp(vec4add(weights));
	weights *= scale;
	
	// we're only looking to run luma detection if there's a favorable color channel read
	bool runLumaDetection = (weights.r + weights.g) > (weights.b + weights.a);
	float2 edges = float2(0,0);
	
	if (runLumaDetection) {
		
	
    float L = dot(middle, weights);

    float Lleft = dot(tex2D(colorTex, offset[0].xy), weights);
    float Ltop  = dot(tex2D(colorTex, offset[0].zw), weights);

    float4 delta;
    delta.xy = abs(L - float2(Lleft, Ltop));
    edges = step(threshold, delta.xy);
	
	if (dot(edges, float2(1,1)) != 0) {
		
	// calculate contrast multiplier. scale has a floor value of 0.25 on a pure bright white pixel
	float adaptationscale = saturate(scale * scale);
	float contrastadaptation = 1 + adaptationscale;

    float Lright = dot(tex2D(colorTex, offset[1].xy), weights);
    float Lbottom  = dot(tex2D(colorTex, offset[1].zw), weights);
    delta.zw = abs(L - float2(Lright, Lbottom));

    float2 maxDelta = max(delta.xy, delta.zw);

    float Lleftleft = dot(tex2D(colorTex, offset[2].xy), weights);
    float Ltoptop = dot(tex2D(colorTex, offset[2].zw), weights);
    delta.zw = abs(float2(Lleft, Ltop) - float2(Lleftleft, Ltoptop));

    maxDelta = max(maxDelta.xy, delta.zw);
    float finalDelta = max(maxDelta.x, maxDelta.y);

	edges.xy *= step(finalDelta, contrastadaptation * delta.xy);
	}
	}
    return edges;
}

/**
 * Allows to decode two binary values from a bilinear-filtered access.
 */
float2 SMAADecodeDiagBilinearAccess(float2 e) {
    e.r = e.r * abs(5.0 * e.r - 5.0 * 0.75);
    return round(e);
}

float4 SMAADecodeDiagBilinearAccess(float4 e) {
    e.rb = e.rb * abs(5.0 * e.rb - 5.0 * 0.75);
    return round(e);
}


float2 SMAASearchDiag1(sampler2D HQAAedgesTex, float2 texcoord, float2 dir, out float2 e) {
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

float2 SMAASearchDiag2(sampler2D HQAAedgesTex, float2 texcoord, float2 dir, out float2 e) {
    float4 coord = float4(texcoord, -1.0, 1.0);
    coord.x += 0.25 * __SMAA_RT_METRICS.x;
    float3 t = float3(__SMAA_RT_METRICS.xy, 1.0);
    while (coord.z < float(__SMAA_MAX_SEARCH_STEPS_DIAG - 1) &&
           coord.w > 0.9) {
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);

        e = __SMAASampleLevelZero(HQAAedgesTex, coord.xy).rg;
        e = SMAADecodeDiagBilinearAccess(e);

        coord.w = dot(e, float2(0.5, 0.5));
    }
    return coord.zw;
}

/** 
 * Similar to SMAAArea, this calculates the area corresponding to a certain
 * diagonal distance and crossing edges 'e'.
 */
float2 SMAAAreaDiag(sampler2D HQAAareaTex, float2 dist, float2 e, float offset) {
    float2 texcoord = mad(float2(__SMAA_AREATEX_MAX_DISTANCE_DIAG, __SMAA_AREATEX_MAX_DISTANCE_DIAG), e, dist);

    texcoord = mad(__SMAA_AREATEX_PIXEL_SIZE, texcoord, 0.5 * __SMAA_AREATEX_PIXEL_SIZE);
    texcoord.x += 0.5;
    texcoord.y += __SMAA_AREATEX_SUBTEX_SIZE * offset;

    return __SMAASampleLevelZero(HQAAareaTex, texcoord).rg;
}

/**
 * This searches for diagonal patterns and returns the corresponding weights.
 */
float2 SMAACalculateDiagWeights(sampler2D HQAAedgesTex, sampler2D HQAAareaTex, float2 texcoord, float2 e, float4 subsampleIndices) {
    float2 weights = float2(0.0, 0.0);

    float4 d;
    float2 end;
    if (e.r > 0.0) {
        d.xz = SMAASearchDiag1(HQAAedgesTex, texcoord, float2(-1.0,  1.0), end);
        d.x += float(end.y > 0.9);
    } else
        d.xz = float2(0.0, 0.0);
    d.yw = SMAASearchDiag1(HQAAedgesTex, texcoord, float2(1.0, -1.0), end);

    __SMAA_BRANCH
    if (d.x + d.y > 2.0) {
        float4 coords = mad(float4(-d.x + 0.25, d.x, d.y, -d.y - 0.25), __SMAA_RT_METRICS.xyxy, texcoord.xyxy);
        float4 c;
        c.xy = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.xy, int2(-1,  0)).rg;
        c.zw = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.zw, int2( 1,  0)).rg;
        c.yxwz = SMAADecodeDiagBilinearAccess(c.xyzw);

        float2 cc = mad(float2(2.0, 2.0), c.xz, c.yw);

        SMAAMovc(bool2(step(0.9, d.zw)), cc, float2(0.0, 0.0));

        weights += SMAAAreaDiag(HQAAareaTex, d.xy, cc, subsampleIndices.z);
    }

    d.xz = SMAASearchDiag2(HQAAedgesTex, texcoord, float2(-1.0, -1.0), end);
    if (__SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord, int2(1, 0)).r > 0.0) {
        d.yw = SMAASearchDiag2(HQAAedgesTex, texcoord, float2(1.0, 1.0), end);
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

        SMAAMovc(bool2(step(0.9, d.zw)), cc, float2(0.0, 0.0));

        weights += SMAAAreaDiag(HQAAareaTex, d.xy, cc, subsampleIndices.w).gr;
    }

    return weights;
}

/**
 * This allows to determine how much length should we add in the last step
 * of the searches. It takes the bilinearly interpolated edge (see 
 * @PSEUDO_GATHER4), and adds 0, 1 or 2, depending on which edges and
 * crossing edges are active.
 */
float SMAASearchLength(sampler2D HQAAsearchTex, float2 e, float offset) {
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
float SMAASearchXLeft(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end) {
    float2 e = float2(0.0, 1.0);
    while (texcoord.x > end && e.g > 0 && e.r == 0) 
	{
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(-float2(2.0, 0.0), __SMAA_RT_METRICS.xy, texcoord);
    }

    float offset = mad(-(255.0 / 127.0), SMAASearchLength(HQAAsearchTex, e, 0.0), 3.25);
    return mad(__SMAA_RT_METRICS.x, offset, texcoord.x);
}

float SMAASearchXRight(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end) {
    float2 e = float2(0.0, 1.0);
    while (texcoord.x < end && e.g > 0 && e.r == 0) 
	{
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(float2(2.0, 0.0), __SMAA_RT_METRICS.xy, texcoord);
    }
    float offset = mad(-(255.0 / 127.0), SMAASearchLength(HQAAsearchTex, e, 0.5), 3.25);
    return mad(-__SMAA_RT_METRICS.x, offset, texcoord.x);
}

float SMAASearchYUp(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end) {
    float2 e = float2(1.0, 0.0);
    while (texcoord.y > end && e.r > 0 && e.g == 0) 
	{
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(-float2(0.0, 2.0), __SMAA_RT_METRICS.xy, texcoord);
    }
    float offset = mad(-(255.0 / 127.0), SMAASearchLength(HQAAsearchTex, e.gr, 0.0), 3.25);
    return mad(__SMAA_RT_METRICS.y, offset, texcoord.y);
}

float SMAASearchYDown(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end) {
    float2 e = float2(1.0, 0.0);
    while (texcoord.y < end && e.r > 0 && e.g == 0) 
	{
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(float2(0.0, 2.0), __SMAA_RT_METRICS.xy, texcoord);
    }
    float offset = mad(-(255.0 / 127.0), SMAASearchLength(HQAAsearchTex, e.gr, 0.5), 3.25);
    return mad(-__SMAA_RT_METRICS.y, offset, texcoord.y);
}

/** 
 * Ok, we have the distance and both crossing edges. So, what are the areas
 * at each side of current edge?
 */
float2 SMAAArea(sampler2D HQAAareaTex, float2 dist, float e1, float e2, float offset) {
    float2 texcoord = mad(float2(__SMAA_AREATEX_MAX_DISTANCE, __SMAA_AREATEX_MAX_DISTANCE), round(4.0 * float2(e1, e2)), dist);
    
    texcoord = mad(__SMAA_AREATEX_PIXEL_SIZE, texcoord, 0.5 * __SMAA_AREATEX_PIXEL_SIZE);
    texcoord.y = mad(__SMAA_AREATEX_SUBTEX_SIZE, offset, texcoord.y);

    return __SMAASampleLevelZero(HQAAareaTex, texcoord).rg;
}


void SMAADetectHorizontalCornerPattern(sampler2D HQAAedgesTex, inout float2 weights, float4 texcoord, float2 d) {
    float2 leftRight = step(d.xy, d.yx);
    float2 rounding = (1.0 - __SMAA_CORNER_ROUNDING_NORM) * leftRight;

    float2 factor = float2(1.0, 1.0);
    factor.x -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2(0,  1)).r;
    factor.x -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2(1,  1)).r;
    factor.y -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2(0, -2)).r;
    factor.y -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2(1, -2)).r;

    weights *= saturate(factor);
}

void SMAADetectVerticalCornerPattern(sampler2D HQAAedgesTex, inout float2 weights, float4 texcoord, float2 d) {
    float2 leftRight = step(d.xy, d.yx);
    float2 rounding = (1.0 - __SMAA_CORNER_ROUNDING_NORM) * leftRight;

    float2 factor = float2(1.0, 1.0);
    factor.x -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2( 1, 0)).g;
    factor.x -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2( 1, 1)).g;
    factor.y -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2(-2, 0)).g;
    factor.y -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2(-2, 1)).g;

    weights *= saturate(factor);
}


float4 SMAABlendingWeightCalculationPS(float2 texcoord,
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
        coords.x = SMAASearchXLeft(HQAAedgesTex, HQAAsearchTex, offset[0].xy, offset[2].x);
        coords.y = offset[1].y;
        d.x = coords.x;

        float e1 = __SMAASampleLevelZero(HQAAedgesTex, coords.xy).r;

        coords.z = SMAASearchXRight(HQAAedgesTex, HQAAsearchTex, offset[0].zw, offset[2].y);
        d.y = coords.z;

        d = abs(round(mad(__SMAA_RT_METRICS.zz, d, -pixcoord.xx)));

        float2 sqrt_d = sqrt(d);

        float e2 = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.zy, int2(1, 0)).r;

        weights.rg = SMAAArea(HQAAareaTex, sqrt_d, e1, e2, subsampleIndices.y);

        coords.y = texcoord.y;
        SMAADetectHorizontalCornerPattern(HQAAedgesTex, weights.rg, coords.xyzy, d);

    }

    __SMAA_BRANCH
    if (e.r > 0.0) {
        float2 d;

        float3 coords;
        coords.y = SMAASearchYUp(HQAAedgesTex, HQAAsearchTex, offset[1].xy, offset[2].z);
        coords.x = offset[0].x;
        d.x = coords.y;

        float e1 = __SMAASampleLevelZero(HQAAedgesTex, coords.xy).g;

        coords.z = SMAASearchYDown(HQAAedgesTex, HQAAsearchTex, offset[1].zw, offset[2].w);
        d.y = coords.z;

        d = abs(round(mad(__SMAA_RT_METRICS.ww, d, -pixcoord.yy)));

        float2 sqrt_d = sqrt(d);

        float e2 = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.xz, int2(0, 1)).g;

        weights.ba = SMAAArea(HQAAareaTex, sqrt_d, e1, e2, subsampleIndices.x);

        coords.x = texcoord.x;
        SMAADetectVerticalCornerPattern(HQAAedgesTex, weights.ba, coords.xyxz, d);
    }

    return weights;
}

float4 SMAANeighborhoodBlendingPS(float2 texcoord,
                                  float4 offset,
                                  sampler2D colorTex,
                                  sampler2D HQAAblendTex
                                  ) {
    float4 m;
    m.x = tex2D(HQAAblendTex, offset.xy).a;
    m.y = tex2D(HQAAblendTex, offset.zw).g;
    m.wz = tex2D(HQAAblendTex, texcoord).xz;
	
	float4 color = float4(0,0,0,0);

    __SMAA_BRANCH
    if (dot(m, float4(1.0, 1.0, 1.0, 1.0)) < 1e-5) {
        color = __SMAASampleLevelZero(colorTex, texcoord);
    } else {
        bool horiz = max(m.x, m.z) > max(m.y, m.w);

        float4 blendingOffset = float4(0.0, m.y, 0.0, m.w);
        float2 blendingWeight = m.yw;
        SMAAMovc(bool4(horiz, horiz, horiz, horiz), blendingOffset, float4(m.x, 0.0, m.z, 0.0));
        SMAAMovc(bool2(horiz, horiz), blendingWeight, m.xz);
        blendingWeight /= dot(blendingWeight, float2(1.0, 1.0));

        float4 blendingCoord = mad(blendingOffset, float4(__SMAA_RT_METRICS.xy, -__SMAA_RT_METRICS.xy), texcoord.xyxy);

        color = blendingWeight.x * __SMAASampleLevelZero(colorTex, blendingCoord.xy);
        color += blendingWeight.y * __SMAASampleLevelZero(colorTex, blendingCoord.zw);
    }
	
	if (__HQAA_SHARPEN_ENABLE == true)
		return float4(Sharpen(texcoord, colorTex, color, __SMAA_EDGE_THRESHOLD, -1), color.a);
	else
		return color;
}

/***************************************************************************************************************************************/
/*********************************************************** SMAA CODE BLOCK END *******************************************************/
/***************************************************************************************************************************************/
// I'm a nested comment!
/***************************************************************************************************************************************/
/*********************************************************** FXAA CODE BLOCK START *****************************************************/
/***************************************************************************************************************************************/

#define FxaaAdaptiveLuma(t) FxaaAdaptiveLumaSelect(t, lumatype)

#define FxaaTex2D(t, p) tex2D(t, p)
#define FxaaTex2DLoop(t, p) tex2Dlod(t, float4(p, 0.0, 0.0))
#define FxaaTex2DOffset(t, p, o) tex2Doffset(t, p, o)

#define __FXAA_MODE_NORMAL 0
#define __FXAA_MODE_SPURIOUS_PIXELS 2
#define __FXAA_MODE_SMAA_DETECTION_POSITIVES 3
#define __FXAA_MODE_SMAA_DETECTION_NEGATIVES 4

float FxaaAdaptiveLumaSelect (float4 rgba, int lumatype)
// Luma types match variable positions. 0=R 1=G 2=B
{
	if (lumatype == 0)
		return mad(1 - rgba.a, rgba.r, rgba.a);
	else if (lumatype == 2)
		return mad(1 - rgba.a, rgba.b, rgba.a);
	else
		return mad(1 - rgba.a, rgba.g, rgba.a);
}

float4 FxaaAdaptiveLumaPixelShader(float2 pos, sampler2D tex, sampler2D edgestex,
 sampler2D referencetex, float fxaaQualitySubpix,
 float baseThreshold, float fxaaQualityEdgeThresholdMin, int pixelmode)
 {
    float4 rgbyM = FxaaTex2D(tex, pos);
	
	 if (pixelmode == __FXAA_MODE_SMAA_DETECTION_POSITIVES) {
		 float2 SMAAedges = tex2D(edgestex, pos).rg;
		 bool noSMAAedges = dot(float2(1.0, 1.0), SMAAedges) == 0;
		 if (noSMAAedges)
			 return rgbyM;
	 }
	 if (pixelmode == __FXAA_MODE_SMAA_DETECTION_NEGATIVES) {
		 float2 SMAAedges = tex2D(edgestex, pos).rg;
		 bool SMAAran = dot(float2(1.0, 1.0), SMAAedges) > 1e-5;
		 if (SMAAran)
			 return rgbyM;
	 }
    float2 posM = pos;
	
	int lumatype = 1; // assume green is luma until determined otherwise
	
	float maxcolor = max3(rgbyM.r, rgbyM.g, rgbyM.b);
	bool stronggreen = rgbyM.g > (rgbyM.r + rgbyM.b);
	
	if (stronggreen == false && rgbyM.g != maxcolor) // check if luma color needs changed
	{
		bool strongred = rgbyM.r > (rgbyM.g + rgbyM.b);
		bool strongblue = rgbyM.b > (rgbyM.g + rgbyM.r);
		
		if (strongred == true || rgbyM.r == maxcolor)
			lumatype = 0;
		else
			lumatype = 2;
	}
			
	float lumaMa = FxaaAdaptiveLuma(rgbyM);
	
	float4 gammaAdjust = __HQAA_LUMA_REFERENCE * rgbyM;
	gammaAdjust *= rcp(vec4add(gammaAdjust));
	float gammaM = FxaaAdaptiveLuma(gammaAdjust);
	float adjustmentrange = (baseThreshold * __HQAA_SUBPIX) * 0.875;
	float estimatedbrightness = lerp(lumaMa, gammaM, 0.5);
	float thresholdOffset = mad(estimatedbrightness, adjustmentrange, -adjustmentrange);
	
	float fxaaQualityEdgeThreshold = baseThreshold + thresholdOffset;
	
	
    float lumaS = FxaaAdaptiveLuma(FxaaTex2DOffset(tex, posM, float2( 0, 1)));
    float lumaE = FxaaAdaptiveLuma(FxaaTex2DOffset(tex, posM, float2( 1, 0)));
    float lumaN = FxaaAdaptiveLuma(FxaaTex2DOffset(tex, posM, float2( 0,-1)));
    float lumaW = FxaaAdaptiveLuma(FxaaTex2DOffset(tex, posM, float2(-1, 0)));
    float lumaNW = FxaaAdaptiveLuma(FxaaTex2DOffset(tex, posM, float2(-1,-1)));
    float lumaSE = FxaaAdaptiveLuma(FxaaTex2DOffset(tex, posM, float2( 1, 1)));
    float lumaNE = FxaaAdaptiveLuma(FxaaTex2DOffset(tex, posM, float2( 1,-1)));
    float lumaSW = FxaaAdaptiveLuma(FxaaTex2DOffset(tex, posM, float2(-1, 1)));
	
    float rangeMax = max9(lumaS, lumaE, lumaN, lumaW, lumaNW, lumaSE, lumaNE, lumaSW, lumaMa);
    float rangeMin = min9(lumaS, lumaE, lumaN, lumaW, lumaNW, lumaSE, lumaNE, lumaSW, lumaMa);
	
    float rangeMaxScaled = rangeMax * fxaaQualityEdgeThreshold;
    float range = rangeMax - rangeMin;
    float rangeMaxClamped = max(fxaaQualityEdgeThresholdMin, rangeMaxScaled);
	
	bool earlyExit = (range < rangeMaxClamped);
	
	if (pixelmode == __FXAA_MODE_SMAA_DETECTION_POSITIVES)
		earlyExit = (rgbyM.r + rgbyM.g + rgbyM.b) < fxaaQualityEdgeThresholdMin;
		
	if (earlyExit)
		return rgbyM;
	
    float lumaNS = lumaN + lumaS;
    float lumaWE = lumaW + lumaE;
    float subpixRcpRange = 1.0/range;
    float subpixNSWE = lumaNS + lumaWE;
    float edgeHorz1 = mad(-2, lumaMa, lumaNS);
    float edgeVert1 = mad(-2, lumaMa, lumaWE);
	
    float lumaNESE = lumaNE + lumaSE;
    float lumaNWNE = lumaNW + lumaNE;
    float edgeHorz2 = mad(-2, lumaE, lumaNESE);
    float edgeVert2 = mad(-2, lumaN, lumaNWNE);
	
    float lumaNWSW = lumaNW + lumaSW;
    float lumaSWSE = lumaSW + lumaSE;
    float edgeHorz4 = mad(2, abs(edgeHorz1), abs(edgeHorz2));
    float edgeVert4 = mad(2, abs(edgeVert1), abs(edgeVert2));
    float edgeHorz3 = mad(-2, lumaW, lumaNWSW);
    float edgeVert3 = mad(-2, lumaS, lumaSWSE);
    float edgeHorz = abs(edgeHorz3) + edgeHorz4;
    float edgeVert = abs(edgeVert3) + edgeVert4;
	
    float subpixNWSWNESE = lumaNWSW + lumaNESE;
    float lengthSign = BUFFER_RCP_WIDTH;
    bool horzSpan = edgeHorz >= edgeVert;
    float subpixA = mad(2, subpixNSWE, subpixNWSWNESE);
	
    if(!horzSpan) {
		lumaN = lumaW;
		lumaS = lumaE;
	}
    else lengthSign = BUFFER_RCP_HEIGHT;
    float subpixB = mad((1.0/12.0), subpixA, -lumaMa);
	
    float gradientN = lumaN - lumaMa;
    float gradientS = lumaS - lumaMa;
    float lumaNN = lumaN + lumaMa;
    float lumaSS = lumaS + lumaMa;
    bool pairN = abs(gradientN) >= abs(gradientS);
    float gradient = max(abs(gradientN), abs(gradientS));
    if(pairN) lengthSign = -lengthSign;
    float subpixC = saturate(abs(subpixB) * subpixRcpRange);
	
    float2 posB;
    posB.x = posM.x;
    posB.y = posM.y;
    float2 offNP;
    offNP.x = (!horzSpan) ? 0.0 : BUFFER_RCP_WIDTH;
    offNP.y = ( horzSpan) ? 0.0 : BUFFER_RCP_HEIGHT;
    if(!horzSpan) posB.x = mad(0.5, lengthSign, posB.x);
    else posB.y = mad(0.5, lengthSign, posB.y);
	
    float2 posN;
    posN = posB - offNP;
	
    float2 posP;
    posP = posB + offNP;
	
    float subpixD = mad(-2, subpixC, 3);
    float lumaEndN = FxaaAdaptiveLuma(FxaaTex2D(tex, posN));
    float subpixE = pow(subpixC, 2);
    float lumaEndP = FxaaAdaptiveLuma(FxaaTex2D(tex, posP));
	
    if(!pairN) lumaNN = lumaSS;
    float gradientScaled = gradient * 1.0/4.0;
    float lumaMM = mad(0.5, -lumaNN, lumaMa);
    float subpixF = subpixD * subpixE;
    bool lumaMLTZero = lumaMM < 0.0;
	
	float2 granularity = float2(__HQAA_FXAA_SCAN_GRANULARITY, __HQAA_FXAA_SCAN_GRANULARITY);
	
    lumaEndN = mad(0.5, -lumaNN, lumaEndN);
    lumaEndP = mad(0.5, -lumaNN, lumaEndP);
	
    bool doneN = abs(lumaEndN) >= gradientScaled;
    bool doneP = abs(lumaEndP) >= gradientScaled;
    bool doneNP = doneN && doneP;
	
    if(!doneN) posN = mad(granularity, -offNP, posN);
    if(!doneP) posP = mad(granularity, offNP, posP);
	
	uint iterations = 0;
	uint maxiterations = trunc(__HQAA_DISPLAY_DENOMINATOR * 0.05) * __HQAA_FXAA_SCAN_MULTIPLIER;
	
	if (frametime > __HQAA_DESIRED_FRAMETIME && maxiterations > 3)
		maxiterations = max(3, trunc(rcp(frametime - __HQAA_DESIRED_FRAMETIME + 1) * maxiterations));
	
    while(!doneNP && iterations < maxiterations) {
		
        if(!doneN) {
			lumaEndN = FxaaAdaptiveLuma(FxaaTex2DLoop(tex, posN.xy));
			lumaEndN = mad(0.5, -lumaNN, lumaEndN);
			doneN = abs(lumaEndN) >= gradientScaled;
		}
		
        if(!doneP) {
			lumaEndP = FxaaAdaptiveLuma(FxaaTex2DLoop(tex, posP.xy));
			lumaEndP = mad(0.5, -lumaNN, lumaEndP);
			doneP = abs(lumaEndP) >= gradientScaled;
		}
		
        if(!doneN) posN = mad(granularity, -offNP, posN);
        if(!doneP) posP = mad(granularity, offNP, posP);
		
        doneNP = doneN && doneP;
		iterations++;
    }
	
    float dstN = posM.x - posN.x;
    float dstP = posP.x - posM.x;
	
    if(!horzSpan) {
		dstN = posM.y - posN.y;
		dstP = posP.y - posM.y;
	}
	
    bool goodSpanN = (lumaEndN < 0.0) != lumaMLTZero;
    float spanLength = (dstP + dstN);
    bool goodSpanP = (lumaEndP < 0.0) != lumaMLTZero;
    float spanLengthRcp = rcp(spanLength);
	
    bool directionN = dstN < dstP;
    float dst = min(dstN, dstP);
    bool goodSpan = directionN ? goodSpanN : goodSpanP;
    float subpixG = subpixF * subpixF;
    float pixelOffset = mad(-spanLengthRcp, dst, 0.5);
    float subpixH = subpixG * fxaaQualitySubpix;
	
    float pixelOffsetGood = goodSpan ? pixelOffset : 0.0;
    float pixelOffsetSubpix = max(pixelOffsetGood, subpixH);
	
    if(!horzSpan) posM.x = mad(lengthSign, pixelOffsetSubpix, posM.x);
    else posM.y = mad(lengthSign, pixelOffsetSubpix, posM.y);
	
	// Establish result
	float4 resultAA = float4(tex2D(tex,posM).rgb, lumaMa);
	
	// grab original buffer state
	float4 prerender = tex2D(referencetex, posM);
	
	// normalize lumas for blending
	float4 resultAAnormal = resultAA * __HQAA_LUMA_REFERENCE;
	resultAAnormal *= rcp(vec4add(resultAAnormal));
	float4 prerendernormal = prerender * __HQAA_LUMA_REFERENCE;
	prerendernormal *= rcp(vec4add(prerendernormal));
	float4 rgbyMnormal = rgbyM * __HQAA_LUMA_REFERENCE;
	rgbyMnormal *= rcp(vec4add(rgbyMnormal));
	
	float resultAAluma = dotluma(resultAAnormal);
	float stepluma = dotluma(rgbyMnormal);
	float originalluma = dotluma(prerendernormal);
	
	// calculate interpolation
	float blendfactor = 1 - abs(resultAAluma - (stepluma - abs(stepluma - originalluma)));
	float4 weightedresult = lerp(rgbyM, resultAA, blendfactor);
	
	// fart the result
#if HQAA_INCLUDE_DEBUG_CODE
	if (debugmode != 4) 
	{
#endif
	if (__HQAA_SHARPEN_ENABLE == true)
		return float4(Sharpen(pos, tex, weightedresult, fxaaQualityEdgeThreshold, fxaaQualitySubpix), weightedresult.a);
	else
		return weightedresult;
#if HQAA_INCLUDE_DEBUG_CODE
	}
	else {
		if (lumatype == 0) return float4(FxaaAdaptiveLuma(rgbyM), 0, 0, rgbyM.a);
		else if (lumatype == 1) return float4(0, FxaaAdaptiveLuma(rgbyM), 0, rgbyM.a);
		else return float4(0, 0, FxaaAdaptiveLuma(rgbyM), rgbyM.a);
	}
#endif
}

/***************************************************************************************************************************************/
/*********************************************************** FXAA CODE BLOCK END *******************************************************/
/***************************************************************************************************************************************/

/***************************************************************************************************************************************/
/*********************************************************** SHADER CODE START *********************************************************/
/***************************************************************************************************************************************/

#include "ReShade.fxh"


//////////////////////////////////////////////////////////// TEXTURES ///////////////////////////////////////////////////////////////////

texture HQAAedgesTex < pooled = true; >
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RG8;
};
texture HQAAblendTex < pooled = true; >
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA8;
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

texture HQAAsupportTex < pooled = true; >
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
#if (BUFFER_COLOR_BIT_DEPTH == 10)
	Format = RGB10A2;
#else
	Format = RGBA8;
#endif
};


//////////////////////////////////////////////////////////// SAMPLERS ///////////////////////////////////////////////////////////////////

sampler HQAAcolorGammaSampler
{
	Texture = ReShade::BackBufferTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Point; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler HQAAcolorLinearSampler
{
	Texture = ReShade::BackBufferTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Point; MinFilter = Linear; MagFilter = Linear;
#if HDR_BACKBUFFER_IS_LINEAR
	SRGBTexture = false;
#else
	SRGBTexture = true;
#endif
};
sampler HQAAsupportSampler
{
	Texture = HQAAsupportTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Point; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler HQAAedgesSampler
{
	Texture = HQAAedgesTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler HQAAblendSampler
{
	Texture = HQAAblendTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler HQAAareaSampler
{
	Texture = HQAAareaTex;
	AddressU = Clamp; AddressV = Clamp; AddressW = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler HQAAsearchSampler
{
	Texture = HQAAsearchTex;
	AddressU = Clamp; AddressV = Clamp; AddressW = Clamp;
	MipFilter = Point; MinFilter = Point; MagFilter = Point;
	SRGBTexture = false;
};

//////////////////////////////////////////////////////////// VERTEX SHADERS /////////////////////////////////////////////////////////////

void SMAAEdgeDetectionWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float4 offset[3] : TEXCOORD1)
{
	PostProcessVS(id, position, texcoord);
	SMAAEdgeDetectionVS(texcoord, offset);
}
void SMAABlendingWeightCalculationWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float2 pixcoord : TEXCOORD1,
	out float4 offset[3] : TEXCOORD2)
{
	PostProcessVS(id, position, texcoord);
	SMAABlendingWeightCalculationVS(texcoord, pixcoord, offset);
}
void SMAANeighborhoodBlendingWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float4 offset : TEXCOORD1)
{
	PostProcessVS(id, position, texcoord);
	SMAANeighborhoodBlendingVS(texcoord, offset);
}

//////////////////////////////////////////////////////////// PIXEL SHADERS //////////////////////////////////////////////////////////////

float4 GenerateImageColorShiftLeftPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 input = tex2D(HQAAcolorGammaSampler, texcoord);
	return float4(input.g, input.b, input.r, input.a);
}
float4 GenerateImageNegativeColorShiftLeftPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 input = tex2D(HQAAcolorGammaSampler, texcoord);
	return float4(1.0 - input.g, 1.0 - input.b, 1.0 - input.r, input.a);
}
float4 GenerateImageColorShiftRightPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 input = tex2D(HQAAcolorGammaSampler, texcoord);
	return float4(input.b, input.r, input.g, input.a);
}
float4 GenerateImageNegativeColorShiftRightPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 input = tex2D(HQAAcolorGammaSampler, texcoord);
	return float4(1.0 - input.b, 1.0 - input.r, 1.0 - input.g, input.a);
}
float4 GenerateImageNegativePS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 input = tex2D(HQAAcolorGammaSampler, texcoord);
	return float4(1.0 - input.r, 1.0 - input.g, 1.0 - input.b, input.a);
}
float4 GenerateImageCopyPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return tex2D(HQAAcolorGammaSampler, texcoord);
}

float2 HQAAPrimaryDetectionPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float4 offset[3] : TEXCOORD1) : SV_Target
{
	return SMAALumaEdgeDetectionPS(texcoord, offset, HQAAcolorGammaSampler);
}
float2 HQAASupportDetectionPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float4 offset[3] : TEXCOORD1) : SV_Target
{
	return SMAALumaEdgeDetectionPS(texcoord, offset, HQAAsupportSampler);
}
float4 SMAABlendingWeightCalculationWrapPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float2 pixcoord : TEXCOORD1,
	float4 offset[3] : TEXCOORD2) : SV_Target
{
	return SMAABlendingWeightCalculationPS(texcoord, pixcoord, offset, HQAAedgesSampler, HQAAareaSampler, HQAAsearchSampler, 0.0);
}
float4 SMAANeighborhoodBlendingWrapPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float4 offset : TEXCOORD1) : SV_Target
{
	return SMAANeighborhoodBlendingPS(texcoord, offset, HQAAcolorLinearSampler, HQAAblendSampler);
}

float3 FXAADetectionPositivesPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float TotalSubpix = __HQAA_SUBPIX * 0.75;
	if (__HQAA_BUFFER_MULTIPLIER < 1)
		TotalSubpix *= __HQAA_BUFFER_MULTIPLIER;
	
	float threshold = max(__FXAA_THRESHOLD_FLOOR,__HQAA_EDGE_THRESHOLD);
	
	float4 result = FxaaAdaptiveLumaPixelShader(texcoord,HQAAcolorGammaSampler,HQAAedgesSampler,HQAAsupportSampler,TotalSubpix,threshold,0.004,__FXAA_MODE_SMAA_DETECTION_POSITIVES);
	
#if HQAA_INCLUDE_DEBUG_CODE
	if ((debugmode == 3 || debugmode == 4) && debugFXAApass == 0) {
		bool validResult = abs(dot(result,float4(1,1,1,1)) - dot(tex2D(HQAAcolorGammaSampler,texcoord), float4(1,1,1,1))) > 1e-5;
		if (validResult)
			return result.rgb;
		else
			return float3(0.0, 0.0, 0.0);
	}
	else
#endif
		return result.rgb;
}
float3 FXAADetectionNegativesPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	// debugs 1 and 2 need to output from the last pass in the technique
#if HQAA_INCLUDE_DEBUG_CODE
	if (debugmode == 1)
		return tex2D(HQAAedgesSampler, texcoord).rgb;
	if (debugmode == 2)
		return tex2D(HQAAblendSampler, texcoord).rgb;
#endif
	
	float TotalSubpix = __HQAA_SUBPIX * 0.5;
	if (__HQAA_BUFFER_MULTIPLIER < 1)
		TotalSubpix *= __HQAA_BUFFER_MULTIPLIER;
	
	float threshold = max(__FXAA_THRESHOLD_FLOOR,__HQAA_EDGE_THRESHOLD);
	threshold = sqrt(threshold);
	
	float4 result = FxaaAdaptiveLumaPixelShader(texcoord,HQAAcolorGammaSampler,HQAAedgesSampler,HQAAsupportSampler,TotalSubpix,threshold,0.004,__FXAA_MODE_SMAA_DETECTION_NEGATIVES);
	
#if HQAA_INCLUDE_DEBUG_CODE
	if ((debugmode == 3 || debugmode == 4) && debugFXAApass == 1) {
		bool validResult = abs(dot(result,float4(1,1,1,1)) - dot(tex2D(HQAAcolorGammaSampler,texcoord), float4(1,1,1,1))) > 1e-5;
		if (validResult)
			return result.rgb;
		else
			return float3(0.0, 0.0, 0.0);
	}
	else
#endif
		return result.rgb;
}

float3 HQAACASOptionalPS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	return HQAACASPS(texcoord, HQAAedgesSampler, HQAAcolorLinearSampler);
}

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
	pass BufferEdgeDetection
	{
		VertexShader = SMAAEdgeDetectionWrapVS;
		PixelShader = HQAAPrimaryDetectionPS;
		RenderTarget = HQAAedgesTex;
		ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = REPLACE;
		StencilRef = 1;
	}
	pass CreateBufferNegative
	{
		VertexShader = PostProcessVS;
		PixelShader = GenerateImageNegativePS;
		RenderTarget = HQAAsupportTex;
		ClearRenderTargets = true;
	}
	pass SupportEdgeDetectionNegative
	{
		VertexShader = SMAAEdgeDetectionWrapVS;
		PixelShader = HQAASupportDetectionPS;
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
		RenderTarget = HQAAsupportTex;
		ClearRenderTargets = true;
	}
	pass SupportEdgeDetectionRightShift
	{
		VertexShader = SMAAEdgeDetectionWrapVS;
		PixelShader = HQAASupportDetectionPS;
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
		RenderTarget = HQAAsupportTex;
		ClearRenderTargets = true;
	}
	pass SupportEdgeDetectionLeftShift
	{
		VertexShader = SMAAEdgeDetectionWrapVS;
		PixelShader = HQAASupportDetectionPS;
		RenderTarget = HQAAedgesTex;
		ClearRenderTargets = false;
		BlendEnable = true;
		BlendOp = MAX;
		BlendOpAlpha = MAX;
		StencilEnable = true;
		StencilPass = REPLACE;
		StencilRef = 1;
	}
	pass CreateBufferColorShiftRightNegative
	{
		VertexShader = PostProcessVS;
		PixelShader = GenerateImageNegativeColorShiftRightPS;
		RenderTarget = HQAAsupportTex;
		ClearRenderTargets = true;
	}
	pass SupportEdgeDetectionNegativeRightShift
	{
		VertexShader = SMAAEdgeDetectionWrapVS;
		PixelShader = HQAASupportDetectionPS;
		RenderTarget = HQAAedgesTex;
		ClearRenderTargets = false;
		BlendEnable = true;
		BlendOp = MAX;
		BlendOpAlpha = MAX;
		StencilEnable = true;
		StencilPass = REPLACE;
		StencilRef = 1;
	}
	pass CreateBufferColorShiftLeftNegative
	{
		VertexShader = PostProcessVS;
		PixelShader = GenerateImageNegativeColorShiftLeftPS;
		RenderTarget = HQAAsupportTex;
		ClearRenderTargets = true;
	}
	pass SupportEdgeDetectionNegativeLeftShift
	{
		VertexShader = SMAAEdgeDetectionWrapVS;
		PixelShader = HQAASupportDetectionPS;
		RenderTarget = HQAAedgesTex;
		ClearRenderTargets = false;
		BlendEnable = true;
		BlendOp = MAX;
		BlendOpAlpha = MAX;
		StencilEnable = true;
		StencilPass = REPLACE;
		StencilRef = 1;
	}
	pass CreateBufferCopy
	{
		VertexShader = PostProcessVS;
		PixelShader = GenerateImageCopyPS;
		RenderTarget = HQAAsupportTex;
		ClearRenderTargets = true;
	}
	pass SMAABlendCalculation
	{
		VertexShader = SMAABlendingWeightCalculationWrapVS;
		PixelShader = SMAABlendingWeightCalculationWrapPS;
		RenderTarget = HQAAblendTex;
		ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = KEEP;
		StencilFunc = EQUAL;
		StencilRef = 1;
	}
	pass SMAABlending
	{
		VertexShader = SMAANeighborhoodBlendingWrapVS;
		PixelShader = SMAANeighborhoodBlendingWrapPS;
		StencilEnable = false;
#if HDR_BACKBUFFER_IS_LINEAR
		SRGBWriteEnable = false;
#else
		SRGBWriteEnable = true;
#endif
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
}

technique HQAACAS <
	ui_tooltip = "HQAA Optional Contrast-Adaptive Sharpening Pass";
>
{
	pass CAS
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAACASOptionalPS;
#if HDR_BACKBUFFER_IS_LINEAR
		SRGBWriteEnable = false;
#else
		SRGBWriteEnable = true;
#endif
	}
}
