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
 *                    v2.8 release
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


uniform float EdgeThreshold < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Edge Detection Threshold";
	ui_tooltip = "Local contrast required to run shader";
        ui_category = "Normal Usage";
> = 0.1;

uniform float Subpix < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Subpixel Effects Strength";
	ui_tooltip = "Lower = sharper image, Higher = more AA effect";
        ui_category = "Normal Usage";
> = 0.5;

uniform int PmodeWarning <
	ui_type = "radio";
	ui_label = " ";	
	ui_text ="\n>>>> WARNING <<<<\n\nVirtual Photography mode allows HQAA to exceed its normal\nlimits when processing subpixel aliasing and will probably\nresult in too much blurring for everyday usage.\n\nIt is only intended for virtual photography purposes where\nthe game's UI is typically not present on the screen.";
	ui_category = "Virtual Photography";
>;

uniform bool Overdrive <
        ui_label = "Enable Virtual Photography Mode";
        ui_category = "Virtual Photography";
> = false;

uniform float SubpixBoost < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Extra Subpixel Effects Strength";
	ui_tooltip = "Additional boost to subpixel aliasing processing";
        ui_category = "Virtual Photography";
> = 0.00;

/*****************************************************************************************************************************************/
/*********************************************************** UI SETUP END ****************************************************************/
/*****************************************************************************************************************************************/

/*****************************************************************************************************************************************/
/*********************************************************** SMAA CODE BLOCK START *******************************************************/
/*****************************************************************************************************************************************/

// DX11 optimization
#if (__RENDERER__ == 0xb000 || __RENDERER__ == 0xb100)
	#define __SMAAGather(tex, coord) tex2Dgather(tex, coord, 0)
#endif

// Configurable
#define __SMAA_THRESHOLD EdgeThreshold
#define __SMAA_MAX_SEARCH_STEPS 112
#define __SMAA_CORNER_ROUNDING (Overdrive ? 50 : 10 * Subpix)
#define __SMAA_MAX_SEARCH_STEPS_DIAG 20
#define __SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR_LUMA (1.0625 + (0.0625 * Subpix) + (Overdrive ? SubpixBoost * 0.125 : 0))
#define __SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR_COLOR (1.125 + (0.125 * Subpix) + (Overdrive ? SubpixBoost * 0.25 : 0))
#define __SMAA_RT_METRICS float4(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT, BUFFER_WIDTH, BUFFER_HEIGHT)
#define __SMAATexture2D(tex) sampler tex
#define __SMAATexturePass2D(tex) tex
#define __SMAASampleLevelZero(tex, coord) tex2Dlod(tex, float4(coord, coord))
#define __SMAASampleLevelZeroPoint(tex, coord) __SMAASampleLevelZero(tex, coord)
#define __SMAASampleLevelZeroOffset(tex, coord, offset) tex2Dlodoffset(tex, float4(coord, coord), offset)
#define __SMAASample(tex, coord) tex2D(tex, coord)
#define __SMAASamplePoint(tex, coord) __SMAASample(tex, coord)
#define __SMAASampleOffset(tex, coord, offset) tex2Doffset(tex, coord, offset)
#define __SMAA_BRANCH [branch]
#define __SMAA_FLATTEN [flatten]
#define __SMAA_REPROJECTION 0
#define __SMAA_INCLUDE_VS 1
#define __SMAA_INCLUDE_PS 1
#define __SMAA_REPROJECTION_WEIGHT_SCALE 30.0
#define __SMAA_AREATEX_SELECT(sample) sample.rg
#define __SMAA_SEARCHTEX_SELECT(sample) sample.r
#define __SMAA_DECODE_VELOCITY(sample) sample.rg

// Constants
#define __SMAA_AREATEX_MAX_DISTANCE 16
#define __SMAA_AREATEX_MAX_DISTANCE_DIAG 20
#define __SMAA_AREATEX_PIXEL_SIZE (1.0 / float2(160.0, 560.0))
#define __SMAA_AREATEX_SUBTEX_SIZE (1.0 / 7.0)
#define __SMAA_SEARCHTEX_SIZE float2(66.0, 33.0)
#define __SMAA_SEARCHTEX_PACKED_SIZE float2(64.0, 16.0)
#define __SMAA_CORNER_ROUNDING_NORM (float(__SMAA_CORNER_ROUNDING) / 100.0)

/////////////////////////////////////////////// SMAA SUPPORT FUNCTIONS ////////////////////////////////////////////////////////////////////

/**
 * Gathers current pixel, and the top-left neighbors.
 */
float3 __SMAAGatherNeighbours(float2 texcoord,
                            float4 offset[3],
                            __SMAATexture2D(tex)) {
    #ifdef __SMAAGather
    return __SMAAGather(tex, texcoord + __SMAA_RT_METRICS.xy * float2(-0.5, -0.5)).grb;
    #else
    float P = __SMAASamplePoint(tex, texcoord).r;
    float Pleft = __SMAASamplePoint(tex, offset[0].xy).r;
    float Ptop  = __SMAASamplePoint(tex, offset[0].zw).r;
    return float3(P, Pleft, Ptop);
    #endif
}

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

/////////////////////////////////////////////// SMAA VERTEX SHADERS ///////////////////////////////////////////////////////////////////////

#if __SMAA_INCLUDE_VS


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

    // We will use these offsets for the searches later on (see @PSEUDO_GATHER4):
    offset[0] = mad(__SMAA_RT_METRICS.xyxy, float4(-0.25, -0.125,  1.25, -0.125), texcoord.xyxy);
    offset[1] = mad(__SMAA_RT_METRICS.xyxy, float4(-0.125, -0.25, -0.125,  1.25), texcoord.xyxy);

    // And these for the searches, they indicate the ends of the loops:
    offset[2] = mad(__SMAA_RT_METRICS.xxyy,
                    float4(-2.0, 2.0, -2.0, 2.0) * float(__SMAA_MAX_SEARCH_STEPS),
                    float4(offset[0].xz, offset[1].yw));
}


void SMAANeighborhoodBlendingVS(float2 texcoord,
                                out float4 offset) {
    offset = mad(__SMAA_RT_METRICS.xyxy, float4( 1.0, 0.0, 0.0,  1.0), texcoord.xyxy);
}
#endif // __SMAA_INCLUDE_VS

/////////////////////////////////////////////// SMAA PIXEL SHADERS ////////////////////////////////////////////////////////////////////////

#if __SMAA_INCLUDE_PS

/**
 * Luma Edge Detection
 *
 * IMPORTANT NOTICE: luma edge detection requires gamma-corrected colors, and
 * thus 'colorTex' should be a non-sRGB texture.
 */
float2 SMAALumaEdgeDetectionPS(float2 texcoord,
                               float4 offset[3],
                               __SMAATexture2D(colorTex)
                               ) {
 // SMAA default luma weights: 0.2126, 0.7152, 0.0722
								   
    // Calculate the threshold:
    float2 threshold = float2(__SMAA_THRESHOLD, __SMAA_THRESHOLD);

    // Calculate lumas:
	float3 middle = __SMAASamplePoint(colorTex, texcoord).rgb;
	float3 weights = float3(middle.r > middle.g? 0.85 : 0.1, middle.r <= middle.g ? 0.85 : 0.1, 0.05);
	
    float L = dot(middle, weights);

    float Lleft = dot(__SMAASamplePoint(colorTex, offset[0].xy).rgb, weights);
    float Ltop  = dot(__SMAASamplePoint(colorTex, offset[0].zw).rgb, weights);

    // We do the usual threshold:
    float4 delta;
    delta.xy = abs(L - float2(Lleft, Ltop));
    float2 edges = step(threshold, delta.xy);

    // Calculate right and bottom deltas:
    float Lright = dot(__SMAASamplePoint(colorTex, offset[1].xy).rgb, weights);
    float Lbottom  = dot(__SMAASamplePoint(colorTex, offset[1].zw).rgb, weights);
    delta.zw = abs(L - float2(Lright, Lbottom));

    // Calculate the maximum delta in the direct neighborhood:
    float2 maxDelta = max(delta.xy, delta.zw);

    // Calculate left-left and top-top deltas:
    float Lleftleft = dot(__SMAASamplePoint(colorTex, offset[2].xy).rgb, weights);
    float Ltoptop = dot(__SMAASamplePoint(colorTex, offset[2].zw).rgb, weights);
    delta.zw = abs(float2(Lleft, Ltop) - float2(Lleftleft, Ltoptop));

    // Calculate the final maximum delta:
    maxDelta = max(maxDelta.xy, delta.zw);
    float finalDelta = max(maxDelta.x, maxDelta.y);

    // Local contrast adaptation:
	edges.xy *= step(finalDelta, __SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR_LUMA * delta.xy);

    return edges;
}

