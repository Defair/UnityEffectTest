// Upgrade NOTE: replaced 'defined MY_LIGHTING_INCLUDED' with 'defined (MY_LIGHTING_INCLUDED)'

#if !defined (MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

#define UNITY_PBS_USE_BRDF3
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"


struct appdata
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
	float3 normal : NORMAL;
	float3 tangent : TANGENT;
};

struct Interpolators
{
	float3 wPos : TEXCOORD0;
	float4 uv : TEXCOORD1;
	float3 normal : TEXCOORD2;
	float4 pos : SV_POSITION;
#if defined(VERTEXLIGHT_ON)
	float3 vertexLightColor : TEXCOORD3;
#endif

	float3 tanToWorld1 : TEXCOORD4;
	float3 tanToWorld2 : TEXCOORD5;
	float3 tanToWorld3 : TEXCOORD6;
};

float _Metallic;
float _Smoothness;
float4 _Tint;
sampler2D _MainTex;
float4 _MainTex_ST;

sampler2D _HeightMap;
float4 _HeightMap_TexelSize;

sampler2D _NormalMap;

sampler2D _DetailMap;
float4 _DetailMap_ST;
sampler2D _DetailNormalMap;


float _BumpScale;
float _DetailBumpScale;


void ComputeVertexLightColor(in Interpolators i)
{
#if defined(VERTEXLIGHT_ON)
	float3 lightPos = float3(unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x);
	float3 lightVec = lightPos - i.wPos;
	float3 lightDir = normalize(lightVec);
	float ndotl = DotClamped(i.normal, lightDir);
	float attenuation = 1 / (1 + dot(lightVec, lightVec) * unity_4LightAtten0.x);

	i.vertexLightColor = unity_LightColor[0].rgb * attenuation * ndotl;

	i.vertexLightColor = Shade4PointLights(
		unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
		unity_LightColor[0].rgb, unity_LightColor[1].rgb,
		unity_LightColor[2].rgb, unity_LightColor[3].rgb,
		unity_4LightAtten0, i.wPos, i.normal
	);
#endif
}
 
UnityLight CreateLight(Interpolators i)
{
	float3 lightDir = normalize(UnityWorldSpaceLightDir(i.wPos.xyz));
	UnityLight light;

	//float3 lightVec = i.wPos - _WorldSpaceLightPos0.xyz;
	//float attenuation = 1/(1+dot(lightVec, lightVec));

	UNITY_LIGHT_ATTENUATION(attenuation, 0, i.wPos);
	light.color = _LightColor0.rgb * attenuation;
	light.dir = lightDir;
	light.ndotl = DotClamped(i.normal, lightDir);

	return light;
}

UnityIndirect CreateIndirectLight(Interpolators i)
{
	UnityIndirect o;

	o.diffuse = 0;
	o.specular = 0;

#if defined(VERTEXLIGHT_ON)
	o.diffuse = i.vertexLightColor;
#endif

#if defined(FORWARD_BASE_PASS)
	o.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
#endif

	return o;
}

void InitializeFragmentNormal(inout Interpolators i)
{
	

	//float u1 = tex2D(_HeightMap, i.uv + float2(_HeightMap_TexelSize.x * 0.5, 0));
	//float u2 = tex2D(_HeightMap, i.uv - float2(_HeightMap_TexelSize.x * 0.5, 0));
	////float3 tu = float3(1, u1 - u2, 0);

	//float v1 = tex2D(_HeightMap, i.uv + float2(0, _HeightMap_TexelSize.y * 0.5));
	//float v2 = tex2D(_HeightMap, i.uv - float2(0, _HeightMap_TexelSize.y * 0.5));
	////float3 tv = float3(0, v1 - v2, 1);

	////float3 normal = cross(tv, tu);

	//i.normal = normalize(float3(u2 - u1, 1, v2 - v1));


	i.normal.xy = tex2D(_NormalMap, i.uv.xy).wy * 2 - 1;
	i.normal.xy = _BumpScale * i.normal.xy;

	i.normal.z = sqrt(1 - saturate(dot(i.normal.xy, i.normal.xy)));

	float3 normal = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
	float3 detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, i.uv.zw), _DetailBumpScale);

	//i.normal = float3(normal.xy / normal.z + detailNormal.xy / detailNormal.z, 1);
	i.normal = BlendNormals(normal, detailNormal); //whiteout blend
	//i.normal = (normal + detailNormal) * 0.5;

	//i.normal = detailNormal;


	i.normal = normalize(i.tanToWorld1) * i.normal.x + normalize(i.tanToWorld2) * i.normal.y + normalize(i.tanToWorld3) * i.normal.z;

	i.normal = normalize(i.normal);
}

Interpolators MyVertexProgram(appdata i)
{
	Interpolators o;
	o.pos = UnityObjectToClipPos(i.vertex);
	o.uv.xy = TRANSFORM_TEX(i.uv, _MainTex);
	o.uv.zw = TRANSFORM_TEX(i.uv, _DetailMap);

	o.normal = UnityObjectToWorldNormal(i.normal);
	o.wPos = mul(unity_ObjectToWorld, i.vertex);
	ComputeVertexLightColor(o);

	float3 normal = normalize(o.normal);
	float3 tangent = normalize(UnityObjectToWorldDir(i.tangent));
	float3 binormal = cross(normal, tangent);


	o.tanToWorld1 = float3(tangent.x, binormal.x, normal.x);
	o.tanToWorld2 = float3(tangent.y, binormal.y, normal.y);
	o.tanToWorld3 = float3(tangent.z, binormal.z, normal.z);

	o.tanToWorld1 = tangent;
	o.tanToWorld2 = binormal;
	o.tanToWorld3 = normal;

	return o;
}

float4 MyFragmentProgram(Interpolators i) : SV_Target
{
	InitializeFragmentNormal(i);
	float3 viewDir = normalize( UnityWorldSpaceViewDir(i.wPos) );
	//float3 lightDir = normalize( UnityWorldSpaceLightDir(i.wPos.xyz));

	float3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;
	albedo *= tex2D(_DetailMap, i.uv.zw) * unity_ColorSpaceDouble;

	float3 specularTint;
	float oneMinusReflectivity;
	albedo = DiffuseAndSpecularFromMetallic(albedo, _Metallic, specularTint, oneMinusReflectivity);

	/*UnityLight light;
	light.color = _LightColor0.rgb;
	light.dir = lightDir;
	light.ndotl = DotClamped(i.normal, lightDir);*/

	/*UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;*/

	//return float4(lightDir, 1);
	/*float3 color = ShadeSH9(float4(i.normal, 1));
	return float4(color, 1);*/

	return BRDF1_Unity_PBS(albedo , specularTint, oneMinusReflectivity, _Smoothness,
	i.normal, viewDir,
	CreateLight(i), CreateIndirectLight(i));
}

#endif