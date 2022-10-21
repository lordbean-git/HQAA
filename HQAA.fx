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
 
 // Special thanks to JudgeK for his help and feedback in developing this shader
 

/*****************************************************************************************************************************************/
/*********************************************************** UI SETUP START **************************************************************/
/*****************************************************************************************************************************************/

#include "ReShadeUI.fxh"

/////////////////////////////////////////////////////// CONFIGURABLE TOGGLES //////////////////////////////////////////////////////////////

#if HQAA__INTRODUCTION_ACKNOWLEDGED != 1
	#ifndef HQAA__INTRODUCTION_ACKNOWLEDGED
		#define HQAA__INTRODUCTION_ACKNOWLEDGED 0
	#endif
#endif
#if HQAA__INTRODUCTION_ACKNOWLEDGED > 1 || HQAA__INTRODUCTION_ACKNOWLEDGED < 0
	#undef HQAA__INTRODUCTION_ACKNOWLEDGED
	#define HQAA__INTRODUCTION_ACKNOWLEDGED 0
#endif

#if !HQAA__INTRODUCTION_ACKNOWLEDGED
	#undef HQAA__GLOBAL_PRESET
	#define HQAA__GLOBAL_PRESET 11
	#undef HQAA_SPLITSCREEN_PREVIEW
	#define HQAA_SPLITSCREEN_PREVIEW 0
	#undef HQAA_OLED_ANTI_BURN_IN
	#define HQAA_OLED_ANTI_BURN_IN 0
#endif

#if HQAA__INTRODUCTION_ACKNOWLEDGED
	#ifndef HQAA_SPLITSCREEN_PREVIEW
		#define HQAA_SPLITSCREEN_PREVIEW 0
	#endif
	#if HQAA_SPLITSCREEN_PREVIEW > 1 || HQAA_SPLITSCREEN_PREVIEW < 0
		#undef HQAA_SPLITSCREEN_PREVIEW
		#define HQAA_SPLITSCREEN_PREVIEW 0
	#endif
#endif

#if HQAA__INTRODUCTION_ACKNOWLEDGED
	#if HQAA_SPLITSCREEN_PREVIEW
		#undef HQAA_OLED_ANTI_BURN_IN
		#define HQAA_OLED_ANTI_BURN_IN 0
	#else
		#ifndef HQAA_OLED_ANTI_BURN_IN
			#define HQAA_OLED_ANTI_BURN_IN 0
		#endif
		#if HQAA_OLED_ANTI_BURN_IN > 1 || HQAA_OLED_ANTI_BURN_IN < 0
			#undef HQAA_OLED_ANTI_BURN_IN
			#define HQAA_OLED_ANTI_BURN_IN 0
		#endif
	#endif
#endif

#if HQAA__INTRODUCTION_ACKNOWLEDGED
	#ifndef HQAA__GLOBAL_PRESET
		#define HQAA__GLOBAL_PRESET 0
	#endif
	#if HQAA__GLOBAL_PRESET > 12 || HQAA__GLOBAL_PRESET < 0
		#undef HQAA__GLOBAL_PRESET
		#define HQAA__GLOBAL_PRESET 0
	#endif
#endif

#if HQAA__GLOBAL_PRESET != 0
	#undef HQAA_ADVANCED_MODE
	#undef HQAA_OPTIONAL__TEMPORAL_AA
	#undef HQAA_OPTIONAL__DEBANDING
	#undef HQAA_OPTIONAL__SOFTENING
	#undef HQAA_FXAA_MULTISAMPLING
	#undef HQAA_DISABLE_SMAA
#endif
#if HQAA__GLOBAL_PRESET == 1 // ARPG/Isometric
	#define HQAA_ADVANCED_MODE 0
	#define HQAA_OPTIONAL__TEMPORAL_AA 1
	#define HQAA_OPTIONAL__DEBANDING 1
	#define HQAA_OPTIONAL__SOFTENING 1
	#define HQAA_FXAA_MULTISAMPLING 1
#endif
#if HQAA__GLOBAL_PRESET == 2 // Open World
	#define HQAA_ADVANCED_MODE 0
	#define HQAA_OPTIONAL__TEMPORAL_AA 2
	#define HQAA_OPTIONAL__DEBANDING 1
	#define HQAA_OPTIONAL__SOFTENING 1
	#define HQAA_FXAA_MULTISAMPLING 1
#endif
#if HQAA__GLOBAL_PRESET == 3 // Survival
	#define HQAA_ADVANCED_MODE 0
	#define HQAA_OPTIONAL__TEMPORAL_AA 1
	#define HQAA_OPTIONAL__DEBANDING 0
	#define HQAA_OPTIONAL__SOFTENING 1
	#define HQAA_FXAA_MULTISAMPLING 1
#endif
#if HQAA__GLOBAL_PRESET == 4 // Action/Racing
	#define HQAA_ADVANCED_MODE 0
	#define HQAA_OPTIONAL__TEMPORAL_AA 2
	#define HQAA_OPTIONAL__DEBANDING 0
	#define HQAA_OPTIONAL__SOFTENING 1
	#define HQAA_FXAA_MULTISAMPLING 1
#endif
#if HQAA__GLOBAL_PRESET == 5 // Horror
	#define HQAA_ADVANCED_MODE 0
	#define HQAA_OPTIONAL__TEMPORAL_AA 3
	#define HQAA_OPTIONAL__DEBANDING 1
	#define HQAA_OPTIONAL__SOFTENING 1
	#define HQAA_FXAA_MULTISAMPLING 2
#endif
#if HQAA__GLOBAL_PRESET == 6 // Fake HDR
	#define HQAA_ADVANCED_MODE 0
	#define HQAA_OPTIONAL__TEMPORAL_AA 2
	#define HQAA_OPTIONAL__DEBANDING 0
	#define HQAA_OPTIONAL__SOFTENING 1
	#define HQAA_FXAA_MULTISAMPLING 1
#endif
#if HQAA__GLOBAL_PRESET == 7 // Dim LCD
	#define HQAA_ADVANCED_MODE 0
	#define HQAA_OPTIONAL__TEMPORAL_AA 2
	#define HQAA_OPTIONAL__DEBANDING 1
	#define HQAA_OPTIONAL__SOFTENING 1
	#define HQAA_FXAA_MULTISAMPLING 1
#endif
#if HQAA__GLOBAL_PRESET == 8 // Stream-Friendly
	#define HQAA_ADVANCED_MODE 0
	#define HQAA_OPTIONAL__TEMPORAL_AA 2
	#define HQAA_OPTIONAL__DEBANDING 0
	#define HQAA_OPTIONAL__SOFTENING 1
	#define HQAA_FXAA_MULTISAMPLING 1
#endif
#if HQAA__GLOBAL_PRESET == 9 // e-sports
	#define HQAA_ADVANCED_MODE 0
	#define HQAA_OPTIONAL__TEMPORAL_AA 1
	#define HQAA_OPTIONAL__DEBANDING 0
	#define HQAA_OPTIONAL__SOFTENING 0
	#define HQAA_FXAA_MULTISAMPLING 1
#endif
#if HQAA__GLOBAL_PRESET == 10 // DLSS/FSR/TAA assist
	#define HQAA_ADVANCED_MODE 0
	#define HQAA_OPTIONAL__TEMPORAL_AA 2
	#define HQAA_OPTIONAL__DEBANDING 1
	#define HQAA_OPTIONAL__SOFTENING 0
	#define HQAA_FXAA_MULTISAMPLING 1
#endif
#if HQAA__GLOBAL_PRESET == 11 // max bang for buck
	#define HQAA_ADVANCED_MODE 1
	#define HQAA_OPTIONAL__TEMPORAL_AA 1
	#undef HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
	#define HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE 0
	#define HQAA_OPTIONAL__DEBANDING 0
	#define HQAA_OPTIONAL__SOFTENING 1
	#define HQAA_FXAA_MULTISAMPLING 1
	#define HQAA_DISABLE_SMAA 0
#endif
#if HQAA__GLOBAL_PRESET == 12 // Beefcake GPU
	#define HQAA_ADVANCED_MODE 0
	#define HQAA_OPTIONAL__TEMPORAL_AA 4
	#define HQAA_OPTIONAL__DEBANDING 2
	#define HQAA_OPTIONAL__SOFTENING 3
	#define HQAA_FXAA_MULTISAMPLING 3
#endif


#if HQAA__GLOBAL_PRESET == 0

	#ifndef HQAA_FXAA_MULTISAMPLING
		#define HQAA_FXAA_MULTISAMPLING 1
	#endif
	#if HQAA_FXAA_MULTISAMPLING > 4 || HQAA_FXAA_MULTISAMPLING < 0
		#undef HQAA_FXAA_MULTISAMPLING
		#define HQAA_FXAA_MULTISAMPLING 1
	#endif

	#ifndef HQAA_ADVANCED_MODE
		#define HQAA_ADVANCED_MODE 0
	#endif
	#if HQAA_ADVANCED_MODE > 1 || HQAA_ADVANCED_MODE < 0
		#undef HQAA_ADVANCED_MODE
		#define HQAA_ADVANCED_MODE 0
	#endif
	
	#if HQAA_ADVANCED_MODE
		#ifndef HQAA_DISABLE_SMAA
			#define HQAA_DISABLE_SMAA 0
		#endif
		#if HQAA_DISABLE_SMAA > 1 || HQAA_DISABLE_SMAA < 0
			#undef HQAA_DISABLE_SMAA
			#define HQAA_DISABLE_SMAA 0
		#endif
	#endif

	#ifndef HQAA_OPTIONAL__TEMPORAL_AA
		#define HQAA_OPTIONAL__TEMPORAL_AA 1
	#endif //HQAA_OPTIONAL__TEMPORAL_AA
	#if HQAA_OPTIONAL__TEMPORAL_AA > 4 || HQAA_OPTIONAL__TEMPORAL_AA < 0
		#undef HQAA_OPTIONAL__TEMPORAL_AA
		#define HQAA_OPTIONAL__TEMPORAL_AA 1
	#endif
	
	#ifndef HQAA_OPTIONAL__DEBANDING
		#define HQAA_OPTIONAL__DEBANDING 0
	#endif
	#if HQAA_OPTIONAL__DEBANDING > 4 || HQAA_OPTIONAL__DEBANDING < 0
		#undef HQAA_OPTIONAL__DEBANDING
		#define HQAA_OPTIONAL__DEBANDING 0
	#endif
		
	#ifndef HQAA_OPTIONAL__SOFTENING
		#define HQAA_OPTIONAL__SOFTENING 1
	#endif
	#if HQAA_OPTIONAL__SOFTENING > 4 || HQAA_OPTIONAL__SOFTENING < 0
		#undef HQAA_OPTIONAL__SOFTENING
		#define HQAA_OPTIONAL__SOFTENING 1
	#endif
		
#endif //HQAA__GLOBAL_PRESET

#if HQAA_OPTIONAL__TEMPORAL_AA && HQAA__GLOBAL_PRESET != 11
	
	#ifndef HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
		#define HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE 0
	#endif
	#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE > 1 || HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE < 0
		#undef HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
		#define HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE 0
	#endif
			
#endif
	
uniform uint HqaaFramecounter < source = "framecount"; >;
#define __HQAA_ALT_FRAME ((HqaaFramecounter + HqaaSourceInterpolationOffset) % 2 == 0)
#define __HQAA_QUAD_FRAME ((HqaaFramecounter + HqaaSourceInterpolationOffset) % 4 == 1)
#define __HQAA_THIRD_FRAME (HqaaFramecounter % 3 == 1)

/////////////////////////////////////////////////////// GLOBAL SETUP OPTIONS //////////////////////////////////////////////////////////////

uniform int HqaaAboutSTART <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n"
			  "---------------------------------- HQAA v29.2 ----------------------------------\n"
			#if !HQAA__INTRODUCTION_ACKNOWLEDGED
			  "READ THIS INFO BEFORE FIRST USE as this information is IMPORTANT and will allow\n"
			  "you to get the most out of this shader.\n"
			  "HQAA is designed to provide anti-aliasing in games that do not have a desirable\n"
			  "AA method active. The defaults (quality profiles, global presets, and advanced\n"
			  "options) assume HQAA is the only anti-aliasing method in use, unless otherwise\n"
			  "explicitly stated. All default settings are intended to provide a balanced\n"
			  "overall final image quality; however the shader can easily be configured either\n"
			  "for increased AA effect or reduced blur, as desired. ALL pre-processor defines\n"
			  "visible in the 'Preprocessor definitions' tab at the end are user-configurable\n"
			  "in HQAA, and control the various features available in the shader.\n"
			  "The Quality Profile determines how aggressively HQAA will search for and correct\n"
			  "edges. Please note that the Balanced profile is intended for general-purpose use\n"
			  "and should be more than capable of handling just about any game. The Aggressive\n"
			  "profile is representative of overkill settings and requires a lot of GPU time to\n"
			  "run. HQAA also depends on 'Performance Mode' being enabled in ReShade as a large\n"
			  "quantity of code will be removed from the compiled shader when it is enabled.\n"
			  "To disable this message and unlock full shader configuration, set the define\n"
			  "'HQAA__INTRODUCTION_ACKNOWLEDGED' to 1.\n"
			  "--------------------------------------------------------------------------------\n"
			#endif
			  "";
>;

#if HQAA__INTRODUCTION_ACKNOWLEDGED
uniform int HQAAintroduction <
	ui_spacing = 3;
	ui_type = "radio";
	ui_label = "Version: 29.2.211022\n\n";
	ui_text = "--------------------------------------------------------------------------------\n"
			"Hybrid high-Quality Anti-Aliasing, a shader by lordbean\n"
			"https://github.com/lordbean-git/HQAA/\n"
			"--------------------------------------------------------------------------------\n"
			"| Currently Compiled Configuration |\n"
			"------------------------------------\n\n"
			
			#if HQAA__GLOBAL_PRESET == 1
			"Preset:                                                        ARPG/Isometric\n"
			#elif HQAA__GLOBAL_PRESET == 2
			"Preset:                                                            Open World\n"
			#elif HQAA__GLOBAL_PRESET == 3
			"Preset:                                                              Survival\n"
			#elif HQAA__GLOBAL_PRESET == 4
			"Preset:                                                         Action/Racing\n"
			#elif HQAA__GLOBAL_PRESET == 5
			"Preset:                                                    Horror/Atmospheric\n"
			#elif HQAA__GLOBAL_PRESET == 6
			"Preset:                                                              Fake HDR\n"
			#elif HQAA__GLOBAL_PRESET == 7
			"Preset:                                                  Dim LCD Compensation\n"
			#elif HQAA__GLOBAL_PRESET == 8
			"Preset:                                                    Streaming-Friendly\n"
			#elif HQAA__GLOBAL_PRESET == 9
			"Preset:                                                              e-Sports\n"
			#elif HQAA__GLOBAL_PRESET == 10
			"Preset:                                                  DLSS/FSR/MSAA Assist\n"
			#elif HQAA__GLOBAL_PRESET == 11
			"Preset:                                                     Max Bang for Buck\n"
			#elif HQAA__GLOBAL_PRESET == 12
			"Preset:                                                          Beefcake GPU\n"
			#else
			"Preset:                                                                Manual\n"
			#endif //HQAA__GLOBAL_PRESET
			#if HQAA_ADVANCED_MODE
			"Advanced Mode:                                                             on  *\n"
			#else
			"Advanced Mode:                                                            off\n"
			#endif
			#if HQAA_FXAA_MULTISAMPLING == 1
			"FXAA Multisampling:                                                       off\n"
			#elif HQAA_FXAA_MULTISAMPLING == 4
			"FXAA Multisampling:                                                   on (4x)  *\n"
			#elif HQAA_FXAA_MULTISAMPLING == 3
			"FXAA Multisampling:                                                   on (3x)  *\n"
			#elif HQAA_FXAA_MULTISAMPLING == 2
			"FXAA Multisampling:                                                   on (2x)  *\n"
			#elif HQAA_FXAA_MULTISAMPLING == 0
			"FXAA:                                                                disabled  *\n"
			#endif //HQAA_FXAA_MULTISAMPLING
			#if HQAA_ADVANCED_MODE
			#if HQAA_DISABLE_SMAA
			"SMAA:                                                                disabled  *\n"
			#else
			"SMAA:                                                                 enabled\n"
			#endif //HQAA_DISABLE_SMAA
			#endif //HQAA_ADVANCED_MODE
			#if HQAA_OPTIONAL__DEBANDING
			"Debanding:                                                            on"
			#if HQAA_OPTIONAL__DEBANDING < 2
			" (1x)  *\n"
			#elif HQAA_OPTIONAL__DEBANDING > 3
			" (4x)  *\n"
			#elif HQAA_OPTIONAL__DEBANDING > 2
			" (3x)  *\n"
			#elif HQAA_OPTIONAL__DEBANDING > 1
			" (2x)  *\n"
			#endif //HQAA_OPTIONAL__DEBANDING
			#else
			"Debanding:                                                                off\n"
			#endif //HQAA_OPTIONAL__DEBANDING
			#if HQAA_OPTIONAL__SOFTENING
			"Image Softening:                                                      on"
			#if HQAA_OPTIONAL__SOFTENING < 2
			" (1x)\n"
			#elif HQAA_OPTIONAL__SOFTENING > 3
			" (4x)  *\n"
			#elif HQAA_OPTIONAL__SOFTENING > 2
			" (3x)  *\n"
			#elif HQAA_OPTIONAL__SOFTENING > 1
			" (2x)  *\n"
			#endif //HQAA_OPTIONAL__SOFTENING
			#else
			"Image Softening:                                                          off  *\n"
			#endif
			#if HQAA_OPTIONAL__TEMPORAL_AA
			"Temporal Anti-Aliasing:                                               on"
			#if HQAA_OPTIONAL__TEMPORAL_AA > 3
			" (4x)  *\n"
			#elif HQAA_OPTIONAL__TEMPORAL_AA > 2
			" (3x)  *\n"
			#elif HQAA_OPTIONAL__TEMPORAL_AA > 1
			" (2x)  *\n"
			#else
			" (1x)\n"
			#endif
			#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
			"|_> Temporal Persistence (Previous Frame Blending):                        on  *\n"
			#else
			"|_> Temporal Persistence (Previous Frame Blending):                       off\n"
			#endif
			#else
			"Temporal Anti-Aliasing:                                                   off  *\n"
			#endif //HQAA_OPTIONAL__TEMPORAL_AA
			#if HQAA_OLED_ANTI_BURN_IN
			"OLED Anti Burn-in (Experimental):                                          on  *\n"
			#else
			"OLED Anti Burn-in (Experimental):                                         off\n"
			#endif
			
			#if HQAA__GLOBAL_PRESET == 0
			"\n--------------------------------------------------------------------------------\n\n"
			
			"Remarks:\n"
			
			"\nFXAA Multisampling can be used to increase correction strength in cases such\n"
			"as edges with more than one color gradient or along objects that have highly\n"
			"irregular geometry. Costs some performance for each extra pass.\n"
			"Valid range: 1 to 4. Higher values are ignored.\n"
			
			#if HQAA_OPTIONAL__DEBANDING || HQAA_OPTIONAL__SOFTENING || HQAA_OPTIONAL__TEMPORAL_AA
			"\nYou can set the number of debanding/softening/temporal AA passes in the same\n"
			"way as FXAA multisampling. Valid range is 1 to 4.\n"
			#endif
			
			#if HQAA_OPTIONAL__TEMPORAL_AA && HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
			"\nPlease note that TAA Persistence uses additional GPU memory for each TAA pass.\n"
			"Disabling Temporal Persistence removes the additional memory footprint.\n"
			#endif
			
			"\nLike how HQAA looks but your GPU isn't keeping up? Try the Max Bang for Buck\n"
			"preset (set HQAA__GLOBAL_PRESET to 11). It uses highly minimalistic settings to\n"
			"provide most of the image quality that HQAA is capable of while using a lot less\n"
			"total GPU time.\n"
			#endif // HQAA__GLOBAL_PRESET
			
			#if HQAA__GLOBAL_PRESET == 11
			"\n--------------------------------------------------------------------------------\n\n"
			
			"Remarks:\n"
			
			"\nMax Bang for Buck uses minimalist configurations of the primary anti-aliasing\n"
			"effects and includes image softening, TAA, and sharpening as well. Additionally,\n"
			"Max Bang for Buck disables unnecessary code in the shader and uses simplified\n"
			"versions of some effects to provide good image quality while consuming as little\n"
			"GPU time as possible.\n"
			#endif
			
			"\n"
			
			"--------------------------------------------------------------------\n"
			"| Available Global Preset Configurations (via HQAA__GLOBAL_PRESET) |\n"
			"--------------------------------------------------------------------\n"
			"\n"
			"0 = Manual Setup (Default)\n"
			"1 = ARPG/Isometric\n"
			"2 = Open World\n"
			"3 = Survival\n"
			"4 = Action/Racing\n"
			"5 = Horror/Atmospheric\n"
			"6 = Fake HDR\n"
			"7 = Dim LCD Compensation\n"
			"8 = Streaming-Friendly\n"
			"9 = e-Sports\n"
			"10 = DLSS/FSR/MSAA Assist\n"
			"11 = Max Bang for Buck\n"
			"12 = Beefcake GPU\n"
			"";
	ui_tooltip = "Quantum Superposition of Cake";
	ui_category = "About";
	ui_category_closed = true;
>;
#endif //HQAA__INTRODUCTION_ACKNOWLEDGED

