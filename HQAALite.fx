/*               HQAA Lite for ReShade 3.1.1+
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
 *                        v1.1.274
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

#ifndef HQAAL_ADVANCED_MODE
	#define HQAAL_ADVANCED_MODE 0
#endif

#ifndef HQAAL_OUTPUT_MODE
	#define HQAAL_OUTPUT_MODE 0
#endif

#ifndef HQAAL_FXAA_MULTISAMPLING
	#define HQAAL_FXAA_MULTISAMPLING 2
#endif

/////////////////////////////////////////////////////// GLOBAL SETUP OPTIONS //////////////////////////////////////////////////////////////

uniform int HQAALintroduction <
	ui_spacing = 3;
	ui_type = "radio";
	ui_label = "Version: 1.1.274";
	ui_text = "-------------------------------------------------------------------------\n"
			"Hybrid high-Quality Anti-Aliasing, a shader by lordbean\n"
			"https://github.com/lordbean-git/HQAA/\n"
			"-------------------------------------------------------------------------\n\n"
			"Currently Compiled Configuration:\n\n"
			#if HQAAL_ADVANCED_MODE
				"Advanced Mode:            on  *\n"
			#else
				"Advanced Mode:           off\n"
			#endif
			#if HQAAL_OUTPUT_MODE == 1
				"Output Mode:        HDR nits  *\n"
			#elif HQAAL_OUTPUT_MODE == 2
				"Output Mode:     PQ accurate  *\n"
			#elif HQAAL_OUTPUT_MODE == 3
				"Output Mode:       PQ approx  *\n"
			#else
				"Output Mode:       Gamma 2.2\n"
			#endif
			#if HQAAL_FXAA_MULTISAMPLING < 2
				"FXAA Multisampling:      off  *\n"
			#elif HQAAL_FXAA_MULTISAMPLING > 3
				"FXAA Multisampling:       4x  *\n"
			#elif HQAAL_FXAA_MULTISAMPLING > 2
				"FXAA Multisampling:       3x  *\n"
			#elif HQAAL_FXAA_MULTISAMPLING > 1
				"FXAA Multisampling:       2x\n"
			#endif
			
			"\nFXAA Multisampling can be used to increase correction strength when\n"
			"encountering edges with more than one color gradient or irregular\n"
			"geometry. Costs some performance for each extra pass.\n"
			"Valid range: 1 to 4. Higher values are ignored.\n"
			
			"\nValid Output Modes (HQAAL_OUTPUT_MODE):\n"
			"0: Gamma 2.2 (default)\n"
			"1: HDR, direct nits scale\n"
			"2: HDR10, accurate encoding\n"
			"3: HDR10, fast encoding\n"
			"\n-------------------------------------------------------------------------"
			"\nSee the 'Preprocessor definitions' section for color & feature toggles.\n"
			"-------------------------------------------------------------------------";
	ui_tooltip = "Lite Edition";
	ui_category = "About";
	ui_category_closed = true;
>;

uniform int HqaalAboutEOF <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n--------------------------------------------------------------------------------";
>;

#if !HQAAL_ADVANCED_MODE
uniform uint HqaalPreset <
	ui_type = "combo";
	ui_spacing = 3;
	ui_label = "Quality Preset\n\n";
	ui_tooltip = "Set HQAAL_ADVANCED_MODE to 1 to customize all options";
	ui_items = "Low\0Medium\0High\0Ultra\0";
> = 2;

#else
uniform float HqaalEdgeThresholdCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_spacing = 4;
	ui_label = "Edge Detection Threshold";
	ui_tooltip = "Local contrast (luma difference) required to be considered an edge";
	ui_category = "Edge Detection";
	ui_category_closed = true;
> = 0.1;

uniform float HqaalDynamicThresholdCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "% Dynamic Reduction Range\n\n";
	ui_tooltip = "Maximum dynamic reduction of edge threshold (as percentage of base threshold)\n"
				 "permitted when detecting low-brightness edges.\n"
				 "Lower = faster, might miss low-contrast edges\n"
				 "Higher = slower, catches more edges in dark scenes";
	ui_category = "Edge Detection";
	ui_category_closed = true;
> = 75;

uniform uint HqaalEdgeErrorMarginCustom <
	ui_type = "radio";
	ui_label = "Mouseover for description";
	ui_spacing = 3;
	ui_text = "Detected Edges Margin of Error:";
	ui_tooltip = "Determines maximum number of neighbor edges allowed before\n"
				"an edge is considered an erroneous detection. Low preserves\n"
				"detail, high increases amount of anti-aliasing applied. You\n"
				"can skip this check entirely by selecting 'Off'.";
	ui_items = "Low\0Balanced\0High\0Off\0";
	ui_category = "SMAA";
	ui_category_closed = true;
> = 1;

static const float HQAAL_ERRORMARGIN_CUSTOM[4] = {4.0, 5.0, 7.0, -1.0};

uniform float HqaalSmCorneringCustom < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_spacing = 2;
	ui_label = "% Corner Rounding\n\n";
	ui_tooltip = "Affects the amount of blending performed when SMAA\ndetects crossing edges";
	ui_category = "SMAA";
	ui_category_closed = true;
> = 25;

uniform float HqaalFxQualityCustom < __UNIFORM_SLIDER_FLOAT1
	ui_spacing = 3;
	ui_min = 25; ui_max = 400; ui_step = 1;
	ui_label = "% Quality";
	ui_tooltip = "Affects the maximum radius FXAA will search\nalong an edge gradient";
	ui_category = "FXAA";
	ui_category_closed = true;
> = 100;

uniform float HqaalFxTexelCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.25; ui_max = 4.0; ui_step = 0.01;
	ui_label = "Edge Gradient Texel Size";
	ui_tooltip = "Determines how far along an edge FXAA will move\nfrom one scan iteration to the next.\n\nLower = slower, more accurate\nHigher = faster, more artifacts";
	ui_category = "FXAA";
	ui_category_closed = true;
> = 1.0;

uniform float HqaalFxBlendCustom < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "% Gradient Blending Strength\n\n";
	ui_tooltip = "Percentage of blending FXAA will apply to long slopes.\n"
				 "Lower = sharper image, Higher = more AA effect";
	ui_category = "FXAA";
	ui_category_closed = true;
> = 50;
#endif //HQAAL_ADVANCED_MODE

#if HQAAL_OUTPUT_MODE == 1
uniform float HqaalHdrNits < 
	ui_spacing = 3;
	ui_type = "slider";
	ui_min = 500.0; ui_max = 10000.0; ui_step = 100.0;
	ui_label = "HDR Nits";
	ui_tooltip = "If the scene brightness changes after HQAA runs, try\n"
				 "adjusting this value up or down until it looks right.";
> = 1000.0;
#endif

uniform int HqaalOptionsEOF <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n--------------------------------------------------------------------------------";
>;

///////////////////////////////////////////////// HUMAN+MACHINE PRESET REFERENCE //////////////////////////////////////////////////////////

#if HQAAL_ADVANCED_MODE
uniform int HqaalPresetBreakdown <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n"
			  "-----------------------------------------------------------------------\n"
			  "|        |       Edges       |      SMAA       |        FXAA          |\n"
	          "|--Preset|-Threshold---Range-|-Corner---%Error-|-Qual---Texel---Blend-|\n"
	          "|--------|-----------|-------|--------|--------|------|-------|-------|\n"
			  "|     Low|    0.25   | 60.0% |   20%  |Balanced|  50% |  2.0  |  50%  |\n"
			  "|  Medium|    0.20   | 75.0% |   25%  |Balanced| 100% |  1.0  |  75%  |\n"
			  "|    High|    0.12   | 75.0% |   33%  |  High  | 150% |  1.0  |  88%  |\n"
			  "|   Ultra|    0.08   | 75.0% |   50%  |  High  | 200% |  0.5  | 100%  |\n"
			  "-----------------------------------------------------------------------";
	ui_category = "Click me to see what settings each preset uses!";
	ui_category_closed = true;
>;

#define __HQAAL_EDGE_THRESHOLD (HqaalEdgeThresholdCustom)
#define __HQAAL_DYNAMIC_RANGE (HqaalDynamicThresholdCustom / 100.0)
#define __HQAAL_SM_CORNERS (HqaalSmCorneringCustom / 100.0)
#define __HQAAL_FX_QUALITY (HqaalFxQualityCustom / 100.0)
#define __HQAAL_FX_TEXEL (HqaalFxTexelCustom)
#define __HQAAL_FX_BLEND (HqaalFxBlendCustom / 100.0)
#define __HQAAL_SM_ERRORMARGIN (HQAAL_ERRORMARGIN_CUSTOM[HqaalEdgeErrorMarginCustom])

#else

static const float HQAAL_THRESHOLD_PRESET[4] = {0.25, 0.2, 0.12, 0.08};
static const float HQAAL_DYNAMIC_RANGE_PRESET[4] = {0.6, 0.75, 0.75, 0.75};
static const float HQAAL_SMAA_CORNER_ROUNDING_PRESET[4] = {0.2, 0.25, 0.333333, 0.5};
static const float HQAAL_FXAA_SCANNING_MULTIPLIER_PRESET[4] = {0.5, 1.0, 1.5, 2.0};
static const float HQAAL_FXAA_TEXEL_SIZE_PRESET[4] = {2.0, 1.0, 1.0, 0.5};
static const float HQAAL_SUBPIX_PRESET[4] = {0.5, 0.75, 0.875, 1.0};
static const float HQAAL_ERRORMARGIN_PRESET[4] = {5.0, 5.0, 7.0, 7.0};

#define __HQAAL_EDGE_THRESHOLD (HQAAL_THRESHOLD_PRESET[HqaalPreset])
#define __HQAAL_DYNAMIC_RANGE (HQAAL_DYNAMIC_RANGE_PRESET[HqaalPreset])
#define __HQAAL_SM_CORNERS (HQAAL_SMAA_CORNER_ROUNDING_PRESET[HqaalPreset])
#define __HQAAL_FX_QUALITY (HQAAL_FXAA_SCANNING_MULTIPLIER_PRESET[HqaalPreset])
#define __HQAAL_FX_TEXEL (HQAAL_FXAA_TEXEL_SIZE_PRESET[HqaalPreset])
#define __HQAAL_FX_BLEND (HQAAL_SUBPIX_PRESET[HqaalPreset])
#define __HQAAL_SM_ERRORMARGIN (HQAAL_ERRORMARGIN_PRESET[HqaalPreset])

#endif //HQAAL_ADVANCED_MODE

/*****************************************************************************************************************************************/
/*********************************************************** UI SETUP END ****************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/******************************************************** SYNTAX SETUP START *************************************************************/
/*****************************************************************************************************************************************/

