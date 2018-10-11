Shader "Unlit/SimpleWater"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 100

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			Cull Off

			CGPROGRAM
// Upgrade NOTE: excluded shader from DX11 because it uses wrong array syntax (type[size] name)
#pragma exclude_renderers d3d11
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			
			#include "UnityCG.cginc"
			#include "UnityStandardBRDF.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 color : COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 color : COLOR;
				float3 normal : TEXCOORD1;
				float4 worldPos : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float angleFreq[10];
			float waveLength[10];
			float amplitude[10];
			float Fresnel_0[10];
			int waveCount;

			float4 _Color;
			
			v2f vert (appdata v)
			{
				v2f o;

				float y = sin(UNITY_TWO_PI * angleFreq * _Time.y + UNITY_TWO_PI / waveLength * v.vertex.x);
				float cosY = cos(UNITY_TWO_PI * angleFreq * _Time.y + UNITY_TWO_PI / waveLength * v.vertex.x);

				float4 updateVert = float4(v.vertex.x, amplitude * y, v.vertex.z, v.vertex.w);

				o.pos = UnityObjectToClipPos(updateVert);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;
				
				float3 normal = float3(-cosY * amplitude, 1, 0);
				o.normal = UnityObjectToWorldNormal(normal);
				o.worldPos = mul(unity_ObjectToWorld, updateVert);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				//fixed4 col = tex2D(_MainTex, i.uv);
				//return col;
				half4 col = half4(i.color, 1);

				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				float3 normal = i.normal;
				float3 lightDir = normalize(WorldSpaceLightDir(i.worldPos));

				float3 halfDir = normalize( lightDir + viewDir );


				float VdotH = saturate(dot(viewDir, halfDir));
				float LdotH = saturate(dot(lightDir, halfDir));


				float3 F = FresnelTerm(float3(Fresnel_0, Fresnel_0, Fresnel_0), VdotH);

				col.rgb = _Color.rgb + F * _LightColor0.rgb;
				col.a = _Color.a + F.r;
				col.rgb = F * _LightColor0.rgb;
				return col;
			}
			ENDCG
		}
	}
}
