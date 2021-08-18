//[Vertex shader]


#define __HAVE_MATRIX_MULTIPLE_SCALAR_CONSTRUCTORS__
#include <metal_stdlib>

using namespace metal;

#include "Shaders/Metal/CommonHelpers.shdh"
#include "Shaders/GlobalConstants_MTL.shdh"
#include "Shaders/GlobalConstants_PS_MTL.shdh"

typedef struct
{
	float4 VertexColor COLOR0;
	float4 LocalQTangent NORMAL0;
	float4 InstanceMatrix1 COLOR1;
	float4 InstanceMatrix2 COLOR2;
	float4 InstanceMatrix3 COLOR3;
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
	float FloatParameter_PulseSpeed;
	float FloatParameter_PulseSize;
	float FloatParameter_PulseStrength;
};

static void CalculateMatWorldPositionOffset(constant LocalUniformsVS& uniforms,
	constant PerFrame& perFrame,
	float4 in_0,
	float3 in_1,
	float3 in_2,
	float3 in_3,
	thread float3& out_0)
{
	float3 Local0 = (in_0.y * in_1);
	float Local1 = (perFrame.global_Data.x * uniforms.FloatParameter_PulseSpeed);
	float3 Local2 = in_2;
	float Local3 = length(Local2);
	float Local4 = in_3.y;
	float Local5 = (Local4 / uniforms.FloatParameter_PulseSize);
	float Local6 = (Local3 + Local5);
	float Local7 = (Local6 + in_0.z);
	float Local8 = (Local1 + Local7);
	//TriangleWave
	float Local9 = abs(((fract((Local8 + 0.5f)) * 2.0f) - 1.0f));
	//Smooth TriangleWave
	float Local10 = ((Local9 * Local9) * (3.0f - (2.0f * Local9)));
	//Bring TriangleWave between range [min, max]
	float Local11 = ((Local10 * (uniforms.FloatParameter_PulseStrength - 0.0f)) + 0.0f);
	float3 Local12 = (Local0 * Local11);
	out_0 = Local12;
}

vertex VertexOutput Characters_PBR_Characters_PRB_Pulse_GM_AlphaTest_2S_STI_DEP_Metal_vertexMain(constant LocalUniformsVS& uniforms [[buffer(5)]],
	constant PerView& perView [[buffer(6)]],
	constant PerFrame& perFrame [[buffer(7)]],
	VertexInput In [[stage_in]])
{
	VertexOutput Out;

	float3 matWorldPositionOffset;
	//Compute local tangent frame
	float3x3 LocalTangentFrame = GetTangentFrame(In.LocalQTangent);

	float3 LocalNormal = LocalTangentFrame[2];

	//Normalize Local Normal
	float3 localNormalNormalized = normalize(LocalNormal);

	//Create Instance World Matrix
	float4 col1 = float4(In.InstanceMatrix1.x, In.InstanceMatrix1.y, In.InstanceMatrix1.z, 0.0f);
	float4 col2 = float4(In.InstanceMatrix1.w, In.InstanceMatrix2.x, In.InstanceMatrix2.y, 0.0f);
	float4 col3 = float4(In.InstanceMatrix2.z, In.InstanceMatrix2.w, In.InstanceMatrix3.x, 0.0f);
	float4 col4 = float4(In.InstanceMatrix3.y, In.InstanceMatrix3.z, In.InstanceMatrix3.w, 1.0f);
	float4x4 WorldMatrix = float4x4(col1, col2, col3, col4);

	//World space Normal
	float3 worldNormal = (float3x3(WorldMatrix[0].xyz, WorldMatrix[1].xyz, WorldMatrix[2].xyz) * localNormalNormalized);

	//Normalize World Normal
	float3 worldNormalNormalized = normalize(worldNormal);

	//Object World Position
	float3 objectWorldPosition = float3(WorldMatrix[3].x, WorldMatrix[3].y, WorldMatrix[3].z);

	CalculateMatWorldPositionOffset(uniforms, perFrame, In.VertexColor, worldNormalNormalized, objectWorldPosition, In.Position.xyz, matWorldPositionOffset);
	//World space position
	float4 worldPosition = (WorldMatrix * float4(In.Position, 1.0f));

	worldPosition = (worldPosition + float4(matWorldPositionOffset, 0.0f));

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

fragment PixelOutput Characters_PBR_Characters_PRB_Pulse_GM_AlphaTest_2S_STI_DEP_Metal_fragmentMain(VertexOutput In [[stage_in]],
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_basecolor_DefaultWrapSampler)
{
	PixelOutput Out;

	float matOpacity;
	CalculateMatOpacity(In.TexCoords0, matOpacity, _DefaultWrapSampler, Texture2DParameter_basecolor_DefaultWrapSampler);
	if ((matOpacity - 0.5f) < 0) discard_fragment();


	return Out;
}
