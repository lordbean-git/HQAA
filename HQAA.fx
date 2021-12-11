/**
 *               HQAA for ReShade 3.1.1+
 *
 *   Smooshes FXAA and SMAA together as a single shader
 *
 *           v1.6 (likely final... maybe?) release
 *
 *                     by lordbean
 *
 */


//------------------------------- UI setup -----------------------------------------------

#include "ReShadeUI.fxh"

uniform float EdgeThreshold < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Edge Detection Threshold";
	ui_tooltip = "Local contrast required to run shader";
        ui_category = "Normal Usage";
> = 0.075;

uniform float Subpix < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Subpixel Effects Strength";
	ui_tooltip = "Lower = sharper image, Higher = more AA effect";
        ui_category = "Normal Usage";
> = 0.375;

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

//------------------------------ Shader Setup -------------------------------------------

/****** COMPATIBILITY DEFINES (hopefully) *******************/
#ifdef FXAA_QUALITY_PRESET
	#undef FXAA_QUALITY_PRESET
#endif
#ifdef FXAA_GREEN_AS_LUMA
	#undef FXAA_GREEN_AS_LUMA
#endif
#ifdef FXAA_LINEAR_LIGHT
	#undef FXAA_LINEAR_LIGHT
#endif
#ifdef FXAA_PC
	#undef FXAA_PC
#endif
#ifdef FXAA_HLSL_3
	#undef FXAA_HLSL_3
#endif
#ifdef FXAA_GATHER4_ALPHA
	#undef FXAA_GATHER4_ALPHA
#endif
#ifdef FxaaTexAlpha4
	#undef FxaaTexAlpha4
#endif
#ifdef FxaaTexOffAlpha4
	#undef FxaaTexOffAlpha4
#endif
#ifdef FxaaTexGreen4
	#undef FxaaTexGreen4
#endif
#ifdef FxaaTexOffGreen4
	#undef FxaaTexOffGreen4
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
#ifdef SMAA_PRESET_CUSTOM
	#undef SMAA_PRESET_CUSTOM
#endif
#ifdef SMAA_THRESHOLD
	#undef SMAA_THRESHOLD
#endif
#ifdef SMAA_MAX_SEARCH_STEPS
	#undef SMAA_MAX_SEARCH_STEPS
#endif
#ifdef SMAA_MAX_SEARCH_STEPS_DIAG
	#undef SMAA_MAX_SEARCH_STEPS_DIAG
#endif
#ifdef SMAA_CORNER_ROUNDING
	#undef SMAA_CORNER_ROUNDING
#endif
#ifdef SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR
	#undef SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR
#endif
#ifdef SMAA_RT_METRICS
	#undef SMAA_RT_METRICS
#endif
#ifdef SMAA_CUSTOM_SL
	#undef SMAA_CUSTOM_SL
#endif
#ifdef SMAATexture2D
	#undef SMAATexture2D
#endif
#ifdef SMAATexturePass2D
	#undef SMAATexturePass2D
#endif
#ifdef SMAASampleLevelZero
	#undef SMAASampleLevelZero
#endif
#ifdef SMAASampleLevelZeroPoint
	#undef SMAASampleLevelZeroPoint
#endif
#ifdef SMAASampleLevelZeroOffset
	#undef SMAASampleLevelZeroOffset
#endif
#ifdef SMAASample
	#undef SMAASample
#endif
#ifdef SMAASamplePoint
	#undef SMAASamplePoint
#endif
#ifdef SMAASampleOffset
	#undef SMAASampleOffset
#endif
#ifdef SMAA_BRANCH
	#undef SMAA_BRANCH
#endif
#ifdef SMAA_FLATTEN
	#undef SMAA_FLATTEN
#endif
#ifdef SMAAGather
	#undef SMAAGather
#endif
#ifdef SMAA_DISABLE_DIAG_DETECTION
	#undef SMAA_DISABLE_DIAG_DETECTION
#endif
#ifdef SMAA_PREDICATION
	#undef SMAA_PREDICATION
#endif
#ifdef SMAA_REPROJECTION
	#undef SMAA_REPROJECTION
#endif
/************************************************************/

