/**
 *               HQAA for ReShade 3.1.1+
 *
 *   Smooshes FXAA and ASSMAA together as a single shader
 *
 *       then uses a light CAS sharpen to minimize blur
 *
 *             v0.3 WIP - Subject to change
 *
 *                     by lordbean
 *
 */

// CAS Algorithm License
// Copyright (c) 2017-2019 Advanced Micro Devices, Inc. All rights reserved.
// -------
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// -------
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
// -------

//------------------------------- UI setup -----------------------------------------------

#include "ReShadeUI.fxh"

uniform float EdgeThreshold < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Edge Detection Threshold";
	ui_tooltip = "Local contrast required to run shader";
> = 0.1;

uniform float Subpix < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Subpixel Effects Strength";
	ui_tooltip = "Lower = sharper image, Higher = more AA effect";
> = 0.25;

//------------------------------ Shader Setup -------------------------------------------

#ifdef FXAA_QUALITY_PRESET
	#undef FXAA_QUALITY_PRESET
#endif
#ifdef FXAA_GREEN_AS_LUMA
	#undef FXAA_GREEN_AS_LUMA
#endif
#ifdef FXAA_LINEAR_LIGHT
	#undef FXAA_LINEAR_LIGHT
#endif
#ifdef SMAA_PRESET_LOW
	#undef SMAA_PRESET_LOW
#endif
#ifdef SMAA_PRESET_MEDIUM
	#undef SMAA_PRESET_MEDIUM
#endif
#ifdef SMAA_PRESET_HIGH
	#undef SMAA_PRESET_HIGH
#endif
#ifdef SMAA_PRESET_ULTRA
	#undef SMAA_PRESET_ULTRA
#endif

#define FXAA_GREEN_AS_LUMA 1    // Seems to play nicer with SMAA, less aliasing artifacts
#define SMAA_PRESET_CUSTOM
#define SMAA_THRESHOLD EdgeThreshold
#define SMAA_MAX_SEARCH_STEPS 112
#define SMAA_CORNER_ROUNDING trunc(20 * Subpix)
#define SMAA_MAX_SEARCH_STEPS_DIAG 20
#define SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR (1.0 + (0.25 * Subpix))
#define FXAA_QUALITY__PRESET 39
#define FXAA_PC 1
#define FXAA_HLSL_3 1
#define SMAA_RT_METRICS float4(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT, BUFFER_WIDTH, BUFFER_HEIGHT)
#define SMAA_CUSTOM_SL 1
#define SMAATexture2D(tex) sampler tex
#define SMAATexturePass2D(tex) tex
#define SMAASampleLevelZero(tex, coord) tex2Dlod(tex, float4(coord, coord))
#define SMAASampleLevelZeroPoint(tex, coord) SMAASampleLevelZero(tex, coord)
#define SMAASampleLevelZeroOffset(tex, coord, offset) tex2Dlodoffset(tex, float4(coord, coord), offset)
#define SMAASample(tex, coord) tex2D(tex, coord)
#define SMAASamplePoint(tex, coord) SMAASample(tex, coord)
#define SMAASampleOffset(tex, coord, offset) tex2Doffset(tex, coord, offset)
#define SMAA_BRANCH [branch]
#define SMAA_FLATTEN [flatten]

#if (__RENDERER__ == 0xb000 || __RENDERER__ == 0xb100)
	#define SMAAGather(tex, coord) tex2Dgather(tex, coord, 0)
	#define FXAA_GATHER4_ALPHA 1
	#define FxaaTexAlpha4(t, p) tex2Dgather(t, p, 3)
	#define FxaaTexOffAlpha4(t, p, o) tex2Dgatheroffset(t, p, o, 3)
	#define FxaaTexGreen4(t, p) tex2Dgather(t, p, 1)
	#define FxaaTexOffGreen4(t, p, o) tex2Dgatheroffset(t, p, o, 1)
#endif

#include "SMAA.fxh"
#include "FXAA.fxh"
#include "ReShade.fxh"

#undef FXAA_QUALITY__PS
#undef FXAA_QUALITY__P0
#undef FXAA_QUALITY__P1
#undef FXAA_QUALITY__P2
#undef FXAA_QUALITY__P3
#undef FXAA_QUALITY__P4
#undef FXAA_QUALITY__P5
#undef FXAA_QUALITY__P6
#undef FXAA_QUALITY__P7
#undef FXAA_QUALITY__P8
#undef FXAA_QUALITY__P9
#undef FXAA_QUALITY__P10
#undef FXAA_QUALITY__P11
#define FXAA_QUALITY__PS 13
#define FXAA_QUALITY__P0 0.5
#define FXAA_QUALITY__P1 0.5
#define FXAA_QUALITY__P2 0.5
#define FXAA_QUALITY__P3 0.5
#define FXAA_QUALITY__P4 0.5
#define FXAA_QUALITY__P5 0.5
#define FXAA_QUALITY__P6 1.0
#define FXAA_QUALITY__P7 1.0
#define FXAA_QUALITY__P8 1.0
#define FXAA_QUALITY__P9 1.0
#define FXAA_QUALITY__P10 1.0
#define FXAA_QUALITY__P11 1.0
#define FXAA_QUALITY__P12 1.0

//------------------------------------- Textures -------------------------------------------

texture edgesTex < pooled = true; >
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RG8;
};
texture blendTex < pooled = true; >
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA8;
};

texture areaTex < source = "AreaTex.png"; >
{
	Width = 160;
	Height = 560;
	Format = RG8;
};
texture searchTex < source = "SearchTex.png"; >
{
	Width = 64;
	Height = 16;
	Format = R8;
};
texture TexColor : COLOR;

// -------------------------------- Samplers -----------------------------------------------

