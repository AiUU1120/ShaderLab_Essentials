// 前向渲染下多光源的综合实现 + 接收阴影 + 光照衰减
Shader "Study/LightAttenuation"
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
            #include "AutoLight.cginc"

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
                // 阴影坐标宏
                SHADOW_COORDS(2)
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
                // 计算阴影映射纹理坐标 它会在内部计算 然后将其存入v2f中的SHADOW_COORDS中
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 计算兰伯特光照模型颜色
                fixed3 lambertColor = getLamebrtColor(i.wNormal);
                // 计算Phong式高光反射颜色
                fixed3 blinnPhongSpecularColor = getBlinnPhongSpecularColor(i.wPos, i.wNormal);
                // 阴影衰减值
                // 该宏会在内部利用v2f中的ShadowCoord对相关纹理进行采样 将采样得到的深度值进行比较 计算出阴影衰减值
                //fixed3 shadow = SHADOW_ATTENUATION(i);
                // 光照衰减值
                //fixed atten = 1;
                UNITY_LIGHT_ATTENUATION(atten, i, i.wPos);
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
            //#pragma multi_compile_fwdadd
            #pragma multi_compile_fwdadd_fullshadows
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

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
                // 阴影坐标宏
                SHADOW_COORDS(2)
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                // 模型空间下的顶点转换到世界坐标系
                o.pos = UnityObjectToClipPos(v.vertex);
                o.wNormal = UnityObjectToWorldNormal(v.normal);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // 计算阴影映射纹理坐标 它会在内部计算 然后将其存入v2f中的SHADOW_COORDS中
                TRANSFER_SHADOW(o);
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
                fixed3 lambertColor = _LightColor0.rgb * _MainColor.rgb * max(0, dot(normalize(i.wNormal), worldLightDir));
                // 计算Phong式高光反射颜色
                fixed3 viewDir = normalize(_WorldSpaceCameraPos - i.wPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 blinnPhongSpecularColor = _LightColor0.rgb * _SpecularColor.rgb * pow(
                    max(0, dot(normalize(i.wNormal), halfDir)), _SpecularLevel);
                // 光照衰减值
                //#if defined(_DIRECTIONAL_LIGHT)
                //    fixed atten = 1;
                //#elif defined(_POINT_LIGHT) // 点光源
                    // 将世界坐标系下顶点转到点光源下
                //    float3 lightCoord = mul(unity_WorldToLight, float4(i.wPos, 1)).xyz;
                    // 光照衰减纹理采样
                //    fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).xx).UNITY_ATTEN_CHANNEL;
                //#elif defined(_SPOT_LIGHT)  // 聚光灯
                //    float4 lightCoord = mul(unity_WorldToLight, float4(i.wPos, 1));
                //    fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w *
                //        tex2D(_LightTextureB0, dot(lightCoord, lightCoord).xx).UNITY_ATTEN_CHANNEL;
                //#else
                //    fixed atten = 1;
                //#endif
                UNITY_LIGHT_ATTENUATION(atten, i, i.wPos);
                // 在附加渲染通道中不需要再加环境光颜色了 只需要计算一次 已经在基础渲染通道中渲染了
                return fixed4((lambertColor + blinnPhongSpecularColor) * atten, 1);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}