#define __HQAAL_DISPLAY_NUMERATOR max(BUFFER_HEIGHT, BUFFER_WIDTH)
#define __HQAAL_SMALLEST_COLOR_STEP rcp(pow(2, BUFFER_COLOR_BIT_DEPTH))
#define __HQAAL_CONST_E 2.718282
#define __HQAAL_LUMA_REF float3(0.333333, 0.333334, 0.333333)

#if (__RENDERER__ >= 0x10000 && __RENDERER__ < 0x20000) || (__RENDERER__ >= 0x09000 && __RENDERER__ < 0x0A000)
#define __HQAAL_FX_RADIUS 16.0
#else
#define __HQAAL_FX_RADIUS (16.0 / __HQAAL_FX_TEXEL)
#endif

#define __HQAAL_SM_RADIUS (__HQAAL_DISPLAY_NUMERATOR * 0.125)
#define __HQAAL_SM_BUFFERINFO float4(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT, BUFFER_WIDTH, BUFFER_HEIGHT)
#define __HQAAL_SM_AREATEX_RANGE 16
#define __HQAAL_SM_AREATEX_RANGE_DIAG 20
#define __HQAAL_SM_AREATEX_TEXEL float2(0.00625, 0.001786) // 1/{160,560}
#define __HQAAL_SM_AREATEX_SUBTEXEL 0.142857 // 1/7
#define __HQAAL_SM_SEARCHTEX_SIZE float2(66.0, 33.0)
#define __HQAAL_SM_SEARCHTEX_SIZE_PACKED float2(64.0, 16.0)

#define HQAAL_Tex2D(tex, coord) tex2Dlod(tex, (coord).xyxy)
#define HQAAL_Tex2DOffset(tex, coord, offset) tex2Dlodoffset(tex, (coord).xyxy, offset)
#define HQAAL_DecodeTex2D(tex, coord) ConditionalDecode(tex2Dlod(tex, (coord).xyxy))
#define HQAAL_DecodeTex2DOffset(tex, coord, offset) ConditionalDecode(tex2Dlodoffset(tex, (coord).xyxy, offset))

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

#define HQAALdotmax(x) max(max((x).r, (x).g), (x).b)
#define HQAALdotmin(x) min(min((x).r, (x).g), (x).b)

#define HQAALvec3add(x) dot(x, float3(1.0, 1.0, 1.0))

