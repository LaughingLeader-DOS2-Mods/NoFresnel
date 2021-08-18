//[Vertex shader]


#define __HAVE_MATRIX_MULTIPLE_SCALAR_CONSTRUCTORS__
#include <metal_stdlib>

using namespace metal;

#include "Shaders/Metal/CommonHelpers.shdh"
#include "Shaders/GlobalConstants_MTL.shdh"
#include "Shaders/GlobalConstants_PS_MTL.shdh"

typedef struct
{
	uint4 BoneIndices BLENDINDICES0;
	float4 BoneWeights BLENDWEIGHT0;
	float3 Position SV_POSITION0;
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
	float3 WorldView;
} VertexOutput;

struct LocalUniformsVS
{
	float3x4 BoneMatrices[128];
	float4x4 WorldMatrix;
};

vertex VertexOutput WeaponExpansion_LLWEAPONEX_Characters_PBR_GM_Base_SK_DEF_Metal_vertexMain(constant LocalUniformsVS& uniforms [[buffer(5)]],
	constant PerView& perView [[buffer(6)]],
	VertexInput In [[stage_in]])
{
	VertexOutput Out;

	float4x3 boneMatrix1 = transpose(uniforms.BoneMatrices[In.BoneIndices.x]);
	float4x3 boneMatrix2 = transpose(uniforms.BoneMatrices[In.BoneIndices.y]);
	float4x3 boneMatrix3 = transpose(uniforms.BoneMatrices[In.BoneIndices.z]);
	float4x3 boneMatrix4 = transpose(uniforms.BoneMatrices[In.BoneIndices.w]);
	//World space position
	float4 worldPosition = float4(0.0f, 0.0f, 0.0f, 1.0f);
	worldPosition.xyz = (worldPosition.xyz + (In.BoneWeights.x * (boneMatrix1 * float4(In.Position, 1.0f))));
	worldPosition.xyz = (worldPosition.xyz + (In.BoneWeights.y * (boneMatrix2 * float4(In.Position, 1.0f))));
	worldPosition.xyz = (worldPosition.xyz + (In.BoneWeights.z * (boneMatrix3 * float4(In.Position, 1.0f))));
	worldPosition.xyz = (worldPosition.xyz + (In.BoneWeights.w * (boneMatrix4 * float4(In.Position, 1.0f))));
	worldPosition = (uniforms.WorldMatrix * worldPosition);

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
	float3 worldNormal = float3(0.0f, 0.0f, 0.0f);
	worldNormal = (worldNormal + (In.BoneWeights.x * (boneMatrix1 * float4(localNormalNormalized, 0.0f))));
	worldNormal = (worldNormal + (In.BoneWeights.y * (boneMatrix2 * float4(localNormalNormalized, 0.0f))));
	worldNormal = (worldNormal + (In.BoneWeights.z * (boneMatrix3 * float4(localNormalNormalized, 0.0f))));
	worldNormal = (worldNormal + (In.BoneWeights.w * (boneMatrix4 * float4(localNormalNormalized, 0.0f))));
	worldNormal = (uniforms.WorldMatrix * float4(worldNormal, 0.0f)).xyz;

	//Normalize World Normal
	float3 worldNormalNormalized = normalize(worldNormal);

	Out.WorldNormal = worldNormalNormalized;

	float3 LocalBinormal = LocalTangentFrame[1];

	//Normalize Local Binormal
	float3 localBinormalNormalized = normalize(LocalBinormal);

	//World space Binormal
	float3 worldBinormal = float3(0.0f, 0.0f, 0.0f);
	worldBinormal = (worldBinormal + (In.BoneWeights.x * (boneMatrix1 * float4(localBinormalNormalized, 0.0f))));
	worldBinormal = (worldBinormal + (In.BoneWeights.y * (boneMatrix2 * float4(localBinormalNormalized, 0.0f))));
	worldBinormal = (worldBinormal + (In.BoneWeights.z * (boneMatrix3 * float4(localBinormalNormalized, 0.0f))));
	worldBinormal = (worldBinormal + (In.BoneWeights.w * (boneMatrix4 * float4(localBinormalNormalized, 0.0f))));
	worldBinormal = (uniforms.WorldMatrix * float4(worldBinormal, 0.0f)).xyz;

	//Normalize World Binormal
	float3 worldBinormalNormalized = normalize(worldBinormal);

	Out.WorldBinormal = worldBinormalNormalized;

	float3 LocalTangent = LocalTangentFrame[0];

	//Normalize Local Tangent
	float3 localTangentNormalized = normalize(LocalTangent);

	//World space Tangent
	float3 worldTangent = float3(0.0f, 0.0f, 0.0f);
	worldTangent = (worldTangent + (In.BoneWeights.x * (boneMatrix1 * float4(localTangentNormalized, 0.0f))));
	worldTangent = (worldTangent + (In.BoneWeights.y * (boneMatrix2 * float4(localTangentNormalized, 0.0f))));
	worldTangent = (worldTangent + (In.BoneWeights.z * (boneMatrix3 * float4(localTangentNormalized, 0.0f))));
	worldTangent = (worldTangent + (In.BoneWeights.w * (boneMatrix4 * float4(localTangentNormalized, 0.0f))));
	worldTangent = (uniforms.WorldMatrix * float4(worldTangent, 0.0f)).xyz;

	//Normalize World Tangent
	float3 worldTangentNormalized = normalize(worldTangent);

	Out.WorldTangent = worldTangentNormalized;

	//World space view vector
	float3 worldView = (perView.global_ViewPos.xyz - worldPosition.xyz);

	Out.WorldView = worldView;


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
	float FloatParameter_FresnelGlow;
	float FloatParameter_FresnelPower;
	float3 Vector3Parameter_FresnelColor;
	float FloatParameter_PulseSpeed;
	float FloatParameter_MinGlow;
	float FloatParameter_MaxGlow;
	float FloatParameter_GlowMultiplier;
	float3 Vector3Parameter_GlowColor;
	float4 Vector4Parameter_Color1;
	float4 Vector4Parameter_Color2;
	float4 Vector4Parameter_Color3;
	float4 Vector4Parameter_Color4;
	float4 Vector4Parameter_Color5;
	float FloatParameter_Reflectance;
	float _OpacityFade;
};

