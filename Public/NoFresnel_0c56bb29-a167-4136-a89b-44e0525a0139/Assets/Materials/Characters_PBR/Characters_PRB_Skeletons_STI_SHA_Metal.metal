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
	float4 InstanceMatrix1 COLOR1;
	float4 InstanceMatrix2 COLOR2;
	float4 InstanceMatrix3 COLOR3;
	float2 TexCoords0 TEXCOORD0;
} VertexInput;

typedef struct
{
	float4 ProjectedPosition [[position]];
	float2 TexCoords0;
	float ShadowDepth;
} VertexOutput;


vertex VertexOutput Characters_PBR_Characters_PRB_Skeletons_STI_SHA_Metal_vertexMain(constant PerView& perView [[buffer(5)]],
	VertexInput In [[stage_in]])
{
	VertexOutput Out;

	//Create Instance World Matrix
	float4 col1 = float4(In.InstanceMatrix1.x, In.InstanceMatrix1.y, In.InstanceMatrix1.z, 0.0f);
	float4 col2 = float4(In.InstanceMatrix1.w, In.InstanceMatrix2.x, In.InstanceMatrix2.y, 0.0f);
	float4 col3 = float4(In.InstanceMatrix2.z, In.InstanceMatrix2.w, In.InstanceMatrix3.x, 0.0f);
	float4 col4 = float4(In.InstanceMatrix3.y, In.InstanceMatrix3.z, In.InstanceMatrix3.w, 1.0f);
	float4x4 WorldMatrix = float4x4(col1, col2, col3, col4);

	//World space position
	float4 worldPosition = (WorldMatrix * float4(In.Position, 1.0f));

	//Projected position
	float4 projectedPosition = (perView.global_ViewProjection * worldPosition);

	//Pass projected position to pixel shader
	Out.ProjectedPosition = projectedPosition;

	Out.TexCoords0 = In.TexCoords0;
	float vertexDepth;
	vertexDepth = distance(worldPosition.xyz, perView.global_ViewPos.xyz);
	//Pass depth to pixel shader
	Out.ShadowDepth = vertexDepth;


	return Out;
}


//[Fragment shader]



typedef struct
{
	float4 Color0 [[color(0)]];
} PixelOutput;


static void CalculateMatOpacity(float2 in_0,
	thread float& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_MSKskin_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_basecolor_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_MSKskin_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Get needed components
	float Local1 = Local0.x;
	float Local2 = Local0.y;
	float Local3 = (1.0f - Local1);
	float4 Local4 = Texture2DParameter_basecolor_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local4] Get needed components
	float3 Local5 = Local4.xyz;
	float Local6 = Local4.w;
	float Local7 = (Local3 * Local6);
	float Local8 = (Local7 * 0.8f);
	out_0 = Local8;
}

fragment PixelOutput Characters_PBR_Characters_PRB_Skeletons_STI_SHA_Metal_fragmentMain(VertexOutput In [[stage_in]],
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_MSKskin_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_basecolor_DefaultWrapSampler)
{
	PixelOutput Out;

	float matOpacity;
	CalculateMatOpacity(In.TexCoords0, matOpacity, _DefaultWrapSampler, Texture2DParameter_MSKskin_DefaultWrapSampler, Texture2DParameter_basecolor_DefaultWrapSampler);
	if ((matOpacity - 0.5f) < 0) discard_fragment();

	float Local0 = dfdx(In.ShadowDepth);
	float Local1 = dfdy(In.ShadowDepth);
	Out.Color0 = float4(0.0f, 0.0f, 0.0f, 0.0f);
	Out.Color0.x = In.ShadowDepth;
	Out.Color0.y = ((In.ShadowDepth * In.ShadowDepth) + (((Local0 * Local0) + (Local1 * Local1)) * 0.25f));

	return Out;
}