/*****************************************************************************************************************************************/
/********************************************************* SYNTAX SETUP END **************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/******************************************************** SUPPORT CODE START *************************************************************/
/*****************************************************************************************************************************************/

//////////////////////////////////////////////////////// PIXEL INFORMATION ////////////////////////////////////////////////////////////////

float dotweight(float3 middle, float3 neighbor, bool useluma, float3 weights)
{
	if (useluma) return dot(neighbor, weights);
	else return dot(abs(middle - neighbor), __HQAAL_LUMA_REF);
}

/////////////////////////////////////////////////////// TRANSFER FUNCTIONS ////////////////////////////////////////////////////////////////

#if HQAAL_OUTPUT_MODE == 2
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
#endif //HQAAL_OUTPUT_MODE == 2

#if HQAAL_OUTPUT_MODE == 3
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
	return saturate((sqrt(sqrt(clamp(x, __HQAAL_SMALLEST_COLOR_STEP, 500.0))) / 4.728708));
#else
	return saturate((sqrt(sqrt(clamp(x, __HQAAL_SMALLEST_COLOR_STEP, 10000.0))) / 10.0));
#endif
}
float2 fastdecodePQ(float2 x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	return saturate((sqrt(sqrt(clamp(x, __HQAAL_SMALLEST_COLOR_STEP, 500.0))) / 4.728708));
#else
	return saturate((sqrt(sqrt(clamp(x, __HQAAL_SMALLEST_COLOR_STEP, 10000.0))) / 10.0));
#endif
}
float3 fastdecodePQ(float3 x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	return saturate((sqrt(sqrt(clamp(x, __HQAAL_SMALLEST_COLOR_STEP, 500.0))) / 4.728708));
#else
	return saturate((sqrt(sqrt(clamp(x, __HQAAL_SMALLEST_COLOR_STEP, 10000.0))) / 10.0));
#endif
}
float4 fastdecodePQ(float4 x)
{
#if BUFFER_COLOR_BIT_DEPTH == 10
	return saturate((sqrt(sqrt(clamp(x, __HQAAL_SMALLEST_COLOR_STEP, 500.0))) / 4.728708));
#else
	return saturate((sqrt(sqrt(clamp(x, __HQAAL_SMALLEST_COLOR_STEP, 10000.0))) / 10.0));
#endif
}
#endif //HQAAL_OUTPUT_MODE == 3

#if HQAAL_OUTPUT_MODE == 1
float encodeHDR(float x)
{
	return saturate(x) * HqaalHdrNits;
}
float2 encodeHDR(float2 x)
{
	return saturate(x) * HqaalHdrNits;
}
float3 encodeHDR(float3 x)
{
	return saturate(x) * HqaalHdrNits;
}
float4 encodeHDR(float4 x)
{
	return saturate(x) * HqaalHdrNits;
}

float decodeHDR(float x)
{
	return saturate(x / HqaalHdrNits);
}
float2 decodeHDR(float2 x)
{
	return saturate(x / HqaalHdrNits);
}
float3 decodeHDR(float3 x)
{
	return saturate(x / HqaalHdrNits);
}
float4 decodeHDR(float4 x)
{
	return saturate(x / HqaalHdrNits);
}
#endif //HQAAL_OUTPUT_MODE == 1

float ConditionalEncode(float x)
{
#if HQAAL_OUTPUT_MODE == 1
	return encodeHDR(x);
#elif HQAAL_OUTPUT_MODE == 2
	return encodePQ(x);
#elif HQAAL_OUTPUT_MODE == 3
	return fastencodePQ(x);
#else
	return x;
#endif
}
float2 ConditionalEncode(float2 x)
{
#if HQAAL_OUTPUT_MODE == 1
	return encodeHDR(x);
#elif HQAAL_OUTPUT_MODE == 2
	return encodePQ(x);
#elif HQAAL_OUTPUT_MODE == 3
	return fastencodePQ(x);
#else
	return x;
#endif
}
float3 ConditionalEncode(float3 x)
{
#if HQAAL_OUTPUT_MODE == 1
	return encodeHDR(x);
#elif HQAAL_OUTPUT_MODE == 2
	return encodePQ(x);
#elif HQAAL_OUTPUT_MODE == 3
	return fastencodePQ(x);
#else
	return x;
#endif
}
float4 ConditionalEncode(float4 x)
{
#if HQAAL_OUTPUT_MODE == 1
	return encodeHDR(x);
#elif HQAAL_OUTPUT_MODE == 2
	return encodePQ(x);
#elif HQAAL_OUTPUT_MODE == 3
	return fastencodePQ(x);
#else
	return x;
#endif
}

float ConditionalDecode(float x)
{
#if HQAAL_OUTPUT_MODE == 1
	return decodeHDR(x);
#elif HQAAL_OUTPUT_MODE == 2
	return decodePQ(x);
#elif HQAAL_OUTPUT_MODE == 3
	return fastdecodePQ(x);
#else
	return x;
#endif
}
float2 ConditionalDecode(float2 x)
{
#if HQAAL_OUTPUT_MODE == 1
	return decodeHDR(x);
#elif HQAAL_OUTPUT_MODE == 2
	return decodePQ(x);
#elif HQAAL_OUTPUT_MODE == 3
	return fastdecodePQ(x);
#else
	return x;
#endif
}
float3 ConditionalDecode(float3 x)
{
#if HQAAL_OUTPUT_MODE == 1
	return decodeHDR(x);
#elif HQAAL_OUTPUT_MODE == 2
	return decodePQ(x);
#elif HQAAL_OUTPUT_MODE == 3
	return fastdecodePQ(x);
#else
	return x;
#endif
}
float4 ConditionalDecode(float4 x)
{
#if HQAAL_OUTPUT_MODE == 1
	return decodeHDR(x);
#elif HQAAL_OUTPUT_MODE == 2
	return decodePQ(x);
#elif HQAAL_OUTPUT_MODE == 3
	return fastdecodePQ(x);
#else
	return x;
#endif
}

//////////////////////////////////////////////////// SATURATION CALCULATIONS //////////////////////////////////////////////////////////////