/**
 * Color Edge Detection
 *
 * IMPORTANT NOTICE: color edge detection requires gamma-corrected colors, and
 * thus 'colorTex' should be a non-sRGB texture.
 */
float2 SMAAColorEdgeDetectionPS(float2 texcoord,
                                float4 offset[3],
                                __SMAATexture2D(colorTex)
                                ) {
    // Calculate the threshold:
    float2 threshold = float2(__SMAA_THRESHOLD, __SMAA_THRESHOLD);

    // Calculate color deltas:
    float4 delta;
    float3 C = __SMAASamplePoint(colorTex, texcoord).rgb;

    float3 Cleft = __SMAASamplePoint(colorTex, offset[0].xy).rgb;
    float3 t = abs(C - Cleft);
    delta.x = max(max(t.r, t.g), t.b);

    float3 Ctop  = __SMAASamplePoint(colorTex, offset[0].zw).rgb;
    t = abs(C - Ctop);
    delta.y = max(max(t.r, t.g), t.b);

    // We do the usual threshold:
    float2 edges = step(threshold, delta.xy);

    // Calculate right and bottom deltas:
    float3 Cright = __SMAASamplePoint(colorTex, offset[1].xy).rgb;
    t = abs(C - Cright);
    delta.z = max(max(t.r, t.g), t.b);

    float3 Cbottom  = __SMAASamplePoint(colorTex, offset[1].zw).rgb;
    t = abs(C - Cbottom);
    delta.w = max(max(t.r, t.g), t.b);

    // Calculate the maximum delta in the direct neighborhood:
    float2 maxDelta = max(delta.xy, delta.zw);

    // Calculate left-left and top-top deltas:
    float3 Cleftleft  = __SMAASamplePoint(colorTex, offset[2].xy).rgb;
    t = abs(Cleft - Cleftleft);
    delta.z = max(max(t.r, t.g), t.b);

    float3 Ctoptop = __SMAASamplePoint(colorTex, offset[2].zw).rgb;
    t = abs(Ctop - Ctoptop);
    delta.w = max(max(t.r, t.g), t.b);

    // Calculate the final maximum delta:
    maxDelta = max(maxDelta.xy, delta.zw);
    float finalDelta = max(maxDelta.x, maxDelta.y);

    // Local contrast adaptation:
    edges.xy *= step(finalDelta, __SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR_COLOR * delta.xy);

    return edges;
}


#if !defined(SMAA_DISABLE_DIAG_DETECTION)

/**
 * Allows to decode two binary values from a bilinear-filtered access.
 */
float2 SMAADecodeDiagBilinearAccess(float2 e) {
    // Bilinear access for fetching 'e' have a 0.25 offset, and we are
    // interested in the R and G edges:
    //
    // +---G---+-------+
    // |   x o R   x   |
    // +-------+-------+
    //
    // Then, if one of these edge is enabled:
    //   Red:   (0.75 * X + 0.25 * 1) => 0.25 or 1.0
    //   Green: (0.75 * 1 + 0.25 * X) => 0.75 or 1.0
    //
    // This function will unpack the values (mad + mul + round):
    // wolframalpha.com: round(x * abs(5 * x - 5 * 0.75)) plot 0 to 1
    e.r = e.r * abs(5.0 * e.r - 5.0 * 0.75);
    return round(e);
}

float4 SMAADecodeDiagBilinearAccess(float4 e) {
    e.rb = e.rb * abs(5.0 * e.rb - 5.0 * 0.75);
    return round(e);
}


float2 SMAASearchDiag1(__SMAATexture2D(HQAAedgesTex), float2 texcoord, float2 dir, out float2 e) {
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

float2 SMAASearchDiag2(__SMAATexture2D(HQAAedgesTex), float2 texcoord, float2 dir, out float2 e) {
    float4 coord = float4(texcoord, -1.0, 1.0);
    coord.x += 0.25 * __SMAA_RT_METRICS.x; // See @SearchDiag2Optimization
    float3 t = float3(__SMAA_RT_METRICS.xy, 1.0);
    while (coord.z < float(__SMAA_MAX_SEARCH_STEPS_DIAG - 1) &&
           coord.w > 0.9) {
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);

        // @SearchDiag2Optimization
        // Fetch both edges at once using bilinear filtering:
        e = __SMAASampleLevelZero(HQAAedgesTex, coord.xy).rg;
        e = SMAADecodeDiagBilinearAccess(e);

        // Non-optimized version:
        // e.g = __SMAASampleLevelZero(HQAAedgesTex, coord.xy).g;
        // e.r = __SMAASampleLevelZeroOffset(HQAAedgesTex, coord.xy, int2(1, 0)).r;

        coord.w = dot(e, float2(0.5, 0.5));
    }
    return coord.zw;
}

/** 
 * Similar to SMAAArea, this calculates the area corresponding to a certain
 * diagonal distance and crossing edges 'e'.
 */
float2 SMAAAreaDiag(__SMAATexture2D(HQAAareaTex), float2 dist, float2 e, float offset) {
    float2 texcoord = mad(float2(__SMAA_AREATEX_MAX_DISTANCE_DIAG, __SMAA_AREATEX_MAX_DISTANCE_DIAG), e, dist);

    // We do a scale and bias for mapping to texel space:
    texcoord = mad(__SMAA_AREATEX_PIXEL_SIZE, texcoord, 0.5 * __SMAA_AREATEX_PIXEL_SIZE);

    // Diagonal areas are on the second half of the texture:
    texcoord.x += 0.5;

    // Move to proper place, according to the subpixel offset:
    texcoord.y += __SMAA_AREATEX_SUBTEX_SIZE * offset;

    // Do it!
    return __SMAA_AREATEX_SELECT(__SMAASampleLevelZero(HQAAareaTex, texcoord));
}

/**
 * This searches for diagonal patterns and returns the corresponding weights.
 */
float2 SMAACalculateDiagWeights(__SMAATexture2D(HQAAedgesTex), __SMAATexture2D(HQAAareaTex), float2 texcoord, float2 e, float4 subsampleIndices) {
    float2 weights = float2(0.0, 0.0);

    // Search for the line ends:
    float4 d;
    float2 end;
    if (e.r > 0.0) {
        d.xz = SMAASearchDiag1(__SMAATexturePass2D(HQAAedgesTex), texcoord, float2(-1.0,  1.0), end);
        d.x += float(end.y > 0.9);
    } else
        d.xz = float2(0.0, 0.0);
    d.yw = SMAASearchDiag1(__SMAATexturePass2D(HQAAedgesTex), texcoord, float2(1.0, -1.0), end);

    __SMAA_BRANCH
    if (d.x + d.y > 2.0) { // d.x + d.y + 1 > 3
        // Fetch the crossing edges:
        float4 coords = mad(float4(-d.x + 0.25, d.x, d.y, -d.y - 0.25), __SMAA_RT_METRICS.xyxy, texcoord.xyxy);
        float4 c;
        c.xy = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.xy, int2(-1,  0)).rg;
        c.zw = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.zw, int2( 1,  0)).rg;
        c.yxwz = SMAADecodeDiagBilinearAccess(c.xyzw);

        // Non-optimized version:
        // float4 coords = mad(float4(-d.x, d.x, d.y, -d.y), __SMAA_RT_METRICS.xyxy, texcoord.xyxy);
        // float4 c;
        // c.x = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.xy, int2(-1,  0)).g;
        // c.y = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.xy, int2( 0,  0)).r;
        // c.z = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.zw, int2( 1,  0)).g;
        // c.w = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.zw, int2( 1, -1)).r;

        // Merge crossing edges at each side into a single value:
        float2 cc = mad(float2(2.0, 2.0), c.xz, c.yw);

        // Remove the crossing edge if we didn't found the end of the line:
        SMAAMovc(bool2(step(0.9, d.zw)), cc, float2(0.0, 0.0));

        // Fetch the areas for this line:
        weights += SMAAAreaDiag(__SMAATexturePass2D(HQAAareaTex), d.xy, cc, subsampleIndices.z);
    }

    // Search for the line ends:
    d.xz = SMAASearchDiag2(__SMAATexturePass2D(HQAAedgesTex), texcoord, float2(-1.0, -1.0), end);
    if (__SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord, int2(1, 0)).r > 0.0) {
        d.yw = SMAASearchDiag2(__SMAATexturePass2D(HQAAedgesTex), texcoord, float2(1.0, 1.0), end);
        d.y += float(end.y > 0.9);
    } else
        d.yw = float2(0.0, 0.0);

    __SMAA_BRANCH
    if (d.x + d.y > 2.0) { // d.x + d.y + 1 > 3
        // Fetch the crossing edges:
        float4 coords = mad(float4(-d.x, -d.x, d.y, d.y), __SMAA_RT_METRICS.xyxy, texcoord.xyxy);
        float4 c;
        c.x  = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.xy, int2(-1,  0)).g;
        c.y  = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.xy, int2( 0, -1)).r;
        c.zw = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.zw, int2( 1,  0)).gr;
        float2 cc = mad(float2(2.0, 2.0), c.xz, c.yw);

        // Remove the crossing edge if we didn't found the end of the line:
        SMAAMovc(bool2(step(0.9, d.zw)), cc, float2(0.0, 0.0));

        // Fetch the areas for this line:
        weights += SMAAAreaDiag(__SMAATexturePass2D(HQAAareaTex), d.xy, cc, subsampleIndices.w).gr;
    }

    return weights;
}
#endif