#if HQAA__GLOBAL_PRESET == 0
#if !HQAA_ADVANCED_MODE
uniform bool HqaaEnableAABlending <
	ui_spacing = 3;
	ui_label = "Enable Anti-Aliasing Blending";
	ui_tooltip = "Uncheck if you want to use the shader for\n"
				 "the optional effects, but not the anti-\n"
				 "aliasing. SMAA edge detection and weight\n"
				 "calculations will still be performed as\n"
				 "most of the optionals use the data. This\n"
				 "option disables SMAA and FXAA blending -\n"
				 "TAA will still be performed if enabled.";
	ui_category = "Output";
	ui_category_closed = true;
> = true;
#else
#if !HQAA_DISABLE_SMAA
uniform bool HqaaEnableSMAABlending <
	ui_spacing = 3;
	ui_label = "Enable SMAA Anti-Aliasing Blending";
	ui_tooltip = "Uncheck if you want to use the shader for\n"
				 "the optional effects, but not the anti-\n"
				 "aliasing. SMAA edge detection and weight\n"
				 "calculations will still be performed as\n"
				 "most of the optionals use the data. This\n"
				 "option disables SMAA blending only -\n"
				 "TAA will still be performed if enabled.";
	ui_category = "Output";
	ui_category_closed = true;
> = true;
#endif //HQAA_DISABLE_SMAA
#if HQAA_FXAA_MULTISAMPLING > 0
uniform bool HqaaEnableFXAABlending <
	ui_label = "Enable FXAA Anti-Aliasing Blending";
	ui_tooltip = "Uncheck if you want to use the shader for\n"
				 "the optional effects, but not the anti-\n"
				 "aliasing. SMAA edge detection and weight\n"
				 "calculations will still be performed as\n"
				 "most of the optionals use the data. This\n"
				 "option disables FXAA blending only -\n"
				 "TAA will still be performed if enabled.";
	ui_category = "Output";
	ui_category_closed = true;
> = true;
#endif //HQAA_FXAA_MULTISAMPLING
#endif //HQAA_ADVANCED_MODE
#else
#if !HQAA_ADVANCED_MODE
static const bool HqaaEnableAABlending = true;
#else
static const bool HqaaEnableSMAABlending = true;
static const bool HqaaEnableFXAABlending = true;
#endif
#endif

#if HQAA__INTRODUCTION_ACKNOWLEDGED
uniform uint HqaaOutputMode <
	ui_type = "radio";
	ui_spacing = 3;
	ui_label = " ";
	ui_text = "Color Format:\n\n";
	ui_items = "Normal (sRGB)\0HDR, Direct Nits Scale\0Perceptual Quantizer, Accurate (HDR10, scRGB)\0Perceptual Quantizer, Fast Transcode (HDR10, scRGB)\0";
	ui_category = "Output";
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
	ui_category = "Output";
	ui_category_closed = true;
> = 1000.0;
#else
static const uint HqaaOutputMode = 0;
static const float HqaaHdrNits = 1000.0;
#endif //HQAA__INTRODUCTION_ACKNOWLEDGED

#if HQAA_OLED_ANTI_BURN_IN
uniform float HqaaOledStrobeStrength <
	ui_spacing = 3;
	ui_type = "slider";
	ui_label = "Luma Strobing Strength\n\n";
	ui_tooltip = "Strobes the luma of every pixel to\n"
				 "force OLED displays to keep updating\n"
				 "static areas each frame. This feature\n"
				 "is experimental, and the extent to\n"
				 "which it helps is unknown.";
	ui_min = 0.0; ui_max = 0.02; ui_step = 0.001;
	ui_category = "OLED Anti Burn-in";
	ui_category_closed = true;
> = 0.008;
#endif

#if HQAA__GLOBAL_PRESET == 0
uniform uint HqaaDebugMode <
	ui_type = "radio";
	ui_category = "Debug";
	ui_category_closed = true;
	ui_spacing = 3;
	ui_label = "Mouseover for info\n\n";
	ui_text = "Debug Mode:";
	ui_items = "Off\n\n\0Detected Edges\0SMAA Blend Weights\n\n\0FXAA Results\0FXAA Lumas\0FXAA Metrics\0FXAA Spans\n\n\0Hysteresis Pattern\n\n\0Dynamic Threshold Usage\n\n\0Disable SMAA\0Disable FXAA\0\n\n";
	ui_tooltip = "Useful primarily for learning what everything\n"
				 "does when using advanced mode setup. Debug\n"
				 "instructions are compiled out of the shader\n"
				 "when 'Off' is selected and ReShade is in\n"
				 "Performance Mode. You can find additional\n"
				 "info on how to read each debug mode in the\n"
				 "'DEBUG README' dropdown near the bottom.";
> = 0;
#else
static const uint HqaaDebugMode = 0;
#endif

#if HQAA_SPLITSCREEN_PREVIEW
uniform float HqaaSplitscreenPosition <
	ui_type = "slider";
	ui_spacing = 3;
	ui_label = "Split Position";
	ui_tooltip = "Moves the separator between before and\n"
				 "after around the screen.";
	ui_min = 0.00; ui_max = 1.0; ui_step = 0.001;
	ui_category = "Splitscreen Preview";
> = 0.5;

uniform bool HqaaSplitscreenFlipped <
	ui_label = "Switch Before/After Sides";
	ui_category = "Splitscreen Preview";
> = false;
#endif //HQAA_SPLITSCREEN_PREVIEW

#if HQAA__INTRODUCTION_ACKNOWLEDGED
uniform int HqaaAboutEOF <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n--------------------------------------------------------------------------------";
>;
#endif //HQAA__INTRODUCTION_ACKNOWLEDGED

#if !HQAA_ADVANCED_MODE
uniform uint HqaaPreset <
	ui_type = "combo";
	ui_label = "Quality Profile";
	ui_tooltip = ""
#if  HQAA__GLOBAL_PRESET == 0
	"For full control over all anti-aliasing-related\n"
	"options, set HQAA_ADVANCED_MODE to 1."
#endif
#if HQAA__GLOBAL_PRESET == 1
	"Recommended profile: Conservative or Balanced"
#endif
#if HQAA__GLOBAL_PRESET == 2
	"Recommended profile: Balanced"
#endif
#if HQAA__GLOBAL_PRESET == 3
	"Recommended profile: Conservative"
#endif
#if HQAA__GLOBAL_PRESET == 4
	"Recommended profile: Balanced"
#endif
#if HQAA__GLOBAL_PRESET == 5
	"Recommended profile: Balanced or Aggressive"
#endif
#if HQAA__GLOBAL_PRESET == 6
	"Recommended profile: Balanced"
#endif
#if HQAA__GLOBAL_PRESET == 7
	"Recommended profile: Conservative or Balanced"
#endif
#if HQAA__GLOBAL_PRESET == 8
	"Recommended profile: Conservative"
#endif
#if HQAA__GLOBAL_PRESET == 9
	"Recommended profile: Conservative"
#endif
#if HQAA__GLOBAL_PRESET == 10
	"Recommended profile: Balanced"
#endif
#if HQAA__GLOBAL_PRESET == 12
	"Recommended profile: Aggressive"
#endif
	"";
	ui_items = "Conservative\0Balanced\0Aggressive\0";
#if HQAA__GLOBAL_PRESET != 0
	ui_text = ""
#if HQAA__GLOBAL_PRESET == 1
	"Global Preset: ARPG/Isometric"
#endif
#if HQAA__GLOBAL_PRESET == 2
	"Global Preset: Open World"
#endif
#if HQAA__GLOBAL_PRESET == 3
	"Global Preset: Survival"
#endif
#if HQAA__GLOBAL_PRESET == 4
	"Global Preset: Action/Racing"
#endif
#if HQAA__GLOBAL_PRESET == 5
	"Global Preset: Horror/Atmospheric"
#endif
#if HQAA__GLOBAL_PRESET == 6
	"Global Preset: Fake HDR"
#endif
#if HQAA__GLOBAL_PRESET == 7
	"Global Preset: Dim LCD Compensation"
#endif
#if HQAA__GLOBAL_PRESET == 8
	"Global Preset: Streaming-Friendly"
#endif
#if HQAA__GLOBAL_PRESET == 9
	"Global Preset: e-Sports"
#endif
#if HQAA__GLOBAL_PRESET == 10
	"Global Preset: DLSS/FSR/MSAA Assist"
#endif
#if HQAA__GLOBAL_PRESET == 12
	"Global Preset: Beefcake GPU"
#endif
	"\n\n";
#endif //HQAA__GLOBAL_PRESET != 0
> = 1;
#endif

#if HQAA__GLOBAL_PRESET == 0
#if !HQAA_ADVANCED_MODE
static const float HqaaNoiseControlStrength = 12.5;
static const float HqaaNoiseFloor = 0.0722;
static const float HqaaLowLumaThreshold = 0.2;
static const bool HqaaSmCornerDetection = true;
static const bool HqaaDoLumaHysteresis = true;
static const bool HqaaFxDiagScans = false;
static const bool HqaaFxEarlyExit = true;
static const bool HqaaFxTexelGrowth = true;
static const uint HqaaFxTexelGrowAfter = 16;
static const float HqaaFxTexelGrowPercent = 1.5;
static const uint HqaaSourceInterpolation = 0;
static const uint HqaaSourceInterpolationOffset = 0;

#else
uniform float HqaaEdgeThresholdCustom <
	ui_type = "slider";
	ui_min = 0.02; ui_max = 1.0;
	ui_spacing = 3;
	ui_label = "Edge Detection Threshold";
	ui_tooltip = "Local contrast required to be considered an edge.\n\n"
				 "Recommended range: [0.05..0.15]";
	ui_category = "Global";
	ui_category_closed = true;
> = 0.05;

uniform float HqaaLowLumaThreshold <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 0.5; ui_step = 0.001;
	ui_label = "Low Luma Threshold";
	ui_tooltip = "Luma level below which dynamic thresholding activates\n\n"
				 "Recommended range: [0.1..0.3]";
	ui_category = "Global";
	ui_category_closed = true;
> = 0.2;

uniform float HqaaDynamicThresholdCustom <
	ui_type = "slider";
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "% Dynamic Range";
	ui_tooltip = "Maximum reduction of edge threshold (% base threshold)\n"
				 "permitted when detecting low-brightness edges.\n"
				 "Lower = faster, might miss low-contrast edges\n"
				 "Higher = slower, catches more edges in dark scenes\n\n"
				 "Recommended range: [40..80]";
	ui_category = "Global";
	ui_category_closed = true;
> = 60;

uniform uint HqaaFxQualityCustom <
	ui_spacing = 6;
	ui_type = "slider";
	ui_min = 5; ui_max = 100; ui_step = 1;
	ui_label = "Scan Distance";
	ui_tooltip = "Maximum radius from center dot\nthat SMAA and FXAA will scan.\n\n"
				 "Recommended range: [40..100]";
	ui_category = "Global";
	ui_category_closed = true;
> = 80;

uniform float HqaaNoiseControlStrength <
	ui_spacing = 6;
	ui_type = "slider";
	ui_min = 0; ui_max = 100; ui_step = 0.1;
	ui_label = "Noise Control Strength";
	ui_tooltip = "Controls how strongly AA blending will be clamped when\n"
				 "the output would cause a high luma delta.\n\n"
				 "Recommended range: [25..67]";
	ui_category = "Global";
	ui_category_closed = true;
> = 12.5;

uniform float HqaaNoiseFloor <
	ui_type = "slider";
	ui_label = "Noise Floor";
	ui_tooltip = "Sets the difference threshold below which\n"
				 "anti-aliasing results will not be considered\n"
				 "as possible noise.\n\n"
				 "Recommended range: [0.08..0.25]";
	ui_min = 0.0; ui_max = 0.5; ui_step = 0.001;
	ui_category = "Global";
	ui_category_closed = true;
> = 0.0722;

uniform float HqaaResolutionScalar <
	ui_spacing = 6;
	ui_type = "slider";
	ui_tooltip = "Allows the blur control scalar to be\n"
				 "changed. Note that HQAA is calibrated\n"
				 "for balanced output at 1440p by default.\n\n"
				 "Recommended setting: 1440";
	ui_label = "Resolution Scalar\n\n";
	ui_min = 360; ui_max = 2160; ui_step = 20;
	ui_category = "Global";
	ui_category_closed = true;
> = 1440;

uniform bool HqaaSmCornerDetection <
	ui_spacing = 3;
	ui_label = "Perform Corner Detection";
	ui_tooltip = "Indicates whether SMAA will detect patterns\n"
				 "that look like corners in the edge data.\n"
				 "Disabling corner detection is equivalent\n"
				 "to setting corner rounding to 100%.\n\n"
				 "Recommended setting: enabled";
	ui_category = "SMAA-Specific";
	ui_category_closed = true;
> = true;
	
uniform float HqaaSmCorneringCustom <
	ui_type = "slider";
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "% Corner Rounding";
	ui_tooltip = "Affects the amount of blending performed when SMAA\ndetects crossing edges. Only works when corner\ndetection is enabled.\n\n"
				 "Recommended range: [0..50]";
	ui_category = "SMAA-Specific";
	ui_category_closed = true;
> = 25;

uniform uint HqaaSourceInterpolation <
	ui_type = "combo";
	ui_spacing = 6;
	ui_label = "Edge Detection Interpolation";
	ui_tooltip = "Offsets edge detection passes by either\n"
				 "two or four frames when enabled. This is\n"
				 "intended for specific usage cases where\n"
				 "the game's framerate is interpolated from\n"
				 "a low value to a higher one (eg capped 30\n"
				 "interpolated to 60fps). For the vast\n"
				 "majority of games, leave this setting off.";
	ui_items = "Off\0Single Interpolation\0Double Interpolation\0";
	ui_category = "SMAA-Specific";
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
	ui_category = "SMAA-Specific";
	ui_category_closed = true;
> = 0;

uniform float HqaaFxTexelCustom <
	ui_type = "slider";
	ui_min = 0.1; ui_max = 2.0; ui_step = 0.01;
	ui_spacing = 3;
	ui_label = "Edge Gradient Texel Size";
	ui_tooltip = "Determines how far along an edge FXAA will move\nfrom one scan iteration to the next.\n\nLower = slower, more accurate\nHigher = faster, causes more blur\n\n"
				 "Recommended range: [0.2..0.67]";
	ui_category = "FXAA-Specific";
	ui_category_closed = true;
> = 0.25;

uniform bool HqaaFxTexelGrowth <
	ui_spacing = 3;
	ui_label = "Enable Texel Growth";
	ui_tooltip = "When enabled, gradually expands the texel size\n"
				 "to increase the total length of the gradient scan.\n"
				 "May cause a slight reduction in result accuracy.\n\n"
				 "Recommended setting: enabled";
	ui_category = "FXAA-Specific";
	ui_category_closed = true;
> = true;
	
uniform uint HqaaFxTexelGrowAfter <
	ui_spacing = 3;
	ui_text = "Texel growth begins after:\n";
	ui_label = "Scan Iterations";
	ui_type = "slider";
	ui_min = 1; ui_max = 100; ui_step = 1;
	ui_tooltip = "When texel growth is enabled, FXAA will scan\n"
				 "this many iterations using the base size\n"
				 "before the texel begins to grow.\n\n"
				 "Recommended range: [10..40]";
	ui_category = "FXAA-Specific";
	ui_category_closed = true;
> = 16;

uniform float HqaaFxTexelGrowPercent <
	ui_text = "Texel growth per subsequent iteration:\n";
	ui_label = "Percent";
	ui_type = "slider";
	ui_min = 0; ui_max = 10; ui_step = 0.1;
	ui_tooltip = "When texel growth is active, the texel will\n"
				 "grow by this percentage of its previous size.\n\n"
				 "Recommended range: [1..2]";
	ui_category = "FXAA-Specific";
	ui_category_closed = true;
> = 1.5;

uniform float HqaaFxBlendCustom <
	ui_spacing = 6;
	ui_type = "slider";
	ui_min = 0; ui_max = 100; ui_step = 1;
	ui_label = "% Blending Strength";
	ui_tooltip = "Percentage of blending FXAA will apply to edges.\n"
				 "Lower = sharper image, Higher = more AA effect\n\n"
				 "Recommended range: [75..100]";
	ui_category = "FXAA-Specific";
	ui_category_closed = true;
> = 100;

uniform bool HqaaFxDiagScans <
	ui_label = "Allow Diagonal Gradient Scanning";
	ui_tooltip = "If enabled, FXAA will perform diagonal\n"
				 "gradient scans when they outweigh vertical\n"
				 "or horizontal gradients. This alters the\n"
				 "final results slightly, and whether it looks\n"
				 "good or bad depends mostly on the game.\n"
				 "Performance is better when disabled.";
	ui_spacing = 3;
	ui_category = "FXAA-Specific";
	ui_category_closed = true;
> = false;

uniform bool HqaaFxEarlyExit <
	ui_label = "Allow Early Exit\n\n";
	ui_tooltip = "Normally, FXAA will early-exit when the\n"
				 "local contrast doesn't exceed the edge\n"
				 "threshold. Uncheck this to force FXAA to\n"
				 "process the entire scene. Costs significant\n"
				 "extra GPU time.\n\n"
				 "Recommended setting: enabled";
	ui_category = "FXAA-Specific";
	ui_category_closed = true;
> = true;

uniform bool HqaaDoLumaHysteresis <
	ui_spacing = 3;
	ui_label = "Enable Hysteresis";
	ui_tooltip = "Hysteresis measures the luma of each pixel\n"
				"before and affer changes are made to it and\n"
				"uses the delta to reconstruct detail from\n"
				"the original scene.\n\n"
				 "Recommended setting: enabled";
	ui_category = "Hysteresis";
	ui_category_closed = true;
> = true;

uniform float HqaaHysteresisStrength <
	ui_type = "slider";
	ui_spacing = 3;
	ui_min = 0; ui_max = 100; ui_step = 0.1;
	ui_label = "% Strength";
	ui_tooltip = "0% = Off (keep anti-aliasing result as-is)\n100% = Aggressive Correction\n\n"
				 "Recommended range: [20..50]";
	ui_category = "Hysteresis";
	ui_category_closed = true;
> = 25;

uniform float HqaaHysteresisFudgeFactor <
	ui_type = "slider";
	ui_min = 0; ui_max = 25; ui_step = 0.01;
	ui_label = "% Fudge Factor\n\n";
	ui_tooltip = "Ignore up to this much difference between the\noriginal pixel and the anti-aliasing result\n\n"
				 "Recommended range: [0..7.5]";
	ui_category = "Hysteresis";
	ui_category_closed = true;
> = 2.5;
#endif //HQAA_ADVANCED_MODE
#endif //HQAA__GLOBAL_PRESET

#if HQAA__GLOBAL_PRESET != 11
uniform int HqaaOptionsEOF <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n--------------------------------------------------------------------------------";
>;
#endif

#if HQAA__GLOBAL_PRESET == 0
uniform bool HqaaEnableSharpening <
	ui_spacing = 3;
	ui_label = "Enable Sharpening";
	ui_tooltip = "Performs full-scene AMD Contrast-Adaptive Sharpening\n"
				"which uses SMAA edge data to reduce sharpen strength\n"
				"in regions containing edges. Not compiled when disabled.\n\n"
				 "Recommended setting: enabled if stand-alone, disabled\nif another sharpener is running after HQAA";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = true;

uniform float HqaaSharpenerStrength <
	ui_type = "slider";
	ui_spacing = 3;
	ui_min = 0; ui_max = 1; ui_step = 0.01;
	ui_label = "Strength";
	ui_tooltip = "Amount of sharpening to apply. Try\n"
				 "adjusting this before the other options\n"
				 "as the defaults are calibrated to provide\n"
				 "balanced output without cancelling much\n"
				 "anti-aliasing effect.\n\n"
				 "Recommended range: [0.67..1.0]";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = 0.6;

uniform float HqaaSharpenerClamping <
	ui_type = "slider";
	ui_min = -0.5; ui_max = 0.5; ui_step = 0.001;
	ui_label = "Edge Bias";
	ui_tooltip = "Modifies the sharpening strength applied in locations\n"
				 "where SMAA detected edges. Adds directly to the\n"
				 "sharpening strength, dropping any excess that would\n"
				 "take it outside the range of [0..1].\n\n"
				 "Recommended range: [-0.2..0.2]\n"
				 "Recommended usage: If starting with a blurry scene,\n"
				 "use weaker strength and a positive bias. Otherwise,\n"
				 "use either no bias or a slight negative bias to\n"
				 "sharpen background details.";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = 0.25;

uniform float HqaaSharpenOffset <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
	ui_label = "Sampling Offset";
	ui_tooltip = "Scales the sample pattern up or down\n"
				 "around the middle pixel. Helps to fine\n"
				 "tune the overall sharpening effect.\n\n"
				 "Recommended range: [0.5..0.9]";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = 0.75;

uniform float HqaaSharpenerAdaptation <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
	ui_label = "Contrast";
	ui_tooltip = "Affects how much the CAS math will cause\ncontrasting details to stand out.\n\n"
				 "Recommended range: [0.5..1.0]";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = 0.75;

uniform float HqaaSharpenerLumaCorrection <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
	ui_label = "Luma Correction\n\n";
	ui_tooltip = "Adjusts sharpened pixel luma toward the original luminance.\nHelps avoid oversharpening artifacts.\n\n"
				 "Recommended range: [0.1..0.3]";
	ui_category = "Sharpening";
	ui_category_closed = true;
> = 0.2;

uniform bool HqaaEnableBrightnessGain <
	ui_spacing = 3;
	ui_label = "Enable Brightness Booster";
	ui_tooltip = "Uses logarithmic adjustment to increase brightness.\n"
				 "Not compiled when disabled.";
	ui_category = "Brightness Booster";
	ui_category_closed = true;