float dotsat(float3 x)
{
	float xl = dot(x, __HQAAL_LUMA_REF);
	return ((HQAALdotmax(x) - HQAALdotmin(x)) / (1.0 - (2.0 * xl - 1.0) + trunc(xl)));
}
float dotsat(float4 x)
{
	return dotsat(x.rgb);
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

float2 HQAASearchDiag1(sampler2D HQAALedgesTex, float2 texcoord, float2 dir, out float2 e)
{
    float4 coord = float4(texcoord, -1.0, 1.0);
    float3 t = float3(__HQAAL_SM_BUFFERINFO.xy, 1.0);
    bool endloop = false;
    
    [loop] while (coord.z < 20.0) 
	{
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);
        e = tex2Dlod(HQAALedgesTex, coord.xyxy).rg;
        coord.w = dot(e, float(0.5).xx);
        endloop = coord.w < 0.9;
        if (endloop) break;
    }
    return coord.zw;
}
float2 HQAASearchDiag2(sampler2D HQAALedgesTex, float2 texcoord, float2 dir, out float2 e)
{
    float4 coord = float4(texcoord, -1.0, 1.0);
    coord.x += 0.25 * __HQAAL_SM_BUFFERINFO.x;
    float3 t = float3(__HQAAL_SM_BUFFERINFO.xy, 1.0);
    bool endloop = false;
    
    [loop] while (coord.z < 20.0) 
	{
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);

        e = tex2Dlod(HQAALedgesTex, coord.xyxy).rg;
        e = HQAADecodeDiagBilinearAccess(e);

        coord.w = dot(e, float(0.5).xx);
        endloop = coord.w < 0.9;
        if (endloop) break;
    }
    return coord.zw;
}

float2 HQAAAreaDiag(sampler2D HQAALareaTex, float2 dist, float2 e, float offset)
{
    float2 texcoord = mad(float(__HQAAL_SM_AREATEX_RANGE_DIAG).xx, e, dist);

    texcoord = mad(__HQAAL_SM_AREATEX_TEXEL, texcoord, 0.5 * __HQAAL_SM_AREATEX_TEXEL);
    texcoord.x += 0.5;
    texcoord.y += __HQAAL_SM_AREATEX_SUBTEXEL * offset;

    return tex2Dlod(HQAALareaTex, texcoord.xyxy).rg;
}

float2 HQAACalculateDiagWeights(sampler2D HQAALedgesTex, sampler2D HQAALareaTex, float2 texcoord, float2 e, float4 subsampleIndices)
{
    float2 weights = float(0.0).xx;
    float2 end;
    float4 d;
    bool checkpassed;
    d.ywxz = float4(HQAASearchDiag1(HQAALedgesTex, texcoord, float2(1.0, -1.0), end), 0.0, 0.0);
    
    checkpassed = e.r > 0.0;
    [branch] if (checkpassed) 
	{
        d.xz = HQAASearchDiag1(HQAALedgesTex, texcoord, float2(-1.0,  1.0), end);
        d.x += float(end.y > 0.9);
    }
	
	checkpassed = d.x + d.y > 2.0;
	[branch] if (checkpassed) 
	{
        float4 coords = mad(float4(-d.x + 0.25, d.x, d.y, -d.y - 0.25), __HQAAL_SM_BUFFERINFO.xyxy, texcoord.xyxy);
        float4 c;
        c.xy = tex2Dlodoffset(HQAALedgesTex, coords.xyxy, int2(-1,  0)).rg;
        c.zw = tex2Dlodoffset(HQAALedgesTex, coords.zwzw, int2( 1,  0)).rg;
        c.yxwz = HQAADecodeDiagBilinearAccess(c.xyzw);

        float2 cc = mad(float(2.0).xx, c.xz, c.yw);

        HQAAMovc(bool2(step(0.9, d.zw)), cc, float(0.0).xx);

        weights += HQAAAreaDiag(HQAALareaTex, d.xy, cc, subsampleIndices.z);
    }

    d.xz = HQAASearchDiag2(HQAALedgesTex, texcoord, float2(-1.0, -1.0), end);
    d.yw = float(0.0).xx;
    
    checkpassed = HQAAL_Tex2DOffset(HQAALedgesTex, texcoord, int2(1, 0)).r > 0.0;
    [branch] if (checkpassed) 
	{
        d.yw = HQAASearchDiag2(HQAALedgesTex, texcoord, float(1.0).xx, end);
        d.y += float(end.y > 0.9);
    }
	
	checkpassed = d.x + d.y > 2.0;
	[branch] if (checkpassed) 
	{
        float4 coords = mad(float4(-d.x, -d.x, d.y, d.y), __HQAAL_SM_BUFFERINFO.xyxy, texcoord.xyxy);
        float4 c;
        c.x  = tex2Dlodoffset(HQAALedgesTex, coords.xyxy, int2(-1,  0)).g;
        c.y  = tex2Dlodoffset(HQAALedgesTex, coords.xyxy, int2( 0, -1)).r;
        c.zw = tex2Dlodoffset(HQAALedgesTex, coords.zwzw, int2( 1,  0)).gr;
        float2 cc = mad(float(2.0).xx, c.xz, c.yw);

        HQAAMovc(bool2(step(0.9, d.zw)), cc, float(0.0).xx);

        weights += HQAAAreaDiag(HQAALareaTex, d.xy, cc, subsampleIndices.w).gr;
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
    bool endedge = false;
    [loop] while (texcoord.x > end) 
	{
        e = tex2Dlod(HQAALedgesTex, texcoord.xyxy).rg;
        texcoord = mad(-float2(2.0, 0.0), __HQAAL_SM_BUFFERINFO.xy, texcoord);
        endedge = e.r > 0.0 || e.g == 0.0;
        if (endedge) break;
    }
    float offset = mad(-2.007874, HQAASearchLength(HQAALsearchTex, e, 0.0), 3.25); // -(255/127)
    return mad(__HQAAL_SM_BUFFERINFO.x, offset, texcoord.x);
}
float HQAASearchXRight(sampler2D HQAALedgesTex, sampler2D HQAALsearchTex, float2 texcoord, float end)
{
    float2 e = float2(0.0, 1.0);
    bool endedge = false;
    [loop] while (texcoord.x < end) 
	{
        e = tex2Dlod(HQAALedgesTex, texcoord.xyxy).rg;
        texcoord = mad(float2(2.0, 0.0), __HQAAL_SM_BUFFERINFO.xy, texcoord);
        endedge = e.r > 0.0 || e.g == 0.0;
        if (endedge) break;
    }
    float offset = mad(-2.007874, HQAASearchLength(HQAALsearchTex, e, 0.5), 3.25);
    return mad(-__HQAAL_SM_BUFFERINFO.x, offset, texcoord.x);
}
float HQAASearchYUp(sampler2D HQAALedgesTex, sampler2D HQAALsearchTex, float2 texcoord, float end)
{
    float2 e = float2(1.0, 0.0);
    bool endedge = false;
    [loop] while (texcoord.y > end) 
	{
        e = tex2Dlod(HQAALedgesTex, texcoord.xyxy).rg;
        texcoord = mad(-float2(0.0, 2.0), __HQAAL_SM_BUFFERINFO.xy, texcoord);
        endedge = e.r == 0.0 || e.g > 0.0;
        if (endedge) break;
    }
    float offset = mad(-2.007874, HQAASearchLength(HQAALsearchTex, e.gr, 0.0), 3.25);
    return mad(__HQAAL_SM_BUFFERINFO.y, offset, texcoord.y);
}
float HQAASearchYDown(sampler2D HQAALedgesTex, sampler2D HQAALsearchTex, float2 texcoord, float end)
{
    float2 e = float2(1.0, 0.0);
    bool endedge = false;
    [loop] while (texcoord.y < end) 
	{
        e = tex2Dlod(HQAALedgesTex, texcoord.xyxy).rg;
        texcoord = mad(float2(0.0, 2.0), __HQAAL_SM_BUFFERINFO.xy, texcoord);
        endedge = e.r == 0.0 || e.g > 0.0;
        if (endedge) break;
    }
    float offset = mad(-2.007874, HQAASearchLength(HQAALsearchTex, e.gr, 0.5), 3.25);
    return mad(-__HQAAL_SM_BUFFERINFO.y, offset, texcoord.y);
}

float2 HQAAArea(sampler2D HQAALareaTex, float2 dist, float e1, float e2, float offset)
{
    float2 texcoord = mad(float(__HQAAL_SM_AREATEX_RANGE).xx, round(4.0 * float2(e1, e2)), dist);
    
    texcoord = mad(__HQAAL_SM_AREATEX_TEXEL, texcoord, 0.5 * __HQAAL_SM_AREATEX_TEXEL);
    texcoord.y = mad(__HQAAL_SM_AREATEX_SUBTEXEL, offset, texcoord.y);

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

//////////////////////////////////////////////////// FXAA HELPER FUNCTIONS //////////////////////////////////////////////////////////////

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

texture HQAALedgesTex
#if __RESHADE__ >= 50000
< pooled = true; >
#else
< pooled = false; >
#endif
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA8;
};

texture HQAALblendTex
#if __RESHADE__ >= 50000
< pooled = true; >
#else
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

sampler HQAALsamplerEdges
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
	MipFilter = Point; MinFilter = Point; MagFilter = Point;
};