static void CalculateMatEmissiveColor(constant LocalUniformsPS& uniforms,
	constant PerFrame& perFrame,
	float2 in_0,
	float3 in_1,
	thread float3& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_normalmap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_Glowmap_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_normalmap_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Convert normalmaps to tangent space vectors
	Local0.xyzw = Local0.wzyx;
	Local0.xyz = ((Local0.xyz * 2.0f) - 1.0f);
	Local0.z = -(Local0.z);
	Local0.xyz = normalize(Local0.xyz);
	//[Local0] Get needed components
	float3 Local1 = Local0.xyz;
	float Local2 = pow((1.0f - saturate(dot(Local1, in_1))), uniforms.FloatParameter_FresnelPower);
	float Local3 = (uniforms.FloatParameter_FresnelGlow * Local2);
	float3 Local4 = (Local3 * uniforms.Vector3Parameter_FresnelColor);
	float Local5 = (perFrame.global_Data.x * uniforms.FloatParameter_PulseSpeed);
	float Local6 = ((((sin(Local5) * 0.5f) + 0.5f) * (uniforms.FloatParameter_MaxGlow - uniforms.FloatParameter_MinGlow)) + uniforms.FloatParameter_MinGlow);
	float4 Local7 = Texture2DParameter_Glowmap_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local7] Get needed components
	float3 Local8 = Local7.xyz;
	float3 Local9 = (Local8 * uniforms.Vector3Parameter_GlowColor);
	float3 Local10 = (uniforms.FloatParameter_GlowMultiplier * Local9);
	float3 Local11 = (Local6 * Local10);
	float3 Local12 = (Local4 + Local11);
	out_0 = Local12;
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
	texture2d<float> Texture2DParameter_MSKskin_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_MSKcloth_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_basecolor_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_MSKskin_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Get needed components
	float Local1 = Local0.x;
	float Local2 = Local0.y;
	float4 Local3 = (uniforms.Vector4Parameter_Color1 * Local1);
	float4 Local4 = (uniforms.Vector4Parameter_Color2 * Local2);
	float4 Local5 = (Local3 + Local4);
	float4 Local6 = Texture2DParameter_MSKcloth_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local6] Get needed components
	float Local7 = Local6.x;
	float Local8 = Local6.y;
	float Local9 = Local6.z;
	float4 Local10 = (uniforms.Vector4Parameter_Color3 * Local7);
	float4 Local11 = (Local5 + Local10);
	float4 Local12 = (uniforms.Vector4Parameter_Color4 * Local8);
	float4 Local13 = (Local11 + Local12);
	float4 Local14 = (uniforms.Vector4Parameter_Color5 * Local9);
	float4 Local15 = (Local13 + Local14);
	float Local16 = (1.0f - Local1);
	float Local17 = (1.0f - Local2);
	float Local18 = (Local16 * Local17);
	float Local19 = (1.0f - Local7);
	float Local20 = (Local18 * Local19);
	float Local21 = (1.0f - Local8);
	float Local22 = (Local20 * Local21);
	float Local23 = (1.0f - Local9);
	float Local24 = (Local22 * Local23);
	float Local25 = pow(Local24, 2.2f);
	float4 Local26 = (Local15 + Local25);
	float3 Local27 = Local26.xyz;
	float4 Local28 = Texture2DParameter_basecolor_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local28] Get needed components
	float3 Local29 = Local28.xyz;
	float3 Local30 = (Local27 * Local29);
	out_0 = Local30;
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