> = false;

uniform float HqaaGainStrength <
	ui_type = "slider";
	ui_min = 0.00; ui_max = 1.0; ui_step = 0.001;
	ui_spacing = 3;
	ui_label = "Boost";
	ui_tooltip = "Allows to raise overall image brightness\n"
			  "as a quick fix for dark games or monitors.";
	ui_category = "Brightness Booster";
	ui_category_closed = true;
> = 0.0;

uniform bool HqaaGainLowLumaCorrection <
	ui_label = "Washout Correction\n\n";
	ui_tooltip = "Normalizes contrast ratio of resulting pixels\n"
				 "to reduce perceived contrast washout.";
	ui_category = "Brightness Booster";
	ui_category_closed = true;
> = true;

uniform bool HqaaEnableColorPalette <
	ui_spacing = 3;
	ui_label = "Enable Color Palette Manipulation";
	ui_tooltip = "Enables processing of colors in ways that\n"
				 "can alter the overall gamut. Not compiled\n"
				 "when disabled. Individual options also will\n"
				 "not compile when left at the default value.";
	ui_category = "Color Palette";
	ui_category_closed = true;
> = false;

 uniform float HqaaSaturationStrength <
	ui_type = "slider";
	ui_spacing = 3;
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
	ui_label = "Saturation";
	ui_tooltip = "This setting is designed to try and help\n"
				 "compensate for contrast washout caused\n"
				 "by displaying a component YCbCr signal\n"
				 "on an ARGB display. 0.5 is neutral,\n"
				 "0.0 is grayscale, 1.0 is cartoony. Unlike\n"
				 "vibrance this setting will alter the\n"
				 "contrast ratio between color channels and\n"
				 "therefore can cause loss of detail.";
	ui_category = "Color Palette";
	ui_category_closed = true;
 > = 0.50;
 
uniform float HqaaVibranceStrength <
	ui_type = "slider";
	ui_min = 0; ui_max = 100; ui_step = 0.1;
	ui_label = "% Vibrance";
	ui_tooltip = "Arbitrarily raises or lowers vibrance of the scene.\n"
				"Vibrance differs from Saturation in that it\n"
				"preserves the correct contrast ratio between\n"
				"color channels after being applied, so it cannot\n"
				"produce a grayscale image nor a blown-out one.";
	ui_category = "Color Palette";
	ui_category_closed = true;
> = 50;

uniform bool HqaaVibranceNoCorrection <
	ui_label = "Allow Vibrance to alter Luma";
	ui_tooltip = "If enabled, Vibrance will not correct\n"
				 "its output to match the original luma\n"
				 "of the pixel. This can make colors pop\n"
				 "somewhat more in exchange for lowered\n"
				 "accuracy in brightness of the scene.";
	ui_category = "Color Palette";
	ui_category_closed = true;
> = false;

 uniform float HqaaColorTemperature <
	ui_spacing = 3;
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
	ui_label = "Temperature";
	ui_tooltip = "Adjusts the color temperature.\n"
				 "Lower = reddish\n"
				 "Higher = blueish\n"
				 "0.5 is neutral.";
	ui_category = "Color Palette";
	ui_category_closed = true;
 > = 0.5;
 
 uniform float HqaaBlueLightFilter <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
	ui_label = "Blue Light Filter";
	ui_tooltip = "Reduces the strength of blue light\n"
				 "rendered in the scene for eye comfort\n"
				 "or to help fall asleep at night";
	ui_category = "Color Palette";
	ui_category_closed = true;
 > = 0.0;
 
uniform uint HqaaTonemapping <
	ui_spacing = 3;
	ui_type = "combo";
	ui_label = "Tonemapping";
	ui_items = "None\0Reinhard Extended\0Reinhard Luminance\0Reinhard-Jodie\0Uncharted 2\0ACES approx\0Logarithmic Fake HDR\0Logarithmic Range Compression\0Logarithmic Black Stabilizer\0";
	ui_category = "Color Palette";
	ui_category_closed = true;
> = 0;

uniform float HqaaTonemappingParameter <
	ui_type = "slider";
	ui_label = "Tonemapping Parameter\n\n";
	ui_tooltip = "Adjusts the controllable parameter for the\n"
				 "active tonemapper, if it has one.";
	ui_min = 0.0; ui_max = 2.71; ui_step = 0.01;
	ui_category = "Color Palette";
	ui_category_closed = true;
> = 1.0;

#if HQAA_OPTIONAL__TEMPORAL_AA
uniform float HqaaTaaJitterOffset <
	ui_spacing = 3;
	ui_type = "slider";
	ui_label = "Jitter Offset";
	ui_min = 0.0; ui_max = 0.5; ui_step = 0.001;
	ui_tooltip = "Distance (in pixels) that temporal samples\n"
				 "will be jittered. Higher counteracts more\n"
				 "aliasing and shimmering but increases blur.\n\n"
				 "Recommended range: [0.25..0.45]";
	ui_category = "Temporal Anti-Aliasing";
	ui_category_closed = true;
> = 0.433333;

#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
uniform float HqaaTaaTemporalWeight <
	ui_type = "slider";
	ui_label = "Previous Frame Weight";
	ui_min = 0.0; ui_max = 0.5; ui_step = 0.001;
	ui_tooltip = "Amount of weight given to previous frame.\n"
				 "Causes a bit of ghosting, but helps to\n"
				 "cover shimmering and temporal aliasing.\n\n"
				 "Recommended range: [0.2..0.4]";
	ui_category = "Temporal Anti-Aliasing";
	ui_category_closed = true;
> = 0.25;
#endif

uniform float HqaaTaaMinimumBlend <
	ui_type = "slider";
	ui_label = "Minimum Blend Strength";
	ui_tooltip = "Blends at least this much of the calculated\n"
				 "jitter result when processing edges. The\n"
				 "remaining portion is flexible and determined\n"
				 "by the detection strength of the edge.\n\n"
				 "Recommended range: [0.0..0.2]";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
	ui_category = "Temporal Anti-Aliasing";
	ui_category_closed = true;
> = 0.0;

uniform bool HqaaTaaSelfSharpen <
	ui_spacing = 3;
	ui_label = "Enable Result Self-Sharpening";
	ui_tooltip = "Performs adaptive result sharpening based on the\n"
				 "amount of blending calculated per pixel. May cause\n"
				 "unexpected results when used with other sharpening\n"
				 "(including HQAA built-in CAS).\n\n"
				 "Recommended setting: disabled";
	ui_category = "Temporal Anti-Aliasing";
	ui_category_closed = true;
> = false;

uniform bool HqaaTaaEdgeHinting <
	ui_label = "Use SMAA Edge Hinting";
	ui_tooltip = "Adaptively increases blending strength where\n"
			   "SMAA recorded diagonal edges\n\n"
				 "Recommended setting: disabled for most games.\n"
				 "Enabling may help control noise along irregular\n"
				 "gradients in modern games.";
	ui_category = "Temporal Anti-Aliasing";
	ui_category_closed = true;
> = false;

uniform bool HqaaTaaThresholdHinting <
	ui_label = "Use Dynamic Threshold Hinting\n\n";
	ui_tooltip = "Adaptively increases blending strength where\n"
			   "dynamic thresholding was used\n\n"
				 "Recommended setting: enabled";
	ui_category = "Temporal Anti-Aliasing";
	ui_category_closed = true;
> = true;
#endif //HQAA_OPTIONAL__TEMPORAL_AA

#if HQAA_OPTIONAL__DEBANDING
uniform uint HqaaDebandPreset <
	ui_type = "combo";
	ui_items = "Automatic\0Low\0Medium\0High\0Very High\0Extreme\0";
	ui_spacing = 3;
    ui_label = "Strength";
    ui_tooltip = "Performs a fast debanding pass similar\n"
			  "to Deband.fx to mitigate color banding.\n"
			  "Stronger presets catch more banding but\n"
			  "increase the risk of detail loss.\n"
			  "The automatic setting uses the edge\n"
			  "threshold to calculate the profile.\n\n"
				 "Recommended setting: Automatic";
	ui_category = "Debanding";
	ui_category_closed = true;
> = 0;

uniform float HqaaDebandRange <
	ui_type = "slider";
    ui_min = 4.0;
    ui_max = 32.0;
    ui_step = 1.0;
    ui_label = "Scan Radius";
    ui_tooltip = "Maximum distance from each dot to check\n"
    			 "for possible color banding artifacts\n\n"
				 "Recommended range: >= 12";
	ui_category = "Debanding";
	ui_category_closed = true;
> = 16.0;

uniform bool HqaaDebandIgnoreLowLuma <
	ui_label = "Skip Dark Pixels";
	ui_tooltip = "Skips performing debanding in areas with\n"
				 "low luma. This can help to preserve detail\n"
				 "in games that have dark scenes or areas.\n\n"
				 "Recommended setting: disabled if Automatic\n"
				 "mode is selected, enabled otherwise";
	ui_spacing = 3;
	ui_category = "Debanding";
	ui_category_closed = true;
> = false;

uniform bool HqaaDebandUseSmaaData <
	ui_label = "SMAA Hinting\n\n";
	ui_tooltip = "Skips performing debanding where SMAA\n"
				 "recorded blending weights. Helps to\n"
				 "preserve detail when using stronger\n"
				 "debanding settings.\n\n"
				 "Recommended setting: enabled";
	ui_category = "Debanding";
	ui_category_closed = true;
> = true;

uniform uint HqaaDebandSeed < source = "random"; min = 0; max = 32767; >;
#endif //HQAA_OPTIONAL__DEBANDING

#if HQAA_OPTIONAL__SOFTENING
uniform float HqaaImageSoftenStrength <
	ui_type = "slider";
	ui_spacing = 3;
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
	ui_label = "Softening Strength";
	ui_tooltip = "HQAA image softening measures error-controlled\n"
				"average differences for the neighborhood around\n"
				"every pixel to apply a subtle blur effect to the\n"
				"scene. Warning: may eat stars.\n\n"
				 "Recommended range: [0.0..0.1]";
	ui_category = "Image Softening";
	ui_category_closed = true;
> = 0.4;

uniform float HqaaImageSoftenOffset <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
	ui_label = "Sampling Offset";
	ui_tooltip = "Adjust this value up or down to expand or\n"
				 "contract the sampling patterns around the\n"
				 "central pixel. Effectively, this gives the\n"
				 "middle dot either less or more weight in\n"
				 "each sample pattern, causing the overall\n"
				 "result to look either more or less blurred.\n\n"
				 "Recommended range: [0.667..0.9]";
	ui_category = "Image Softening";
	ui_category_closed = true;
> = 0.9;

uniform bool HqaaSoftenerSpuriousDetection <
	ui_label = "Spurious Pixel Correction";
	ui_tooltip = "Uses different blending strength when an\n"
				 "overly bright or dark pixel (compared to\n"
				 "its surroundings) is detected.\n\n"
				 "Recommended setting: enabled";
	ui_spacing = 3;
	ui_category = "Image Softening";
	ui_category_closed = true;
> = true;

uniform float HqaaSoftenerSpuriousThreshold <
	ui_label = "Detection Threshold";
	ui_tooltip = "Difference in contrast between the middle\n"
				 "pixel and the neighborhood around it to be\n"
				 "considered a spurious pixel\n\n"
				 "Recommended range: [0.125..0.2]";
	ui_min = 0.0; ui_max = 0.5; ui_step = 0.001;
	ui_type = "slider";
	ui_category = "Image Softening";
	ui_category_closed = true;
> = 0.15;

uniform float HqaaSoftenerSpuriousStrength <
	ui_label = "Spurious Softening Strength\n\n";
	ui_tooltip = "Overrides the base softening strength to this\n"
				 "when a pixel is flagged as spurious.\n\n"
				 "Recommended range: [0.75..1.0]";
	ui_type = "slider";
	ui_min = 0; ui_max = 2.0; ui_step = 0.001;
	ui_category = "Image Softening";
	ui_category_closed = true;
> = 1.0;
#endif //HQAA_OPTIONAL__SOFTENING

uniform int HqaaOptionalsEOF <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n--------------------------------------------------------------------------------";
>;

uniform int HqaaDebugExplainer <
	ui_type = "radio";
	ui_spacing = 3;
	ui_label = " ";
	ui_text = "----------------------------------------------------------------\n"
			  "When you enable a debug mode, all effects other than SMAA and\n"
			  "FXAA are temporarily disabled to allow for easier reading of the\n"
			  "debug outputs.\n\n"
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
			  "FXAA selects luma based on the strongest color channel in the\n"
			  "center pixel. The color of the lumas displayed indicates which\n"
			  "color was used as the primary luma weight.\n\n"
			  "FXAA metrics draws a range of green to red where the selected\n"
			  "pass ran, with green representing not much execution time used\n"
			  "and red representing a lot of execution time used.\n\n"
			  "FXAA spans shows a color-coded view of the FXAA gradient scan\n"
			  "direction and whether or not it generated a good span result.\n"
			  "White indicates a good span, red indicates a failed vertical\n"
			  "span, green indicates a failed horizontal span, and blue is\n"
			  "a failed diagonal span. It is normal for around 1/4 to 1/2 of\n"
			  "the FXAA span checks to fail in HQAA - it is merely showing\n"
			  "where the FXAA blend had to use its fallback method to reach\n"
			  "the final result.\n\n"
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

#elif HQAA__GLOBAL_PRESET == 11 /////////////////////////////////////////////// CUSTOM CODE PRESET //////////////////////////////////////////////////////////
static const float HqaaEdgeThresholdCustom = 0.075;
static const float HqaaLowLumaThreshold = 0.2;
static const float HqaaDynamicThresholdCustom = 66.666667;
static const uint HqaaFxQualityCustom = 20;
static const float HqaaNoiseFloor = 0.0722;
static const float HqaaResolutionScalar = 1440.;
static const uint HqaaSourceInterpolation = 0;
static const uint HqaaSourceInterpolationOffset = 0;
static const bool HqaaSmCornerDetection = true;
static const float HqaaSmCorneringCustom = 33.333333;
static const float HqaaFxTexelCustom = 0.333333;
static const bool HqaaFxTexelGrowth = true;
static const uint HqaaFxTexelGrowAfter = 12;
static const float HqaaFxTexelGrowPercent = 3;
static const float HqaaFxBlendCustom = 100;
static const bool HqaaFxDiagScans = false;
static const bool HqaaFxEarlyExit = true;
static const bool HqaaDoLumaHysteresis = true;
static const float HqaaHysteresisStrength = 0.2;
static const float HqaaHysteresisFudgeFactor = 0.0375;

#if HQAA__INTRODUCTION_ACKNOWLEDGED
uniform bool HqaaEnableSharpening <
	ui_label = "Enable Preset Sharpening";
	ui_tooltip = "Enables or disables sharpening using the\n"
				 "settings baked into the global preset.";
> = true;

uniform int HqaaOptionalsEOF <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n--------------------------------------------------------------------------------";
>;
#else
static const bool HqaaEnableSharpening = true;
#endif //HQAA__INTRODUCTION_ACKNOWLEDGED

#else // HQAA__GLOBAL_PRESET != 0 || 11 ///////////////////////////////////// END CUSTOM CODE PRESET ////////////////////////////////////////////////////////
static const float HqaaLowLumaThreshold = 0.2;
static const float HqaaNoiseFloor = 0.0722;
static const bool HqaaSmCornerDetection = true;
static const bool HqaaDoLumaHysteresis = true;
static const bool HqaaFxTexelGrowth = true;
static const uint HqaaFxTexelGrowAfter = 16;
static const float HqaaFxTexelGrowPercent = 1.5;
static const bool HqaaFxDiagScans = false;
static const bool HqaaFxEarlyExit = true;
static const uint HqaaSourceInterpolation = 0;
static const uint HqaaSourceInterpolationOffset = 0;

uniform bool HqaaEnableSharpening <
	ui_label = "Enable Preset Sharpening";
	ui_tooltip = "Enables or disables sharpening using the\n"
				 "settings baked into the global preset.";
> = true;

#if HQAA__GLOBAL_PRESET != 7
uniform bool HqaaEnableBrightnessGain <
	ui_label = "Enable Preset Brightness Boost";
	ui_tooltip = "Enables or disables brightness gain based\n"
				 "on the global preset. Not all presets use\n"
				 "this setting, but enabling it will not\n"
				 "cause the brightness code to compile when\n"
				 "the preset does not apply a gain.";
> = true;
#endif

#if HQAA__GLOBAL_PRESET != 6
uniform bool HqaaEnableColorPalette <
	ui_label = "Enable Preset Color Processing";
	ui_tooltip = "Enables or disables color processing based\n"
				 "on the global preset. Not all presets perform\n"
				 "any color manipulation, but enabling this\n"
				 "option will not cause any extra code to compile.";
> = true;
#endif

uniform int HqaaOptionalsEOF <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n--------------------------------------------------------------------------------";
>;
#endif // HQAA__GLOBAL_PRESET

///////////////////////////////////////////////// HUMAN+MACHINE PRESET REFERENCE //////////////////////////////////////////////////////////

#if HQAA_ADVANCED_MODE && HQAA__GLOBAL_PRESET != 11
uniform int HqaaPresetBreakdown <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "\n"
			  "---------------------------------------------------------------------------------\n"
			  "|        |           Edges          |  SMAA  |     FXAA      |     Hysteresis   |\n"
	          "|-Profile|-Threshold---Range---Dist-|-Corner-|-Texel---Blend-|-Strength---Fudge-|\n"
	          "|--------|-----------|-------|------|--------|-------|-------|----------|-------|\n"
			  "| Conserv|    .10    | 76.0% |  30  |   20%  |  2/3  |  100% |   33.3%  |  5.0% |\n"
			  "|Balanced|    .05    | 60.0% |  40  |   33%  |  1/2  |  100% |   20.0%  |  2.5% |\n"
			  "| Aggress|    .03    | 46.7% |  60  |   50%  |  1/3  |  100% |   12.5%  |  1.5% |\n"
			  "---------------------------------------------------------------------------------";
	ui_category = "Click me to see what settings each profile uses!";
	ui_category_closed = true;
>;
#endif

#if HQAA_ADVANCED_MODE
	#define  __HQAA_BUFFER_MULT saturate(rcp(HqaaResolutionScalar / BUFFER_HEIGHT))
#else
	#define __HQAA_BUFFER_MULT saturate(BUFFER_HEIGHT / 1440.)
#endif

#define __HQAA_SMALLEST_COLOR_STEP rcp(pow(2., BUFFER_COLOR_BIT_DEPTH))
#define __HQAA_CONST_E 2.718282
#define __HQAA_CONST_HALFROOT2 0.707107
#define __HQAA_LUMA_REF float3(0.2126, 0.7152, 0.0722)
#define __HQAA_AVERAGE_REF float3(0.333333, 0.333334, 0.333333)
#define __HQAA_YUV_LUMA float3(0.299, 0.587, 0.114)
#define __HQAA_GREEN_LUMA float3(0.2, 0.7, 0.1)
#define __HQAA_RED_LUMA float3(0.625, 0.25, 0.125)
#define __HQAA_BLUE_LUMA float3(0.125, 0.375, 0.5)

#define __HQAA_SM_RADIUS float(__HQAA_FX_QUALITY)
#define __HQAA_SM_AREATEX_RANGE_DIAG clamp(__HQAA_SM_RADIUS, 0.0, 20.0)
#define __HQAA_SM_BUFFERINFO float4(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT, BUFFER_WIDTH, BUFFER_HEIGHT)
#define __HQAA_SM_AREATEX_RANGE 16.
#define __HQAA_SM_AREATEX_TEXEL rcp(float2(160., 560.))
#define __HQAA_SM_AREATEX_SUBTEXEL 0.142857
#define __HQAA_SM_SEARCHTEX_SIZE float2(66.0, 33.0)
#define __HQAA_SM_SEARCHTEX_SIZE_PACKED float2(64.0, 16.0)

#define HQAA_Tex2D(tex, coord) tex2Dlod(tex, (coord).xyxy)
#define HQAA_DecodeTex2D(tex, coord) ConditionalDecode(tex2Dlod(tex, (coord).xyxy))

#define HQAAmax3(x,y,z) max(max(x,y),z)
#define HQAAmax4(w,x,y,z) max(max(w,x),max(y,z))
#define HQAAmax5(v,w,x,y,z) max(max(max(v,w),x),max(y,z))
#define HQAAmax6(u,v,w,x,y,z) max(max(max(u,v),max(w,x)),max(y,z))
#define HQAAmax7(t,u,v,w,x,y,z) max(max(max(t,u),max(v,w)),max(max(x,y),z))
#define HQAAmax8(s,t,u,v,w,x,y,z) max(max(max(s,t),max(u,v)),max(max(w,x),max(y,z)))
#define HQAAmax9(r,s,t,u,v,w,x,y,z) max(max(max(max(r,s),t),max(u,v)),max(max(w,x),max(y,z)))
#define HQAAmax10(q,r,s,t,u,v,w,x,y,z) max(max(max(max(q,r),max(s,t)),max(u,v)),max(max(w,x),max(y,z)))
#define HQAAmax11(p,q,r,s,t,u,v,w,x,y,z) max(max(max(max(p,q),max(r,s)),max(max(t,u),v)),max(max(w,x),max(y,z)))
#define HQAAmax12(o,p,q,r,s,t,u,v,w,x,y,z) max(max(max(max(o,p),max(q,r)),max(max(s,t),max(u,v))),max(max(w,x),max(y,z)))
#define HQAAmax13(n,o,p,q,r,s,t,u,v,w,x,y,z) max(max(max(max(n,o),max(p,q)),max(max(r,s),max(t,u))),max(max(max(v,w),x),max(y,z)))
#define HQAAmax14(m,n,o,p,q,r,s,t,u,v,w,x,y,z) max(max(max(max(m,n),max(o,p)),max(max(q,r),max(s,t))),max(max(max(u,v),max(w,x)),max(y,z)))