/**
 * This allows to determine how much length should we add in the last step
 * of the searches. It takes the bilinearly interpolated edge (see 
 * @PSEUDO_GATHER4), and adds 0, 1 or 2, depending on which edges and
 * crossing edges are active.
 */
float SMAASearchLength(__SMAATexture2D(HQAAsearchTex), float2 e, float offset) {
    // The texture is flipped vertically, with left and right cases taking half
    // of the space horizontally:
    float2 scale = __SMAA_SEARCHTEX_SIZE * float2(0.5, -1.0);
    float2 bias = __SMAA_SEARCHTEX_SIZE * float2(offset, 1.0);

    // Scale and bias to access texel centers:
    scale += float2(-1.0,  1.0);
    bias  += float2( 0.5, -0.5);

    // Convert from pixel coordinates to texcoords:
    // (We use __SMAA_SEARCHTEX_PACKED_SIZE because the texture is cropped)
    scale *= 1.0 / __SMAA_SEARCHTEX_PACKED_SIZE;
    bias *= 1.0 / __SMAA_SEARCHTEX_PACKED_SIZE;

    // Lookup the search texture:
    return __SMAA_SEARCHTEX_SELECT(__SMAASampleLevelZero(HQAAsearchTex, mad(scale, e, bias)));
}

/**
 * Horizontal/vertical search functions for the 2nd pass.
 */
float SMAASearchXLeft(__SMAATexture2D(HQAAedgesTex), __SMAATexture2D(HQAAsearchTex), float2 texcoord, float end) {
    /**
     * @PSEUDO_GATHER4
     * This texcoord has been offset by (-0.25, -0.125) in the vertex shader to
     * sample between edge, thus fetching four edges in a row.
     * Sampling with different offsets in each direction allows to disambiguate
     * which edges are active from the four fetched ones.
     */
    float2 e = float2(0.0, 1.0);
    while (texcoord.x > end && 
           e.g > 0.8281 && // Is there some edge not activated?
           e.r == 0.0) { // Or is there a crossing edge that breaks the line?
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(-float2(2.0, 0.0), __SMAA_RT_METRICS.xy, texcoord);
    }

    float offset = mad(-(255.0 / 127.0), SMAASearchLength(__SMAATexturePass2D(HQAAsearchTex), e, 0.0), 3.25);
    return mad(__SMAA_RT_METRICS.x, offset, texcoord.x);

    // Non-optimized version:
    // We correct the previous (-0.25, -0.125) offset we applied:
    // texcoord.x += 0.25 * __SMAA_RT_METRICS.x;

    // The searches are bias by 1, so adjust the coords accordingly:
    // texcoord.x += __SMAA_RT_METRICS.x;

    // Disambiguate the length added by the last step:
    // texcoord.x += 2.0 * __SMAA_RT_METRICS.x; // Undo last step
    // texcoord.x -= __SMAA_RT_METRICS.x * (255.0 / 127.0) * SMAASearchLength(__SMAATexturePass2D(HQAAsearchTex), e, 0.0);
    // return mad(__SMAA_RT_METRICS.x, offset, texcoord.x);
}

float SMAASearchXRight(__SMAATexture2D(HQAAedgesTex), __SMAATexture2D(HQAAsearchTex), float2 texcoord, float end) {
    float2 e = float2(0.0, 1.0);
    while (texcoord.x < end && 
           e.g > 0.8281 && // Is there some edge not activated?
           e.r == 0.0) { // Or is there a crossing edge that breaks the line?
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(float2(2.0, 0.0), __SMAA_RT_METRICS.xy, texcoord);
    }
    float offset = mad(-(255.0 / 127.0), SMAASearchLength(__SMAATexturePass2D(HQAAsearchTex), e, 0.5), 3.25);
    return mad(-__SMAA_RT_METRICS.x, offset, texcoord.x);
}

float SMAASearchYUp(__SMAATexture2D(HQAAedgesTex), __SMAATexture2D(HQAAsearchTex), float2 texcoord, float end) {
    float2 e = float2(1.0, 0.0);
    while (texcoord.y > end && 
           e.r > 0.8281 && // Is there some edge not activated?
           e.g == 0.0) { // Or is there a crossing edge that breaks the line?
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(-float2(0.0, 2.0), __SMAA_RT_METRICS.xy, texcoord);
    }
    float offset = mad(-(255.0 / 127.0), SMAASearchLength(__SMAATexturePass2D(HQAAsearchTex), e.gr, 0.0), 3.25);
    return mad(__SMAA_RT_METRICS.y, offset, texcoord.y);
}

float SMAASearchYDown(__SMAATexture2D(HQAAedgesTex), __SMAATexture2D(HQAAsearchTex), float2 texcoord, float end) {
    float2 e = float2(1.0, 0.0);
    while (texcoord.y < end && 
           e.r > 0.8281 && // Is there some edge not activated?
           e.g == 0.0) { // Or is there a crossing edge that breaks the line?
        e = __SMAASampleLevelZero(HQAAedgesTex, texcoord).rg;
        texcoord = mad(float2(0.0, 2.0), __SMAA_RT_METRICS.xy, texcoord);
    }
    float offset = mad(-(255.0 / 127.0), SMAASearchLength(__SMAATexturePass2D(HQAAsearchTex), e.gr, 0.5), 3.25);
    return mad(-__SMAA_RT_METRICS.y, offset, texcoord.y);
}

/** 
 * Ok, we have the distance and both crossing edges. So, what are the areas
 * at each side of current edge?
 */
float2 SMAAArea(__SMAATexture2D(HQAAareaTex), float2 dist, float e1, float e2, float offset) {
    // Rounding prevents precision errors of bilinear filtering:
    float2 texcoord = mad(float2(__SMAA_AREATEX_MAX_DISTANCE, __SMAA_AREATEX_MAX_DISTANCE), round(4.0 * float2(e1, e2)), dist);
    
    // We do a scale and bias for mapping to texel space:
    texcoord = mad(__SMAA_AREATEX_PIXEL_SIZE, texcoord, 0.5 * __SMAA_AREATEX_PIXEL_SIZE);

    // Move to proper place, according to the subpixel offset:
    texcoord.y = mad(__SMAA_AREATEX_SUBTEX_SIZE, offset, texcoord.y);

    // Do it!
    return __SMAA_AREATEX_SELECT(__SMAASampleLevelZero(HQAAareaTex, texcoord));
}


void SMAADetectHorizontalCornerPattern(__SMAATexture2D(HQAAedgesTex), inout float2 weights, float4 texcoord, float2 d) {
    #if !defined(SMAA_DISABLE_CORNER_DETECTION)
    float2 leftRight = step(d.xy, d.yx);
    float2 rounding = (1.0 - __SMAA_CORNER_ROUNDING_NORM) * leftRight;

    rounding /= leftRight.x + leftRight.y; // Reduce blending for pixels in the center of a line.

    float2 factor = float2(1.0, 1.0);
    factor.x -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2(0,  1)).r;
    factor.x -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2(1,  1)).r;
    factor.y -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2(0, -2)).r;
    factor.y -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2(1, -2)).r;

    weights *= saturate(factor);
    #endif
}

void SMAADetectVerticalCornerPattern(__SMAATexture2D(HQAAedgesTex), inout float2 weights, float4 texcoord, float2 d) {
    #if !defined(SMAA_DISABLE_CORNER_DETECTION)
    float2 leftRight = step(d.xy, d.yx);
    float2 rounding = (1.0 - __SMAA_CORNER_ROUNDING_NORM) * leftRight;

    rounding /= leftRight.x + leftRight.y;

    float2 factor = float2(1.0, 1.0);
    factor.x -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2( 1, 0)).g;
    factor.x -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2( 1, 1)).g;
    factor.y -= rounding.x * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.xy, int2(-2, 0)).g;
    factor.y -= rounding.y * __SMAASampleLevelZeroOffset(HQAAedgesTex, texcoord.zw, int2(-2, 1)).g;

    weights *= saturate(factor);
    #endif
}