//////////////////////////////////////////////////////////// VERTEX SHADERS /////////////////////////////////////////////////////////////

void HQAALEdgeDetectionVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0, out float4 offset[3] : TEXCOORD1)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    offset[0] = mad(__HQAAL_SM_BUFFERINFO.xyxy, float4(-1.0, 0.0, 0.0, -1.0), texcoord.xyxy);
    offset[1] = mad(__HQAAL_SM_BUFFERINFO.xyxy, float4( 1.0, 0.0, 0.0,  1.0), texcoord.xyxy);
    offset[2] = mad(__HQAAL_SM_BUFFERINFO.xyxy, float4(-2.0, 0.0, 0.0, -2.0), texcoord.xyxy);
}

void HQAALBlendingWeightCalculationVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0, out float2 pixcoord : TEXCOORD1, out float4 offset[3] : TEXCOORD2)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    pixcoord = texcoord * __HQAAL_SM_BUFFERINFO.zw;

    offset[0] = mad(__HQAAL_SM_BUFFERINFO.xyxy, float4(-0.25, -0.125,  1.25, -0.125), texcoord.xyxy);
    offset[1] = mad(__HQAAL_SM_BUFFERINFO.xyxy, float4(-0.125, -0.25, -0.125,  1.25), texcoord.xyxy);
	
	float searchrange = trunc(__HQAAL_SM_RADIUS);
	
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
float4 HQAALHybridEdgeDetectionPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float4 offset[3] : TEXCOORD1) : SV_Target
{
	float3 middle = HQAAL_DecodeTex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 adaptationaverage = middle;
	
	float basethreshold = __HQAAL_EDGE_THRESHOLD;
	
	float satmult = 1.0 - dotsat(middle);
	satmult = pow(abs(satmult), BUFFER_COLOR_BIT_DEPTH / 4.0);
	float lumamult = 1.0 - dot(middle, __HQAAL_LUMA_REF);
	lumamult = pow(abs(satmult), BUFFER_COLOR_BIT_DEPTH / 4.0);
	float2 lumathreshold = mad(lumamult, -(__HQAAL_DYNAMIC_RANGE * basethreshold), basethreshold).xx;
	float2 satthreshold = mad(satmult, -(__HQAAL_DYNAMIC_RANGE * basethreshold), basethreshold).xx;
	
	float2 edges = float(0.0).xx;
	
    float L = dotweight(0, middle, true, __HQAAL_LUMA_REF);
	
	float3 neighbor = HQAAL_DecodeTex2D(ReShade::BackBuffer, offset[0].xy).rgb;
	adaptationaverage += neighbor;
    float Lleft = dotweight(0, neighbor, true, __HQAAL_LUMA_REF);
    float Cleft = dotweight(middle, neighbor, false, 0);
    
	neighbor = HQAAL_DecodeTex2D(ReShade::BackBuffer, offset[0].zw).rgb;
	adaptationaverage += neighbor;
    float Ltop = dotweight(0, neighbor, true, __HQAAL_LUMA_REF);
    float Ctop = dotweight(middle, neighbor, false, 0);
    
    neighbor = HQAAL_DecodeTex2D(ReShade::BackBuffer, offset[1].xy).rgb;
	adaptationaverage += neighbor;
    float Lright = dotweight(0, neighbor, true, __HQAAL_LUMA_REF);
    float Cright = dotweight(middle, neighbor, false, 0);
	
	neighbor = HQAAL_DecodeTex2D(ReShade::BackBuffer, offset[1].zw).rgb;
	adaptationaverage += neighbor;
	float Lbottom = dotweight(0, neighbor, true, __HQAAL_LUMA_REF);
	float Cbottom = dotweight(middle, neighbor, false, 0);
	
	float maxL = HQAALmax4(Lleft, Ltop, Lright, Lbottom);
	float maxC = HQAALmax4(Cleft, Ctop, Cright, Cbottom);
	
	bool earlyExit = (abs(L - maxL) < lumathreshold.x) && (maxC < satthreshold.x);
	if (earlyExit) return float4(edges, HQAAL_Tex2D(HQAALsamplerEdges, texcoord).ba);
	
	adaptationaverage /= 5.0;
	
	bool useluma = abs(L - maxL) > maxC;
	float finalDelta;
	float4 delta;
	float scale;
	
	if (useluma)
	{
    	delta = abs(L - float4(Lleft, Ltop, Lright, Lbottom));
		edges = step(lumathreshold, delta.xy);
		float2 maxDelta = max(delta.xy, delta.zw);
		
		neighbor = HQAAL_DecodeTex2D(ReShade::BackBuffer, offset[2].xy).rgb;
		float Lleftleft = dotweight(0, neighbor, true, __HQAAL_LUMA_REF);
		
		neighbor = HQAAL_DecodeTex2D(ReShade::BackBuffer, offset[2].zw).rgb;
		float Ltoptop = dotweight(0, neighbor, true, __HQAAL_LUMA_REF);
		
		delta.zw = abs(float2(Lleft, Ltop) - float2(Lleftleft, Ltoptop));
		maxDelta = max(maxDelta, delta.zw);
		finalDelta = max(maxDelta.x, maxDelta.y);
	}
	else
	{
		delta = float4(Cleft, Ctop, Cright, Cbottom);
	    edges = step(satthreshold, delta.xy);
		float2 maxDelta = max(delta.xy, delta.zw);
		
		neighbor = HQAAL_DecodeTex2D(ReShade::BackBuffer, offset[2].xy).rgb;
		float Cleftleft = dotweight(middle, neighbor, false, 0);
		
		neighbor = HQAAL_DecodeTex2D(ReShade::BackBuffer, offset[2].zw).rgb;
		float Ctoptop = dotweight(middle, neighbor, false, 0);
		
		delta.zw = abs(float2(Cleft, Ctop) - float2(Cleftleft, Ctoptop));
		maxDelta = max(maxDelta, delta.zw);
		finalDelta = max(maxDelta.x, maxDelta.y);
	}
	
	// scale always has a range of 1 to e regardless of the bit depth.
	scale = pow(clamp(log(rcp(dot(adaptationaverage, __HQAAL_LUMA_REF))), 1.0, BUFFER_COLOR_BIT_DEPTH), rcp(log(BUFFER_COLOR_BIT_DEPTH)));
	
	edges *= step(finalDelta, scale * delta.xy);
	return float4(edges, HQAAL_Tex2D(HQAALsamplerEdges, texcoord).ba);
}