#define HQAAmin3(x,y,z) min(min(x,y),z)
#define HQAAmin4(w,x,y,z) min(min(w,x),min(y,z))
#define HQAAmin5(v,w,x,y,z) min(min(min(v,w),x),min(y,z))
#define HQAAmin6(u,v,w,x,y,z) min(min(min(u,v),min(w,x)),min(y,z))
#define HQAAmin7(t,u,v,w,x,y,z) min(min(min(t,u),min(v,w)),min(min(x,y),z))
#define HQAAmin8(s,t,u,v,w,x,y,z) min(min(min(s,t),min(u,v)),min(min(w,x),min(y,z)))
#define HQAAmin9(r,s,t,u,v,w,x,y,z) min(min(min(min(r,s),t),min(u,v)),min(min(w,x),min(y,z)))
#define HQAAmin10(q,r,s,t,u,v,w,x,y,z) min(min(min(min(q,r),min(s,t)),min(u,v)),min(min(w,x),min(y,z)))
#define HQAAmin11(p,q,r,s,t,u,v,w,x,y,z) min(min(min(min(p,q),min(r,s)),min(min(t,u),v)),min(min(w,x),min(y,z)))
#define HQAAmin12(o,p,q,r,s,t,u,v,w,x,y,z) min(min(min(min(o,p),min(q,r)),min(min(s,t),min(u,v))),min(min(w,x),min(y,z)))
#define HQAAmin13(n,o,p,q,r,s,t,u,v,w,x,y,z) min(min(min(min(n,o),min(p,q)),min(min(r,s),min(t,u))),min(min(min(v,w),x),min(y,z)))
#define HQAAmin14(m,n,o,p,q,r,s,t,u,v,w,x,y,z) min(min(min(min(m,n),min(o,p)),min(min(q,r),min(s,t))),min(min(min(u,v),min(w,x)),min(y,z)))

#if HQAA_ADVANCED_MODE
#define __HQAA_EDGE_THRESHOLD clamp(HqaaEdgeThresholdCustom, 0.02, 1.00)
#define __HQAA_DYNAMIC_RANGE saturate(HqaaDynamicThresholdCustom / 100.0)
#define __HQAA_SM_CORNERS saturate((HqaaSmCorneringCustom / 100.0) * __HQAA_BUFFER_MULT)
#define __HQAA_FX_QUALITY clamp(HqaaFxQualityCustom * __HQAA_BUFFER_MULT, 1, 200)
#define __HQAA_FX_TEXEL clamp(HqaaFxTexelCustom * __HQAA_BUFFER_MULT, 0.0, 4.0)
#define __HQAA_FX_BLEND saturate(HqaaFxBlendCustom / 100.0)
#define __HQAA_HYSTERESIS_STRENGTH saturate(HqaaHysteresisStrength / 100.0)
#define __HQAA_HYSTERESIS_FUDGE saturate(HqaaHysteresisFudgeFactor / 100.0)

#else
static const float HQAA_THRESHOLD_PRESET[3] = {0.1, 0.05, 0.03};
static const float HQAA_DYNAMIC_RANGE_PRESET[3] = {0.76, 0.6, 0.466667};
static const uint HQAA_FXAA_SCAN_ITERATIONS_PRESET[3] = {30, 40, 60};
static const float HQAA_SMAA_CORNER_ROUNDING_PRESET[3] = {0.2, 0.333333, 0.5};
static const float HQAA_FXAA_TEXEL_SIZE_PRESET[3] = {0.666667, 0.5, 0.333333};
static const float HQAA_SUBPIX_PRESET[3] = {1.0, 1.0, 1.0};
static const float HQAA_HYSTERESIS_STRENGTH_PRESET[3] = {0.333333, 0.2, 0.125};
static const float HQAA_HYSTERESIS_FUDGE_PRESET[3] = {0.05, 0.025, 0.015};

#define __HQAA_EDGE_THRESHOLD clamp(HQAA_THRESHOLD_PRESET[clamp(HqaaPreset, 0, 2)], 0.02, 1.0)
#define __HQAA_DYNAMIC_RANGE saturate(HQAA_DYNAMIC_RANGE_PRESET[clamp(HqaaPreset, 0, 2)])
#define __HQAA_SM_CORNERS saturate(HQAA_SMAA_CORNER_ROUNDING_PRESET[clamp(HqaaPreset, 0, 2)] * __HQAA_BUFFER_MULT)
#define __HQAA_FX_QUALITY clamp(HQAA_FXAA_SCAN_ITERATIONS_PRESET[clamp(HqaaPreset, 0, 2)] * __HQAA_BUFFER_MULT, 1, 200)
#define __HQAA_FX_TEXEL clamp(HQAA_FXAA_TEXEL_SIZE_PRESET[clamp(HqaaPreset, 0, 2)] * __HQAA_BUFFER_MULT, 0.0, 4.0)
#define __HQAA_FX_BLEND saturate(HQAA_SUBPIX_PRESET[clamp(HqaaPreset, 0, 2)])
#define __HQAA_HYSTERESIS_STRENGTH saturate(HQAA_HYSTERESIS_STRENGTH_PRESET[clamp(HqaaPreset, 0, 2)])
#define __HQAA_HYSTERESIS_FUDGE saturate(HQAA_HYSTERESIS_FUDGE_PRESET[clamp(HqaaPreset, 0, 2)])
#endif //HQAA_ADVANCED_MODE

#if HQAA__GLOBAL_PRESET == 1 // ARPG/Isometric
static const float HqaaNoiseControlStrength = 33.333333;
static const float HqaaSharpenerStrength = 0.375;
static const float HqaaSharpenerAdaptation = 0.8;
static const float HqaaSharpenOffset = 0.8;
static const float HqaaSharpenerLumaCorrection = 0.333333;
static const float HqaaSharpenerClamping = 0.625;
static const float HqaaGainStrength = 0.375;
static const bool HqaaGainLowLumaCorrection = true;
static const float HqaaVibranceStrength = 50;
static const bool HqaaVibranceNoCorrection = false;
static const float HqaaSaturationStrength = 0.6;
static const float HqaaColorTemperature = 0.5;
static const float HqaaBlueLightFilter = 0.0;
static const uint HqaaTonemapping = 6;
static const float HqaaTonemappingParameter = 0.8;
static const float HqaaTaaJitterOffset = 0.333333;
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
static const float HqaaTaaTemporalWeight = 0.088;
#endif
static const float HqaaTaaMinimumBlend = 0.0;
static const bool HqaaTaaSelfSharpen = false;
static const bool HqaaTaaEdgeHinting = false;
static const bool HqaaTaaThresholdHinting = true;
static const uint HqaaDebandPreset = 0;
static const float HqaaDebandRange = 16.0;
static const bool HqaaDebandIgnoreLowLuma = false;
static const bool HqaaDebandUseSmaaData = true;
uniform uint HqaaDebandSeed < source = "random"; min = 0; max = 32767; >;
static const float HqaaImageSoftenStrength = 0.0;
static const float HqaaImageSoftenOffset = 0.9;
static const bool HqaaSoftenerSpuriousDetection = true;
static const float HqaaSoftenerSpuriousThreshold = 0.15;
static const float HqaaSoftenerSpuriousStrength = 1.0;
#endif // Preset = Top Down

#if HQAA__GLOBAL_PRESET == 2 // Open World
static const float HqaaNoiseControlStrength = 12.5;
static const float HqaaSharpenerStrength = 0.5;
static const float HqaaSharpenerAdaptation = 0.75;
static const float HqaaSharpenOffset = 0.75;
static const float HqaaSharpenerLumaCorrection = 0.2;
static const float HqaaSharpenerClamping = 0.25;
static const float HqaaGainStrength = 0.125;
static const bool HqaaGainLowLumaCorrection = true;
static const float HqaaVibranceStrength = 55;
static const bool HqaaVibranceNoCorrection = false;
static const float HqaaSaturationStrength = 0.55;
static const float HqaaColorTemperature = 0.5;
static const float HqaaBlueLightFilter = 0.0;
static const uint HqaaTonemapping = 0;
static const float HqaaTonemappingParameter = 1.8;
static const float HqaaTaaJitterOffset = 0.333333;
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
static const float HqaaTaaTemporalWeight = 0.25;
#endif
static const float HqaaTaaMinimumBlend = 0.0;
static const bool HqaaTaaSelfSharpen = false;
static const bool HqaaTaaEdgeHinting = true;
static const bool HqaaTaaThresholdHinting = true;
static const uint HqaaDebandPreset = 0;
static const float HqaaDebandRange = 16.0;
static const bool HqaaDebandIgnoreLowLuma = false;
static const bool HqaaDebandUseSmaaData = true;
uniform uint HqaaDebandSeed < source = "random"; min = 0; max = 32767; >;
static const float HqaaImageSoftenStrength = 0.4;
static const float HqaaImageSoftenOffset = 0.9;
static const bool HqaaSoftenerSpuriousDetection = true;
static const float HqaaSoftenerSpuriousThreshold = 0.15;
static const float HqaaSoftenerSpuriousStrength = 1.0;
#endif // Preset = Open World

#if HQAA__GLOBAL_PRESET == 3 // Survival
static const float HqaaNoiseControlStrength = 25;
static const float HqaaSharpenerStrength = 1.0;
static const float HqaaSharpenerAdaptation = 0.8;
static const float HqaaSharpenOffset = 0.8;
static const float HqaaSharpenerLumaCorrection = 0.333333;
static const float HqaaSharpenerClamping = -0.2;
static const float HqaaGainStrength = 0.25;
static const bool HqaaGainLowLumaCorrection = true;
static const float HqaaVibranceStrength = 55;
static const bool HqaaVibranceNoCorrection = false;
static const float HqaaSaturationStrength = 0.55;
static const float HqaaColorTemperature = 0.5;
static const float HqaaBlueLightFilter = 0.333333;
static const uint HqaaTonemapping = 8;
static const float HqaaTonemappingParameter = 2.718282;
static const float HqaaTaaJitterOffset = 0.333333;
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
static const float HqaaTaaTemporalWeight = 0.125;
#endif
static const float HqaaTaaMinimumBlend = 0.0;
static const bool HqaaTaaSelfSharpen = false;
static const bool HqaaTaaEdgeHinting = false;
static const bool HqaaTaaThresholdHinting = true;
//static const uint HqaaDebandPreset = 0;
//static const float HqaaDebandRange = 16.0;
//static const bool HqaaDebandIgnoreLowLuma = true;
//static const bool HqaaDebandUseSmaaData = true;
//uniform uint HqaaDebandSeed < source = "random"; min = 0; max = 32767; >;
static const float HqaaImageSoftenStrength = 0.0;
static const float HqaaImageSoftenOffset = 0.9;
static const bool HqaaSoftenerSpuriousDetection = true;
static const float HqaaSoftenerSpuriousThreshold = 0.15;
static const float HqaaSoftenerSpuriousStrength = 1.0;
#endif // Preset = Survival

#if HQAA__GLOBAL_PRESET == 4 // Action/Racing
static const float HqaaNoiseControlStrength = 20;
static const float HqaaSharpenerStrength = 0.6;
static const float HqaaSharpenerAdaptation = 0.75;
static const float HqaaSharpenOffset = 0.75;
static const float HqaaSharpenerLumaCorrection = 0.2;
static const float HqaaSharpenerClamping = 0.3;
static const float HqaaGainStrength = 0.125;
static const bool HqaaGainLowLumaCorrection = true;
static const float HqaaVibranceStrength = 55;
static const bool HqaaVibranceNoCorrection = false;
static const float HqaaSaturationStrength = 0.55;
static const float HqaaColorTemperature = 0.5;
static const float HqaaBlueLightFilter = 0.0;
static const uint HqaaTonemapping = 0;
static const float HqaaTonemappingParameter = 1.8;
static const float HqaaTaaJitterOffset = 0.333333;
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
static const float HqaaTaaTemporalWeight = 0.1;
#endif
static const float HqaaTaaMinimumBlend = 0.0;
static const bool HqaaTaaSelfSharpen = false;
static const bool HqaaTaaEdgeHinting = true;
static const bool HqaaTaaThresholdHinting = true;
//static const uint HqaaDebandPreset = 0;
//static const float HqaaDebandRange = 16.0;
//static const bool HqaaDebandIgnoreLowLuma = true;
//static const bool HqaaDebandUseSmaaData = true;
//uniform uint HqaaDebandSeed < source = "random"; min = 0; max = 32767; >;
static const float HqaaImageSoftenStrength = 0.2;
static const float HqaaImageSoftenOffset = 0.9;
static const bool HqaaSoftenerSpuriousDetection = true;
static const float HqaaSoftenerSpuriousThreshold = 0.15;
static const float HqaaSoftenerSpuriousStrength = 1.0;
#endif // Preset = Action

#if HQAA__GLOBAL_PRESET == 5 // Horror
static const float HqaaNoiseControlStrength = 10;
static const float HqaaSharpenerStrength = 0.25;
static const float HqaaSharpenerAdaptation = 0.875;
static const float HqaaSharpenOffset = 0.875;
static const float HqaaSharpenerLumaCorrection = 0.4;
static const float HqaaSharpenerClamping = 0.375;
static const float HqaaGainStrength = 0.125;
static const bool HqaaGainLowLumaCorrection = true;
static const float HqaaVibranceStrength = 50;
static const bool HqaaVibranceNoCorrection = false;
static const float HqaaSaturationStrength = 0.6;
static const float HqaaColorTemperature = 0.5;
static const float HqaaBlueLightFilter = 0.0;
static const uint HqaaTonemapping = 6;
static const float HqaaTonemappingParameter = 0.333333;
static const float HqaaTaaJitterOffset = 0.333333;
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
static const float HqaaTaaTemporalWeight = 0.25;
#endif
static const float HqaaTaaMinimumBlend = 0.0;
static const bool HqaaTaaSelfSharpen = true;
static const bool HqaaTaaEdgeHinting = true;
static const bool HqaaTaaThresholdHinting = true;
static const uint HqaaDebandPreset = 0;
static const float HqaaDebandRange = 16.0;
static const bool HqaaDebandIgnoreLowLuma = false;
static const bool HqaaDebandUseSmaaData = true;
uniform uint HqaaDebandSeed < source = "random"; min = 0; max = 32767; >;
static const float HqaaImageSoftenStrength = 0.5;
static const float HqaaImageSoftenOffset = 0.9;
static const bool HqaaSoftenerSpuriousDetection = true;
static const float HqaaSoftenerSpuriousThreshold = 0.15;
static const float HqaaSoftenerSpuriousStrength = 1.0;
#endif // Preset = Horror

#if HQAA__GLOBAL_PRESET == 6 // Fake HDR
static const float HqaaNoiseControlStrength = 12.5;
static const float HqaaSharpenerStrength = 0.5;
static const float HqaaSharpenerAdaptation = 0.75;
static const float HqaaSharpenOffset = 0.75;
static const float HqaaSharpenerLumaCorrection = 0.2;
static const float HqaaSharpenerClamping = 0.25;
static const float HqaaGainStrength = 0.125;
static const bool HqaaGainLowLumaCorrection = true;
static const bool HqaaEnableColorPalette = true;
static const float HqaaVibranceStrength = 55;
static const bool HqaaVibranceNoCorrection = false;
static const float HqaaSaturationStrength = 0.55;
static const float HqaaColorTemperature = 0.5;
static const float HqaaBlueLightFilter = 0.0;
static const uint HqaaTonemapping = 6;
static const float HqaaTonemappingParameter = 2.718282;
static const float HqaaTaaJitterOffset = 0.333333;
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
static const float HqaaTaaTemporalWeight = 0.2;
#endif
static const float HqaaTaaMinimumBlend = 0.0;
static const bool HqaaTaaSelfSharpen = false;
static const bool HqaaTaaEdgeHinting = true;
static const bool HqaaTaaThresholdHinting = true;
//static const uint HqaaDebandPreset = 0;
//static const float HqaaDebandRange = 16.0;
//static const bool HqaaDebandIgnoreLowLuma = true;
//static const bool HqaaDebandUseSmaaData = true;
//uniform uint HqaaDebandSeed < source = "random"; min = 0; max = 32767; >;
static const float HqaaImageSoftenStrength = 0.4;
static const float HqaaImageSoftenOffset = 0.9;
static const bool HqaaSoftenerSpuriousDetection = true;
static const float HqaaSoftenerSpuriousThreshold = 0.15;
static const float HqaaSoftenerSpuriousStrength = 1.0;
#endif // Preset = Fake HDR

#if HQAA__GLOBAL_PRESET == 7 // Dim LCD Compensation
static const float HqaaNoiseControlStrength = 12.5;
static const float HqaaSharpenerStrength = 0.625;
static const float HqaaSharpenerAdaptation = 0.75;
static const float HqaaSharpenOffset = 0.75;
static const float HqaaSharpenerLumaCorrection = 0.2;
static const float HqaaSharpenerClamping = 0.25;
static const bool HqaaEnableBrightnessGain = true;
static const float HqaaGainStrength = 0.625;
static const bool HqaaGainLowLumaCorrection = true;
static const float HqaaVibranceStrength = 55;
static const bool HqaaVibranceNoCorrection = true;
static const float HqaaSaturationStrength = 0.5625;
static const float HqaaColorTemperature = 0.5;
static const float HqaaBlueLightFilter = 0.0;
static const uint HqaaTonemapping = 8;
static const float HqaaTonemappingParameter = 2.25;
static const float HqaaTaaJitterOffset = 0.333333;
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
static const float HqaaTaaTemporalWeight = 0.2;
#endif
static const float HqaaTaaMinimumBlend = 0.0;
static const bool HqaaTaaSelfSharpen = false;
static const bool HqaaTaaEdgeHinting = false;
static const bool HqaaTaaThresholdHinting = true;
static const uint HqaaDebandPreset = 0;
static const float HqaaDebandRange = 16.0;
static const bool HqaaDebandIgnoreLowLuma = false;
static const bool HqaaDebandUseSmaaData = true;
uniform uint HqaaDebandSeed < source = "random"; min = 0; max = 32767; >;
static const float HqaaImageSoftenStrength = 0.2;
static const float HqaaImageSoftenOffset = 0.9;
static const bool HqaaSoftenerSpuriousDetection = true;
static const float HqaaSoftenerSpuriousThreshold = 0.15;
static const float HqaaSoftenerSpuriousStrength = 1.0;
#endif // Preset = Dim LCD Compensation

#if HQAA__GLOBAL_PRESET == 8 // Stream-friendly
static const float HqaaNoiseControlStrength = 20;
static const float HqaaSharpenerStrength = 0.5;
static const float HqaaSharpenerAdaptation = 0.75;
static const float HqaaSharpenOffset = 0.75;
static const float HqaaSharpenerLumaCorrection = 0.2;
static const float HqaaSharpenerClamping = 0.25;
static const float HqaaGainStrength = 0.125;
static const bool HqaaGainLowLumaCorrection = true;
static const float HqaaVibranceStrength = 66.666667;
static const bool HqaaVibranceNoCorrection = false;
static const float HqaaSaturationStrength = 0.5;
static const float HqaaColorTemperature = 0.5;
static const float HqaaBlueLightFilter = 0.0;
static const uint HqaaTonemapping = 8;
static const float HqaaTonemappingParameter = 1.8;
static const float HqaaTaaJitterOffset = 0.333333;
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
static const float HqaaTaaTemporalWeight = 0.125;
#endif
static const float HqaaTaaMinimumBlend = 0.0;
static const bool HqaaTaaSelfSharpen = false;
static const bool HqaaTaaEdgeHinting = false;
static const bool HqaaTaaThresholdHinting = true;
//static const uint HqaaDebandPreset = 0;
//static const float HqaaDebandRange = 32.0;
//static const bool HqaaDebandIgnoreLowLuma = true;
//static const bool HqaaDebandUseSmaaData = true;
//uniform uint HqaaDebandSeed < source = "random"; min = 0; max = 32767; >;
static const float HqaaImageSoftenStrength = 0.0;
static const float HqaaImageSoftenOffset = 0.9;
static const bool HqaaSoftenerSpuriousDetection = true;
static const float HqaaSoftenerSpuriousThreshold = 0.15;
static const float HqaaSoftenerSpuriousStrength = 1.0;
#endif // Preset = Stream-friendly