float4 SMAABlendingWeightCalculationPS(float2 texcoord,
                                       float2 pixcoord,
                                       float4 offset[3],
                                       __SMAATexture2D(HQAAedgesTex),
                                       __SMAATexture2D(HQAAareaTex),
                                       __SMAATexture2D(HQAAsearchTex),
                                       float4 subsampleIndices) { // Just pass zero for SMAA 1x, see @SUBSAMPLE_INDICES.
    float4 weights = float4(0.0, 0.0, 0.0, 0.0);

    float2 e = __SMAASample(HQAAedgesTex, texcoord).rg;

    __SMAA_BRANCH
    if (e.g > 0.0) { // Edge at north
        #if !defined(SMAA_DISABLE_DIAG_DETECTION)
        // Diagonals have both north and west edges, so searching for them in
        // one of the boundaries is enough.
        weights.rg = SMAACalculateDiagWeights(__SMAATexturePass2D(HQAAedgesTex), __SMAATexturePass2D(HQAAareaTex), texcoord, e, subsampleIndices);

        // We give priority to diagonals, so if we find a diagonal we skip 
        // horizontal/vertical processing.
        __SMAA_BRANCH
        if (weights.r == -weights.g) { // weights.r + weights.g == 0.0
        #endif

        float2 d;

        // Find the distance to the left:
        float3 coords;
        coords.x = SMAASearchXLeft(__SMAATexturePass2D(HQAAedgesTex), __SMAATexturePass2D(HQAAsearchTex), offset[0].xy, offset[2].x);
        coords.y = offset[1].y; // offset[1].y = texcoord.y - 0.25 * __SMAA_RT_METRICS.y (@CROSSING_OFFSET)
        d.x = coords.x;

        // Now fetch the left crossing edges, two at a time using bilinear
        // filtering. Sampling at -0.25 (see @CROSSING_OFFSET) enables to
        // discern what value each edge has:
        float e1 = __SMAASampleLevelZero(HQAAedgesTex, coords.xy).r;

        // Find the distance to the right:
        coords.z = SMAASearchXRight(__SMAATexturePass2D(HQAAedgesTex), __SMAATexturePass2D(HQAAsearchTex), offset[0].zw, offset[2].y);
        d.y = coords.z;

        // We want the distances to be in pixel units (doing this here allow to
        // better interleave arithmetic and memory accesses):
        d = abs(round(mad(__SMAA_RT_METRICS.zz, d, -pixcoord.xx)));

        // SMAAArea below needs a sqrt, as the areas texture is compressed
        // quadratically:
        float2 sqrt_d = sqrt(d);

        // Fetch the right crossing edges:
        float e2 = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.zy, int2(1, 0)).r;

        // Ok, we know how this pattern looks like, now it is time for getting
        // the actual area:
        weights.rg = SMAAArea(__SMAATexturePass2D(HQAAareaTex), sqrt_d, e1, e2, subsampleIndices.y);

        // Fix corners:
        coords.y = texcoord.y;
        SMAADetectHorizontalCornerPattern(__SMAATexturePass2D(HQAAedgesTex), weights.rg, coords.xyzy, d);

        #if !defined(SMAA_DISABLE_DIAG_DETECTION)
        } else
            e.r = 0.0; // Skip vertical processing.
        #endif
    }

    __SMAA_BRANCH
    if (e.r > 0.0) { // Edge at west
        float2 d;

        // Find the distance to the top:
        float3 coords;
        coords.y = SMAASearchYUp(__SMAATexturePass2D(HQAAedgesTex), __SMAATexturePass2D(HQAAsearchTex), offset[1].xy, offset[2].z);
        coords.x = offset[0].x; // offset[1].x = texcoord.x - 0.25 * __SMAA_RT_METRICS.x;
        d.x = coords.y;

        // Fetch the top crossing edges:
        float e1 = __SMAASampleLevelZero(HQAAedgesTex, coords.xy).g;

        // Find the distance to the bottom:
        coords.z = SMAASearchYDown(__SMAATexturePass2D(HQAAedgesTex), __SMAATexturePass2D(HQAAsearchTex), offset[1].zw, offset[2].w);
        d.y = coords.z;

        // We want the distances to be in pixel units:
        d = abs(round(mad(__SMAA_RT_METRICS.ww, d, -pixcoord.yy)));

        // SMAAArea below needs a sqrt, as the areas texture is compressed 
        // quadratically:
        float2 sqrt_d = sqrt(d);

        // Fetch the bottom crossing edges:
        float e2 = __SMAASampleLevelZeroOffset(HQAAedgesTex, coords.xz, int2(0, 1)).g;

        // Get the area for this direction:
        weights.ba = SMAAArea(__SMAATexturePass2D(HQAAareaTex), sqrt_d, e1, e2, subsampleIndices.x);

        // Fix corners:
        coords.x = texcoord.x;
        SMAADetectVerticalCornerPattern(__SMAATexturePass2D(HQAAedgesTex), weights.ba, coords.xyxz, d);
    }

    return weights;
}

float4 SMAANeighborhoodBlendingPS(float2 texcoord,
                                  float4 offset,
                                  __SMAATexture2D(colorTex),
                                  __SMAATexture2D(HQAAblendTex)
                                  ) {
    // Fetch the blending weights for current pixel:
    float4 m;
    m.x = __SMAASample(HQAAblendTex, offset.xy).a; // Right
    m.y = __SMAASample(HQAAblendTex, offset.zw).g; // Top
    m.wz = __SMAASample(HQAAblendTex, texcoord).xz; // Bottom / Left

    // Is there any blending weight with a value greater than 0.0?
    __SMAA_BRANCH
    if (dot(m, float4(1.0, 1.0, 1.0, 1.0)) < 1e-5) {
        float4 color = __SMAASampleLevelZero(colorTex, texcoord);
		
		return color;
    } else {
        bool horiz = max(m.x, m.z) > max(m.y, m.w); // max(horizontal) > max(vertical)

        // Calculate the blending offsets:
        float4 blendingOffset = float4(0.0, m.y, 0.0, m.w);
        float2 blendingWeight = m.yw;
        SMAAMovc(bool4(horiz, horiz, horiz, horiz), blendingOffset, float4(m.x, 0.0, m.z, 0.0));
        SMAAMovc(bool2(horiz, horiz), blendingWeight, m.xz);
        blendingWeight /= dot(blendingWeight, float2(1.0, 1.0));

        // Calculate the texture coordinates:
        float4 blendingCoord = mad(blendingOffset, float4(__SMAA_RT_METRICS.xy, -__SMAA_RT_METRICS.xy), texcoord.xyxy);

        // We exploit bilinear filtering to mix current pixel with the chosen
        // neighbor:
        float4 color = blendingWeight.x * __SMAASampleLevelZero(colorTex, blendingCoord.xy);
        color += blendingWeight.y * __SMAASampleLevelZero(colorTex, blendingCoord.zw);

        return color;
    }
}

#endif // SMAA_INCLUDE_PS
/***************************************************************************************************************************************/
/*********************************************************** SMAA CODE BLOCK END *******************************************************/
/***************************************************************************************************************************************/
// I'm a nested comment!
/***************************************************************************************************************************************/
/*********************************************************** FXAA CODE BLOCK START *****************************************************/
/***************************************************************************************************************************************/

#define __FXAA_ADAPTIVE_SUBPIX min(1 - BUFFER_HEIGHT / 4320, 1) * Subpix

