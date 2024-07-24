// 世界空间下计算法线纹理贴图
Shader "Study/StandardDiffuse"
{
    Properties
    {
        _MainColor("MainColor", Color) = (1, 1, 1, 1)
        // 主纹理
        _MainTex("MainTex", 2D) = ""{}
        // 凹凸纹理
        _BumpMap("BumpMap", 2D) = ""{}
        // 凹凸程度
        _BumpScale("BumpScale", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            // 不透明物体通常使用几何队列
            "Queue" = "Geometry"
        }
        Pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct v2f
            {
                float4 pos: SV_POSITION;
                float4 uv : TEXCOORD0;
                // 切线空间到世界空间的变换矩阵的三行
                // 多出来的w分量存储顶点在世界空间中的坐标
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;

                SHADOW_COORDS(4)
            };

            float4 _MainColor;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;

            v2f vert(appdata_full v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // 计算纹理的缩放偏移
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                float3 wPos = mul(unity_ObjectToWorld, v.vertex);
                // 把模型空间法线转换到世界空间
                float3 wNormal = UnityObjectToWorldNormal(v.normal);
                // 把模型空间切线转换到世界空间
                float3 wTangent = UnityObjectToWorldDir(v.tangent);
                // 计算副切线 = 切线与法线叉乘
                float3 wBinormal = cross(normalize(wTangent), normalize(wNormal)) * v.tangent.w;
                // 转换矩阵
                o.TtoW0 = float4(wTangent.x, wBinormal.x, wNormal.x, wPos.x);
                o.TtoW1 = float4(wTangent.y, wBinormal.y, wNormal.y, wPos.y);
                o.TtoW2 = float4(wTangent.z, wBinormal.z, wNormal.z, wPos.z);

                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 世界空间下光的方向
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 wPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                // 世界空间下视角方向
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(wPos));
                // 通过纹理采样函数取出法线纹理贴图中的数据
                float4 packedNormal = tex2D(_BumpMap, i.uv.zw);
                // 将取出来的法线数据进行逆运算并进行解压缩运算 最终得到切线空间下的法线数据
                float3 tangentNormal = UnpackNormal(packedNormal);
                tangentNormal *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                float3 wNormal = float3(dot(i.TtoW0.xyz, tangentNormal), dot(i.TtoW1.xyz, tangentNormal),
                                        dot(i.TtoW2.xyz, tangentNormal));
                // 漫反射材质颜色与纹理颜色叠加
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _MainColor.rgb;
                // 计算兰伯特光照模型颜色
                fixed3 lambertColor = _LightColor0.rgb * albedo * max(0, dot(wNormal, normalize(lightDir)));
                
                UNITY_LIGHT_ATTENUATION(atten, i, wPos);
                
                fixed3 color = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo + lambertColor * atten;
                return fixed4(color.rgb, 1);
            }
            ENDCG
        }
        // 附加渲染通道
        Pass
        {
            Tags
            {
                "LightMode"="ForwardAdd"
            }
            
            Blend One One
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct v2f
            {
                float4 pos: SV_POSITION;
                float4 uv : TEXCOORD0;
                // 切线空间到世界空间的变换矩阵的三行
                // 多出来的w分量存储顶点在世界空间中的坐标
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;

                SHADOW_COORDS(4)
            };

            float4 _MainColor;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;

            v2f vert(appdata_full v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // 计算纹理的缩放偏移
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                float3 wPos = mul(unity_ObjectToWorld, v.vertex);
                // 把模型空间法线转换到世界空间
                float3 wNormal = UnityObjectToWorldNormal(v.normal);
                // 把模型空间切线转换到世界空间
                float3 wTangent = UnityObjectToWorldDir(v.tangent);
                // 计算副切线 = 切线与法线叉乘
                float3 wBinormal = cross(normalize(wTangent), normalize(wNormal)) * v.tangent.w;
                // 转换矩阵
                o.TtoW0 = float4(wTangent.x, wBinormal.x, wNormal.x, wPos.x);
                o.TtoW1 = float4(wTangent.y, wBinormal.y, wNormal.y, wPos.y);
                o.TtoW2 = float4(wTangent.z, wBinormal.z, wNormal.z, wPos.z);

                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 世界空间下光的方向
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 wPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                // 世界空间下视角方向
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(wPos));
                // 通过纹理采样函数取出法线纹理贴图中的数据
                float4 packedNormal = tex2D(_BumpMap, i.uv.zw);
                // 将取出来的法线数据进行逆运算并进行解压缩运算 最终得到切线空间下的法线数据
                float3 tangentNormal = UnpackNormal(packedNormal);
                tangentNormal *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                float3 wNormal = float3(dot(i.TtoW0.xyz, tangentNormal), dot(i.TtoW1.xyz, tangentNormal),
                                        dot(i.TtoW2.xyz, tangentNormal));
                // 漫反射材质颜色与纹理颜色叠加
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _MainColor.rgb;
                // 计算兰伯特光照模型颜色
                fixed3 lambertColor = _LightColor0.rgb * albedo * max(0, dot(wNormal, normalize(lightDir)));
                
                UNITY_LIGHT_ATTENUATION(atten, i, wPos);
                
                fixed3 color = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo + lambertColor * atten;
                return fixed4(color.rgb, 1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}