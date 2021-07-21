//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
// visit facebook.com/MartyMcModding for news/updates
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Marty's LUT shader 1.0 for ReShade 3.0
// Copyright © 2008-2016 Marty McFly
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Feature by voltamage and Lord of Lunacy
// Implemented TriDither.fxh to remove banding
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Implemented Gamma and output value controls
// Feature by silver and Prod80
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


#ifndef pLUT_TextureName
	#define pLUT_TextureName "lut.png"
#endif
#ifndef pLUT_TileSizeXY
	#define pLUT_TileSizeXY 32
#endif
#ifndef pLUT_TileAmount
	#define pLUT_TileAmount 32
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShadeUI.fxh"
#include "TriDither.fxh"
#include "Comment.fxh"
#define MIT
#define USEMACROS

FLOAT_D1(pLUT_AmountChroma, "LUT++ Chroma", "Intensity of color/chroma change of the LUT.", 0.00, 1.00, 1.00, 0)
FLOAT_D1(pLUT_AmountLuma, "LUT++ Luma", "Intensity of luma change of the LUT.", 0.00, 1.00, 1.00, 0)
COLOR(ob, "LUT++ Black OUT Level", "LUT++ Black OUT Level", 0, 0, 0, 0)
COLOR(ow, "LUT++ White OUT Level", "LUT++ White OUT Level", 255, 255, 255, 0)
FLOAT_D1(ig, "LUT++ Gamma", "LUT++ Gamma", 0.05, 10.00, 1.00, 0)

/*
uniform float pLUT_AmountChroma <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "LUT++ Chroma";
	ui_tooltip = "Intensity of color/chroma change of the LUT.";
> = 1.00;

uniform float pLUT_AmountLuma <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "LUT++ Luma";
	ui_tooltip = "Intensity of luma change of the LUT.";
> = 1.00;

uniform float3 ob <
    ui_type = "color";
    ui_label = "LUT Black OUT Level";
    ui_tooltip = "LUT Black OUT Level";
    ui_category = "Advanced Controls";
> = float3(0.0, 0.0, 0.0);

uniform float3 ow <
    ui_type = "color";
    ui_label = "LUT White OUT Level";
    ui_tooltip = "LUT White OUT Level";
    ui_category = "Advanced Controls";
> = float3(1.0, 1.0, 1.0);

uniform float ig <
    ui_label = "LUT Gamma Adjustment";
    ui_tooltip = "LUT Gamma Adjustment";
    ui_category = "Advanced Controls";
    ui_type = "slider";
    ui_min = 0.05;
    ui_max = 10.0;
> = 1.0;
*/
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"
texture texLUT < source = pLUT_TextureName; > { Width = pLUT_TileSizeXY*pLUT_TileAmount; Height = pLUT_TileSizeXY; Format = RGBA8; };
sampler SamplerLUT 	{ Texture = texLUT; };

float3 levels( float3 color, float gamma, float3 outblack, float3 outwhite )
{
	float3 blackin   = (0, 0, 0);
	float3 whitein   = (1, 1, 1);

    float3 ret       = saturate( color.xyz - blackin.xyz ) / max( whitein.xyz - blackin.xyz, 0.000001f );
    ret.xyz          = pow( ret.xyz, gamma );
    ret.xyz          = ret.xyz * saturate( outwhite.xyz - outblack.xyz ) + outblack.xyz;
    return ret;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_LUT_Apply(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_Target0)
{
	float4 color = tex2D(ReShade::BackBuffer, texcoord.xy);
	float2 texelsize = 1.0 / pLUT_TileSizeXY;
	texelsize.x /= pLUT_TileAmount;

	float3 lutcoord = float3((color.xy*pLUT_TileSizeXY-color.xy+0.5)*texelsize.xy,color.z*pLUT_TileSizeXY-color.z);
	float lerpfact = frac(lutcoord.z);
	lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;

	float3 lutcolor = lerp(tex2D(SamplerLUT, lutcoord.xy).xyz, tex2D(SamplerLUT, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);

	color.xyz = lerp (normalize(color.xyz), normalize(lutcolor.xyz), pLUT_AmountChroma) * 
	            lerp (length(color.xyz),    length(lutcolor.xyz),    pLUT_AmountLuma);
	color.xyz = levels( color.xyz, ig, ob, ow );

	res.xyz = color.xyz;
	res.w = 1.0;

	color.rgb += TriDither(color.rgb, texcoord, 8).rgb;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


technique LUTplus < ui_label = "LUT++"; 
ui_tooltip =   "LUT++ is a modified version of LUTplus.fx\n "
			   "       Which was based on LUT.fx\n\n        "
			   "It adds dithering through TriDither.fxh\n   "
			   " to reduce image banding and artifacts\n    "
			   "Along with that, it adds Gamma controls.\n\n"
			   "  TriDither.fxh by The Sandvich Maker\n     "
			   "      Function call by voltamage\n          "
			   "      Bugfixes by Lord of Lunacy\n          "
			   "       Gamma Controls by Prod80\n           "
; >
{
	pass LUT_Apply
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_LUT_Apply;
	}
}
