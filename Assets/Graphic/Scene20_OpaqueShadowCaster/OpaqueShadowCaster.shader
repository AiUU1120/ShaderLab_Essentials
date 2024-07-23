// 前向渲染下多光源的综合实现 + 阴影投射
Shader "Study/OpaqueShadowCaster"
{
    Properties
    {
        _MainColor("MainColor", Color) = (1, 1, 1, 1)
        // 高光反射颜色
        _SpecularColor("SpecularColor", Color) = (1,1,1,1)
        // 光泽度
        _SpecularLevel("SpecularLevel", Range(0, 255)) = 15
    }
    SubShader
    {
        // 基础渲染通道
        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // 用于帮助编译所有变体
            #pragma multi_compile_fwdbase

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
                // 光照衰减值
                fixed atten = 1;
                fixed3 color = UNITY_LIGHTMODEL_AMBIENT + (lambertColor + blinnPhongSpecularColor) * atten;
                return fixed4(color.rgb, 1);
            }
            ENDCG
        }
        // 附加渲染通道
        Pass
        {
            Tags
            {
                "LightMode" = "ForwardAdd"
            }
            // 开启混合 线性减淡
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // 用于帮助编译所有变体
            #pragma multi_compile_fwdadd

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
                // 平行光
                #if defined(_DIRECTIONAL_LIGHT)
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                #else // 点光源和聚光灯
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.wPos);
                #endif
                fixed3 lambertColor = _LightColor0.rgb * _MainColor.rgb * max(
                    0, dot(normalize(i.wNormal), worldLightDir));
                // 计算Phong式高光反射颜色
                fixed3 viewDir = normalize(_WorldSpaceCameraPos - i.wPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 blinnPhongSpecularColor = _LightColor0.rgb * _SpecularColor.rgb * pow(
                    max(0, dot(normalize(i.wNormal), halfDir)), _SpecularLevel);
                // 光照衰减值
                #if defined(_DIRECTIONAL_LIGHT)
                    fixed atten = 1;
                #elif defined(_POINT_LIGHT) // 点光源
                    // 将世界坐标系下顶点转到点光源下
                    float3 lightCoord = mul(unity_WorldToLight, float4(i.wPos, 1)).xyz;
                    // 光照衰减纹理采样
                    fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).xx).UNITY_ATTEN_CHANNEL;
                #elif defined(_SPOT_LIGHT)  // 聚光灯
                    float4 lightCoord = mul(unity_WorldToLight, float4(i.wPos, 1));
                    fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w *
                        tex2D(_LightTextureB0, dot(lightCoord, lightCoord).xx).UNITY_ATTEN_CHANNEL;
                #else
                fixed atten = 1;
                #endif
                // 在附加渲染通道中不需要再加环境光颜色了 只需要计算一次 已经在基础渲染通道中渲染了
                return fixed4((lambertColor + blinnPhongSpecularColor) * atten, 1);
            }
            ENDCG
        }
        // 该Pass用于计算阴影
        Pass
        {
            Tags
            {
                "lightMode" = "ShadowCaster"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // 该编译指令告诉Unity编译器生成多个着色器变体 用于支持不同类型的阴影 SM SSSM等 可以确保着色器在所有可能的阴影投射模式下正确渲染
            #pragma multi_compile_shadowcaster

            #include "UnityCG.cginc"

            struct v2f
            {
                // 该宏为顶点到片元着色器阴影投射结构数据结构宏 定义了一些标准成员变量 用于在阴影投射路径中传递顶点数据到片元着色器
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata_base v)
            {
                v2f data;
                // 转移阴影投射器法线偏移宏 用于在顶点着色器中计算和传递阴影投射所需的变量
                // 主要做了 将对象空间的顶点位置转换为裁剪空间的位置
                // 考虑法线偏移 以减轻阴影失真问题 尤其是在处理自阴影时
                // 传递顶点的投影空间位置 用于后续的阴影计算
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(data);
                return data;
            }

            float4 frag(v2f i) : SV_Target
            {
                // 投射阴影片元宏
                // 将深度值写入到阴影映射纹理中
                SHADOW_CASTER_FRAGMENT(i);
            }
            
            ENDCG
        }
    }

}