#if HQAA__GLOBAL_PRESET == 9 // e-sports
static const float HqaaNoiseControlStrength = 50;
static const float HqaaSharpenerStrength = 0.5;
static const float HqaaSharpenerAdaptation = 0.875;
static const float HqaaSharpenOffset = 0.875;
static const float HqaaSharpenerLumaCorrection = 0.4;
static const float HqaaSharpenerClamping = 0.5;
static const float HqaaGainStrength = 0.125;
static const bool HqaaGainLowLumaCorrection = true;
static const float HqaaVibranceStrength = 55;
static const bool HqaaVibranceNoCorrection = false;
static const float HqaaSaturationStrength = 0.55;
static const float HqaaColorTemperature = 0.5;
static const float HqaaBlueLightFilter = 0.25;
static const uint HqaaTonemapping = 8;
static const float HqaaTonemappingParameter = 2.0;
static const float HqaaTaaJitterOffset = 0.333333;
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
static const float HqaaTaaTemporalWeight = 0.088;
#endif
static const float HqaaTaaMinimumBlend = 0.0;
static const bool HqaaTaaSelfSharpen = false;
static const bool HqaaTaaEdgeHinting = false;
static const bool HqaaTaaThresholdHinting = false;
//static const uint HqaaDebandPreset = 0;
//static const float HqaaDebandRange = 32.0;
//static const bool HqaaDebandIgnoreLowLuma = true;
//static const bool HqaaDebandUseSmaaData = true;
//uniform uint HqaaDebandSeed < source = "random"; min = 0; max = 32767; >;
//static const float HqaaImageSoftenStrength = 0.125;
//static const float HqaaImageSoftenOffset = 0.75;
//static const bool HqaaSoftenerSpuriousDetection = true;
//static const float HqaaSoftenerSpuriousThreshold = 0.1;
//static const float HqaaSoftenerSpuriousStrength = 1.0;
#endif // Preset = e-sports

#if HQAA__GLOBAL_PRESET == 10 // DLSS Assist
static const float HqaaNoiseControlStrength = 12.5;
static const float HqaaSharpenerStrength = 0.375;
static const float HqaaSharpenerAdaptation = 0.75;
static const float HqaaSharpenOffset = 0.75;
static const float HqaaSharpenerLumaCorrection = 0.2;
static const float HqaaSharpenerClamping = 0.375;
static const float HqaaGainStrength = 0.125;
static const bool HqaaGainLowLumaCorrection = true;
static const float HqaaVibranceStrength = 55;
static const bool HqaaVibranceNoCorrection = false;
static const float HqaaSaturationStrength = 0.55;
static const float HqaaColorTemperature = 0.5;
static const float HqaaBlueLightFilter = 0.0;
static const uint HqaaTonemapping = 0;
static const float HqaaTonemappingParameter = 1.8;
static const float HqaaTaaJitterOffset = 0.333333;
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
static const float HqaaTaaTemporalWeight = 0.2;
#endif
static const float HqaaTaaMinimumBlend = 0.0;
static const bool HqaaTaaSelfSharpen = false;
static const bool HqaaTaaEdgeHinting = true;
static const bool HqaaTaaThresholdHinting = true;
static const uint HqaaDebandPreset = 0;
static const float HqaaDebandRange = 16.0;
static const bool HqaaDebandIgnoreLowLuma = false;
static const bool HqaaDebandUseSmaaData = true;
uniform uint HqaaDebandSeed < source = "random"; min = 0; max = 32767; >;
//static const float HqaaImageSoftenStrength = 0.0;
//static const float HqaaImageSoftenOffset = 0.75;
//static const bool HqaaSoftenerSpuriousDetection = true;
//static const float HqaaSoftenerSpuriousThreshold = 0.125;
//static const float HqaaSoftenerSpuriousStrength = 0.5;
#endif // Preset = DLSS assist

#if HQAA__GLOBAL_PRESET == 11 // Max Bang for Buck
static const float HqaaNoiseControlStrength = 12.5;
static const float HqaaSharpenerStrength = 0.5;
static const float HqaaSharpenerAdaptation = 0.8;
static const float HqaaSharpenOffset = 0.8;
static const float HqaaSharpenerLumaCorrection = 0.3;
static const float HqaaSharpenerClamping = 0.25;
static const bool HqaaEnableBrightnessGain = false;
static const float HqaaGainStrength = 0.0;
static const bool HqaaGainLowLumaCorrection = true;
static const bool HqaaEnableColorPalette = false;
static const float HqaaVibranceStrength = 50;
static const bool HqaaVibranceNoCorrection = false;
static const float HqaaSaturationStrength = 0.5;
static const float HqaaColorTemperature = 0.5;
static const float HqaaBlueLightFilter = 0.0;
static const uint HqaaTonemapping = 0;
static const float HqaaTonemappingParameter = 1.0;
static const float HqaaTaaJitterOffset = 0.433333;
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
static const float HqaaTaaTemporalWeight = 0.1;
#endif
static const float HqaaTaaMinimumBlend = 0.0;
static const bool HqaaTaaSelfSharpen = false;
static const bool HqaaTaaEdgeHinting = true;
static const bool HqaaTaaThresholdHinting = true;
//static const uint HqaaDebandPreset = 0;
//static const float HqaaDebandRange = 32.0;
//static const bool HqaaDebandIgnoreLowLuma = true;
//static const bool HqaaDebandUseSmaaData = true;
//uniform uint HqaaDebandSeed < source = "random"; min = 0; max = 32767; >;
static const float HqaaImageSoftenStrength = 0.4;
static const float HqaaImageSoftenOffset = 0.9;
static const bool HqaaSoftenerSpuriousDetection = true;
static const float HqaaSoftenerSpuriousThreshold = 0.15;
static const float HqaaSoftenerSpuriousStrength = 1.0;
#endif // Preset = Max Bang for Buck

#if HQAA__GLOBAL_PRESET == 12 // Beefcake GPU
static const float HqaaNoiseControlStrength = 33.333333;
static const float HqaaSharpenerStrength = 0.333333;
static const float HqaaSharpenerAdaptation = 0.9;
static const float HqaaSharpenOffset = 0.9;
static const float HqaaSharpenerLumaCorrection = 0.5;
static const float HqaaSharpenerClamping = 0.666667;
static const float HqaaGainStrength = 0.125;
static const bool HqaaGainLowLumaCorrection = true;
static const float HqaaVibranceStrength = 55;
static const bool HqaaVibranceNoCorrection = false;
static const float HqaaSaturationStrength = 0.55;
static const float HqaaColorTemperature = 0.5;
static const float HqaaBlueLightFilter = 0.0;
static const uint HqaaTonemapping = 0;
static const float HqaaTonemappingParameter = 1.8;
static const float HqaaTaaJitterOffset = 0.25;
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
static const float HqaaTaaTemporalWeight = 0.125;
#endif
static const float HqaaTaaMinimumBlend = 0.0;
static const bool HqaaTaaSelfSharpen = false;
static const bool HqaaTaaEdgeHinting = true;
static const bool HqaaTaaThresholdHinting = true;
static const uint HqaaDebandPreset = 0;
static const float HqaaDebandRange = 16.0;
static const bool HqaaDebandIgnoreLowLuma = false;
static const bool HqaaDebandUseSmaaData = true;
uniform uint HqaaDebandSeed < source = "random"; min = 0; max = 32767; >;
static const float HqaaImageSoftenStrength = 0.125;
static const float HqaaImageSoftenOffset = 0.9;
static const bool HqaaSoftenerSpuriousDetection = true;
static const float HqaaSoftenerSpuriousThreshold = 0.125;
static const float HqaaSoftenerSpuriousStrength = 0.75;
#endif // Preset = Beefcake GPU

/*****************************************************************************************************************************************/
/*********************************************************** UI SETUP END ****************************************************************/
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

/*
Ey = 0.299R+0.587G+0.114B
Ecr = 0.713(R - Ey) = 0.500R-0.419G-0.081B
Ecb = 0.564(B - Ey) = -0.169R-0.331G+0.500B

where Ey, R, G and B are in the range [0,1] and Ecr and Ecb are in the range [-0.5,0.5]
*/
float3 RGBtoYUV(float3 input)
{
	float3 yuv;
	yuv.x = dot(input, __HQAA_YUV_LUMA);
	yuv.y = 0.713 * (input.r - yuv.x);
	yuv.z = 0.564 * (input.b - yuv.x);
	yuv.yz = clamp(yuv.yz, -0.5, 0.5);
	yuv.x = saturate(yuv.x);
	
	return yuv;
}
float4 RGBtoYUV(float4 input)
{
	return float4(RGBtoYUV(input.rgb), input.a);
}

/*
/* reverse transfer accomplished by solving original equations for R and B and then
/* using those channels to solve the luma equation for G
*/
float3 YUVtoRGB(float3 yuv)
{
	float3 argb;
	argb.r = (1.402525 * yuv.y) + yuv.x;
	argb.b = (1.77305 * yuv.z) + yuv.x;
	argb.g = (1.703578 * yuv.x) - (0.50937 * argb.r) - (0.194208 * argb.b);
	
	return saturate(argb);
}
float4 YUVtoRGB(float4 yuv)
{
	return float4(YUVtoRGB(yuv.xyz), yuv.a);
}

// saturation calculator
float dotsat(float3 x)
{
	// trunc(xl) only = 1 when x = float3(1,1,1)
	// float3(1,1,1) produces 0/0 in the original calculation
	// this should change it to 0/1 to avoid the possible NaN out
	float xl = dot(x, __HQAA_AVERAGE_REF);
	return ((max3(x.r, x.g, x.b) - min3(x.r, x.g, x.b)) / (1.0 - (2.0 * xl - 1.0) + trunc(xl)));
}
float dotsat(float4 x)
{
	return dotsat(x.rgb);
}

// color delta calculator
float chromadelta(float3 pixel1, float3 pixel2)
{
	float3 delta = abs(pixel1 - pixel2);
	return max3(delta.r, delta.g, delta.b);
}

// pixel max channel delta
float maxcolordelta(float3 pixel)
{
	float3 deltas = abs(float3(pixel.r - pixel.g, pixel.g - pixel.b, pixel.b - pixel.r));
	return max(max(deltas.x, deltas.y), deltas.z);
}

// vibrance adjustment
float3 AdjustVibrance(float3 pixel, float satadjust)
{
	float3 outdot = pixel;
	float refY = dot(pixel, __HQAA_LUMA_REF);
	float refsat = dotsat(pixel);
	float realadjustment = saturate(refsat + satadjust) - refsat;
	float2 highlow = float2(max3(pixel.r, pixel.g, pixel.b), min3(pixel.r, pixel.g, pixel.b));
	float maxpositive = 1.0 - highlow.x;
	float maxnegative = -highlow.y;
	[branch] if (abs(realadjustment) > __HQAA_SMALLEST_COLOR_STEP)
	{
		// there won't necessarily be a valid mid if eg. pixel.r == pixel.g > pixel.b
		float mid = -1.0;
		
		// figure out if the low needs to move up or down
		float lowadjust = clamp(((highlow.y - highlow.x / 2.0) / highlow.x) * realadjustment, maxnegative, maxpositive);
		
		// same calculation used with the high factors to this
		float highadjust = clamp(0.5 * realadjustment, maxnegative, maxpositive);
		
		// method = apply corrections based on matched high or low channel, assign mid if neither
		if (pixel.r == highlow.x) outdot.r = pow(abs(1.0 + highadjust) * 2.0, log2(pixel.r));
		else if (pixel.r == highlow.y) outdot.r = pow(abs(1.0 + lowadjust) * 2.0, log2(pixel.r));
		else mid = pixel.r;
		if (pixel.g == highlow.x) outdot.g = pow(abs(1.0 + highadjust) * 2.0, log2(pixel.g));
		else if (pixel.g == highlow.y) outdot.g = pow(abs(1.0 + lowadjust) * 2.0, log2(pixel.g));
		else mid = pixel.g;
		if (pixel.b == highlow.x) outdot.b = pow(abs(1.0 + highadjust) * 2.0, log2(pixel.b));
		else if (pixel.b == highlow.y) outdot.b = pow(abs(1.0 + lowadjust) * 2.0, log2(pixel.b));
		else mid = pixel.b;
		
		// perform mid channel calculations if a valid mid was found
		if (mid > 0.0)
		{
			// figure out whether it should move up or down
			float midadjust = clamp(((mid - highlow.x / 2.0) / highlow.x) * realadjustment, maxnegative, maxpositive);
			
			// determine which channel is mid and apply correction
			if (pixel.r == mid) outdot.r = pow(abs(1.0 + midadjust) * 2.0, log2(pixel.r));
			else if (pixel.g == mid) outdot.g = pow(abs(1.0 + midadjust) * 2.0, log2(pixel.g));
			else if (pixel.b == mid) outdot.b = pow(abs(1.0 + midadjust) * 2.0, log2(pixel.b));
		}
	}
	
	if (!HqaaVibranceNoCorrection)
	{
		float outY = dot(outdot, __HQAA_LUMA_REF);
		float deltaY = (outY == 0.0) ? 0.0 : (refY / outY);
		outdot *= deltaY;
	}
	
	return saturate(outdot);
}
float4 AdjustVibrance(float4 pixel, float satadjust)
{
	return float4(AdjustVibrance(pixel.rgb, satadjust), pixel.a);
}

// saturation adjustment
float3 AdjustSaturation(float3 input, float requestedadjustment)
{
	// change to YCrCb (component) color space
	// access: x=Y, y=Cr, z=Cb
	float3 yuv = RGBtoYUV(input);
	
	// convert absolute saturation to adjustment delta
	float adjustment = 2.0 * (saturate(requestedadjustment) - 0.5);
	
	// for a positive adjustment, determine ceiling and clamp if necessary
	if (adjustment > 0.0)
	{
		float maxboost = 1.0 / (max(abs(yuv.y), abs(yuv.z)) / 0.5);
		if (adjustment > maxboost) adjustment = maxboost;
	}
	
	// compute delta Cr,Cb
	yuv.y = yuv.y > 0.0 ? (yuv.y + (adjustment * yuv.y)) : (yuv.y - (adjustment * abs(yuv.y)));
	yuv.z = yuv.z > 0.0 ? (yuv.z + (adjustment * yuv.z)) : (yuv.z - (adjustment * abs(yuv.z)));
	
	// change back to ARGB color space
	return YUVtoRGB(yuv);
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
	return BUFFER_COLOR_BIT_DEPTH == 10 ? saturate((sqrt(sqrt(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 500.0))) / 4.7287080450158790665084805994361)) : saturate((sqrt(sqrt(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 10000.0))) / 10.0));
}
float2 fastdecodePQ(float2 x)
{
	return BUFFER_COLOR_BIT_DEPTH == 10 ? saturate((sqrt(sqrt(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 500.0))) / 4.7287080450158790665084805994361)) : saturate((sqrt(sqrt(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 10000.0))) / 10.0));
}
float3 fastdecodePQ(float3 x)
{
	return BUFFER_COLOR_BIT_DEPTH == 10 ? saturate((sqrt(sqrt(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 500.0))) / 4.7287080450158790665084805994361)) : saturate((sqrt(sqrt(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 10000.0))) / 10.0));
}
float4 fastdecodePQ(float4 x)
{
	return BUFFER_COLOR_BIT_DEPTH == 10 ? saturate((sqrt(sqrt(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 500.0))) / 4.7287080450158790665084805994361)) : saturate((sqrt(sqrt(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 10000.0))) / 10.0));
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

#if !HQAA_DISABLE_SMAA
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

float2 HQAASearchDiag(sampler2D HQAAedgesTex, float2 texcoord, float2 dir, out float2 e)
{
    float4 coord = float4(texcoord, -1.0, 1.0);
    float3 t = float3(__HQAA_SM_BUFFERINFO.xy, 1.0);
    [loop] while (coord.z < 20.0) 
	{
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);
        e = tex2Dlod(HQAAedgesTex, coord.xyxy).rg;
        coord.w = dot(e, float(0.5).xx);
        if (coord.w < 0.9) break;
    }
    return coord.zw;
}

float2 HQAAAreaDiag(sampler2D HQAAareaTex, float2 dist, float2 e)
{
    float2 texcoord = mad(float(__HQAA_SM_AREATEX_RANGE_DIAG).xx, e, dist);

    texcoord = mad(__HQAA_SM_AREATEX_TEXEL, texcoord, 0.5 * __HQAA_SM_AREATEX_TEXEL);
    texcoord.x += 0.5;

    return tex2Dlod(HQAAareaTex, texcoord.xyxy).rg;
}

float2 HQAACalculateDiagWeights(sampler2D HQAAedgesTex, sampler2D HQAAareaTex, float2 texcoord, float2 e)
{
    float2 weights = float(0.0).xx;
    float2 end;
    float4 d;
    d.ywxz = float4(HQAASearchDiag(HQAAedgesTex, texcoord, float2(1.0, -1.0), end), 0.0, 0.0);
    
    if (e.r > 0.0) 
	{
        d.xz = HQAASearchDiag(HQAAedgesTex, texcoord, float2(-1.0,  1.0), end);
        d.x += float(end.y > 0.9);
    }
	
	if (d.x + d.y > 2.0) 
	{
        float4 coords = mad(float4(-d.x + 0.25, d.x, d.y, -d.y - 0.25), __HQAA_SM_BUFFERINFO.xyxy, texcoord.xyxy);
        float4 c;
        c.xy = tex2Dlodoffset(HQAAedgesTex, coords.xyxy, int2(-1,  0)).rg;
        c.zw = tex2Dlodoffset(HQAAedgesTex, coords.zwzw, int2( 1,  0)).rg;
        c.yxwz = HQAADecodeDiagBilinearAccess(c.xyzw);

        float2 cc = mad(float(2.0).xx, c.xz, c.yw);

        HQAAMovc(bool2(step(0.9, d.zw)), cc, float(0.0).xx);

        weights += HQAAAreaDiag(HQAAareaTex, d.xy, cc);
    }

    d.xz = HQAASearchDiag(HQAAedgesTex, texcoord, float2(-1.0, -1.0), end);
    d.yw = float(0.0).xx;
    
    if (HQAA_Tex2D(HQAAedgesTex, texcoord + float2(BUFFER_RCP_WIDTH, 0)).r > 0.0) 
	{
        d.yw = HQAASearchDiag(HQAAedgesTex, texcoord, float(1.0).xx, end);
        d.y += float(end.y > 0.9);
    }
	
	if (d.x + d.y > 2.0) 
	{
        float4 coords = mad(float4(-d.x, -d.x, d.y, d.y), __HQAA_SM_BUFFERINFO.xyxy, texcoord.xyxy);
        float4 c;
        c.x  = tex2Dlodoffset(HQAAedgesTex, coords.xyxy, int2(-1,  0)).g;
        c.y  = tex2Dlodoffset(HQAAedgesTex, coords.xyxy, int2( 0, -1)).r;
        c.zw = tex2Dlodoffset(HQAAedgesTex, coords.zwzw, int2( 1,  0)).gr;
        float2 cc = mad(float(2.0).xx, c.xz, c.yw);

        HQAAMovc(bool2(step(0.9, d.zw)), cc, float(0.0).xx);

        weights += HQAAAreaDiag(HQAAareaTex, d.xy, cc).gr;
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
    [loop] while (texcoord.x > end) 
	{
        e = tex2Dlod(HQAAedgesTex, texcoord.xyxy).rg;
        texcoord.x -= BUFFER_RCP_WIDTH + BUFFER_RCP_WIDTH;
        if (e.r > 0.0) break;
    }
    float offset = mad(-(255./127.), HQAASearchLength(HQAAsearchTex, e, 0.0), 3.25);
    return mad(__HQAA_SM_BUFFERINFO.x, offset, texcoord.x);
}
float HQAASearchXRight(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end)
{
    float2 e = float2(0.0, 1.0);
    [loop] while (texcoord.x < end) 
	{
        e = tex2Dlod(HQAAedgesTex, texcoord.xyxy).rg;
        texcoord.x += BUFFER_RCP_WIDTH + BUFFER_RCP_WIDTH;
        if (e.r > 0.0) break;
    }
    float offset = mad(-(255./127.), HQAASearchLength(HQAAsearchTex, e, 0.0), 3.25);
    return mad(-__HQAA_SM_BUFFERINFO.x, offset, texcoord.x);
}
float HQAASearchYUp(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end)
{
    float2 e = float2(1.0, 0.0);
    [loop] while (texcoord.y > end) 
	{
        e = tex2Dlod(HQAAedgesTex, texcoord.xyxy).rg;
        texcoord.y -= BUFFER_RCP_HEIGHT + BUFFER_RCP_HEIGHT;
        if (e.g > 0.0) break;
    }
    float offset = mad(-(255./127.), HQAASearchLength(HQAAsearchTex, e.gr, 0.0), 3.25);
    return mad(__HQAA_SM_BUFFERINFO.y, offset, texcoord.y);
}
float HQAASearchYDown(sampler2D HQAAedgesTex, sampler2D HQAAsearchTex, float2 texcoord, float end)
{
    float2 e = float2(1.0, 0.0);
    [loop] while (texcoord.y < end) 
	{
        e = tex2Dlod(HQAAedgesTex, texcoord.xyxy).rg;
        texcoord.y += BUFFER_RCP_HEIGHT + BUFFER_RCP_HEIGHT;
        if (e.g > 0.0) break;
    }
    float offset = mad(-(255./127.), HQAASearchLength(HQAAsearchTex, e.gr, 0.0), 3.25);
    return mad(-__HQAA_SM_BUFFERINFO.y, offset, texcoord.y);
}

float2 HQAAArea(sampler2D HQAAareaTex, float2 dist, float e1, float e2)
{
    float2 texcoord = mad(float(__HQAA_SM_AREATEX_RANGE).xx, 4.0 * float2(e1, e2), dist);
    
    texcoord = mad(__HQAA_SM_AREATEX_TEXEL, texcoord, 0.5 * __HQAA_SM_AREATEX_TEXEL);

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
#endif //HQAA_DISABLE_SMAA

/////////////////////////////////////////////////// OPTIONAL HELPER FUNCTIONS /////////////////////////////////////////////////////////////

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

////////////////////////////////////////////////////////// TONE MAPPERS ///////////////////////////////////////////////////////////////////

float3 tonemap_adjustluma(float3 x, float xl_out)
{
	float xl = dot(x, __HQAA_LUMA_REF);
	return x * (xl_out / xl);
}

float3 reinhard_jodie(float3 x)
{
	float xl = dot(x, __HQAA_LUMA_REF);
	float3 xv = x / (1.0 + x);
	return lerp(x / (1.0 + xl), xv, xv);
}

float3 extended_reinhard(float3 x)
{
	float whitepoint = abs(HqaaTonemappingParameter);
	float3 numerator = x * (1.0 + (x / (whitepoint * whitepoint)));
	return numerator / (1.0 + x);
}

float3 extended_reinhard_luma(float3 x)
{
	float whitepoint = abs(HqaaTonemappingParameter);
	float xl = dot(x, __HQAA_LUMA_REF);
	float numerator = xl * (1.0 + (xl / (whitepoint * whitepoint)));
	float xl_shift = numerator / (1.0 + xl);
	return tonemap_adjustluma(x, xl_shift);
}

float3 uncharted2_partial(float3 x)
{
	float A = 0.15;
	float B = 0.5;
	float C = 0.1;
	float D = 0.2;
	float E = 0.02;
	float F = 0.3;
	
	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

float3 uncharted2_filmic(float3 x)
{
	float exposure_bias = 2.0;
	float3 curr = uncharted2_partial(x * exposure_bias);
	float3 whitescale = rcp(uncharted2_partial(float(11.2).xxx));
	return curr * whitescale;
}

float3 aces_approx(float3 x)
{
	float3 xout = x * 0.6;
	float A = 2.51;
	float B = 0.03;
	float C = 2.43;
	float D = 0.59;
	float E = 0.14;
	
	return saturate((xout*(A*xout+B))/(xout*(C*xout+D)+E));
}

float3 logarithmic_fake_hdr(float3 x)
{
	bool3 truezero = !x;
	return saturate(pow(abs(__HQAA_CONST_E + (abs(HqaaTonemappingParameter) * (0.5 - log2(1.0 + dot(x, __HQAA_LUMA_REF))))), log(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 1.0)))) * (!truezero);
}

float3 logarithmic_range_compression(float3 x)
{
	float luma = dot(x, __HQAA_LUMA_REF);
	bool3 truezero = !x;
	float offset = abs(HqaaTonemappingParameter) * (0.5 - luma);
	float3 result = pow(abs(__HQAA_CONST_E - offset), log(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 1.0))) * (!truezero);
	return saturate(result);
}

float3 logarithmic_black_stabilizer(float3 x)
{
	float luma = dot(x, __HQAA_LUMA_REF);
	bool3 truezero = !x;
	float offset = abs(HqaaTonemappingParameter) * ((1.0 - pow(saturate(luma * 8.), __HQAA_CONST_E)) / 8.);
	float3 result = pow(abs(__HQAA_CONST_E - offset), log(clamp(x, __HQAA_SMALLEST_COLOR_STEP, 1.0))) * (!truezero);
	return saturate(result);
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
	Format = RGBA16F;
};

#if !HQAA_DISABLE_SMAA
texture HQAAblendTex
#if __RESHADE__ >= 50000
< pooled = true; >
#endif
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA16F;
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
#endif //HQAA_DISABLE_SMAA

#if HQAA_SPLITSCREEN_PREVIEW
texture HQAAOriginalBufferTex
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	#if BUFFER_COLOR_BIT_DEPTH == 8
	Format = RGBA8;
	#elif BUFFER_COLOR_BIT_DEPTH == 10
	Format = RGB10A2;
	#else
	Format = RGBA16F;
	#endif
};
sampler OriginalBuffer {Texture = HQAAOriginalBufferTex;};
#endif

