﻿Shader "Custom/100-109/109_Ambient_Vert" 
{
	Properties
    {
        _Diffuse ("Diffuse %", Range(0, 1)) = 1
        _SpecularMap ("Specular map", 2d) = "white" {}
        _SpecularFactor ("Specular %", Range(0, 1)) = 1
        _SpecularPower ("Specular power", Float) = 100
        _AmbientFactor ("Ambient %", Range(0, 1)) = 0
    }
    
    SubShader
    {
        Pass 
        {
            Tags { "LightMode" = "ForwardBase" }
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            float _Diffuse;
            float4 _LightColor0;
            
            sampler2D _SpecularMap;
            float4 _SpecularMap_ST;
            float _SpecularFactor;
            float _SpecularPower;
            
            float _AmbientFactor;
            
            float3 DiffuseLambert(float3 normalVal, float3 lightDir, float3 lightColor, float diffuseFactor, float attenuation)
            {
                return lightColor * diffuseFactor * attenuation * saturate(dot(normalVal, lightDir));
            }
            
            float SpecularBlinnPhong(float3 normalDir, float3 lightDir, float3 worldSpaceViewDir, float3 specularColor, float specularFactor, float attenuation, float specularPower)
            {
                float3 halfwayDir = normalize(lightDir + worldSpaceViewDir);
                return specularColor * specularFactor * attenuation * pow(saturate(dot(normalDir, halfwayDir)), specularPower);
            }
            
            struct vertexInput
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float3 tangent : TANGENT;
                float2 texcoord : TEXCOORD0;
            };
            
            struct vertexOuput
            {
                float4 pos : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float4 surfaceColor : COLOR0;
            };
            
            vertexOuput vert(vertexInput v)
            {
                vertexOuput o;
                UNITY_INITIALIZE_OUTPUT(vertexOuput, o);
                
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                o.texcoord = v.texcoord;
                
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                
                
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 lightColor = _LightColor0.rgb;
                float attenuation = 1;
                float3 diffuseColor = DiffuseLambert(o.worldNormal, lightDir, lightColor, _Diffuse, attenuation);
                
                float4 specularMap = tex2Dlod(_SpecularMap, float4(o.texcoord.xy, 0, 0));
                float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos - o.worldPos);
                float3 specularColor = SpecularBlinnPhong(o.worldNormal, lightDir, worldSpaceViewDir, specularMap.rgb, _SpecularFactor, attenuation, _SpecularPower);
                
                float3 ambientColor = _AmbientFactor * UNITY_LIGHTMODEL_AMBIENT;
                
                o.surfaceColor = float4(diffuseColor + specularColor + ambientColor, 1);
                
                return o;
            }
            
            fixed4 frag(vertexOuput i) : SV_TARGET
            {
                return i.surfaceColor;
            }
            ENDCG
        }
    }
}
