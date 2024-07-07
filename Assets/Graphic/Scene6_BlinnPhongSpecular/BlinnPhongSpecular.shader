Shader "Study/BlinnPhongSpecular"
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
        Pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }
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
                fixed3 color : COLOR;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                // 获得标准化顶点法线向量
                float3 normal = UnityObjectToWorldDir(v.normal);
                // 将模型空间下的顶点位置转换到世界空间下
                float3 worldPos = mul(UNITY_MATRIX_M, v.vertex);
                // 获取标准化半角方向向量
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 halfAngle = normalize(viewDir + lightDir);
                o.color = _LightColor0.rgb * _SpecularColor.rgb * pow(max(0, dot(normal, halfAngle)), _SpecularLevel);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return fixed4(i.color.rgb, 1);
            }
            ENDCG
        }
    }
}