#if HQAA_OPTIONAL__TEMPORAL_AA
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE

texture HqaaTaaJitterTex0
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	#if BUFFER_COLOR_BIT_DEPTH == 8
	Format = RGBA8;
	#elif BUFFER_COLOR_BIT_DEPTH == 10
	Format = RGB10A2;
	#else
	Format = RGBA16F;
	#endif
};
sampler TaaJitterTex0 {Texture = HqaaTaaJitterTex0;};

texture HqaaTaaJitterTex1
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	#if BUFFER_COLOR_BIT_DEPTH == 8
	Format = RGBA8;
	#elif BUFFER_COLOR_BIT_DEPTH == 10
	Format = RGB10A2;
	#else
	Format = RGBA16F;
	#endif
};
sampler TaaJitterTex1 {Texture = HqaaTaaJitterTex1;};

#if HQAA_OPTIONAL__TEMPORAL_AA > 1
texture HqaaTaaJitterTex2
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	#if BUFFER_COLOR_BIT_DEPTH == 8
	Format = RGBA8;
	#elif BUFFER_COLOR_BIT_DEPTH == 10
	Format = RGB10A2;
	#else
	Format = RGBA16F;
	#endif
};
sampler TaaJitterTex2 {Texture = HqaaTaaJitterTex2;};

texture HqaaTaaJitterTex3
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	#if BUFFER_COLOR_BIT_DEPTH == 8
	Format = RGBA8;
	#elif BUFFER_COLOR_BIT_DEPTH == 10
	Format = RGB10A2;
	#else
	Format = RGBA16F;
	#endif
};
sampler TaaJitterTex3 {Texture = HqaaTaaJitterTex3;};
#endif //HQAA_OPTIONAL__TEMPORAL_AA > 1

#if HQAA_OPTIONAL__TEMPORAL_AA > 2
texture HqaaTaaJitterTex4
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	#if BUFFER_COLOR_BIT_DEPTH == 8
	Format = RGBA8;
	#elif BUFFER_COLOR_BIT_DEPTH == 10
	Format = RGB10A2;
	#else
	Format = RGBA16F;
	#endif
};
sampler TaaJitterTex4 {Texture = HqaaTaaJitterTex4;};

texture HqaaTaaJitterTex5
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	#if BUFFER_COLOR_BIT_DEPTH == 8
	Format = RGBA8;
	#elif BUFFER_COLOR_BIT_DEPTH == 10
	Format = RGB10A2;
	#else
	Format = RGBA16F;
	#endif
};
sampler TaaJitterTex5 {Texture = HqaaTaaJitterTex5;};
#endif //HQAA_OPTIONAL__TEMPORAL_AA > 2

#if HQAA_OPTIONAL__TEMPORAL_AA > 3
texture HqaaTaaJitterTex6
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	#if BUFFER_COLOR_BIT_DEPTH == 8
	Format = RGBA8;
	#elif BUFFER_COLOR_BIT_DEPTH == 10
	Format = RGB10A2;
	#else
	Format = RGBA16F;
	#endif
};
sampler TaaJitterTex6 {Texture = HqaaTaaJitterTex6;};

texture HqaaTaaJitterTex7
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	#if BUFFER_COLOR_BIT_DEPTH == 8
	Format = RGBA8;
	#elif BUFFER_COLOR_BIT_DEPTH == 10
	Format = RGB10A2;
	#else
	Format = RGBA16F;
	#endif
};
sampler TaaJitterTex7 {Texture = HqaaTaaJitterTex7;};
#endif //HQAA_OPTIONAL__TEMPORAL_AA > 3
#endif //HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
#endif //HQAA_OPTIONAL__TEMPORAL_AA

//////////////////////////////////////////////////////////// SAMPLERS ///////////////////////////////////////////////////////////////////

sampler HQAAsamplerAlphaEdges
{
	Texture = HQAAedgesTex;
};

#if !HQAA_DISABLE_SMAA
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
};
#endif //HQAA_DISABLE_SMAA

//////////////////////////////////////////////////////////// VERTEX SHADERS /////////////////////////////////////////////////////////////
void HQAABlendingWeightCalculationVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0, out float2 pixcoord : TEXCOORD1, out float4 offset[3] : TEXCOORD2)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    pixcoord = texcoord * __HQAA_SM_BUFFERINFO.zw;

    offset[0] = mad(__HQAA_SM_BUFFERINFO.xyxy, float4(-0.25, -0.125,  1.25, -0.125), texcoord.xyxy);
    offset[1] = mad(__HQAA_SM_BUFFERINFO.xyxy, float4(-0.125, -0.25, -0.125,  1.25), texcoord.xyxy);
	
	float searchrange = __HQAA_SM_RADIUS;
	
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
float4 HQAAHybridEdgeDetectionPS(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	if ((HqaaSourceInterpolation == 1) && __HQAA_ALT_FRAME) discard;
	if ((HqaaSourceInterpolation == 2) && !__HQAA_QUAD_FRAME) discard;
	
	float3 middle = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 ref = __HQAA_LUMA_REF;
	float2 hvstep = __HQAA_SM_BUFFERINFO.xy;
	
    float L = dot(middle, ref);
    float3 top = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - float2(0, hvstep.y)).rgb;
    float Dtop = chromadelta(middle, top);
    float Ltop = dot(top, ref);
    float3 left = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - float2(hvstep.x, 0)).rgb;
    float Dleft = chromadelta(middle, left);
    float Lleft = dot(left, ref);
    
	float Lavg = sqrt(L * clamp(((Lleft + Ltop) / 2.0), __HQAA_SMALLEST_COLOR_STEP, 1.0));
	float rangemult = 1.0 - log2(1.0 + clamp(log2(1.0 + Lavg), 0.0, HqaaLowLumaThreshold) * rcp(HqaaLowLumaThreshold));
	float edgethreshold = __HQAA_EDGE_THRESHOLD;
	edgethreshold = clamp(mad(rangemult, -(__HQAA_DYNAMIC_RANGE * edgethreshold), edgethreshold), 0.02, 1.00);
	float2 bufferdata = float2(L, edgethreshold);
	
	float2 edges = step(edgethreshold, float2(Dleft, Dtop));
	if (!any(edges)) return float4(0.0, 0.0, bufferdata);
    
    float3 right = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(hvstep.x, 0)).rgb;
    float Dright = chromadelta(middle, right);
    float3 bottom = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(0, hvstep.y)).rgb;
    float Dbottom = chromadelta(middle, bottom);
    
    float2 maxdelta = float2(max(Dleft, Dright), max(Dtop, Dbottom));
    
    float Dleftleft = chromadelta(left, HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - float2(hvstep.x + hvstep.x, 0.0)).rgb);
    float Dtoptop = chromadelta(top, HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - float2(0.0, hvstep.y + hvstep.y)).rgb);
	
	maxdelta = max(maxdelta, float2(Dleftleft, Dtoptop));
	float largestdelta = max(maxdelta.x, maxdelta.y);
	
	float contrastadaptation = 2.5 * rcp(__HQAA_EDGE_THRESHOLD / edgethreshold);
	edges *= step(largestdelta, contrastadaptation * float2(Dleft, Dtop));
	
	return float4(edges, bufferdata);
}

/////////////////////////////////////////////////// BLEND WEIGHT CALCULATION //////////////////////////////////////////////////////////////
#if !HQAA_DISABLE_SMAA
float4 HQAABlendingWeightCalculationPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float2 pixcoord : TEXCOORD1, float4 offset[3] : TEXCOORD2) : SV_Target
{
    float4 weights = float(0.0).xxxx;
    float2 e = HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord).rg;
    
	[branch] if (e.g > 0.0)
	{
    	float2 diagweights = HQAACalculateDiagWeights(HQAAsamplerAlphaEdges, HQAAsamplerSMarea, texcoord, e);
    	if (any(diagweights)) weights.xy = diagweights;
    	else
    	{
			float3 coords = float3(HQAASearchXLeft(HQAAsamplerAlphaEdges, HQAAsamplerSMsearch, offset[0].xy, offset[2].x), offset[1].y, HQAASearchXRight(HQAAsamplerAlphaEdges, HQAAsamplerSMsearch, offset[0].zw, offset[2].y));
			float e1 = HQAA_Tex2D(HQAAsamplerAlphaEdges, coords.xy).r;
			float2 d = coords.xz;
			d = abs((mad(__HQAA_SM_BUFFERINFO.zz, d, -pixcoord.xx)));
			float e2 = HQAA_Tex2D(HQAAsamplerAlphaEdges, coords.zy + float2(BUFFER_RCP_WIDTH, 0)).r;
			weights.rg = HQAAArea(HQAAsamplerSMarea, sqrt(d), e1, e2);
			coords.y = texcoord.y;
			if (HqaaSmCornerDetection) HQAADetectHorizontalCornerPattern(HQAAsamplerAlphaEdges, weights.rg, coords.xyzy, d);
		}
    }
    
	if (!e.r) return weights;
		
    float3 coords = float3(offset[0].x, HQAASearchYUp(HQAAsamplerAlphaEdges, HQAAsamplerSMsearch, offset[1].xy, offset[2].z), HQAASearchYDown(HQAAsamplerAlphaEdges, HQAAsamplerSMsearch, offset[1].zw, offset[2].w));
    float e1 = HQAA_Tex2D(HQAAsamplerAlphaEdges, coords.xy).g;
	float2 d = coords.yz;
    d = abs((mad(__HQAA_SM_BUFFERINFO.ww, d, -pixcoord.yy)));
    float e2 = HQAA_Tex2D(HQAAsamplerAlphaEdges, coords.xz + float2(0, BUFFER_RCP_HEIGHT)).g;
    weights.ba = HQAAArea(HQAAsamplerSMarea, sqrt(d), e1, e2);
    coords.x = texcoord.x;
    if (HqaaSmCornerDetection) HQAADetectVerticalCornerPattern(HQAAsamplerAlphaEdges, weights.ba, coords.xyxz, d);
    
    return weights;
}
#endif //HQAA_DISABLE_SMAA

//////////////////////////////////////////////////// NEIGHBORHOOD BLENDING ////////////////////////////////////////////////////////////////
#if !HQAA_DISABLE_SMAA
float3 HQAANeighborhoodBlendingPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float4 offset : TEXCOORD1) : SV_Target
{
	float3 resultAA = HQAA_Tex2D(ReShade::BackBuffer, texcoord).rgb;
#if !HQAA_ADVANCED_MODE
	if (HqaaDebugMode == 9 || !HqaaEnableAABlending) return resultAA;
#else
	if (HqaaDebugMode == 9 || !HqaaEnableSMAABlending) return resultAA;
#endif
    float4 m = float4(HQAA_Tex2D(HQAAsamplerSMweights, offset.xy).a, HQAA_Tex2D(HQAAsamplerSMweights, offset.zw).g, HQAA_Tex2D(HQAAsamplerSMweights, texcoord).zx);

	[branch] if (any(m))
	{
		resultAA = ConditionalDecode(resultAA);
		float deltapre = maxcolordelta(resultAA);
		float3 original = resultAA;
		float Lpre = dot(resultAA, __HQAA_LUMA_REF);
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
        float4 blendingCoord = mad(blendingOffset, float4(__HQAA_SM_BUFFERINFO.xy, -__HQAA_SM_BUFFERINFO.xy), texcoord.xyxy);
        resultAA = maxratio * blendingWeight.x * HQAA_DecodeTex2D(ReShade::BackBuffer, blendingCoord.xy).rgb;
        resultAA += maxratio * blendingWeight.y * HQAA_DecodeTex2D(ReShade::BackBuffer, blendingCoord.zw).rgb;
        
        [branch] if (minratio != 0.0)
        {
        	blendingOffset = 0.0.xxxx;
        	HQAAMovc(bool4(!horiz, horiz, !horiz, horiz), blendingOffset, float4(m.x, m.y, m.z, m.w));
	        HQAAMovc(bool(!horiz).xx, blendingWeight, m.xz);
	        HQAAMovc(bool(horiz).xx, blendingWeight, m.yw);
	        blendingWeight /= dot(blendingWeight, float(1.0).xx);
	        blendingCoord = mad(blendingOffset, float4(__HQAA_SM_BUFFERINFO.xy, -__HQAA_SM_BUFFERINFO.xy), texcoord.xyxy);
	        resultAA += minratio * blendingWeight.x * HQAA_DecodeTex2D(ReShade::BackBuffer, blendingCoord.xy).rgb;
	        resultAA += minratio * blendingWeight.y * HQAA_DecodeTex2D(ReShade::BackBuffer, blendingCoord.zw).rgb;
 	   }
        
        float Lpost = dot(resultAA, __HQAA_LUMA_REF);
        float deltapost = maxcolordelta(resultAA);
        float deltadelta = 1.0 - abs(deltapre - deltapost);
        float noisepotential = saturate(abs(Lpost - Lpre) - saturate(HqaaNoiseFloor)) * deltadelta;
        float dynamicadjust = __HQAA_EDGE_THRESHOLD / HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord).a;
		float noisecontrol = saturate(noisepotential * dynamicadjust * saturate(HqaaNoiseControlStrength / 100.));
		resultAA = lerp(resultAA, original, noisecontrol);
		
		resultAA = ConditionalEncode(resultAA);
    }
	return resultAA;
}
#endif //HQAA_DISABLE_SMAA

/***************************************************************************************************************************************/
/********************************************************** SMAA SHADER CODE END *******************************************************/
/***************************************************************************************************************************************/

/***************************************************************************************************************************************/
/********************************************************** FXAA SHADER CODE START *****************************************************/
/***************************************************************************************************************************************/

