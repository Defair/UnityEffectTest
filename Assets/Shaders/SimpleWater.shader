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
			float stepness[10];

			float4 waveDir[10];
			float Fresnel_0;
			int waveCount;

			float4 _Color;
			
			v2f vert (appdata v)
			{
				v2f o;

				

				float4 updateVert = float4(v.vertex.x, 0, v.vertex.z, v.vertex.w);

				for (int i = 0; i < waveCount; i++)
				{
					updateVert.x += stepness[i] * amplitude[i] * waveDir[i].x * cos(dot(waveDir[i].xy, v.vertex.xz) * UNITY_TWO_PI / waveLength[i] + UNITY_TWO_PI * angleFreq[i] * _Time.y);
					updateVert.z += stepness[i] * amplitude[i] * waveDir[i].y * cos(dot(waveDir[i].xy, v.vertex.xz) * UNITY_TWO_PI / waveLength[i] + UNITY_TWO_PI * angleFreq[i] * _Time.y);
					updateVert.y += amplitude[i] * sin(dot(waveDir[i].xy, v.vertex.xz) * UNITY_TWO_PI / waveLength[i] + UNITY_TWO_PI * angleFreq[i] * _Time.y);
				}


				o.pos = UnityObjectToClipPos(updateVert);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;
							
				//o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, updateVert);


				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				//fixed4 col = tex2D(_MainTex, i.uv);
				//return col;
				half4 col = half4(i.color, 1);

				float3 normal = float3(0, 1, 0);

				for (int j = 0; j < waveCount; j++)
				{
					normal.x -= waveDir[j].x * stepness[j] * UNITY_TWO_PI / waveLength[j] * amplitude[j] *
						cos(dot(waveDir[j].xy, i.worldPos.xz) * UNITY_TWO_PI / waveLength[j] + UNITY_TWO_PI * angleFreq[j] * _Time.y);

					normal.z -= waveDir[j].y * stepness[j] * UNITY_TWO_PI / waveLength[j] * amplitude[j] *
						cos(dot(waveDir[j].xy, i.worldPos.xz) * UNITY_TWO_PI / waveLength[j] + UNITY_TWO_PI * angleFreq[j] * _Time.y);

					normal.y -= stepness[j] * UNITY_TWO_PI / waveLength[j] * amplitude[j] *
						sin(dot(waveDir[j].xy, i.worldPos.xz) * UNITY_TWO_PI / waveLength[j] + UNITY_TWO_PI * angleFreq[j] * _Time.y);
				}

				/*float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				float3 lightDir = normalize(WorldSpaceLightDir(i.worldPos));

				float3 halfDir = normalize( lightDir + viewDir );


				float VdotH = saturate(dot(viewDir, halfDir));
				float LdotH = saturate(dot(lightDir, halfDir));


				float3 F = FresnelTerm(float3(Fresnel_0, Fresnel_0, Fresnel_0), VdotH);

				col.rgb = _Color.rgb + F * _LightColor0.rgb;
				col.a = _Color.a + F.r;
				col.rgb = F * _LightColor0.rgb;*/
				normal = saturate(normal);
				col.rgb = normal;
				return col;
			}
			ENDCG
		}
	}
}
