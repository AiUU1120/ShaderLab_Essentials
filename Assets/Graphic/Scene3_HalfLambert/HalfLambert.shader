Shader "Study/HalfLambert"
{
    Properties
    {
        _MainColor("MainColor", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags
        {
            "LightMode" = "ForwardBase"
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            // 材质漫反射颜色
            fixed4 _MainColor;

            // 顶点着色器传递给片元着色器的内容
            struct v2f
            {
                // 裁剪空间下的顶点坐标信息
                float4 pos: SV_POSITION;
                // 对应顶点的漫反射光照颜色
                fixed3 color: COLOR;
            };

            // 逐顶点光照 所以把光照计算写在顶点着色器中
            v2f vert(appdata_base v)
            {
                v2f o;
                // 模型空间下的顶点转换到世界坐标系
                o.pos = UnityObjectToClipPos(v.vertex);

                // 获取世界坐标下的法线信息
                float3 normal = UnityObjectToWorldNormal(v.normal);
                // 获取归一化的光源方向
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                fixed3 color = _LightColor0.rgb * _MainColor * (dot(normal, lightDir) * 0.5 + 0.5);
                // 记录颜色 传递给片元着色器
                o.color = color + UNITY_LIGHTMODEL_AMBIENT.rgb;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 把计算好的兰伯特光照颜色传递出去
                return fixed4(i.color.rgb, 1);
            }
            ENDCG
        }
    }
}