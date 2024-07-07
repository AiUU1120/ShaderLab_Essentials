Shader "Study/BlinnPhongF"
{
    Properties
    {
        _MainColor("MainColor", Color) = (1, 1, 1, 1)
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
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            // 材质漫反射颜色
            fixed4 _MainColor;
            fixed4 _SpecularColor;
            float _SpecularLevel;

            // 顶点着色器传递给片元着色器的内容
            struct v2f
            {
                // 裁剪空间下的顶点坐标信息
                float4 pos: SV_POSITION;
                // 世界空间下的法线信息
                fixed3 wNormal : NORMAL;
                // 世界空间下的顶点坐标
                float3 wPos : TEXCOORD0;
            };

            // 计算兰伯特光照模型
            fixed3 getLamebrtColor(in float3 normal)
            {
                // 获取归一化的光源方向
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 color = _LightColor0.rgb * _MainColor * max(0, dot(normal, lightDir));
                return color;
            }

            // 计算Phong式高光反射
            fixed3 getBlinnPhongSpecularColor(in float3 wVertexPos, in float3 wNormal)
            {
                // 获取标准化观察方向向量
                float3 viewDir = _WorldSpaceCameraPos.xyz - wVertexPos;
                viewDir = normalize(viewDir);
                // 获取标准化反射方向向量
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 normal = UnityObjectToWorldNormal(wNormal);
                float3 halfAngle = normalize(lightDir + viewDir);
                fixed3 color = _LightColor0.rgb * _SpecularColor.rgb * pow(
                    max(0, dot(normal, halfAngle)), _SpecularLevel);
                return color;
            }

            v2f vert(appdata_base v)
            {
                v2f o;
                // 模型空间下的顶点转换到世界坐标系
                o.pos = UnityObjectToClipPos(v.vertex);
                o.wNormal = UnityObjectToWorldNormal(v.normal);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 计算兰伯特光照模型颜色
                fixed3 lambertColor = getLamebrtColor(i.wNormal);
                // 计算Phong式高光反射颜色
                fixed3 blinnPhongSpecularColor = getBlinnPhongSpecularColor(i.wPos, i.wNormal);
                fixed3 color = UNITY_LIGHTMODEL_AMBIENT + lambertColor + blinnPhongSpecularColor;
                return fixed4(color.rgb, 1);
            }
            ENDCG
        }
    }
}