#if HQAA_FXAA_MULTISAMPLING > 0
float3 HQAAFXPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
 {
    float3 original = HQAA_Tex2D(ReShade::BackBuffer, texcoord).rgb;
#if !HQAA_ADVANCED_MODE
	if (HqaaDebugMode == 10 || !HqaaEnableAABlending) return original;
#else
	if (HqaaDebugMode == 10 || !HqaaEnableFXAABlending) return original;
#endif
	
	float4 smaadata = HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord);
	float edgethreshold = smaadata.a;
	float3 middle = ConditionalDecode(original);
	float3 channeldeltas = abs(float3(middle.r - middle.g, middle.g - middle.b, middle.b - middle.r));
	float maxchannel = max3(middle.r, middle.g, middle.b);
	float3 ref = __HQAA_BLUE_LUMA;
	if (max3(channeldeltas.r, channeldeltas.g, channeldeltas.b) < 0.0722) ref = __HQAA_AVERAGE_REF;
	else if (maxchannel == middle.g) ref = __HQAA_GREEN_LUMA;
	else if (maxchannel == middle.r) ref = __HQAA_RED_LUMA;
	float lumaM = dot(middle, ref);
	float2 lengthSign = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	
    float lumaS = dot(HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(0, lengthSign.y)).rgb, ref);
    float lumaE = dot(HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(lengthSign.x, 0)).rgb, ref);
    float lumaN = dot(HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - float2(0, lengthSign.y)).rgb, ref);
    float lumaW = dot(HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - float2(lengthSign.x, 0)).rgb, ref);
    float4 crossdelta = abs(lumaM - float4(lumaS, lumaE, lumaN, lumaW));
    float2 weightsHV = float2(max(crossdelta.x, crossdelta.z), max(crossdelta.y, crossdelta.w));
    
    // pattern
    // * z *
    // w * y
    // * x *
    
    float2 diagstep = lengthSign * __HQAA_CONST_HALFROOT2;
    float lumaNW = dot(HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - diagstep).rgb, ref);
    float lumaSE = dot(HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + diagstep).rgb, ref);
    float lumaNE = dot(HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(diagstep.x, -diagstep.y)).rgb, ref);
    float lumaSW = dot(HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(-diagstep.x, diagstep.y)).rgb, ref);
	float4 diagdelta = abs(lumaM - float4(lumaNW, lumaSE, lumaNE, lumaSW));
	float2 weightsDI = float2(max(diagdelta.w, diagdelta.z), max(diagdelta.x, diagdelta.y));
    
    // pattern
    // x * z
    // * * *
    // w * y
    
	// early exit check
    float range = max4(weightsHV.x, weightsHV.y, weightsDI.x, weightsDI.y);
	if (HqaaFxEarlyExit && (range < edgethreshold))
		if (clamp(HqaaDebugMode, 3, 6) == HqaaDebugMode) return float(0.0).xxx;
		else return original;
	
    // get edge pattern
	bool diagSpan = false;
	if (HqaaFxDiagScans) diagSpan = max(weightsDI.x, weightsDI.y) > max(weightsHV.x, weightsHV.y);
	bool inverseDiag = diagSpan && weightsDI.y > weightsDI.x;
	bool horzSpan = weightsHV.x >= weightsHV.y;
	
	float2 lumaNP = float2(lumaN, lumaS);
	HQAAMovc(!horzSpan.xx, lumaNP, float2(lumaW, lumaE));
	HQAAMovc(diagSpan.xx, lumaNP, float2(lumaSW, lumaNE));
	HQAAMovc((diagSpan && inverseDiag).xx, lumaNP, float2(lumaNW, lumaSE));
	float2 gradientNP = abs(lumaNP - lumaM);
    float lumaNN = ((gradientNP.y > gradientNP.x) ? (lumaNP.y + lumaM) : (lumaNP.x + lumaM)) * 0.5;
    if (gradientNP.x >= gradientNP.y && !diagSpan) lengthSign = -lengthSign;
    if (diagSpan && inverseDiag) lengthSign.y = -lengthSign.y;
    float gradientScaled = max(gradientNP.x, gradientNP.y) * 0.25;
    bool lumaMLTZero = (lumaM - lumaNN) < 0.0;
	
	float2 offNPdir = float2(horzSpan || diagSpan, (!diagSpan && !horzSpan) || (diagSpan && !inverseDiag)) - float2(0.0, diagSpan && inverseDiag);
	float2 offNPsign = offNPdir * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	if (diagSpan) offNPsign *= __HQAA_CONST_HALFROOT2;
	float2 offNPref = __HQAA_FX_TEXEL.xx;
	float2 offNP = offNPref * offNPsign;
    float2 posB;
    if (!diagSpan) posB = texcoord + lengthSign * 0.333333 * abs(offNPdir.yx);
    else posB = texcoord;
    float2 posN = posB - offNP;
    float2 posP = posB + offNP;
    float lumaEndN = dot(HQAA_DecodeTex2D(ReShade::BackBuffer, posN).rgb, ref);
    float lumaEndP = dot(HQAA_DecodeTex2D(ReShade::BackBuffer, posP).rgb, ref);
	
    lumaEndN -= lumaNN;
    lumaEndP -= lumaNN;
	
    bool doneN = abs(lumaEndN) >= gradientScaled;
    bool doneP = abs(lumaEndP) >= gradientScaled;
	uint iterations = 0;
	uint maxiterations = __HQAA_FX_QUALITY;
	uint startgrowingafter = clamp(HqaaFxTexelGrowAfter, 1, 200) - 1;
	float growpercent = saturate(HqaaFxTexelGrowPercent / 100.) + 1.;
	
	[loop] while (iterations < maxiterations)
	{
		if (doneN && doneP) break;
		[branch] if (!doneN)
		{
			posN -= offNP;
			lumaEndN = dot(HQAA_DecodeTex2D(ReShade::BackBuffer, posN).rgb, ref);
			lumaEndN -= lumaNN;
			doneN = abs(lumaEndN) >= gradientScaled;
		}
		[branch] if (!doneP)
		{
			posP += offNP;
			lumaEndP = dot(HQAA_DecodeTex2D(ReShade::BackBuffer, posP).rgb, ref);
			lumaEndP -= lumaNN;
			doneP = abs(lumaEndP) >= gradientScaled;
		}
		if (HqaaFxTexelGrowth)
		[branch] if (iterations > startgrowingafter)
		{
			offNPref *= growpercent;
			offNP = offNPref * offNPsign;
		}
		iterations++;
    }
	
	float2 dstNP = float2(texcoord.y - posN.y, posP.y - texcoord.y);
	HQAAMovc(bool(horzSpan).xx, dstNP, float2(texcoord.x - posN.x, posP.x - texcoord.x));
	HQAAMovc(bool(diagSpan).xx, dstNP, float2(sqrt(pow(abs(texcoord.y - posN.y), 2.0) + pow(abs(texcoord.x - posN.x), 2.0)), sqrt(pow(abs(posP.y - texcoord.y), 2.0) + pow(abs(posP.x - texcoord.x), 2.0))));
    float endluma = (dstNP.x < dstNP.y) ? lumaEndN : lumaEndP;
    bool goodSpan = endluma < 0.0 != lumaMLTZero;
	if ((HqaaDebugMode == 0 || HqaaDebugMode == 3) && !any(smaadata.rg) && !goodSpan) return original;
    
    float subpixOut = __HQAA_FX_BLEND;
	[branch] if (!goodSpan) // bad span
	{
		float dynamicmult = __HQAA_EDGE_THRESHOLD / edgethreshold;
		float localdelta = pow(maxcolordelta(middle), 0.333333);
		float noisepotential = saturate(abs(endluma - lumaM) * HQAA_FXAA_MULTISAMPLING - saturate(HqaaNoiseFloor));
    	float blendclamp = 1.0 - saturate(noisepotential * dynamicmult * saturate(HqaaNoiseControlStrength / 100.));
    	subpixOut = clamp(subpixOut, 0.0, blendclamp);
		float cross = lumaS + lumaE + lumaN + lumaW;
		float star = lumaNW + lumaSE + lumaNE + lumaSW;
		float fallback = mad(cross + star, 0.125, -lumaM) * rcp(range); //ABC
		fallback = pow(saturate(mad(-2.0, fallback, 3.0) * (fallback * fallback)), 2.0) * localdelta; // DEFGH +I
		subpixOut *= fallback;
	}
	else subpixOut *= abs(mad(-rcp(dstNP.y + dstNP.x), min(dstNP.x, dstNP.y), 0.5)); // good span coords

    float2 posM = texcoord;
	HQAAMovc(bool2(!horzSpan || diagSpan, horzSpan || diagSpan), posM, float2(posM.x + lengthSign.x * subpixOut, posM.y + lengthSign.y * subpixOut));
    
	// output selection
	if (HqaaDebugMode == 4)
	{
		float3 debugout = ref * lumaM * middle * 0.75 + 0.25;
		return debugout;
	}
	if (HqaaDebugMode == 5)
	{
		// metrics output
		float runtime = float(iterations / maxiterations) * 0.5;
		float3 FxaaMetrics = float3(runtime, 0.5 - runtime, 0.0);
		return FxaaMetrics;
	}
	if (HqaaDebugMode == 6)
	{
		// span output
		if (goodSpan) return float3(1, 1, 1);
		else
		{
			float3 spantype = float3(!horzSpan && !diagSpan, horzSpan && !diagSpan, diagSpan);
			return spantype * float3(0.666667, 0.5, 0.8);
		}
	}
	
	// normal output
	return HQAA_Tex2D(ReShade::BackBuffer, posM).rgb;
}
#endif //HQAA_FXAA_MULTISAMPLING

/***************************************************************************************************************************************/
/********************************************************** FXAA SHADER CODE END *******************************************************/
/***************************************************************************************************************************************/

/***************************************************************************************************************************************/
/****************************************************** HYSTERESIS SHADER CODE START ***************************************************/
/***************************************************************************************************************************************/

float3 HQAAPostProcessPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float4 offset : TEXCOORD1) : SV_Target
{
	float3 pixel = HQAA_Tex2D(ReShade::BackBuffer, texcoord).rgb;
	float4 edgedata = HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord);
#if !HQAA_DISABLE_SMAA
	float4 blendingdata = float4(HQAA_Tex2D(HQAAsamplerSMweights, offset.xy).a, HQAA_Tex2D(HQAAsamplerSMweights, offset.zw).g, HQAA_Tex2D(HQAAsamplerSMweights, texcoord).zx);
#endif //HQAA_DISABLE_SMAA
	
	float safethreshold = __HQAA_EDGE_THRESHOLD;
	
	if (HqaaDebugMode == 1) return float3(edgedata.rg, 0.0);
#if !HQAA_DISABLE_SMAA
	if (HqaaDebugMode == 2) return blendingdata.rgb;
#endif //HQAA_DISABLE_SMAA
	if (HqaaDebugMode == 8) { float usedthreshold = 1.0 - rcp(safethreshold / edgedata.a); return float3(0.0, saturate(usedthreshold), 0.0); }

	float3 original = pixel;
	bool altered = false;
	pixel = ConditionalDecode(pixel);
	float3 AAdot = pixel;
	
	if (HqaaDoLumaHysteresis)
	{
#if !HQAA_DISABLE_SMAA
		float blendweight = 1.0 - saturate(blendingdata.x + blendingdata.y + blendingdata.z + blendingdata.w);
		float blendclamp = any(blendingdata) ? blendweight : 1.0;
#else
		float blendclamp = 1.0;
#endif //HQAA_DISABLE_SMAA
		float lowlumaclamp = rcp(safethreshold / edgedata.a);
		float blendstrength = __HQAA_HYSTERESIS_STRENGTH * min(blendclamp, lowlumaclamp);

		float hysteresis = (dot(pixel, __HQAA_LUMA_REF) - edgedata.b) * blendstrength;
		if (abs(hysteresis) > __HQAA_HYSTERESIS_FUDGE)
		{
			bool3 truezero = !pixel;
			pixel = pow(abs(1.0 + hysteresis) * 2.0, log2(pixel)) * (!truezero);
			altered = true;
		}
	}
	
	//debug out
	if (HqaaDebugMode == 7)
	{
		// hysteresis pattern
		if (altered) return sqrt(abs(pixel - AAdot));
		else return 0.0.xxx;
	}
	
	if (HqaaEnableSharpening && (HqaaDebugMode == 0))
	{
		float3 casdot = pixel;
	
		float sharpening = saturate(HqaaSharpenerStrength);
	
		if (any(edgedata.rg)) sharpening = saturate(sharpening + clamp(HqaaSharpenerClamping, -1.0, 1.0));
		
		float2 hvstep = __HQAA_SM_BUFFERINFO.xy * HqaaSharpenOffset;
		float2 diagstep = hvstep * __HQAA_CONST_HALFROOT2;
	
		float3 a = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - diagstep).rgb;
		float3 c = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(diagstep.x, -diagstep.y)).rgb;
		float3 g = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(-diagstep.x, diagstep.y)).rgb;
		float3 i = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + diagstep).rgb;
		float3 b = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - float2(0.0, hvstep.y)).rgb;
		float3 d = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - float2(hvstep.x, 0.0)).rgb;
		float3 f = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(hvstep.x, 0.0)).rgb;
		float3 h = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(0.0, hvstep.y)).rgb;
	
		float3 mnRGB = HQAAmin5(d, casdot, f, b, h);
		float3 mnRGB2 = HQAAmin5(mnRGB, a, c, g, i);

		float3 mxRGB = HQAAmax5(d, casdot, f, b, h);
		float3 mxRGB2 = HQAAmax5(mxRGB, a, c, g, i);
	
		mnRGB += mnRGB2;
		mxRGB += mxRGB2;
	
		float3 ampRGB = 1.0 / sqrt(saturate(min(mnRGB, 2.0 - mxRGB) * (1.0 / mxRGB)));    
		float3 wRGB = -(1.0 / (ampRGB * mad(-3.9, saturate(HqaaSharpenerAdaptation), 8.0)));
		float3 window = (b + d) + (f + h);
	
		float3 outColor = saturate(mad(window, wRGB, casdot) * (1.0 / mad(4.0, wRGB, 1.0)));
		
    	float Lpre = dot(casdot, __HQAA_LUMA_REF);
    	float Lpost = dot(outColor, __HQAA_LUMA_REF);
    	float Ldelta = (Lpost == 0.0) ? 0.0 : (Lpre / Lpost);
    	float Ladjust = lerp(1.0, Ldelta, saturate(HqaaSharpenerLumaCorrection));
    	outColor *= Ladjust;
    
		casdot = lerp(casdot, outColor, sharpening);
	
		pixel = casdot;
		altered = true;
	}
	
	if (HqaaEnableBrightnessGain && (saturate(HqaaGainStrength) > 0.0))
	{
		float3 outdot = pixel;
		bool3 truezero = !outdot;
		float presaturation = dotsat(outdot);
		float preluma = dot(outdot, __HQAA_LUMA_REF);
		float colorgain = 2.0 - log2(saturate(HqaaGainStrength) + 1.0);
		float channelfloor = __HQAA_SMALLEST_COLOR_STEP;
		outdot = log2(clamp(outdot, channelfloor, 1.0 - channelfloor));
		outdot = pow(abs(colorgain), outdot);
		if (HqaaGainLowLumaCorrection)
		{
			// calculate new black level
			channelfloor = pow(abs(colorgain), log2(channelfloor));
			// calculate reduction strength to apply
			float contrastgain = log(1.0 / (dot(outdot, __HQAA_LUMA_REF) - channelfloor)) * pow(__HQAA_CONST_E, (1.0 + channelfloor) * __HQAA_CONST_E) * pow(saturate(HqaaGainStrength), 2);
			outdot = pow(abs(2.0 + contrastgain) * 5.0, log10(outdot));
			float lumadelta = dot(outdot, __HQAA_LUMA_REF) - preluma;
			outdot = RGBtoYUV(outdot);
			outdot.x = saturate(outdot.x - lumadelta * channelfloor);
			outdot = YUVtoRGB(outdot);
			float newsat = dotsat(outdot);
			float satadjust = abs(((newsat - presaturation) / 2.0) * (1.0 + saturate(HqaaGainStrength))); // compute difference in before/after saturation
			bool adjustsat = satadjust != 0.0;
			if (adjustsat) outdot = AdjustSaturation(outdot, 0.5 + satadjust);
		}
		pixel = outdot * (!truezero);
		altered = true;
	}

	if (HqaaEnableColorPalette && (HqaaTonemapping > 0))
	{
		if (HqaaTonemapping == 1) pixel = extended_reinhard(pixel);
		if (HqaaTonemapping == 2) pixel = extended_reinhard_luma(pixel);
		if (HqaaTonemapping == 3) pixel = reinhard_jodie(pixel);
		if (HqaaTonemapping == 4) pixel = uncharted2_filmic(pixel);
		if (HqaaTonemapping == 5) pixel = aces_approx(pixel);
		if (HqaaTonemapping == 6) pixel = logarithmic_fake_hdr(pixel);
		if (HqaaTonemapping == 7) pixel = logarithmic_range_compression(pixel);
		if (HqaaTonemapping == 8) pixel = logarithmic_black_stabilizer(pixel);
		altered = true;
	}
	
	if (HqaaEnableColorPalette && (clamp(HqaaVibranceStrength, 0, 100) != 50.0))
	{
		float3 outdot = pixel;
		bool3 truezero = lnand(1.0.xxx, outdot);
		outdot = AdjustVibrance(outdot, -(saturate(HqaaVibranceStrength / 100.0) - 0.5));
		pixel = lnand(outdot, truezero);
		altered = true;
	}
	
	if (HqaaEnableColorPalette && (saturate(HqaaSaturationStrength) != 0.5))
	{
		float3 outdot = AdjustSaturation(pixel, saturate(HqaaSaturationStrength));
		pixel = outdot;
		altered = true;
	}
	
	if (HqaaEnableColorPalette && (saturate(HqaaColorTemperature) != 0.5))
	{
		float3 outdot = RGBtoYUV(pixel);
		float direction = (0.5 - saturate(HqaaColorTemperature)) * abs(outdot.z) * outdot.x;
		outdot.y += direction * 0.5;
		outdot.z -= direction;
		pixel = YUVtoRGB(outdot);
		altered = true;
	}
	
	if (HqaaEnableColorPalette && (saturate(HqaaBlueLightFilter) != 0.0))
	{
		float3 outdot = RGBtoYUV(pixel);
		float strength = 1.0 - saturate(HqaaBlueLightFilter);
		float signalclamp = (outdot.x * 0.5) * dotsat(pixel) * abs(outdot.y);
		if (outdot.z > 0.0) outdot.z = clamp(outdot.z * strength, signalclamp, 0.5);
		pixel = YUVtoRGB(outdot);
		altered = true;
	}
	
	if (altered) return ConditionalEncode(pixel);
	else return original;
}

/***************************************************************************************************************************************/
/******************************************************* HYSTERESIS SHADER CODE END ****************************************************/
/***************************************************************************************************************************************/

/***************************************************************************************************************************************/
/******************************************************* OPTIONAL SHADER CODE START ****************************************************/
/***************************************************************************************************************************************/

#if HQAA_OPTIONAL__TEMPORAL_AA || HQAA_OPTIONAL__DEBANDING
float HQAATAAEdgeDetectionPS(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 middle = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord).rgb;
	float2 hvstep = __HQAA_SM_BUFFERINFO.xy;
	float edgethreshold = HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord).a;
	
    float Dtop = chromadelta(middle, HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - float2(0, hvstep.y)).rgb);
    float Dleft = chromadelta(middle, HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - float2(hvstep.x, 0)).rgb);
    float Dright = chromadelta(middle, HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(hvstep.x, 0)).rgb);
    float Dbottom = chromadelta(middle, HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(0, hvstep.y)).rgb);
	
	float edges = max4(Dtop, Dleft, Dright, Dbottom);
	edges *= step(edgethreshold, edges);
	
	return edges;
}
#endif //HQAA_OPTIONAL__TEMPORAL_AA || HQAA_OPTIONAL__DEBANDING

#if HQAA_OPTIONAL__TEMPORAL_AA
float4 HQAATAASelfSharpen(float4 jitter, float2 texcoord, float blendweight, float edges)
{
	float SharpeningStrength = blendweight;
	float SharpeningContrast = edges;
	float offset = clamp(HqaaTaaJitterOffset, 0.0, 4.0) * __HQAA_BUFFER_MULT;
	float2 bstep = offset * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float2 diagstep = (sqrt(2.)/2.) * bstep;
	
	float4 a = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - diagstep);
    float4 b = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - float2(0., bstep.y));
    float4 c = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(diagstep.x, -diagstep.y));
    float4 d = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - float2(bstep.x, 0.));
    float4 g = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(-diagstep.x, diagstep.y));
    float4 f = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(bstep.x, 0.));
    float4 h = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(0., bstep.y));
    float4 i = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + diagstep);

    float4 mnRGB = min(min(min(d, jitter), min(f, b)), h);
    float4 mnRGB2 = min(mnRGB, min(min(a, c), min(g, i)));
    mnRGB += mnRGB2;

    float4 mxRGB = max(max(max(d, jitter), max(f, b)), h);
    float4 mxRGB2 = max(mxRGB, max(max(a, c), max(g, i)));
    mxRGB += mxRGB2;

    float4 rcpMRGB = rcp(mxRGB);
    float4 ampRGB = saturate(min(mnRGB, 2.0 - mxRGB) * rcpMRGB);    
    
    ampRGB = rsqrt(ampRGB);
    
    float peak = -3.0 * SharpeningContrast + 8.0;
    float4 wRGB = -rcp(ampRGB * peak);

    float4 rcpWeightRGB = rcp(4.0 * wRGB + 1.0);
	
    float4 window = (b + d) + (f + h);
    float4 outColor = saturate((window * wRGB + jitter) * rcpWeightRGB);
    
	return lerp(jitter, outColor, SharpeningStrength);
}

float4 HQAATAAGenerateBufferJitterPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD) : SV_Target
{
	float2 offsetdir = 0.0.xx;
	if (__HQAA_ALT_FRAME) offsetdir = __HQAA_SM_BUFFERINFO.xy * clamp(HqaaTaaJitterOffset, 0.0, 4.0) * __HQAA_BUFFER_MULT;
	else offsetdir = float2(BUFFER_RCP_WIDTH, -BUFFER_RCP_HEIGHT) * clamp(HqaaTaaJitterOffset, 0.0, 4.0) * __HQAA_BUFFER_MULT;
	return (HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + offsetdir) + HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - offsetdir)) / 2.0;
}

#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
float4 HQAATAATransferJitterTexPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD) : SV_Target
{
	return HQAA_Tex2D(TaaJitterTex0, texcoord);
}

#if HQAA_OPTIONAL__TEMPORAL_AA > 1
float4 HQAATAATransferJitterTexTwoPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD) : SV_Target
{
	return HQAA_Tex2D(TaaJitterTex2, texcoord);
}

#if HQAA_OPTIONAL__TEMPORAL_AA > 2
float4 HQAATAATransferJitterTexThreePS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD) : SV_Target
{
	return HQAA_Tex2D(TaaJitterTex4, texcoord);
}

#if HQAA_OPTIONAL__TEMPORAL_AA > 3
float4 HQAATAATransferJitterTexFourPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD) : SV_Target
{
	return HQAA_Tex2D(TaaJitterTex6, texcoord);
}
#endif
#endif
#endif
#endif //HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE

float4 HQAATAATemporalBlendingPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD) : SV_Target
{
	float edges = HQAATAAEdgeDetectionPS(vpos, texcoord).r;
	float4 original = HQAA_Tex2D(ReShade::BackBuffer, texcoord);
	if (!edges || HqaaDebugMode != 0) return original;
	original = ConditionalDecode(original);
	float4 smaaedges = HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord);
	float upperlimit = (1.0 - saturate(HqaaTaaMinimumBlend));
	float safethreshold = max(__HQAA_EDGE_THRESHOLD, __HQAA_SMALLEST_COLOR_STEP);
	float recorded = clamp(smaaedges.a, __HQAA_SMALLEST_COLOR_STEP, safethreshold);
	float edgestrength = sqrt(edges);
	if (HqaaTaaEdgeHinting && all(smaaedges.rg)) edgestrength = log2(1.0 + edgestrength);
	float lumamult = 1.0;
	if (HqaaTaaThresholdHinting) lumamult = rcp(recorded / safethreshold);
	float blendweight = clamp(edgestrength * lumamult, 0.0, upperlimit) + saturate(HqaaTaaMinimumBlend);
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
	float4 jitter0 = HQAA_Tex2D(TaaJitterTex0, texcoord);
	float4 jitter1 = HQAA_Tex2D(TaaJitterTex1, texcoord);
	float4 temporaljitter = lerp(jitter0, jitter1, saturate(HqaaTaaTemporalWeight));
	if (HqaaTaaSelfSharpen) temporaljitter = HQAATAASelfSharpen(temporaljitter, texcoord, blendweight, edges);
	return ConditionalEncode(lerp(original, temporaljitter, blendweight));
#else
	float4 jitter0 = HQAATAAGenerateBufferJitterPS(vpos, texcoord);
	if (HqaaTaaSelfSharpen) jitter0 = HQAATAASelfSharpen(jitter0, texcoord, blendweight, edges);
	return ConditionalEncode(lerp(original, jitter0, blendweight));
#endif
}