/////////////////////////////////////////////////////// ERROR REDUCTION ///////////////////////////////////////////////////////////////////
float4 HQAALTemporalEdgeAggregationPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float2 edges = HQAAL_Tex2D(HQAALsamplerSMweights, texcoord).rg;
	float2 aggregate = saturate(edges + HQAAL_Tex2D(HQAALsamplerSMweights, texcoord).ba);
	
	// skip checking neighbors if there's already no detected edge or no error margin check is desired
	if (!any(aggregate) || (__HQAAL_SM_ERRORMARGIN == -1.0)) return float4(aggregate, edges);
	
	float2 mask = float2(0.0, 1.0);
	if (all(aggregate)) mask = float2(0.0, 0.0);
	else if (aggregate.g > 0.0) mask = float2(1.0, 0.0);
	
    float2 a = saturate(saturate(HQAAL_Tex2DOffset(HQAALsamplerSMweights, texcoord, int2(-1, -1)).rg + HQAAL_Tex2DOffset(HQAALsamplerSMweights, texcoord, int2(-1, -1)).ba) - mask);
    float2 c = saturate(saturate(HQAAL_Tex2DOffset(HQAALsamplerSMweights, texcoord, int2(1, -1)).rg + HQAAL_Tex2DOffset(HQAALsamplerSMweights, texcoord, int2(1, -1)).ba) - mask);
    float2 g = saturate(saturate(HQAAL_Tex2DOffset(HQAALsamplerSMweights, texcoord, int2(-1, 1)).rg + HQAAL_Tex2DOffset(HQAALsamplerSMweights, texcoord, int2(-1, 1)).ba) - mask);
    float2 i = saturate(saturate(HQAAL_Tex2DOffset(HQAALsamplerSMweights, texcoord, int2(1, 1)).rg + HQAAL_Tex2DOffset(HQAALsamplerSMweights, texcoord, int2(1, 1)).ba) - mask);
    float2 b = saturate(saturate(HQAAL_Tex2DOffset(HQAALsamplerSMweights, texcoord, int2(0, -1)).rg + HQAAL_Tex2DOffset(HQAALsamplerSMweights, texcoord, int2(0, -1)).ba) - mask);
    float2 d = saturate(saturate(HQAAL_Tex2DOffset(HQAALsamplerSMweights, texcoord, int2(-1, 0)).rg + HQAAL_Tex2DOffset(HQAALsamplerSMweights, texcoord, int2(-1, 0)).ba) - mask);
    float2 f = saturate(saturate(HQAAL_Tex2DOffset(HQAALsamplerSMweights, texcoord, int2(1, 0)).rg + HQAAL_Tex2DOffset(HQAALsamplerSMweights, texcoord, int2(1, 0)).ba) - mask);
    float2 h = saturate(saturate(HQAAL_Tex2DOffset(HQAALsamplerSMweights, texcoord, int2(0, 1)).rg + HQAAL_Tex2DOffset(HQAALsamplerSMweights, texcoord, int2(0, 1)).ba) - mask);
    
    // this case isn't mathematically handled by the mask value, partials can pass
    if (all(aggregate))
    {
    	a = all(a) ? float2(1.0, 1.0) : float2(0.0, 0.0);
    	c = all(c) ? float2(1.0, 1.0) : float2(0.0, 0.0);
    	g = all(g) ? float2(1.0, 1.0) : float2(0.0, 0.0);
    	i = all(i) ? float2(1.0, 1.0) : float2(0.0, 0.0);
    	b = all(b) ? float2(1.0, 1.0) : float2(0.0, 0.0);
    	d = all(d) ? float2(1.0, 1.0) : float2(0.0, 0.0);
    	f = all(f) ? float2(1.0, 1.0) : float2(0.0, 0.0);
    	h = all(h) ? float2(1.0, 1.0) : float2(0.0, 0.0);
    }
    
	float2 adjacentsum = a + c + g + i + b + d + f + h;

	bool validedge = any(saturate(adjacentsum - 1.0)) && !any(saturate(adjacentsum - __HQAAL_SM_ERRORMARGIN));
	if (validedge) return float4(aggregate, edges);
	else return float4(0.0, 0.0, edges);
}

