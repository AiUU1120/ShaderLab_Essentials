Shader "Study/PhongSpecularF"
{
    Properties
    {
        // 高光反射颜色
        _SpecularColor("SpecularColor", Color) = (1,1,1,1)
        // 光泽度
        _SpecularLevel("SpecularLevel", Range(0, 20)) = 0.5
    }
    SubShader
    {
        Tags
        {
            "LightMode"="ForwardBase"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            fixed4 _SpecularColor;
            float _SpecularLevel;

            struct v2f
            {
                float4 vertex : SV_POSITION;
                // 世界空间下的法线信息
                fixed3 wNormal : NORMAL;
                // 世界空间下的顶点坐标
                float3 wPos : TEXCOORD0;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.wNormal = UnityObjectToWorldNormal(v.normal);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 获取标准化观察方向向量
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.wPos);
                // 获取标准化反射方向向量
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 reflectDir = reflect(-lightDir, i.wNormal);
                fixed3 color = _LightColor0.rgb * _SpecularColor.rgb * pow(
                    max(0, dot(viewDir, reflectDir)), _SpecularLevel);
                return fixed4(color, 1);
            }
            ENDCG
        }
    }
}