#define __FXAA_QUALITY__PS 13
#define __FXAA_QUALITY__P0 1
#define __FXAA_QUALITY__P1 1
#define __FXAA_QUALITY__P2 1
#define __FXAA_QUALITY__P3 1
#define __FXAA_QUALITY__P4 1
#define __FXAA_QUALITY__P5 1
#define __FXAA_QUALITY__P6 1
#define __FXAA_QUALITY__P7 1
#define __FXAA_QUALITY__P8 1
#define __FXAA_QUALITY__P9 1
#define __FXAA_QUALITY__P10 1
#define __FXAA_QUALITY__P11 1
#define __FXAA_QUALITY__P12 1
#define __FXAA_QUALITY__PRESET 39
#define __FXAA_PC 1
#define __FXAA_HLSL_3 1
#define __FxaaTexLuma4(t, p) textureGather(t, p, lumatype)
#define __FxaaTexOffLuma4(t, p, o) textureGatherOffset(t, p, o, lumatype)
#define __FxaaAdaptiveLuma(t) __FxaaAdaptiveLumaSelect(t, lumatype)
#define __FXAA_DISCARD 1
#define __FXAA_GLSL_120 0
#define __FXAA_GLSL_130 0
#define __FXAA_HLSL_4 0
#define __FXAA_HLSL_5 0
#ifndef __FXAA_FAST_PIXEL_OFFSET
    //
    // Used for GLSL 120 only.
    //
    // 1 = GL API supports fast pixel offsets
    // 0 = do not use fast pixel offsets
    //
    #ifdef GL_EXT_gpu_shader4
        #define __FXAA_FAST_PIXEL_OFFSET 1
    #endif
    #ifdef GL_NV_gpu_shader5
        #define __FXAA_FAST_PIXEL_OFFSET 1
    #endif
    #ifdef GL_ARB_gpu_shader5
        #define __FXAA_FAST_PIXEL_OFFSET 1
    #endif
    #ifndef __FXAA_FAST_PIXEL_OFFSET
        #define __FXAA_FAST_PIXEL_OFFSET 0
    #endif
#endif
#ifndef __FXAA_GATHER4_ALPHA
    //
    // 1 = API supports gather4 on alpha channel.
    // 0 = API does not support gather4 on alpha channel.
    //
    #if (__FXAA_HLSL_5 == 1)
        #define __FXAA_GATHER4_ALPHA 1
    #endif
    #ifdef GL_ARB_gpu_shader5
        #define __FXAA_GATHER4_ALPHA 1
    #endif
    #ifdef GL_NV_gpu_shader5
        #define __FXAA_GATHER4_ALPHA 1
    #endif
    #ifndef __FXAA_GATHER4_ALPHA
        #define __FXAA_GATHER4_ALPHA 0
    #endif
#endif


#if (__FXAA_GLSL_120 == 1) || (__FXAA_GLSL_130 == 1)
    #define __FxaaBool bool
    #define __FxaaDiscard discard
    #define __FxaaFloat float
    #define __FxaaFloat2 vec2
    #define __FxaaFloat3 vec3
    #define __FxaaFloat4 vec4
    #define __FxaaHalf float
    #define __FxaaHalf2 vec2
    #define __FxaaHalf3 vec3
    #define __FxaaHalf4 vec4
    #define __FxaaInt2 ivec2
    #define __FxaaSat(x) clamp(x, 0.0, 1.0)
    #define __FxaaTex sampler2D
#else
    #define __FxaaBool bool
    #define __FxaaDiscard discard
    #define __FxaaFloat float
    #define __FxaaFloat2 float2
    #define __FxaaFloat3 float3
    #define __FxaaFloat4 float4
    #define __FxaaHalf half
    #define __FxaaHalf2 half2
    #define __FxaaHalf3 half3
    #define __FxaaHalf4 half4
    #define __FxaaSat(x) saturate(x)
#endif

#if (__FXAA_GLSL_120 == 1)
    // Requires,
    //  #version 120
    // And at least,
    //  #extension GL_EXT_gpu_shader4 : enable
    //  (or set __FXAA_FAST_PIXEL_OFFSET 1 to work like DX9)
    #define __FxaaTexTop(t, p) texture2DLod(t, p, 0.0)
    #if (__FXAA_FAST_PIXEL_OFFSET == 1)
        #define __FxaaTexOff(t, p, o, r) texture2DLodOffset(t, p, 0.0, o)
    #else
        #define __FxaaTexOff(t, p, o, r) texture2DLod(t, p + (o * r), 0.0)
    #endif
    #if (__FXAA_GATHER4_ALPHA == 1)
        // use #extension GL_ARB_gpu_shader5 : enable
        #define __FxaaTexAlpha4(t, p) textureGather(t, p, 3)
        #define __FxaaTexOffAlpha4(t, p, o) textureGatherOffset(t, p, o, 3)
        #define __FxaaTexGreen4(t, p) textureGather(t, p, 1)
        #define __FxaaTexOffGreen4(t, p, o) textureGatherOffset(t, p, o, 1)
    #endif
#endif

#if (__FXAA_GLSL_130 == 1)
    // Requires "#version 130" or better
    #define __FxaaTexTop(t, p) textureLod(t, p, 0.0)
    #define __FxaaTexOff(t, p, o, r) textureLodOffset(t, p, 0.0, o)
    #if (__FXAA_GATHER4_ALPHA == 1)
        // use #extension GL_ARB_gpu_shader5 : enable
        #define __FxaaTexAlpha4(t, p) textureGather(t, p, 3)
        #define __FxaaTexOffAlpha4(t, p, o) textureGatherOffset(t, p, o, 3)
        #define __FxaaTexGreen4(t, p) textureGather(t, p, 1)
        #define __FxaaTexOffGreen4(t, p, o) textureGatherOffset(t, p, o, 1)
    #endif
#endif

#if (__FXAA_HLSL_3 == 1)
    #define __FxaaInt2 float2
    #define __FxaaTex sampler2D
    #define __FxaaTexTop(t, p) tex2Dlod(t, float4(p, 0.0, 0.0))
    #define __FxaaTexOff(t, p, o, r) tex2Dlod(t, float4(p + (o * r), 0, 0))
#endif

#if (__FXAA_HLSL_4 == 1)
    #define __FxaaInt2 int2
    struct __FxaaTex { SamplerState smpl; Texture2D tex; };
    #define __FxaaTexTop(t, p) t.tex.SampleLevel(t.smpl, p, 0.0)
    #define __FxaaTexOff(t, p, o, r) t.tex.SampleLevel(t.smpl, p, 0.0, o)
#endif

#if (__FXAA_HLSL_5 == 1)
    #define __FxaaInt2 int2
    struct __FxaaTex { SamplerState smpl; Texture2D tex; };
    #define __FxaaTexTop(t, p) t.tex.SampleLevel(t.smpl, p, 0.0)
    #define __FxaaTexOff(t, p, o, r) t.tex.SampleLevel(t.smpl, p, 0.0, o)
    #define __FxaaTexAlpha4(t, p) t.tex.GatherAlpha(t.smpl, p)
    #define __FxaaTexOffAlpha4(t, p, o) t.tex.GatherAlpha(t.smpl, p, o)
    #define __FxaaTexGreen4(t, p) t.tex.GatherGreen(t.smpl, p)
    #define __FxaaTexOffGreen4(t, p, o) t.tex.GatherGreen(t.smpl, p, o)
#endif

__FxaaFloat __FxaaAdaptiveLumaSelect (__FxaaFloat4 rgba, int lumatype)
// Luma types match variable positions. 0=R 1=G 2=B 3=A
{
	if (lumatype == 0)
		return rgba.x;
	else if (lumatype == 2)
		return rgba.z;
	else if (lumatype == 3)
		return rgba.w;
	else
		return rgba.y;
}