#if HQAA_OPTIONAL__TEMPORAL_AA > 1
float4 HQAATAATemporalBlendingTwoPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD) : SV_Target
{
	float edges = HQAATAAEdgeDetectionPS(vpos, texcoord).r;
	float4 original = HQAA_Tex2D(ReShade::BackBuffer, texcoord);
	if (!edges || HqaaDebugMode != 0) return original;
	original = ConditionalDecode(original);
	float4 smaaedges = HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord);
	float upperlimit = (1.0 - saturate(HqaaTaaMinimumBlend));
	float safethreshold = max(__HQAA_EDGE_THRESHOLD, __HQAA_SMALLEST_COLOR_STEP);
	float recorded = clamp(smaaedges.a, __HQAA_SMALLEST_COLOR_STEP, safethreshold);
	float edgestrength = sqrt(edges);
	if (HqaaTaaEdgeHinting && all(smaaedges.rg)) edgestrength = log2(1.0 + edgestrength);
	float lumamult = 1.0;
	if (HqaaTaaThresholdHinting) lumamult = rcp(recorded / safethreshold);
	float blendweight = clamp(edgestrength * lumamult, 0.0, upperlimit) + saturate(HqaaTaaMinimumBlend);
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
	float4 jitter0 = HQAA_Tex2D(TaaJitterTex2, texcoord);
	float4 jitter1 = HQAA_Tex2D(TaaJitterTex3, texcoord);
	float4 temporaljitter = lerp(jitter0, jitter1, saturate(HqaaTaaTemporalWeight));
	if (HqaaTaaSelfSharpen) temporaljitter = HQAATAASelfSharpen(temporaljitter, texcoord, blendweight, edges);
	return ConditionalEncode(lerp(original, temporaljitter, blendweight));
#else
	float4 jitter0 = HQAATAAGenerateBufferJitterPS(vpos, texcoord);
	if (HqaaTaaSelfSharpen) jitter0 = HQAATAASelfSharpen(jitter0, texcoord, blendweight, edges);
	return ConditionalEncode(lerp(original, jitter0, blendweight));
#endif
}

#if HQAA_OPTIONAL__TEMPORAL_AA > 2
float4 HQAATAATemporalBlendingThreePS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD) : SV_Target
{
	float edges = HQAATAAEdgeDetectionPS(vpos, texcoord).r;
	float4 original = HQAA_Tex2D(ReShade::BackBuffer, texcoord);
	if (!edges || HqaaDebugMode != 0) return original;
	original = ConditionalDecode(original);
	float4 smaaedges = HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord);
	float upperlimit = (1.0 - saturate(HqaaTaaMinimumBlend));
	float safethreshold = max(__HQAA_EDGE_THRESHOLD, __HQAA_SMALLEST_COLOR_STEP);
	float recorded = clamp(smaaedges.a, __HQAA_SMALLEST_COLOR_STEP, safethreshold);
	float edgestrength = sqrt(edges);
	if (HqaaTaaEdgeHinting && all(smaaedges.rg)) edgestrength = log2(1.0 + edgestrength);
	float lumamult = 1.0;
	if (HqaaTaaThresholdHinting) lumamult = rcp(recorded / safethreshold);
	float blendweight = clamp(edgestrength * lumamult, 0.0, upperlimit) + saturate(HqaaTaaMinimumBlend);
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
	float4 jitter0 = HQAA_Tex2D(TaaJitterTex4, texcoord);
	float4 jitter1 = HQAA_Tex2D(TaaJitterTex5, texcoord);
	float4 temporaljitter = lerp(jitter0, jitter1, saturate(HqaaTaaTemporalWeight));
	if (HqaaTaaSelfSharpen) temporaljitter = HQAATAASelfSharpen(temporaljitter, texcoord, blendweight, edges);
	return ConditionalEncode(lerp(original, temporaljitter, blendweight));
#else
	float4 jitter0 = HQAATAAGenerateBufferJitterPS(vpos, texcoord);
	if (HqaaTaaSelfSharpen) jitter0 = HQAATAASelfSharpen(jitter0, texcoord, blendweight, edges);
	return ConditionalEncode(lerp(original, jitter0, blendweight));
#endif
}

#if HQAA_OPTIONAL__TEMPORAL_AA > 3
float4 HQAATAATemporalBlendingFourPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD) : SV_Target
{
	float edges = HQAATAAEdgeDetectionPS(vpos, texcoord).r;
	float4 original = HQAA_Tex2D(ReShade::BackBuffer, texcoord);
	if (!edges || HqaaDebugMode != 0) return original;
	original = ConditionalDecode(original);
	float4 smaaedges = HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord);
	float upperlimit = (1.0 - saturate(HqaaTaaMinimumBlend));
	float safethreshold = max(__HQAA_EDGE_THRESHOLD, __HQAA_SMALLEST_COLOR_STEP);
	float recorded = clamp(smaaedges.a, __HQAA_SMALLEST_COLOR_STEP, safethreshold);
	float edgestrength = sqrt(edges);
	if (HqaaTaaEdgeHinting && all(smaaedges.rg)) edgestrength = log2(1.0 + edgestrength);
	float lumamult = 1.0;
	if (HqaaTaaThresholdHinting) lumamult = rcp(recorded / safethreshold);
	float blendweight = clamp(edgestrength * lumamult, 0.0, upperlimit) + saturate(HqaaTaaMinimumBlend);
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
	float4 jitter0 = HQAA_Tex2D(TaaJitterTex6, texcoord);
	float4 jitter1 = HQAA_Tex2D(TaaJitterTex7, texcoord);
	float4 temporaljitter = lerp(jitter0, jitter1, saturate(HqaaTaaTemporalWeight));
	if (HqaaTaaSelfSharpen) temporaljitter = HQAATAASelfSharpen(temporaljitter, texcoord, blendweight, edges);
	return ConditionalEncode(lerp(original, temporaljitter, blendweight));
#else
	float4 jitter0 = HQAATAAGenerateBufferJitterPS(vpos, texcoord);
	if (HqaaTaaSelfSharpen) jitter0 = HQAATAASelfSharpen(jitter0, texcoord, blendweight, edges);
	return ConditionalEncode(lerp(original, jitter0, blendweight));
#endif
}
#endif // > 3
#endif // > 2
#endif // > 1
#endif //HQAA_OPTIONAL__TEMPORAL_AA

#if HQAA_OPTIONAL__DEBANDING
float3 HQAADebandPS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 encodedori = HQAA_Tex2D(ReShade::BackBuffer, texcoord).rgb; // Original pixel
	float3 ori = ConditionalDecode(encodedori);
	float4 smaadata = HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord);
	
	bool earlyExit = false; 
	if (HqaaDebugMode != 0) earlyExit = true;
	if (HqaaDebandIgnoreLowLuma) earlyExit = earlyExit || (dot(ori, __HQAA_AVERAGE_REF) < (__HQAA_EDGE_THRESHOLD * 0.5));
	if (HqaaDebandUseSmaaData) earlyExit = earlyExit || any(smaadata.rg);
	if (earlyExit) return encodedori;
	
    // Settings
	float pixstep = __HQAA_SMALLEST_COLOR_STEP;
	float edgethreshold = __HQAA_EDGE_THRESHOLD * (1.0 - __HQAA_DYNAMIC_RANGE);
#if (__RENDERER__ >= 0x10000 && __RENDERER__ < 0x20000) || (__RENDERER__ >= 0x09000 && __RENDERER__ < 0x0A000)
	float avgdiff, maxdiff, middiff;
	if (HqaaDebandPreset == 1) { avgdiff = 0.6 * pixstep; maxdiff = 1.9 * pixstep; middiff = 1.2 * pixstep; }
	else if (HqaaDebandPreset == 2) { avgdiff = 1.8 * pixstep; maxdiff = 4.0 * pixstep; middiff = 2.0 * pixstep; }
	else if (HqaaDebandPreset == 3) { avgdiff = 3.4 * pixstep; maxdiff = 6.8 * pixstep; middiff = 3.3 * pixstep; }
	else if (HqaaDebandPreset == 4) { avgdiff = 4.9 * pixstep; maxdiff = 9.5 * pixstep; middiff = 4.7 * pixstep; }
	else if (HqaaDebandPreset == 5) { avgdiff = 7.1 * pixstep; maxdiff = 13.3 * pixstep; middiff = 6.3 * pixstep; }
	else { avgdiff = edgethreshold * 0.38; maxdiff = edgethreshold * 0.75; middiff = edgethreshold * 0.36; }
#else
    float avgdiff[6] = {0.38 * edgethreshold, 1.1 * pixstep, 1.8 * pixstep, 3.4 * pixstep, 4.9 * pixstep, 7.1 * pixstep}; // 0.6/255, 1.8/255, 3.4/255
    float maxdiff[6] = {0.75 * edgethreshold, 2.5 * pixstep, 4.0 * pixstep, 6.8 * pixstep, 9.5 * pixstep, 13.3 * pixstep}; // 1.9/255, 4.0/255, 6.8/255
    float middiff[6] = {0.36 * edgethreshold, 1.5 * pixstep, 2.0 * pixstep, 3.3 * pixstep, 4.7 * pixstep, 6.3 * pixstep}; // 1.2/255, 2.0/255, 3.3/255
#endif

    float randomseed = HqaaDebandSeed / 32767.0;
    float h = permute(float2(permute(float2(texcoord.x, randomseed)), permute(float2(texcoord.y, randomseed))));

    float dir = frac(permute(h) / 41.0) * 6.2831853;
    float2 angle = float2(cos(dir), sin(dir));

    float2 dist = frac(h / 41.0) * clamp(HqaaDebandRange, 1, 128) * BUFFER_PIXEL_SIZE;

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
}
#endif //HQAA_OPTIONAL__DEBANDING

#if HQAA_OPTIONAL__SOFTENING
float3 HQAASofteningPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 original = HQAA_Tex2D(ReShade::BackBuffer, texcoord).rgb;
	if (HqaaDebugMode != 0) return original;
    float4 edgedata = HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord);
	bool lowdetail = !any(edgedata.rg);
    bool horiz = edgedata.g;
    bool possiblediag = lowdetail ? false : all(edgedata.rg);
    bool diag = false;
	float2 pixstep = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT) * (lowdetail ? (clamp(HqaaImageSoftenOffset, 0.0, 4.0) * 0.5) : clamp(HqaaImageSoftenOffset, 0.0, 4.0)) * __HQAA_BUFFER_MULT;
	float2 pixstepdiag = pixstep * __HQAA_CONST_HALFROOT2;
	bool highdelta = false;
	
	if (possiblediag)
	{
		bool4 nearbydiags = bool4(all(HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord + float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT))), all(HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord - float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT))), all(HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord + float2(-BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT))), all(HQAA_Tex2D(HQAAsamplerAlphaEdges, texcoord + float2(BUFFER_RCP_WIDTH, -BUFFER_RCP_HEIGHT))));
		diag = any(nearbydiags);
	}
	
// pattern:
//  e f g
//  h a b
//  i c d
	
	float3 a = ConditionalDecode(original);
	float3 b = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(pixstep.x, 0)).rgb;
	float3 c = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(0, pixstep.y)).rgb;
	float3 d = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + pixstepdiag).rgb;
	float3 e = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - pixstepdiag).rgb;
	float3 f = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - float2(0, pixstep.y)).rgb;
	float3 g = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(pixstepdiag.x, -pixstepdiag.y)).rgb;
	float3 h = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord - float2(pixstep.x, 0)).rgb;
	float3 i = HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord + float2(-pixstepdiag.x, pixstepdiag.y)).rgb;
	
	if (HqaaSoftenerSpuriousDetection)
	{
    	float spuriousthreshold = rcp(__HQAA_EDGE_THRESHOLD / edgedata.a) * saturate(HqaaSoftenerSpuriousThreshold);
		float3 surroundavg = (b + c + d + e + f + g + h + i) / 8.0;
		float middledelta = dot(abs(a - surroundavg), __HQAA_LUMA_REF);
		highdelta = middledelta > spuriousthreshold;
	}
	
	if (HqaaSoftenerSpuriousDetection && !highdelta && (HqaaImageSoftenStrength == 0.0)) return original;
	
	float3 highterm = float3(0.0, 0.0, 0.0);
	float3 lowterm = float3(1.0, 1.0, 1.0);
	
	float3 diag1;
	float3 diag2;
	float3 square;
	if (diag)
	{
		square = (h + f + c + b) / 4.0;
		diag1 = (e + d) / 2.0;
		diag2 = (g + i) / 2.0;
		highterm = HQAAmax3(highterm, diag1, diag2);
		lowterm = HQAAmin3(lowterm, diag1, diag2);
	}
	else square = (e + g + i + d) / 4.0;
	
	float3 x1;
	float3 x2;
	float3 x3;
	float3 xy1;
	float3 xy2;
	float3 xy3;
	float3 xy4;
	float3 box = (e + f + g + h + b + i + c + d) / 8.0;
	
	if (lowdetail)
	{
		x1 = (f + a + c) / 3.0;
		x2 = (h + a + b) / 3.0;
		x3 = (a + e + f + g + h + b + i + c + d) / 9.0;
		xy1 = (e + a + d) / 3.0;
		xy2 = (i + a + g) / 3.0;
		xy3 = (e + f + g + i + c + d) / 6.0;
		xy4 = (e + h + i + g + b + d) / 6.0;
		square = (e + g + i + d + a) / 5.0;
	}
	else if (!horiz)
	{
		x1 = (e + h + i) / 3.0;
		x2 = (f + a + c) / 3.0;
		x3 = (g + b + d) / 3.0;
		xy1 = (e + a + c) / 3.0;
		xy2 = (g + a + c) / 3.0;
		xy3 = (f + a + i) / 3.0;
		xy4 = (f + a + d) / 3.0;
	}
	else
	{
		x1 = (e + f + g) / 3.0;
		x2 = (h + a + b) / 3.0;
		x3 = (i + c + d) / 3.0;
		xy1 = (h + a + g) / 3.0;
		xy2 = (h + a + d) / 3.0;
		xy3 = (b + a + e) / 3.0;
		xy4 = (b + a + i) / 3.0;
	}
	
	highterm = HQAAmax10(x1, x2, x3, xy1, xy2, xy3, xy4, box, square, highterm);
	lowterm = HQAAmin10(x1, x2, x3, xy1, xy2, xy3, xy4, box, square, lowterm);
	
	float3 localavg;
	if (!diag) localavg = ((x1 + x2 + x3 + xy1 + xy2 + xy3 + xy4 + square + box) - (highterm + lowterm)) / 7.0;
	else localavg = ((x1 + x2 + x3 + xy1 + xy2 + xy3 + xy4 + square + box + diag1 + diag2) - (highterm + lowterm)) / 9.0;
	
	return lerp(original, ConditionalEncode(localavg), (highdelta ? clamp(HqaaSoftenerSpuriousStrength, 0.0, 4.0) : saturate(HqaaImageSoftenStrength)));
}
#endif //HQAA_OPTIONAL__SOFTENING

#if HQAA_OLED_ANTI_BURN_IN
float3 HQAALumaStrobePS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	if (HqaaDebugMode != 0) return HQAA_Tex2D(ReShade::BackBuffer, texcoord).rgb;
	if (__HQAA_THIRD_FRAME) return HQAA_Tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 pixel = RGBtoYUV(HQAA_DecodeTex2D(ReShade::BackBuffer, texcoord).rgb);
	float strobeadd = (1.0 - pixel.x) * saturate(HqaaOledStrobeStrength);
	float strobesubtract = pixel.x * saturate(HqaaOledStrobeStrength);
	if (__HQAA_ALT_FRAME && (strobeadd > strobesubtract)) pixel.x += strobeadd;
	else if (strobesubtract >= strobeadd) pixel.x -= strobesubtract;
	return ConditionalEncode(YUVtoRGB(pixel));
}
#endif //HQAA_OLED_ANTI_BURN_IN

#if HQAA_SPLITSCREEN_PREVIEW
float4 HQAABufferCopyPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return HQAA_Tex2D(ReShade::BackBuffer, texcoord);
}

float4 HQAASplitScreenPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float leftbound = HqaaSplitscreenPosition - BUFFER_RCP_WIDTH;
	float rightbound = HqaaSplitscreenPosition + BUFFER_RCP_WIDTH;
	if (clamp(texcoord.x, leftbound, rightbound) == texcoord.x) return 0.0;
	if ((texcoord.x > HqaaSplitscreenPosition) && HqaaSplitscreenFlipped) return HQAA_Tex2D(OriginalBuffer, texcoord);
	if ((texcoord.x < HqaaSplitscreenPosition) && !HqaaSplitscreenFlipped) return HQAA_Tex2D(OriginalBuffer, texcoord);
	return HQAA_Tex2D(ReShade::BackBuffer, texcoord);
}
#endif //HQAA_SPLITSCREEN_PREVIEW
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
#if HQAA_SPLITSCREEN_PREVIEW
	pass CopyBuffer
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAABufferCopyPS;
		RenderTarget = HQAAOriginalBufferTex;
		ClearRenderTargets = true;
	}
#endif
	pass EdgeDetection
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAHybridEdgeDetectionPS;
		RenderTarget = HQAAedgesTex;
	}
#if !HQAA_DISABLE_SMAA
	pass SMAABlendCalculation
	{
		VertexShader = HQAABlendingWeightCalculationVS;
		PixelShader = HQAABlendingWeightCalculationPS;
		RenderTarget = HQAAblendTex;
		ClearRenderTargets = true;
	}
#endif //HQAA_DISABLE_SMAA
#if !HQAA_DISABLE_SMAA
	pass SMAABlending
	{
		VertexShader = HQAANeighborhoodBlendingVS;
		PixelShader = HQAANeighborhoodBlendingPS;
	}
#endif //HQAA_DISABLE_SMAA
#if HQAA_FXAA_MULTISAMPLING > 0
	pass FXAA
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAAFXPS;
	}
#endif //HQAA_FXAA_MULTISAMPLING
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
#endif
#endif
#endif
#if HQAA_OPTIONAL__TEMPORAL_AA
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
	pass TAACreateJitter
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAATAAGenerateBufferJitterPS;
		RenderTarget = HqaaTaaJitterTex0;
		ClearRenderTargets = true;
	}
#endif
	pass TAABlending
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAATAATemporalBlendingPS;
	}
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
	pass TAAJitterTransfer
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAATAATransferJitterTexPS;
		RenderTarget = HqaaTaaJitterTex1;
		ClearRenderTargets = true;
	}
#endif
#endif
#if HQAA_OPTIONAL__TEMPORAL_AA
#if HQAA_OPTIONAL__TEMPORAL_AA > 1
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
	pass TAACreateJitter
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAATAAGenerateBufferJitterPS;
		RenderTarget = HqaaTaaJitterTex2;
		ClearRenderTargets = true;
	}
#endif
	pass TAABlending
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAATAATemporalBlendingTwoPS;
	}
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
	pass TAAJitterTransfer
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAATAATransferJitterTexTwoPS;
		RenderTarget = HqaaTaaJitterTex3;
		ClearRenderTargets = true;
	}
#endif
#if HQAA_OPTIONAL__TEMPORAL_AA > 2
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
	pass TAACreateJitter
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAATAAGenerateBufferJitterPS;
		RenderTarget = HqaaTaaJitterTex4;
		ClearRenderTargets = true;
	}
#endif
	pass TAABlending
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAATAATemporalBlendingThreePS;
	}
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
	pass TAAJitterTransfer
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAATAATransferJitterTexThreePS;
		RenderTarget = HqaaTaaJitterTex5;
		ClearRenderTargets = true;
	}
#endif
#if HQAA_OPTIONAL__TEMPORAL_AA > 3
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
	pass TAACreateJitter
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAATAAGenerateBufferJitterPS;
		RenderTarget = HqaaTaaJitterTex6;
		ClearRenderTargets = true;
	}
#endif
	pass TAABlending
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAATAATemporalBlendingFourPS;
	}
#if HQAA_OPTIONAL__TEMPORAL_AA_PERSISTENCE
	pass TAAJitterTransfer
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAATAATransferJitterTexFourPS;
		RenderTarget = HqaaTaaJitterTex7;
		ClearRenderTargets = true;
	}
#endif
#endif //3
#endif //2
#endif //1
#endif //HQAA_OPTIONAL__TEMPORAL_AA
#if HQAA_OPTIONAL__SOFTENING
	pass ImageSoftening
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAASofteningPS;
	}
#if HQAA_OPTIONAL__SOFTENING > 1
	pass ImageSoftening
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAASofteningPS;
	}
#if HQAA_OPTIONAL__SOFTENING > 2
	pass ImageSoftening
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAASofteningPS;
	}
#if HQAA_OPTIONAL__SOFTENING > 3
	pass ImageSoftening
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAASofteningPS;
	}
#endif
#endif
#endif
#endif //HQAA_OPTIONAL__SOFTENING
	pass Hysteresis
	{
		VertexShader = HQAANeighborhoodBlendingVS;
		PixelShader = HQAAPostProcessPS;
	}
#if HQAA_OPTIONAL__DEBANDING
	pass Deband
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAADebandPS;
	}
#if HQAA_OPTIONAL__DEBANDING > 1
	pass Deband
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAADebandPS;
	}
#if HQAA_OPTIONAL__DEBANDING > 2
	pass Deband
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAADebandPS;
	}
#if HQAA_OPTIONAL__DEBANDING > 3
	pass Deband
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAADebandPS;
	}
#endif //HQAA_OPTIONAL__DEBANDING_PASSES 3
#endif //HQAA_OPTIONAL__DEBANDING_PASSES 2
#endif //HQAA_OPTIONAL__DEBANDING_PASSES 1
#endif //HQAA_OPTIONAL__DEBANDING
#if HQAA_OLED_ANTI_BURN_IN
	pass OLEDAntiBurninStrobe
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAALumaStrobePS;
	}
#endif //HQAA_OLED_ANTI_BURN_IN
#if HQAA_SPLITSCREEN_PREVIEW
	pass SplitScreenPreview
	{
		VertexShader = PostProcessVS;
		PixelShader = HQAASplitScreenPS;
	}
#endif //HQAA_SPLITSCREEN_PREVIEW
}
