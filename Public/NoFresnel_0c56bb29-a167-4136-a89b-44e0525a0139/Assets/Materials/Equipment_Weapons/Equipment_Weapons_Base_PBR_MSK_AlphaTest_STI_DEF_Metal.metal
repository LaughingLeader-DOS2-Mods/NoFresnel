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
	float4 LocalQTangent NORMAL0;
} VertexInput;

typedef struct
{
	float4 ProjectedPosition [[position]];
	float2 TexCoords0;
	float3 WorldNormal;
	float3 WorldBinormal;
	float3 WorldTangent;
} VertexOutput;


vertex VertexOutput Equipment_Weapons_Equipment_Weapons_Base_PBR_MSK_AlphaTest_STI_DEF_Metal_vertexMain(constant PerView& perView [[buffer(5)]],
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
	//Compute local tangent frame
	float3x3 LocalTangentFrame = GetTangentFrame(In.LocalQTangent);

	float3 LocalNormal = LocalTangentFrame[2];

	//Normalize Local Normal
	float3 localNormalNormalized = normalize(LocalNormal);

	//World space Normal
	float3 worldNormal = (float3x3(WorldMatrix[0].xyz, WorldMatrix[1].xyz, WorldMatrix[2].xyz) * localNormalNormalized);

	//Normalize World Normal
	float3 worldNormalNormalized = normalize(worldNormal);

	Out.WorldNormal = worldNormalNormalized;

	float3 LocalBinormal = LocalTangentFrame[1];

	//Normalize Local Binormal
	float3 localBinormalNormalized = normalize(LocalBinormal);

	//World space Binormal
	float3 worldBinormal = (float3x3(WorldMatrix[0].xyz, WorldMatrix[1].xyz, WorldMatrix[2].xyz) * localBinormalNormalized);

	//Normalize World Binormal
	float3 worldBinormalNormalized = normalize(worldBinormal);

	Out.WorldBinormal = worldBinormalNormalized;

	float3 LocalTangent = LocalTangentFrame[0];

	//Normalize Local Tangent
	float3 localTangentNormalized = normalize(LocalTangent);

	//World space Tangent
	float3 worldTangent = (float3x3(WorldMatrix[0].xyz, WorldMatrix[1].xyz, WorldMatrix[2].xyz) * localTangentNormalized);

	//Normalize World Tangent
	float3 worldTangentNormalized = normalize(worldTangent);

	Out.WorldTangent = worldTangentNormalized;


	return Out;
}


//[Fragment shader]


#include "Shaders/Metal/PBR.shdh"

typedef struct
{
	float4 Color0 [[color(0)]];
	float4 Color1 [[color(1)]];
	float4 Color2 [[color(2)]];
	float4 Color3 [[color(3)]];
} PixelOutput;

struct LocalUniformsPS
{
	float4 Vector4Parameter_Color3;
	float4 Vector4Parameter_Color4;
	float4 Vector4Parameter_Color5;
	float _OpacityFade;
};

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

static void CalculateMatNormal(float2 in_0,
	thread float3& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_normalmap_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_normalmap_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Convert normalmaps to tangent space vectors
	Local0.xyzw = Local0.wzyx;
	Local0.xyz = ((Local0.xyz * 2.0f) - 1.0f);
	Local0.z = -(Local0.z);
	Local0.xyz = normalize(Local0.xyz);
	//[Local0] Get needed components
	float3 Local1 = Local0.xyz;
	out_0 = Local1;
}

static void CalculateMatBaseColor(constant LocalUniformsPS& uniforms,
	float2 in_0,
	thread float3& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_basecolor_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_MSKcloth_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_MSKcloth_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Get needed components
	float Local1 = Local0.x;
	float Local2 = Local0.y;
	float Local3 = Local0.z;
	float4 Local4 = (uniforms.Vector4Parameter_Color3 * Local1);
	float4 Local5 = (uniforms.Vector4Parameter_Color4 * Local2);
	float4 Local6 = (Local4 + Local5);
	float4 Local7 = (uniforms.Vector4Parameter_Color5 * Local3);
	float4 Local8 = (Local6 + Local7);
	float Local9 = (1.0f - Local1);
	float Local10 = (1.0f - Local2);
	float Local11 = (Local9 * Local10);
	float Local12 = (1.0f - Local3);
	float Local13 = (Local11 * Local12);
	float Local14 = pow(Local13, 2.2f);
	float4 Local15 = (Local8 + Local14);
	float3 Local16 = Local15.xyz;
	float4 Local17 = Texture2DParameter_basecolor_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local17] Get needed components
	float3 Local18 = Local17.xyz;
	float Local19 = Local17.w;
	float3 Local20 = (Local16 * Local18);
	out_0 = Local20;
}