__FxaaFloat4 FxaaAdaptiveLumaPixelShader(__FxaaFloat2 pos, __FxaaFloat4 fxaaConsolePosPos, __FxaaTex tex, __FxaaTex fxaaConsole360TexExpBiasNegOne,
 __FxaaTex fxaaConsole360TexExpBiasNegTwo, __FxaaFloat2 fxaaQualityRcpFrame, __FxaaFloat4 fxaaConsoleRcpFrameOpt,
 __FxaaFloat4 fxaaConsoleRcpFrameOpt2, __FxaaFloat4 fxaaConsole360RcpFrameOpt2, __FxaaFloat fxaaQualitySubpix,
 __FxaaFloat fxaaQualityEdgeThreshold, __FxaaFloat fxaaQualityEdgeThresholdMin, __FxaaFloat fxaaConsoleEdgeSharpness,
 __FxaaFloat fxaaConsoleEdgeThreshold, __FxaaFloat fxaaConsoleEdgeThresholdMin, __FxaaFloat4 fxaaConsole360ConstDir) 
 {
    __FxaaFloat2 posM;
    posM.x = pos.x;
    posM.y = pos.y;
	
	int lumatype = 2; // assume blue is luma until determined otherwise
    __FxaaFloat4 rgbyM = __FxaaTexTop(tex, posM);
	float lumatest = min(1.5 * rgbyM.x, 1.0);
	if ((rgbyM.y > lumatest) || (rgbyM.x > lumatest))
		if (rgbyM.y > lumatest) // use green if strong
			lumatype = 1;
		else			// otherwise use red as luma
			lumatype = 0;
			
	float lumaMa = (lumatype == 0 ? rgbyM.x : (lumatype == 2 ? rgbyM.z : rgbyM.y));
	
    __FxaaFloat lumaS = __FxaaAdaptiveLuma(__FxaaTexOff(tex, posM, __FxaaInt2( 0, 1), fxaaQualityRcpFrame.xy));
    __FxaaFloat lumaE = __FxaaAdaptiveLuma(__FxaaTexOff(tex, posM, __FxaaInt2( 1, 0), fxaaQualityRcpFrame.xy));
    __FxaaFloat lumaN = __FxaaAdaptiveLuma(__FxaaTexOff(tex, posM, __FxaaInt2( 0,-1), fxaaQualityRcpFrame.xy));
    __FxaaFloat lumaW = __FxaaAdaptiveLuma(__FxaaTexOff(tex, posM, __FxaaInt2(-1, 0), fxaaQualityRcpFrame.xy));
	
    __FxaaFloat maxSM = max(lumaS, lumaMa);
    __FxaaFloat minSM = min(lumaS, lumaMa);
    __FxaaFloat maxESM = max(lumaE, maxSM);
    __FxaaFloat minESM = min(lumaE, minSM);
    __FxaaFloat maxWN = max(lumaN, lumaW);
    __FxaaFloat minWN = min(lumaN, lumaW);
    __FxaaFloat rangeMax = max(maxWN, maxESM);
    __FxaaFloat rangeMin = min(minWN, minESM);
    __FxaaFloat rangeMaxScaled = rangeMax * fxaaQualityEdgeThreshold;
    __FxaaFloat range = rangeMax - rangeMin;
    __FxaaFloat rangeMaxClamped = max(fxaaQualityEdgeThresholdMin, rangeMaxScaled);
    __FxaaBool earlyExit = range < rangeMaxClamped;
	
    if(earlyExit)
        #if (__FXAA_DISCARD == 1)
            __FxaaDiscard;
        #else
            return rgbyM;
        #endif
		
    __FxaaFloat lumaNW = __FxaaAdaptiveLuma(__FxaaTexOff(tex, posM, __FxaaInt2(-1,-1), fxaaQualityRcpFrame.xy));
    __FxaaFloat lumaSE = __FxaaAdaptiveLuma(__FxaaTexOff(tex, posM, __FxaaInt2( 1, 1), fxaaQualityRcpFrame.xy));
    __FxaaFloat lumaNE = __FxaaAdaptiveLuma(__FxaaTexOff(tex, posM, __FxaaInt2( 1,-1), fxaaQualityRcpFrame.xy));
    __FxaaFloat lumaSW = __FxaaAdaptiveLuma(__FxaaTexOff(tex, posM, __FxaaInt2(-1, 1), fxaaQualityRcpFrame.xy));
	
    __FxaaFloat lumaNS = lumaN + lumaS;
    __FxaaFloat lumaWE = lumaW + lumaE;
    __FxaaFloat subpixRcpRange = 1.0/range;
    __FxaaFloat subpixNSWE = lumaNS + lumaWE;
    __FxaaFloat edgeHorz1 = (-2.0 * lumaMa) + lumaNS;
    __FxaaFloat edgeVert1 = (-2.0 * lumaMa) + lumaWE;
	
    __FxaaFloat lumaNESE = lumaNE + lumaSE;
    __FxaaFloat lumaNWNE = lumaNW + lumaNE;
    __FxaaFloat edgeHorz2 = (-2.0 * lumaE) + lumaNESE;
    __FxaaFloat edgeVert2 = (-2.0 * lumaN) + lumaNWNE;
	
    __FxaaFloat lumaNWSW = lumaNW + lumaSW;
    __FxaaFloat lumaSWSE = lumaSW + lumaSE;
    __FxaaFloat edgeHorz4 = (abs(edgeHorz1) * 2.0) + abs(edgeHorz2);
    __FxaaFloat edgeVert4 = (abs(edgeVert1) * 2.0) + abs(edgeVert2);
    __FxaaFloat edgeHorz3 = (-2.0 * lumaW) + lumaNWSW;
    __FxaaFloat edgeVert3 = (-2.0 * lumaS) + lumaSWSE;
    __FxaaFloat edgeHorz = abs(edgeHorz3) + edgeHorz4;
    __FxaaFloat edgeVert = abs(edgeVert3) + edgeVert4;
	
    __FxaaFloat subpixNWSWNESE = lumaNWSW + lumaNESE;
    __FxaaFloat lengthSign = fxaaQualityRcpFrame.x;
    __FxaaBool horzSpan = edgeHorz >= edgeVert;
    __FxaaFloat subpixA = subpixNSWE * 2.0 + subpixNWSWNESE;
	
    if(!horzSpan) lumaN = lumaW;
    if(!horzSpan) lumaS = lumaE;
    if(horzSpan) lengthSign = fxaaQualityRcpFrame.y;
    __FxaaFloat subpixB = (subpixA * (1.0/12.0)) - lumaMa;
	
    __FxaaFloat gradientN = lumaN - lumaMa;
    __FxaaFloat gradientS = lumaS - lumaMa;
    __FxaaFloat lumaNN = lumaN + lumaMa;
    __FxaaFloat lumaSS = lumaS + lumaMa;
    __FxaaBool pairN = abs(gradientN) >= abs(gradientS);
    __FxaaFloat gradient = max(abs(gradientN), abs(gradientS));
    if(pairN) lengthSign = -lengthSign;
    __FxaaFloat subpixC = __FxaaSat(abs(subpixB) * subpixRcpRange);
	
    __FxaaFloat2 posB;
    posB.x = posM.x;
    posB.y = posM.y;
    __FxaaFloat2 offNP;
    offNP.x = (!horzSpan) ? 0.0 : fxaaQualityRcpFrame.x;
    offNP.y = ( horzSpan) ? 0.0 : fxaaQualityRcpFrame.y;
    if(!horzSpan) posB.x += lengthSign * 0.5;
    if( horzSpan) posB.y += lengthSign * 0.5;
	
    __FxaaFloat2 posN;
    posN.x = posB.x - offNP.x * __FXAA_QUALITY__P0;
    posN.y = posB.y - offNP.y * __FXAA_QUALITY__P0;
    __FxaaFloat2 posP;
    posP.x = posB.x + offNP.x * __FXAA_QUALITY__P0;
    posP.y = posB.y + offNP.y * __FXAA_QUALITY__P0;
    __FxaaFloat subpixD = ((-2.0)*subpixC) + 3.0;
    __FxaaFloat lumaEndN = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posN));
    __FxaaFloat subpixE = subpixC * subpixC;
    __FxaaFloat lumaEndP = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posP));
	
    if(!pairN) lumaNN = lumaSS;
    __FxaaFloat gradientScaled = gradient * 1.0/4.0;
    __FxaaFloat lumaMM = lumaMa - lumaNN * 0.5;
    __FxaaFloat subpixF = subpixD * subpixE;
    __FxaaBool lumaMLTZero = lumaMM < 0.0;
	
    lumaEndN -= lumaNN * 0.5;
    lumaEndP -= lumaNN * 0.5;
    __FxaaBool doneN = abs(lumaEndN) >= gradientScaled;
    __FxaaBool doneP = abs(lumaEndP) >= gradientScaled;
    if(!doneN) posN.x -= offNP.x * __FXAA_QUALITY__P1;
    if(!doneN) posN.y -= offNP.y * __FXAA_QUALITY__P1;
    __FxaaBool doneNP = (!doneN) || (!doneP);
    if(!doneP) posP.x += offNP.x * __FXAA_QUALITY__P1;
    if(!doneP) posP.y += offNP.y * __FXAA_QUALITY__P1;
	
    if(doneNP) {
        if(!doneN) lumaEndN = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posN.xy));
        if(!doneP) lumaEndP = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posP.xy));
        if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
        if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
        doneN = abs(lumaEndN) >= gradientScaled;
        doneP = abs(lumaEndP) >= gradientScaled;
        if(!doneN) posN.x -= offNP.x * __FXAA_QUALITY__P2;
        if(!doneN) posN.y -= offNP.y * __FXAA_QUALITY__P2;
        doneNP = (!doneN) || (!doneP);
        if(!doneP) posP.x += offNP.x * __FXAA_QUALITY__P2;
        if(!doneP) posP.y += offNP.y * __FXAA_QUALITY__P2;
        #if (__FXAA_QUALITY__PS > 3)
        if(doneNP) {
            if(!doneN) lumaEndN = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posN.xy));
            if(!doneP) lumaEndP = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posP.xy));
            if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
            if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
            doneN = abs(lumaEndN) >= gradientScaled;
            doneP = abs(lumaEndP) >= gradientScaled;
            if(!doneN) posN.x -= offNP.x * __FXAA_QUALITY__P3;
            if(!doneN) posN.y -= offNP.y * __FXAA_QUALITY__P3;
            doneNP = (!doneN) || (!doneP);
            if(!doneP) posP.x += offNP.x * __FXAA_QUALITY__P3;
            if(!doneP) posP.y += offNP.y * __FXAA_QUALITY__P3;
            #if (__FXAA_QUALITY__PS > 4)
            if(doneNP) {
                if(!doneN) lumaEndN = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posN.xy));
                if(!doneP) lumaEndP = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posP.xy));
                if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                doneN = abs(lumaEndN) >= gradientScaled;
                doneP = abs(lumaEndP) >= gradientScaled;
                if(!doneN) posN.x -= offNP.x * __FXAA_QUALITY__P4;
                if(!doneN) posN.y -= offNP.y * __FXAA_QUALITY__P4;
                doneNP = (!doneN) || (!doneP);
                if(!doneP) posP.x += offNP.x * __FXAA_QUALITY__P4;
                if(!doneP) posP.y += offNP.y * __FXAA_QUALITY__P4;
                #if (__FXAA_QUALITY__PS > 5)
                if(doneNP) {
                    if(!doneN) lumaEndN = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posN.xy));
                    if(!doneP) lumaEndP = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posP.xy));
                    if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                    if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                    doneN = abs(lumaEndN) >= gradientScaled;
                    doneP = abs(lumaEndP) >= gradientScaled;
                    if(!doneN) posN.x -= offNP.x * __FXAA_QUALITY__P5;
                    if(!doneN) posN.y -= offNP.y * __FXAA_QUALITY__P5;
                    doneNP = (!doneN) || (!doneP);
                    if(!doneP) posP.x += offNP.x * __FXAA_QUALITY__P5;
                    if(!doneP) posP.y += offNP.y * __FXAA_QUALITY__P5;
                    #if (__FXAA_QUALITY__PS > 6)
                    if(doneNP) {
                        if(!doneN) lumaEndN = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posN.xy));
                        if(!doneP) lumaEndP = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posP.xy));
                        if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                        if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                        doneN = abs(lumaEndN) >= gradientScaled;
                        doneP = abs(lumaEndP) >= gradientScaled;
                        if(!doneN) posN.x -= offNP.x * __FXAA_QUALITY__P6;
                        if(!doneN) posN.y -= offNP.y * __FXAA_QUALITY__P6;
                        doneNP = (!doneN) || (!doneP);
                        if(!doneP) posP.x += offNP.x * __FXAA_QUALITY__P6;
                        if(!doneP) posP.y += offNP.y * __FXAA_QUALITY__P6;
                        #if (__FXAA_QUALITY__PS > 7)
                        if(doneNP) {
                            if(!doneN) lumaEndN = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posN.xy));
                            if(!doneP) lumaEndP = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posP.xy));
                            if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                            if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                            doneN = abs(lumaEndN) >= gradientScaled;
                            doneP = abs(lumaEndP) >= gradientScaled;
                            if(!doneN) posN.x -= offNP.x * __FXAA_QUALITY__P7;
                            if(!doneN) posN.y -= offNP.y * __FXAA_QUALITY__P7;
                            doneNP = (!doneN) || (!doneP);
                            if(!doneP) posP.x += offNP.x * __FXAA_QUALITY__P7;
                            if(!doneP) posP.y += offNP.y * __FXAA_QUALITY__P7;
    #if (__FXAA_QUALITY__PS > 8)
    if(doneNP) {
        if(!doneN) lumaEndN = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posN.xy));
        if(!doneP) lumaEndP = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posP.xy));
        if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
        if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
        doneN = abs(lumaEndN) >= gradientScaled;
        doneP = abs(lumaEndP) >= gradientScaled;
        if(!doneN) posN.x -= offNP.x * __FXAA_QUALITY__P8;
        if(!doneN) posN.y -= offNP.y * __FXAA_QUALITY__P8;
        doneNP = (!doneN) || (!doneP);
        if(!doneP) posP.x += offNP.x * __FXAA_QUALITY__P8;
        if(!doneP) posP.y += offNP.y * __FXAA_QUALITY__P8;
        #if (__FXAA_QUALITY__PS > 9)
        if(doneNP) {
            if(!doneN) lumaEndN = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posN.xy));
            if(!doneP) lumaEndP = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posP.xy));
            if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
            if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
            doneN = abs(lumaEndN) >= gradientScaled;
            doneP = abs(lumaEndP) >= gradientScaled;
            if(!doneN) posN.x -= offNP.x * __FXAA_QUALITY__P9;
            if(!doneN) posN.y -= offNP.y * __FXAA_QUALITY__P9;
            doneNP = (!doneN) || (!doneP);
            if(!doneP) posP.x += offNP.x * __FXAA_QUALITY__P9;
            if(!doneP) posP.y += offNP.y * __FXAA_QUALITY__P9;
            #if (__FXAA_QUALITY__PS > 10)
            if(doneNP) {
                if(!doneN) lumaEndN = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posN.xy));
                if(!doneP) lumaEndP = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posP.xy));
                if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                doneN = abs(lumaEndN) >= gradientScaled;
                doneP = abs(lumaEndP) >= gradientScaled;
                if(!doneN) posN.x -= offNP.x * __FXAA_QUALITY__P10;
                if(!doneN) posN.y -= offNP.y * __FXAA_QUALITY__P10;
                doneNP = (!doneN) || (!doneP);
                if(!doneP) posP.x += offNP.x * __FXAA_QUALITY__P10;
                if(!doneP) posP.y += offNP.y * __FXAA_QUALITY__P10;
                #if (__FXAA_QUALITY__PS > 11)
                if(doneNP) {
                    if(!doneN) lumaEndN = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posN.xy));
                    if(!doneP) lumaEndP = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posP.xy));
                    if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                    if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                    doneN = abs(lumaEndN) >= gradientScaled;
                    doneP = abs(lumaEndP) >= gradientScaled;
                    if(!doneN) posN.x -= offNP.x * __FXAA_QUALITY__P11;
                    if(!doneN) posN.y -= offNP.y * __FXAA_QUALITY__P11;
                    doneNP = (!doneN) || (!doneP);
                    if(!doneP) posP.x += offNP.x * __FXAA_QUALITY__P11;
                    if(!doneP) posP.y += offNP.y * __FXAA_QUALITY__P11;
                    #if (__FXAA_QUALITY__PS > 12)
                    if(doneNP) {
                        if(!doneN) lumaEndN = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posN.xy));
                        if(!doneP) lumaEndP = __FxaaAdaptiveLuma(__FxaaTexTop(tex, posP.xy));
                        if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                        if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                        doneN = abs(lumaEndN) >= gradientScaled;
                        doneP = abs(lumaEndP) >= gradientScaled;
                        if(!doneN) posN.x -= offNP.x * __FXAA_QUALITY__P12;
                        if(!doneN) posN.y -= offNP.y * __FXAA_QUALITY__P12;
                        doneNP = (!doneN) || (!doneP);
                        if(!doneP) posP.x += offNP.x * __FXAA_QUALITY__P12;
                        if(!doneP) posP.y += offNP.y * __FXAA_QUALITY__P12;
                    }
                    #endif
                }
                #endif
            }
            #endif
        }
        #endif
    }
    #endif
                        }
                        #endif
                    }
                    #endif
                }
                #endif
            }
            #endif
        }
        #endif
    }
    __FxaaFloat dstN = posM.x - posN.x;
    __FxaaFloat dstP = posP.x - posM.x;
    if(!horzSpan) dstN = posM.y - posN.y;
    if(!horzSpan) dstP = posP.y - posM.y;
	
    __FxaaBool goodSpanN = (lumaEndN < 0.0) != lumaMLTZero;
    __FxaaFloat spanLength = (dstP + dstN);
    __FxaaBool goodSpanP = (lumaEndP < 0.0) != lumaMLTZero;
    __FxaaFloat spanLengthRcp = 1.0/spanLength;
	
    __FxaaBool directionN = dstN < dstP;
    __FxaaFloat dst = min(dstN, dstP);
    __FxaaBool goodSpan = directionN ? goodSpanN : goodSpanP;
    __FxaaFloat subpixG = subpixF * subpixF;
    __FxaaFloat pixelOffset = (dst * (-spanLengthRcp)) + 0.5;
    __FxaaFloat subpixH = subpixG * fxaaQualitySubpix;
	
    __FxaaFloat pixelOffsetGood = goodSpan ? pixelOffset : 0.0;
    __FxaaFloat pixelOffsetSubpix = max(pixelOffsetGood, subpixH);
    if(!horzSpan) posM.x += pixelOffsetSubpix * lengthSign;
    if( horzSpan) posM.y += pixelOffsetSubpix * lengthSign;

	// Calculate sharpening based on perceived luminance of the colors not chosen to represent luma
	// we avoid creating spurious white pixels by choosing to sharpen only darkish results
	float sharpening = 0;
	if (rgbyM.x + rgbyM.y + rgbyM.z < 1.5 && rgbyM.x < 0.625 && rgbyM.y < 0.625 && rgbyM.z < 0.625) {
		if (lumatype == 0)
			sharpening = max(((0.05 * rgbyM.x) + (0.6 * rgbyM.y) + (0.35 * rgbyM.z)) * fxaaQualitySubpix, 0);
		else if (lumatype == 1)
			sharpening = max(((0.25 * rgbyM.x) + (0.05 * rgbyM.y) + (0.7 * rgbyM.z)) * fxaaQualitySubpix, 0);
		else
			sharpening = max(((0.25 * rgbyM.x) + (0.7 * rgbyM.y) + (0.05 * rgbyM.z)) * fxaaQualitySubpix, 0);
	}
	
	// Skip calculating the sharpening if the amount calculation returned zero
	if (sharpening == 0)
		return float4(tex2D(tex, posM).rgb, lumaMa);

    float3 a = tex2Doffset(tex, posM, int2(-1, -1)).rgb;
    float3 b = tex2Doffset(tex, posM, int2(0, -1)).rgb;
    float3 c = tex2Doffset(tex, posM, int2(1, -1)).rgb;
    float3 d = tex2Doffset(tex, posM, int2(-1, 0)).rgb;
    float3 e = tex2D(tex, posM).rgb;
    float3 f = tex2Doffset(tex, posM, int2(1, 0)).rgb;
    float3 g = tex2Doffset(tex, posM, int2(-1, 1)).rgb;
    float3 h = tex2Doffset(tex, posM, int2(0, 1)).rgb;
    float3 i = tex2Doffset(tex, posM, int2(1, 1)).rgb;
	
    float3 mnRGB = min(min(min(d, e), min(f, b)), h);
    float3 mnRGB2 = min(mnRGB, min(min(a, c), min(g, i)));
    mnRGB += mnRGB2;

    float3 mxRGB = max(max(max(d, e), max(f, b)), h);
    float3 mxRGB2 = max(mxRGB, max(max(a, c), max(g, i)));
    mxRGB += mxRGB2;
	
    float3 rcpMRGB = rcp(mxRGB);
    float3 ampRGB = saturate(min(mnRGB, 2.0 - mxRGB) * rcpMRGB);    
	
    ampRGB = rsqrt(ampRGB);
    
    float peak = 8.0;
    float3 wRGB = -rcp(ampRGB * peak);

    float3 rcpWeightRGB = rcp(4.0 * wRGB + 1.0);
	
    float3 window = (b + d) + (f + h);
    float4 outColor = float4(saturate((window * wRGB + e) * rcpWeightRGB),lumaMa);
    
	outColor = lerp(float4(e,lumaMa), outColor, sharpening);
    return outColor;
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
	SRGBTexture = true;
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
sampler HQAAFXTex
{
	Texture = ReShade::BackBufferTex;
	MinFilter = Linear; MagFilter = Linear;
};

