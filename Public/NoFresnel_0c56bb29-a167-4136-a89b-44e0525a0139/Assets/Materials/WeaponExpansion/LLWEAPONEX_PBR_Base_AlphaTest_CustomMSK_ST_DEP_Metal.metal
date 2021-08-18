//[Vertex shader]


#define __HAVE_MATRIX_MULTIPLE_SCALAR_CONSTRUCTORS__
#include <metal_stdlib>

using namespace metal;

#include "Shaders/Metal/CommonHelpers.shdh"
#include "Shaders/GlobalConstants_MTL.shdh"
#include "Shaders/GlobalConstants_PS_MTL.shdh"

typedef struct
{
	float3 Position SV_POSITION0;
	float2 TexCoords0 TEXCOORD0;
} VertexInput;

typedef struct
{
	float4 ProjectedPosition [[position]];
	float2 TexCoords0;
} VertexOutput;

struct LocalUniformsVS
{
	float4x4 WorldMatrix;
};

vertex VertexOutput WeaponExpansion_LLWEAPONEX_PBR_Base_AlphaTest_CustomMSK_ST_DEP_Metal_vertexMain(constant LocalUniformsVS& uniforms [[buffer(5)]],
	constant PerView& perView [[buffer(6)]],
	VertexInput In [[stage_in]])
{
	VertexOutput Out;

	//World space position
	float4 worldPosition = (uniforms.WorldMatrix * float4(In.Position, 1.0f));

	//Projected position
	float4 projectedPosition = (perView.global_ViewProjection * worldPosition);

	//Pass projected position to pixel shader
	Out.ProjectedPosition = projectedPosition;

	Out.TexCoords0 = In.TexCoords0;

	return Out;
}


//[Fragment shader]



typedef struct
{
} PixelOutput;


static void CalculateMatOpacity(float2 in_0,
	thread float& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_basecolor_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_basecolor_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Get needed components
	float3 Local1 = Local0.xyz;
	float Local2 = Local0.w;
	out_0 = Local2;
}

fragment PixelOutput WeaponExpansion_LLWEAPONEX_PBR_Base_AlphaTest_CustomMSK_ST_DEP_Metal_fragmentMain(VertexOutput In [[stage_in]],
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_basecolor_DefaultWrapSampler)
{
	PixelOutput Out;

	float matOpacity;
	CalculateMatOpacity(In.TexCoords0, matOpacity, _DefaultWrapSampler, Texture2DParameter_basecolor_DefaultWrapSampler);
	if ((matOpacity - 0.5f) < 0) discard_fragment();


	return Out;
}
