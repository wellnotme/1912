/*
	Credits :: icelaglace, a.o => (ported from some blog, author unknown)
	Credits :: Pascal aka Marty McFly
	Amateur port by Insomnia 
	Modified by Marot for ReShade 4.0 compatibility.
*/

#include "ReShade.fxh"
#include "TriDither.fxh"
#define MIT
#define USEMACROS

FLOAT_S1(fFisheyeZoom, "Fish Eye Zoom", "Lens zoom to hide bugged edges due to texcoord modification", 0.5, 1.0, 0.55, 0)
FLOAT_S1(fFisheyeDistortion, "Fisheye Distortion", "Distortion of image", -0.300, 0.300, 0.01, 0)
FLOAT_S1(fFisheyeDistortionCubic, "Fisheye Distortion Cubic", "Distortion of image, cube based", -0.300, 0.300, 0.7, 0)
FLOAT_S1(fFisheyeColorshift, "Colorshift", "Amount of color shifting", -0.300, 0.300, 0.002	, 0)
LICENSE_MIT()

/*
uniform float fFisheyeZoom <
	ui_type = "slider";
	ui_min = 0.5; ui_max = 1.0;
	ui_label = "Fish Eye Zoom";
	ui_tooltip = "Lens zoom to hide bugged edges due to texcoord modification";
> = 0.55;
uniform float fFisheyeDistortion <
	ui_type = "slider";
	ui_min = -0.300; ui_max = 0.300;
	ui_label = "Fisheye Distortion";
	ui_tooltip = "Distortion of image";
> = 0.01;
uniform float fFisheyeDistortionCubic <
	ui_type = "slider";
	ui_min = -0.300; ui_max = 0.300;
	ui_label = "Fisheye Distortion Cubic";
	ui_tooltip = "Distortion of image, cube based";
> = 0.7;
uniform float fFisheyeColorshift <
	ui_type = "slider";
	ui_min = -0.10; ui_max = 0.10;
	ui_label = "Colorshift";
	ui_tooltip = "Amount of color shifting";
> = 0.002;
*/

float3 FISHEYE_Horiz_CAPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	float4 coord=0.0;
	coord.xy=texcoord.xy;
	coord.w=0.0;

	color.rgb = 0.0;
	  
	float3 eta = float3(1.0+fFisheyeColorshift*0.9,1.0+fFisheyeColorshift*0.6,1.0+fFisheyeColorshift*0.3);
	float2 center;
	center.x = coord.x-0.5;
	center.y = coord.y-0.5;
	float LensZoom = 1.0/fFisheyeZoom;

	float r2 = (texcoord.y-0.5) * (texcoord.y-0.5);// + (texcoord.y-0.5) * (texcoord.y-0.5);
	float f = 0;

	if( fFisheyeDistortionCubic == 0.0){
		f = 1 + r2 * fFisheyeDistortion;
	}else{
                f = 1 + r2 * (fFisheyeDistortion + fFisheyeDistortionCubic * sqrt(r2));
	};

	float x = f*LensZoom*(coord.x-0.5)+0.5;
	float y = f*LensZoom*(coord.y-0.5)+0.5;
	float2 rCoords = (f*eta.r)*LensZoom*(center.xy*0.5)+0.5;
	float2 gCoords = (f*eta.g)*LensZoom*(center.xy*0.5)+0.5;
	float2 bCoords = (f*eta.b)*LensZoom*(center.xy*0.5)+0.5;
	
	color.x = tex2D(ReShade::BackBuffer,rCoords).r;
	color.y = tex2D(ReShade::BackBuffer,gCoords).g;
	color.z = tex2D(ReShade::BackBuffer,bCoords).b;
	color.xyz += TriDither(color.xyz, texcoord, 8);
	
	return color.rgb;

}

float3 FISHEYE_Verti_CAPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	float4 coord=0.0;
	coord.xy=texcoord.xy;
	coord.w=0.0;

	color.rgb = 0.0;
	  
	float3 eta = float3(1.0+fFisheyeColorshift*0.9,1.0+fFisheyeColorshift*0.6,1.0+fFisheyeColorshift*0.3);
	float2 center;
	center.x = coord.x-0.5;
	center.y = coord.y-0.5;
	float LensZoom = 1.0/fFisheyeZoom;

	float r2 = (texcoord.x-0.5) * (texcoord.x-0.5);// + (texcoord.y-0.5) * (texcoord.y-0.5);
	float f = 0;

	if( fFisheyeDistortionCubic == 0.0){
		f = 1 + r2 * fFisheyeDistortion;
	}else{
                f = 1 + r2 * (fFisheyeDistortion + fFisheyeDistortionCubic * sqrt(r2));
	};

	float x = f*LensZoom*(coord.x-0.5)+0.5;
	float y = f*LensZoom*(coord.y-0.5)+0.5;
	float2 rCoords = (f*eta.r)*LensZoom*(center.xy*0.5)+0.5;
	float2 gCoords = (f*eta.g)*LensZoom*(center.xy*0.5)+0.5;
	float2 bCoords = (f*eta.b)*LensZoom*(center.xy*0.5)+0.5;
	
	color.x = tex2D(ReShade::BackBuffer,rCoords).r;
	color.y = tex2D(ReShade::BackBuffer,gCoords).g;
	color.z = tex2D(ReShade::BackBuffer,bCoords).b;
	color.xyz += TriDither(color.xyz, texcoord, 8);
	
	return color.rgb;

}

technique FISHEYE_PLUS < ui_label = "Lens Distortion"; >
{	
	pass horizontal
	{
		VertexShader = PostProcessVS;
		PixelShader = FISHEYE_Horiz_CAPass;
	}

	pass vertical
	{
		VertexShader = PostProcessVS;
		PixelShader = FISHEYE_Verti_CAPass;
	}
}