/////////////////////////////////////////////////// BLEND WEIGHT CALCULATION //////////////////////////////////////////////////////////////
float4 HQAALBlendingWeightCalculationPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float2 pixcoord : TEXCOORD1, float4 offset[3] : TEXCOORD2) : SV_Target
{
    float4 weights = float(0.0).xxxx;
    float2 e = HQAAL_Tex2D(HQAALsamplerEdges, texcoord).rg;
    bool2 edges = bool2(e.r > 0.0, e.g > 0.0);
	
	[branch] if (edges.g) 
	{
        float3 coords = float3(HQAASearchXLeft(HQAALsamplerEdges, HQAALsamplerSMsearch, offset[0].xy, offset[2].x), offset[1].y, HQAASearchXRight(HQAALsamplerEdges, HQAALsamplerSMsearch, offset[0].zw, offset[2].y));
        float e1 = HQAAL_Tex2D(HQAALsamplerEdges, coords.xy).r;
		float2 d = coords.xz;
        d = abs(round(mad(__HQAAL_SM_BUFFERINFO.zz, d, -pixcoord.xx)));
        float e2 = HQAAL_Tex2DOffset(HQAALsamplerEdges, coords.zy, int2(1, 0)).r;
        weights.rg = HQAAArea(HQAALsamplerSMarea, sqrt(d), e1, e2, 0.0);
        coords.y = texcoord.y;
        HQAADetectHorizontalCornerPattern(HQAALsamplerEdges, weights.rg, coords.xyzy, d);
    }
	
	[branch] if (edges.r) 
	{
        float3 coords = float3(offset[0].x, HQAASearchYUp(HQAALsamplerEdges, HQAALsamplerSMsearch, offset[1].xy, offset[2].z), HQAASearchYDown(HQAALsamplerEdges, HQAALsamplerSMsearch, offset[1].zw, offset[2].w));
        float e1 = HQAAL_Tex2D(HQAALsamplerEdges, coords.xy).g;
		float2 d = coords.yz;
        d = abs(round(mad(__HQAAL_SM_BUFFERINFO.ww, d, -pixcoord.yy)));
        float e2 = HQAAL_Tex2DOffset(HQAALsamplerEdges, coords.xz, int2(0, 1)).g;
        weights.ba = HQAAArea(HQAALsamplerSMarea, sqrt(d), e1, e2, 0.0);
        coords.x = texcoord.x;
        HQAADetectVerticalCornerPattern(HQAALsamplerEdges, weights.ba, coords.xyxz, d);
    }

    return weights;
}

