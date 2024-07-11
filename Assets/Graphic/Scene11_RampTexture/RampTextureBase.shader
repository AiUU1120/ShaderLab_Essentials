Shader "Study/RampTextureBase"
{
    Properties
    {
        _MainColor("MainColor", Color) = (1, 1, 1, 1)
        // 渐变纹理
        _RampTex("RampTex", 2D) = ""{}
        // 高光反射颜色
        _SpecularColor("SpecularColor", Color) = (1,1,1,1)
        // 光泽度
        _SpecularLevel("SpecularLevel", Range(0, 256)) = 10
    }
    SubShader
    {
        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            fixed4 _MainColor;
            sampler2D _RampTex;
            float4 _RampTex_ST;
            fixed4 _SpecularColor;
            float _SpecularLevel;

            struct v2f
            {
                // 裁剪空间下顶点坐标
                float4 pos : SV_POSITION;
                // 世界空间下顶点坐标
                float4 wPos : TEXCOORD0;
                // 世界空间下法线
                float3 wNormal : TEXCOORD1;
            };

            v2f vert(appdata_base v)
            {
                v2f data;
                data.pos = UnityObjectToClipPos(v.vertex);
                data.wPos = mul(unity_ObjectToWorld, v.vertex);
                data.wNormal = UnityObjectToWorldNormal(v.normal);
                return data;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 lightDir = normalize(_WorldSpaceLightPos0);
                // 半兰伯特取值
                fixed halfLambertNum = dot(normalize(i.wNormal), lightDir) * 0.5 + 0.5;
                fixed3 diffuseColor = _LightColor0.rgb * _MainColor.rgb * tex2D(
                    _RampTex, fixed2(halfLambertNum, halfLambertNum));
                float3 viewDir = normalize(WorldSpaceViewDir(i.wPos));
                float3 halfDir = normalize(viewDir + lightDir);
                fixed3 specularColor = _LightColor0.rgb * _SpecularColor.rgb * pow(
                    max(0, dot(i.wNormal, halfDir)), _SpecularLevel);
                fixed3 color = UNITY_LIGHTMODEL_AMBIENT.rgb + diffuseColor + specularColor;
                return fixed4(color, 1);
            }
            ENDCG
        }
    }
}