sampler colorGammaSampler
{
	Texture = ReShade::BackBufferTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Point; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler colorLinearSampler
{
	Texture = ReShade::BackBufferTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Point; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = true;
};
sampler edgesSampler
{
	Texture = edgesTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler blendSampler
{
	Texture = blendTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler areaSampler
{
	Texture = areaTex;
	AddressU = Clamp; AddressV = Clamp; AddressW = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler searchSampler
{
	Texture = searchTex;
	AddressU = Clamp; AddressV = Clamp; AddressW = Clamp;
	MipFilter = Point; MinFilter = Point; MagFilter = Point;
	SRGBTexture = false;
};
sampler FXAATexture
{
	Texture = ReShade::BackBufferTex;
	MinFilter = Linear; MagFilter = Linear;
};
sampler sTexColor {Texture = TexColor; SRGBTexture = true;};


//----------------------------------- Vertex Shaders ---------------------------------------

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

// -------------------------------- Pixel shaders ------------------------------------------
// SMAA detection method is using ASSMAA "Both, biasing Clarity" to minimize blurring

float2 SMAAEdgeDetectionWrapPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float4 offset[3] : TEXCOORD1) : SV_Target
{
	return (SMAAColorEdgeDetectionPS(texcoord, offset, colorGammaSampler) && SMAALumaEdgeDetectionPS(texcoord, offset, colorGammaSampler));
}
float4 SMAABlendingWeightCalculationWrapPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float2 pixcoord : TEXCOORD1,
	float4 offset[3] : TEXCOORD2) : SV_Target
{
	return SMAABlendingWeightCalculationPS(texcoord, pixcoord, offset, edgesSampler, areaSampler, searchSampler, 0.0);
}
float3 SMAANeighborhoodBlendingWrapPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float4 offset : TEXCOORD1) : SV_Target
{
	return SMAANeighborhoodBlendingPS(texcoord, offset, colorLinearSampler, blendSampler).rgb;
}

float4 FXAALumaPass(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 color = tex2D(ReShade::BackBuffer, texcoord.xy);
	color.a = sqrt(dot(color.rgb * color.rgb, float3(0.299, 0.587, 0.114)));
	return color;
}
float4 FXAAPixelShader(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return FxaaPixelShader(texcoord,0,FXAATexture,FXAATexture,FXAATexture,BUFFER_PIXEL_SIZE,0,0,0,(0.5 * Subpix),(0.4 * EdgeThreshold),0,0,0,0,0);
}

float3 CASPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 a = tex2Doffset(sTexColor, texcoord, int2(-1, -1)).rgb;
    float3 b = tex2Doffset(sTexColor, texcoord, int2(0, -1)).rgb;
    float3 c = tex2Doffset(sTexColor, texcoord, int2(1, -1)).rgb;
    float3 d = tex2Doffset(sTexColor, texcoord, int2(-1, 0)).rgb;
    float3 g = tex2Doffset(sTexColor, texcoord, int2(-1, 1)).rgb;
    float3 e = tex2D(sTexColor, texcoord).rgb;
    float3 f = tex2Doffset(sTexColor, texcoord, int2(1, 0)).rgb;
    float3 h = tex2Doffset(sTexColor, texcoord, int2(0, 1)).rgb;
    float3 i = tex2Doffset(sTexColor, texcoord, int2(1, 1)).rgb;
    float3 mnRGB = min(min(min(d, e), min(f, b)), h);
    float3 mnRGB2 = min(mnRGB, min(min(a, c), min(g, i)));
    mnRGB += mnRGB2;
    float3 mxRGB = max(max(max(d, e), max(f, b)), h);
    float3 mxRGB2 = max(mxRGB, max(max(a, c), max(g, i)));
    mxRGB += mxRGB2;
    float3 rcpMRGB = rcp(mxRGB);
    float3 ampRGB = rsqrt(saturate(min(mnRGB, 2.0 - mxRGB) * rcpMRGB));
    float3 outColor = saturate((((b + d) + (f + h)) * (-rcp(ampRGB * 8.0)) + e) * (rcp(4.0 * (-rcp(ampRGB * 8.0)) + 1.0)));
    return lerp(e, outColor, (0.125 + (Subpix * 0.5)));
}

// -------------------------------- Rendering passes ----------------------------------------

technique HQAA <
	ui_tooltip = "HQAA combines techniques of both ASSMAA and FXAA to produce\n"
	             "best possible image quality from using both while minimizing\n"
	             "the performance overhead resulting from running two post process\n"  
	             "anti-aliasing techniques.";
>
{
	pass SMAAEdgeDetection
	{
		VertexShader = SMAAEdgeDetectionWrapVS;
		PixelShader = SMAAEdgeDetectionWrapPS;
		RenderTarget = edgesTex;
		ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = REPLACE;
		StencilRef = 1;
	}
	pass SMAABlendWeightCalculation
	{
		VertexShader = SMAABlendingWeightCalculationWrapVS;
		PixelShader = SMAABlendingWeightCalculationWrapPS;
		RenderTarget = blendTex;
		ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = KEEP;
		StencilFunc = EQUAL;
		StencilRef = 1;
	}
	pass SMAANeighborhoodBlending
	{
		VertexShader = SMAANeighborhoodBlendingWrapVS;
		PixelShader = SMAANeighborhoodBlendingWrapPS;
		StencilEnable = false;
		SRGBWriteEnable = true;
	}
	pass FXAALumaSampler
	{
		VertexShader = PostProcessVS;
		PixelShader = FXAALumaPass;
	}
	pass FXAA
	{
		VertexShader = PostProcessVS;
		PixelShader = FXAAPixelShader;
	}
	pass Unblur
	{
		VertexShader = PostProcessVS;
		PixelShader = CASPass;
		SRGBWriteEnable = true;
	}
}
