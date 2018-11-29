Shader "Unlit/BaseParallaxMap"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NormalTex("Normal Map", 2D) = "white" {}
		_HeightTex("Height Map", 2D) = "white" {}
		_ParallaxScale("Parallax Scale", Range(0, 1)) = 0.2
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float3 tangent : TANGENT;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 normal : TEXCOORD1;
				float3 tangent : TEXCOORD2;
				float3 binormal : TEXCOORD3;
				float3 worldPos : TEXCOORD4;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _NormalTex;
			sampler2D _HeightTex;
			
			float _ParallaxScale;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.tangent = UnityObjectToWorldDir(v.tangent);
				o.binormal = normalize(cross(o.normal, o.tangent));
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

				float3 lightDirInTan = float3(dot(i.tangent, lightDir), dot(i.binormal, lightDir), dot(i.normal, lightDir));
				float3 viewDirInTan = float3(dot(i.tangent, viewDir), dot(i.binormal, viewDir), dot(i.normal, viewDir));
				
				float height = tex2D(_HeightTex, i.uv);


				float2 offsetUV = i.uv + viewDirInTan.xy / viewDirInTan.z * height * _ParallaxScale;
				// sample the texture
				half4 diffuse = tex2D(_MainTex, offsetUV);
				float4 normalMap = tex2D(_NormalTex, offsetUV);
				normalMap.xyz = 2 * normalMap.xyz - 1;
				normalMap.z = -normalMap.z;

				float3 worldNormalMap = i.normal * normalMap.z + i.tangent * normalMap.x + i.binormal * normalMap.y;
				float3 normal = normalize(worldNormalMap);

				float NdotL = dot(normal, lightDir);
				half4 col;
				col.rgb = diffuse.rgb * saturate(NdotL);
				col.a = 1;
				return col;
			}
			ENDCG
		}
	}
}
