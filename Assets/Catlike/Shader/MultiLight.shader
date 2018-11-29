Shader "Unlit/MultiLight"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		[NoScaleOffset]_HeightMap("Height Map", 2D) = "gray" {}
		[NoScaleOffset]_NormalMap("Normal Map", 2D) = "bump" {}
		_DetailMap("Detail Map", 2D) = "gray" {}
		[NoScaleOffset]_DetailNormalMap("Detail Normal Map", 2D) = "bump" {}
		_DetailBumpScale("Detail Bump Scale", Float) = 1


		_BumpScale("Bump Scale", Float) = 1

		_Tint("Diffuse Tint", Color) = (1,1,1,1)
		[Gamma]_Metallic("Metallic", Range(0, 1)) = 0
		_Smoothness("Smoothness", Range(0, 1)) = 1
	}
	SubShader
	{

		Pass
		{
			Tags { "RenderType" = "Opaque" "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma multi_compile _ VERTEXLIGHT_ON
			#define FORWARD_BASE_PASS
			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram
			
			#include "UnityCG.cginc"
			#include "MyLighting.cginc"								
						
			ENDCG
		}

		Pass
		{
			Tags { "RenderType" = "Opaque" "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off

			CGPROGRAM
			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram
			#pragma multi_compile DIRECTIONAL DIRECTIONAL_COOKIE POINT_COOKIE POINT SPOT

			#include "UnityCG.cginc"

//			#define POINT
			#include "MyLighting.cginc"								

			ENDCG
		}
	}
}
