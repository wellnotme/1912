
//////////////////////////////////////////////////
//                                              //
//    ▄▄███    ▄██████▄   ▄▄███   ▄██████▄▄     //
//    █████   ████  ████  █████  ▐██▌  ████▌    //
//     ▐███   ▀███▄▄█████  ▐███   ▀▀▀ ▄████     //
//     ▐███      ▀▀▀█████  ▐███    ▄███▀▀▀      //
//    ▄████▄▄ ▐██▌  ████  ▄████▄▄ ▐█████▄▄██▌   //
//   ▐███████  ▀▀█████▀  ▐███████ ▐█▀▀▀████▀    //
//          1912 SHADER REPO by 𝐬𝐢𝐥𝐯𝐞𝐫           //
//////////////////////////////////////////////////

#include "ReShade.fxh"
#include "TriDither.fxh"
#include "Comment.fxh"
#define MIT
#define USEMACROS

LICENSE_MIT()
RADIO2(Mode, "Curve Mode", 1, "Pick your tonemap mode!", 0, "sRGB\0Linear\0Log")

float3 SRGBToLinear(float3 SRGB)
{
    return (SRGB < 0.04045)
        ? SRGB / 12.92
        : pow(abs((SRGB + 0.055) / 1.055), 2.4);
}
float3 LinearToLog(float3 LinearColor)
{
    float3 LogColor;
    // Apply Cineon / REDlogfilm curve
    LogColor = (300.0 * log10(LinearColor * (1 - 0.0108) + 0.0108) + 685.0) / 1023.0;
    // Return the LOG output
    return saturate(LogColor);
}

float3 AdjustColorPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    if(Mode != 1);
    float3 pixelColor = tex2D(ReShade::BackBuffer, texcoord).rgb;
    if(Mode == 2)
    pixelColor  = SRGBToLinear(pixelColor);
    if(mode == 3)
    pixelColor  = LinearToLog(pixelColor);
    pixelColor += TriDither(pixelColor.rgb, texcoord, 8).rgb;
    return pixelColor;
}


technique sRGB2Log
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = AdjustColorPass;
    }
}