static void CalculateMatMetalMask(float2 in_0,
	thread float& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_physicalmap_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_physicalmap_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Get needed components
	float Local1 = Local0.x;
	float Local2 = Local0.y;
	out_0 = Local1;
}

static void CalculateMatReflectance(thread float& out_0)
{
	out_0 = 0.5f;
}

static void CalculateMatRoughness(float2 in_0,
	thread float& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_physicalmap_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_physicalmap_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Get needed components
	float Local1 = Local0.x;
	float Local2 = Local0.y;
	out_0 = Local2;
}

fragment PixelOutput Equipment_Weapons_Equipment_Weapons_Base_PBR_MSK_AlphaTest_STI_DEF_Metal_fragmentMain(constant LocalUniformsPS& uniforms,
	constant PerView& perView,
	VertexOutput In [[stage_in]],
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_basecolor_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_normalmap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_MSKcloth_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_physicalmap_DefaultWrapSampler)
{
	PixelOutput Out;

	float matOpacity;
	CalculateMatOpacity(In.TexCoords0, matOpacity, _DefaultWrapSampler, Texture2DParameter_basecolor_DefaultWrapSampler);
	if ((matOpacity - 0.5f) < 0) discard_fragment();

	float3 matNormal;
	CalculateMatNormal(In.TexCoords0, matNormal, _DefaultWrapSampler, Texture2DParameter_normalmap_DefaultWrapSampler);
	//Normalize World Normal
	float3 worldNormalNormalized = normalize(In.WorldNormal);

	//Normalize World Binormal
	float3 worldBinormalNormalized = normalize(In.WorldBinormal);

	//Normalize World Tangent
	float3 worldTangentNormalized = normalize(In.WorldTangent);

	float3x3 NBT = float3x3(float3(worldTangentNormalized.x, worldNormalNormalized.x, worldBinormalNormalized.x), float3(worldTangentNormalized.y, worldNormalNormalized.y, worldBinormalNormalized.y), float3(worldTangentNormalized.z, worldNormalNormalized.z, worldBinormalNormalized.z));

	matNormal = (float3x3(perView.global_View[0].xyz, perView.global_View[1].xyz, perView.global_View[2].xyz) * normalize((matNormal * NBT)));

	float3 matBaseColor;
	CalculateMatBaseColor(uniforms, In.TexCoords0, matBaseColor, _DefaultWrapSampler, Texture2DParameter_basecolor_DefaultWrapSampler, Texture2DParameter_MSKcloth_DefaultWrapSampler);
	float matMetalMask;
	CalculateMatMetalMask(In.TexCoords0, matMetalMask, _DefaultWrapSampler, Texture2DParameter_physicalmap_DefaultWrapSampler);
	float matReflectance;
	CalculateMatReflectance(matReflectance);
	float matRoughness;
	CalculateMatRoughness(In.TexCoords0, matRoughness, _DefaultWrapSampler, Texture2DParameter_physicalmap_DefaultWrapSampler);
	GBufferData gBufferData;
	gBufferData.Emissive = float3(0.0f, 0.0f, 0.0f);
	gBufferData.ViewSpaceNormal = matNormal;
	gBufferData.BaseColor = matBaseColor;
	gBufferData.FadeOpacity = uniforms._OpacityFade;
	gBufferData.Roughness = matRoughness;
	gBufferData.Reflectance = matReflectance;
	gBufferData.MetalMask = matMetalMask;
	gBufferData.FXEmissive = false;
	gBufferData.ShadingModel = 0;
	gBufferData.Custom = float4(0.0f, 0.0f, 0.0f, 0.0f);
	EncodeGBufferData(gBufferData, Out.Color0, Out.Color1, Out.Color2, Out.Color3);

	return Out;
}