//////////////////////////////////////////////////////////// VERTEX SHADERS /////////////////////////////////////////////////////////////

void HQSMAAEdgeDetectionWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float4 offset[3] : TEXCOORD1)
{
	PostProcessVS(id, position, texcoord);
	SMAAEdgeDetectionVS(texcoord, offset);
}
void HQSMAABlendingWeightCalculationWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float2 pixcoord : TEXCOORD1,
	out float4 offset[3] : TEXCOORD2)
{
	PostProcessVS(id, position, texcoord);
	SMAABlendingWeightCalculationVS(texcoord, pixcoord, offset);
}
void HQSMAANeighborhoodBlendingWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float4 offset : TEXCOORD1)
{
	PostProcessVS(id, position, texcoord);
	SMAANeighborhoodBlendingVS(texcoord, offset);
}

//////////////////////////////////////////////////////////// PIXEL SHADERS //////////////////////////////////////////////////////////////

float2 HQSMAAEdgeDetectionWrapPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float4 offset[3] : TEXCOORD1) : SV_Target
{
	float2 luma = SMAALumaEdgeDetectionPS(texcoord, offset, HQAAcolorGammaSampler);
	float2 color = SMAAColorEdgeDetectionPS(texcoord, offset, HQAAcolorGammaSampler);
	
	float2 result = float2(0, 0);
	
	if (color.r > luma.r)
		result = float2(color.r, lerp(luma.g, color.g, tex2D(HQAAcolorGammaSampler,texcoord).g));
	else
		result = luma;
	
	if (dot(result, float2(1.0, 1.0)) == 0.0)
		discard;
	
	return result;
}
float4 HQSMAABlendingWeightCalculationWrapPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float2 pixcoord : TEXCOORD1,
	float4 offset[3] : TEXCOORD2) : SV_Target
{
	return SMAABlendingWeightCalculationPS(texcoord, pixcoord, offset, HQAAedgesSampler, HQAAareaSampler, HQAAsearchSampler, 0.0);
}
float3 HQSMAANeighborhoodBlendingWrapPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float4 offset : TEXCOORD1) : SV_Target
{
	float3 SMAAresult = SMAANeighborhoodBlendingPS(texcoord, offset, HQAAcolorLinearSampler, HQAAblendSampler).rgb;
	return saturate(SMAAresult);
}