//////////////////////////////////////////////////// NEIGHBORHOOD BLENDING ////////////////////////////////////////////////////////////////
float3 HQAALNeighborhoodBlendingPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float4 offset : TEXCOORD1) : SV_Target
{
    float4 m = float4(HQAAL_Tex2D(HQAALsamplerSMweights, offset.xy).a, HQAAL_Tex2D(HQAALsamplerSMweights, offset.zw).g, HQAAL_Tex2D(HQAALsamplerSMweights, texcoord).zx);
	float3 resultAA = HQAAL_Tex2D(ReShade::BackBuffer, texcoord).rgb;
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
        float4 blendingCoord = mad(blendingOffset, float4(__HQAAL_SM_BUFFERINFO.xy, -__HQAAL_SM_BUFFERINFO.xy), texcoord.xyxy);
        resultAA = blendingWeight.x * HQAAL_DecodeTex2D(ReShade::BackBuffer, blendingCoord.xy).rgb;
        resultAA += blendingWeight.y * HQAAL_DecodeTex2D(ReShade::BackBuffer, blendingCoord.zw).rgb;
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

float3 HQAALFXPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
 {
    float3 middle = HQAAL_Tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 eedot = middle;
	
	middle = ConditionalDecode(middle);
	float lumaM = dot(middle, __HQAAL_LUMA_REF);
	
	float3 neighbor = HQAAL_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 0, 1)).rgb;
    float lumaS = dotweight(middle, neighbor, true, __HQAAL_LUMA_REF);
    float chromaS = dotweight(middle, neighbor, false, __HQAAL_LUMA_REF);
    
	neighbor = HQAAL_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 1, 0)).rgb;
    float lumaE = dotweight(middle, neighbor, true, __HQAAL_LUMA_REF);
    float chromaE = dotweight(middle, neighbor, false, __HQAAL_LUMA_REF);
    
	neighbor = HQAAL_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 0,-1)).rgb;
    float lumaN = dotweight(middle, neighbor, true, __HQAAL_LUMA_REF);
    float chromaN = dotweight(middle, neighbor, false, __HQAAL_LUMA_REF);
    
	neighbor = HQAAL_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, 0)).rgb;
    float lumaW = dotweight(middle, neighbor, true, __HQAAL_LUMA_REF);
    float chromaW = dotweight(middle, neighbor, false, __HQAAL_LUMA_REF);
    
    bool useluma = HQAALmax4(abs(lumaS - lumaM), abs(lumaE - lumaM), abs(lumaN - lumaM), abs(lumaW - lumaM)) > HQAALmax4(chromaS, chromaE, chromaN, chromaW);
    
    if (!useluma) { lumaS = chromaS; lumaE = chromaE; lumaN = chromaN; lumaW = chromaW; lumaM = 0.0; }
	
    float rangeMax = HQAALmax5(lumaS, lumaE, lumaN, lumaW, lumaM);
    float rangeMin = HQAALmin5(lumaS, lumaE, lumaN, lumaW, lumaM);
	
    float range = rangeMax - rangeMin;
    
	// early exit check
	bool SMAAedge = any(HQAAL_Tex2D(HQAALsamplerEdges, texcoord).rg);
    bool earlyExit = (range < __HQAAL_EDGE_THRESHOLD) && (!SMAAedge);
	if (earlyExit) return eedot;
	
    float lumaNW = dotweight(middle, HQAAL_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1,-1)).rgb, useluma, __HQAAL_LUMA_REF);
    float lumaSE = dotweight(middle, HQAAL_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 1, 1)).rgb, useluma, __HQAAL_LUMA_REF);
    float lumaNE = dotweight(middle, HQAAL_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2( 1,-1)).rgb, useluma, __HQAAL_LUMA_REF);
    float lumaSW = dotweight(middle, HQAAL_DecodeTex2DOffset(ReShade::BackBuffer, texcoord, int2(-1, 1)).rgb, useluma, __HQAAL_LUMA_REF);
	
    bool horzSpan = (abs(mad(-2.0, lumaW, lumaNW + lumaSW)) + mad(2.0, abs(mad(-2.0, lumaM, lumaN + lumaS)), abs(mad(-2.0, lumaE, lumaNE + lumaSE)))) >= (abs(mad(-2.0, lumaS, lumaSW + lumaSE)) + mad(2.0, abs(mad(-2.0, lumaM, lumaW + lumaE)), abs(mad(-2.0, lumaN, lumaNW + lumaNE))));	
    float lengthSign = horzSpan ? BUFFER_RCP_HEIGHT : BUFFER_RCP_WIDTH;
	
	float2 lumaNP = float2(lumaN, lumaS);
	HQAAMovc(bool(!horzSpan).xx, lumaNP, float2(lumaW, lumaE));
	
    float gradientN = lumaNP.x - lumaM;
    float gradientS = lumaNP.y - lumaM;
    float lumaNN = lumaNP.x + lumaM;
	
    if (abs(gradientN) >= abs(gradientS)) lengthSign = -lengthSign;
    else lumaNN = lumaNP.y + lumaM;
	
    float2 posB = texcoord;
	
	float texelsize = __HQAAL_FX_TEXEL;

    float2 offNP = float2(0.0, BUFFER_RCP_HEIGHT * texelsize);
	HQAAMovc(bool(horzSpan).xx, offNP, float2(BUFFER_RCP_WIDTH * texelsize, 0.0));
	
	HQAAMovc(bool2(!horzSpan, horzSpan), posB, float2(posB.x + lengthSign / 2.0, posB.y + lengthSign / 2.0));
	
    float2 posN = posB - offNP;
    float2 posP = posB + offNP;
    
    float lumaEndN = dotweight(middle, HQAAL_DecodeTex2D(ReShade::BackBuffer, posN).rgb, useluma, __HQAAL_LUMA_REF);
    float lumaEndP = dotweight(middle, HQAAL_DecodeTex2D(ReShade::BackBuffer, posP).rgb, useluma, __HQAAL_LUMA_REF);
	
    float gradientScaled = max(abs(gradientN), abs(gradientS)) * 0.25;
    bool lumaMLTZero = mad(0.5, -lumaNN, lumaM) < 0.0;
	
	lumaNN *= 0.5;
	
    lumaEndN -= lumaNN;
    lumaEndP -= lumaNN;
	
    bool doneN = abs(lumaEndN) >= gradientScaled;
    bool doneP = abs(lumaEndP) >= gradientScaled;
    bool doneNP;
	
	uint iterations = 0;
	uint maxiterations = trunc(__HQAAL_FX_RADIUS * __HQAAL_FX_QUALITY);
	[loop] while (iterations < maxiterations)
	{
		doneNP = doneN && doneP;
		if (doneNP) break;
		if (!doneN)
		{
			posN -= offNP;
			lumaEndN = dotweight(middle, HQAAL_DecodeTex2D(ReShade::BackBuffer, posN).rgb, useluma, __HQAAL_LUMA_REF);
			lumaEndN -= lumaNN;
			doneN = abs(lumaEndN) >= gradientScaled;
		}
		if (!doneP)
		{
			posP += offNP;
			lumaEndP = dotweight(middle, HQAAL_DecodeTex2D(ReShade::BackBuffer, posP).rgb, useluma, __HQAAL_LUMA_REF);
			lumaEndP -= lumaNN;
			doneP = abs(lumaEndP) >= gradientScaled;
		}
		iterations++;
    }
	
	float2 dstNP = float2(texcoord.y - posN.y, posP.y - texcoord.y);
	HQAAMovc(bool(horzSpan).xx, dstNP, float2(texcoord.x - posN.x, posP.x - texcoord.x));
	
    bool goodSpan = (dstNP.x < dstNP.y) ? ((lumaEndN < 0.0) != lumaMLTZero) : ((lumaEndP < 0.0) != lumaMLTZero);
    float pixelOffset = mad(-rcp(dstNP.y + dstNP.x), min(dstNP.x, dstNP.y), 0.5);
    float maxblending = __HQAAL_FX_BLEND;
    float subpixOut = pixelOffset * maxblending;
	
	[branch] if (!goodSpan)
	{
		subpixOut = mad(mad(2.0, lumaS + lumaE + lumaN + lumaW, lumaNW + lumaSE + lumaNE + lumaSW), 0.083333, -lumaM) * rcp(range); //ABC
		subpixOut = squared(saturate(mad(-2.0, subpixOut, 3.0) * (subpixOut * subpixOut))) * maxblending * pixelOffset; // DEFGH
	}

    float2 posM = texcoord;
	HQAAMovc(bool2(!horzSpan, horzSpan), posM, float2(posM.x + lengthSign * subpixOut, posM.y + lengthSign * subpixOut));
    
	return HQAAL_Tex2D(ReShade::BackBuffer, posM).rgb;
}

/***************************************************************************************************************************************/
/********************************************************** FXAA SHADER CODE END *******************************************************/
/***************************************************************************************************************************************/

technique HQAA_Lite <
	ui_tooltip = "============================================================\n"
				 "Hybrid high-Quality Anti-Aliasing combines techniques of\n"
				 "both SMAA and FXAA to produce best possible image quality\n"
				 "from using both. HQAA uses customized edge detection methods\n"
				 "designed for maximum possible aliasing detection.\n"
				 "Lite version trades flexibility for speed while keeping as\n"
				 "many advanced features as possible.\n"
				 "============================================================";
>
{
	pass EdgeDetection
	{
		VertexShader = HQAALEdgeDetectionVS;
		PixelShader = HQAALHybridEdgeDetectionPS;
		RenderTarget = HQAALblendTex;
		ClearRenderTargets = true;
	}
	pass TemporalEdgeAggregation
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAALTemporalEdgeAggregationPS;
		RenderTarget = HQAALedgesTex;
		ClearRenderTargets = true;
	}
	pass SMAABlendCalculation
	{
		VertexShader = HQAALBlendingWeightCalculationVS;
		PixelShader = HQAALBlendingWeightCalculationPS;
		RenderTarget = HQAALblendTex;
		ClearRenderTargets = true;
	}
	pass SMAABlending
	{
		VertexShader = HQAALNeighborhoodBlendingVS;
		PixelShader = HQAALNeighborhoodBlendingPS;
	}
	pass FXAA
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAALFXPS;
	}
#if HQAAL_FXAA_MULTISAMPLING > 1
	pass FXAA
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAALFXPS;
	}
#if HQAAL_FXAA_MULTISAMPLING > 2
	pass FXAA
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAALFXPS;
	}
#if HQAAL_FXAA_MULTISAMPLING > 3
	pass FXAA
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAALFXPS;
	}
#endif //HQAA_USE_MULTISAMPLED_FXAA3
#endif //HQAA_USE_MULTISAMPLED_FXAA2
#endif //HQAA_USE_MULTISAMPLED_FXAA1
}