#define FXAA_GREEN_AS_LUMA 1    // Seems to play nicer with SMAA, less aliasing artifacts
#define SMAA_PRESET_CUSTOM
#define SMAA_THRESHOLD max(0.05, EdgeThreshold)
#define SMAA_MAX_SEARCH_STEPS 112
#define SMAA_CORNER_ROUNDING 0
#define SMAA_MAX_SEARCH_STEPS_DIAG 20
#define SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR (1.1 + (0.65 * Subpix)) // Range 1.1 to 1.75
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
#define FXAA_QUALITY__P0 0.25
#define FXAA_QUALITY__P1 0.25
#define FXAA_QUALITY__P2 0.5
#define FXAA_QUALITY__P3 0.5
#define FXAA_QUALITY__P4 0.75
#define FXAA_QUALITY__P5 0.75
#define FXAA_QUALITY__P6 1.0
#define FXAA_QUALITY__P7 1.0
#define FXAA_QUALITY__P8 1.25
#define FXAA_QUALITY__P9 1.25
#define FXAA_QUALITY__P10 1.5
#define FXAA_QUALITY__P11 1.5
#define FXAA_QUALITY__P12 2.0

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
	float2 color = SMAAColorEdgeDetectionPS(texcoord, offset, colorGammaSampler);
	float2 luma = SMAALumaEdgeDetectionPS(texcoord, offset, colorGammaSampler);
	float2 result = float2(sqrt(color.r * luma.r), sqrt(color.g * luma.g));
	return result;
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

float4 FXAAPixelShaderCoarse(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float TotalSubpix = 0.0;
	if (Overdrive)
	{
		TotalSubpix += SubpixBoost;
		TotalSubpix = TotalSubpix * 0.125;
	}
	TotalSubpix += Subpix * 0.125;
	#undef FXAA_QUALITY__PS
	#define FXAA_QUALITY__PS 3
	float4 output = FxaaPixelShader(texcoord,0,FXAATexture,FXAATexture,FXAATexture,BUFFER_PIXEL_SIZE,0,0,0,TotalSubpix,0.925 - (Subpix * 0.125),0.004,0,0,0,0); // Range 0.925 to 0.8
	return saturate(output);
}

float4 FXAAPixelShaderMid(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float TotalSubpix = 0.0;
	if (Overdrive)
	{
		TotalSubpix += SubpixBoost;
		TotalSubpix = TotalSubpix * 0.25;
	}
	TotalSubpix += Subpix * 0.25;
	#undef FXAA_QUALITY__PS
	#define FXAA_QUALITY__PS 3
	float4 output = FxaaPixelShader(texcoord,0,FXAATexture,FXAATexture,FXAATexture,BUFFER_PIXEL_SIZE,0,0,0,TotalSubpix,0.85 - (Subpix * 0.15),0.012,0,0,0,0); // Range 0.85 to 0.7
	return saturate(output);
}

float4 FXAAPixelShaderFine(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float TotalSubpix = 0.0;
	if (Overdrive)
	{
		TotalSubpix += SubpixBoost;
		TotalSubpix = TotalSubpix * 0.5;
	}
	TotalSubpix += Subpix * 0.5;
	#undef FXAA_QUALITY__PS
	#define FXAA_QUALITY__PS 13
	float4 output = FxaaPixelShader(texcoord,0,FXAATexture,FXAATexture,FXAATexture,BUFFER_PIXEL_SIZE,0,0,0,TotalSubpix,max(0.1,0.7 * EdgeThreshold),0,0,0,0,0); // Cap maximum sensitivity level for blur control
	return saturate(output);
}

// -------------------------------- Rendering passes ----------------------------------------

technique HQAA <
	ui_tooltip = "Hybrid high-Quality AA combines techniques of both SMAA and FXAA to\n"
	             "produce best possible image quality from using both.";
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
	pass FXAA1
	{
		VertexShader = PostProcessVS;
		PixelShader = FXAAPixelShaderCoarse;
	}
	pass FXAA2
	{
		VertexShader = PostProcessVS;
		PixelShader = FXAAPixelShaderMid;
	}
	pass FXAA3
	{
		VertexShader = PostProcessVS;
		PixelShader = FXAAPixelShaderFine;
	}
}
