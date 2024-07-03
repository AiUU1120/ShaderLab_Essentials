Shader "Study/LambertF"
{
    Properties
    {
        _MainColor("MainColor", Color) = (1,1,1,1)
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

            fixed4 _MainColor;

            struct v2f
            {
                // 裁剪空间下的顶点位置
                float4 vertex : SV_POSITION;
                // 世界空间下的法线位置
                float3 normal : NORMAL;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                // 转换模型空间下的顶点到裁剪空间中
                o.vertex = UnityObjectToClipPos(v.vertex);
                // 转换模型空间下的法线到世界空间中
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 得到光源单位向量
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 color = _LightColor0.rgb * _MainColor.rgb * max(0, dot(i.normal, lightDir));
                color = UNITY_LIGHTMODEL_AMBIENT + color;
                return fixed4(color.rgb, 1);
            }
            ENDCG
        }
    }
}