float4 FXAAPixelShaderAdaptiveCoarse(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float TotalSubpix = Subpix * 0.125 + Overdrive ? SubpixBoost * 0.375 : 0;
	float4 output = FxaaAdaptiveLumaPixelShader(texcoord,0,HQAAFXTex,HQAAFXTex,HQAAFXTex,BUFFER_PIXEL_SIZE,0,0,0,TotalSubpix,Overdrive ? sqrt(EdgeThreshold) : 0.75 + (EdgeThreshold * 0.25),0.004,0,0,0,0);
	return saturate(output);
}

float4 FXAAPixelShaderAdaptiveFine(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float TotalSubpix = __FXAA_ADAPTIVE_SUBPIX;
	if (Overdrive)
		TotalSubpix += 1 - __FXAA_ADAPTIVE_SUBPIX;
	float4 output = FxaaAdaptiveLumaPixelShader(texcoord,0,HQAAFXTex,HQAAFXTex,HQAAFXTex,BUFFER_PIXEL_SIZE,0,0,0,TotalSubpix,max(0.03125,EdgeThreshold),0.004,0,0,0,0);
	return saturate(output);
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
	pass SMAAEdgeDetection
	{
		VertexShader = HQSMAAEdgeDetectionWrapVS;
		PixelShader = HQSMAAEdgeDetectionWrapPS;
		RenderTarget = HQAAedgesTex;
		ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = REPLACE;
		StencilRef = 1;
	}
	pass SMAABlendWeightCalculation
	{
		VertexShader = HQSMAABlendingWeightCalculationWrapVS;
		PixelShader = HQSMAABlendingWeightCalculationWrapPS;
		RenderTarget = HQAAblendTex;
		ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = KEEP;
		StencilFunc = EQUAL;
		StencilRef = 1;
	}
	pass SMAANeighborhoodBlending
	{
		VertexShader = HQSMAANeighborhoodBlendingWrapVS;
		PixelShader = HQSMAANeighborhoodBlendingWrapPS;
		StencilEnable = false;
		SRGBWriteEnable = true;
	}
#if (BUFFER_HEIGHT > 1400) // resolution >= 1440p - run +1 FXAA coarse pass
	pass FXAACoarse
	{
		VertexShader = PostProcessVS;
		PixelShader = FXAAPixelShaderAdaptiveCoarse;
	}
#if (BUFFER_HEIGHT > 2100) // resolution >= 2160p (4K) - run +1 FXAA coarse pass
	pass FXAACoarse
	{
		VertexShader = PostProcessVS;
		PixelShader = FXAAPixelShaderAdaptiveCoarse;
	}
#if (BUFFER_HEIGHT > 4200) // resolution >= 4320p (8K) - run +1 FXAA coarse pass
	pass FXAACoarse
	{
		VertexShader = PostProcessVS;
		PixelShader = FXAAPixelShaderAdaptiveCoarse;
	}
#endif
#endif
#endif
	pass FXAAFine
	{
		VertexShader = PostProcessVS;
		PixelShader = FXAAPixelShaderAdaptiveFine;
	}
}