static void CalculateMatReflectance(constant LocalUniformsPS& uniforms,
	thread float& out_0)
{
	out_0 = uniforms.FloatParameter_Reflectance;
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

fragment PixelOutput WeaponExpansion_LLWEAPONEX_Characters_PBR_GM_Base_SK_DEF_Metal_fragmentMain(constant LocalUniformsPS& uniforms,
	constant PerView& perView,
	constant PerFrame& perFrame,
	VertexOutput In [[stage_in]],
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_normalmap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_Glowmap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_MSKskin_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_MSKcloth_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_basecolor_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_physicalmap_DefaultWrapSampler)
{
	PixelOutput Out;

	float3 matEmissiveColor;
	//Normalize World Normal
	float3 worldNormalNormalized = normalize(In.WorldNormal);

	//Normalize World Binormal
	float3 worldBinormalNormalized = normalize(In.WorldBinormal);

	//Normalize World Tangent
	float3 worldTangentNormalized = normalize(In.WorldTangent);

	float3x3 NBT = float3x3(float3(worldTangentNormalized.x, worldNormalNormalized.x, worldBinormalNormalized.x), float3(worldTangentNormalized.y, worldNormalNormalized.y, worldBinormalNormalized.y), float3(worldTangentNormalized.z, worldNormalNormalized.z, worldBinormalNormalized.z));

	//Normalized world space view vector
	float3 worldViewNormalized = normalize(In.WorldView);

	//Calculate tangent space view vector
	float3 tangentView = (NBT * worldViewNormalized);

	CalculateMatEmissiveColor(uniforms, perFrame, In.TexCoords0, tangentView, matEmissiveColor, _DefaultWrapSampler, Texture2DParameter_normalmap_DefaultWrapSampler, Texture2DParameter_Glowmap_DefaultWrapSampler);
	float3 matNormal;
	CalculateMatNormal(In.TexCoords0, matNormal, _DefaultWrapSampler, Texture2DParameter_normalmap_DefaultWrapSampler);
	matNormal = (float3x3(perView.global_View[0].xyz, perView.global_View[1].xyz, perView.global_View[2].xyz) * normalize((matNormal * NBT)));

	float3 matBaseColor;
	CalculateMatBaseColor(uniforms, In.TexCoords0, matBaseColor, _DefaultWrapSampler, Texture2DParameter_MSKskin_DefaultWrapSampler, Texture2DParameter_MSKcloth_DefaultWrapSampler, Texture2DParameter_basecolor_DefaultWrapSampler);
	float matMetalMask;
	CalculateMatMetalMask(In.TexCoords0, matMetalMask, _DefaultWrapSampler, Texture2DParameter_physicalmap_DefaultWrapSampler);
	float matReflectance;
	CalculateMatReflectance(uniforms, matReflectance);
	float matRoughness;
	CalculateMatRoughness(In.TexCoords0, matRoughness, _DefaultWrapSampler, Texture2DParameter_physicalmap_DefaultWrapSampler);
	GBufferData gBufferData;
	gBufferData.Emissive = matEmissiveColor;
	gBufferData.ViewSpaceNormal = matNormal;
	gBufferData.BaseColor = matBaseColor;
	gBufferData.FadeOpacity = uniforms._OpacityFade;
	gBufferData.Roughness = matRoughness;
	gBufferData.Reflectance = matReflectance;
	gBufferData.MetalMask = matMetalMask;
	gBufferData.FXEmissive = true;
	gBufferData.ShadingModel = 0;
	gBufferData.Custom = float4(0.0f, 0.0f, 0.0f, 0.0f);
	EncodeGBufferData(gBufferData, Out.Color0, Out.Color1, Out.Color2, Out.Color3);

	return Out;
}
