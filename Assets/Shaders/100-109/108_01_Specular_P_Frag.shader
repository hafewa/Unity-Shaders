﻿Shader "Custom/100-109/108_01_Specular_P_Frag" 
{
	Properties
    {
        _NormalMap ("Normal map", 2D) = "bump" {}
        _Diffuse ("Diffuse %", Range(0, 1)) = 1
        _SpecularMap ("Specular map", 2d) = "white" {}
        _SpecularFactor ("Specular %", Range(0, 1)) = 1
        _SpecularPower ("Specular power", Float) = 100
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
            
            sampler2D _NormalMap;
            float4 _NormalMap_ST;
            
            float _Diffuse;
            float4 _LightColor0;
            
            sampler2D _SpecularMap;
            float4 _SpecularMap_ST;
            float _SpecularFactor;
            float _SpecularPower;
            
            float3 normalFromColor (float4 colorVal)
            {
	            #if defined(UNITY_NO_DXT5nm)
		            return colorVal.xyz * 2 - 1;
	            #else
                    float3 normalVal;
                    normalVal = float3 (colorVal.a * 2.0 - 1.0,
                                colorVal.g * 2.0 - 1.0,
                                0.0);
                    normalVal.z = sqrt(1.0 - dot(normalVal, normalVal));
                    return normalVal;
	            #endif
            }
            
            float3 WorldNormalFromNormalMap(sampler2D normalMap, float2 normalTexCoord, float3 tangentWorld, float3 binormalWorld, float3 normalWorld)
            {
		        float4 colorAtPixel = tex2D(normalMap, normalTexCoord);
		
		        float3 normalAtPixel = normalFromColor(colorAtPixel);
		
		        float3x3 TBNWorld = float3x3(tangentWorld, binormalWorld, normalWorld);
		        return normalize(mul(normalAtPixel, TBNWorld));	
            }
            
            float3 DiffuseLambert(float3 normalVal, float3 lightDir, float3 lightColor, float diffuseFactor, float attenuation)
            {
                return lightColor * diffuseFactor * attenuation * saturate(dot(normalVal, lightDir));
            }
            
            float SpecularPhong(float3 normalDir, float3 lightDir, float3 worldSpaceViewDir, float3 specularColor, float specularFactor, float attenuation, float specularPower)
            {
                float3 reflection = 2 * dot(normalDir, lightDir) * normalDir - lightDir; // reflect(-lightDir, normalDir)
                return specularColor * specularFactor * attenuation * pow(saturate(dot(reflection, worldSpaceViewDir)), specularPower);
            }
            
            struct vertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord : TEXCOORD0;
            };
            
            struct vertexOuput
            {
                float4 pos : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float3 worldTangent : TEXCOORD3;
                float3 worldBinormal : TEXCOORD4;
                float2 normalTexCoord : TEXCOORD5;
            };
            
            vertexOuput vert(vertexInput v)
            {
                vertexOuput o;
                UNITY_INITIALIZE_OUTPUT(vertexOuput, o);
                
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.texcoord = v.texcoord;
                o.normalTexCoord = v.texcoord.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
                
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                o.worldBinormal = normalize(cross(o.worldNormal, o.worldTangent) * v.tangent.w); 
                
                return o;
            }
            
            fixed4 frag(vertexOuput i) : SV_TARGET  
            {
                float3 worldNormalAtPixel = WorldNormalFromNormalMap(_NormalMap, i.normalTexCoord, i.worldTangent, i.worldBinormal, i.worldNormal);
                
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 lightColor = _LightColor0.rgb;
                float attenuation = 1;
                float3 diffuseColor = DiffuseLambert(worldNormalAtPixel, lightDir, lightColor, _Diffuse, attenuation);
                
                float4 specularMap = tex2D(_SpecularMap, i.texcoord);
                float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 specularColor = SpecularPhong(worldNormalAtPixel, lightDir, worldSpaceViewDir, specularMap.rgb, _SpecularFactor, attenuation, _SpecularPower);
                
                return float4(diffuseColor + specularColor, 1);
            }
            ENDCG
        }
    }
}
