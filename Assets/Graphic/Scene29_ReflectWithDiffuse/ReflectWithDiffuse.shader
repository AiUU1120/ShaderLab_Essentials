Shader "Study/ReflectWithDiffuse"
{
    Properties
    {
        // 漫反射颜色
        _Color("Color", Color) = (1, 1, 1, 1)
        // 反射颜色
        _ReflectColor("ReflectColor", Color) = (1, 1, 1, 1)
        // 立方体纹理
        _Cube("CubeMap", Cube) = ""{}
        // 反射率
        _Reflectivity("Reflectivity", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderQueue" = "Geometry"
        }
        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            fixed4 _ReflectColor;
            samplerCUBE _Cube;
            float _Reflectivity;

            struct v2f
            {
                float4 pos : SV_POSITION;
                // 世界空间下法线
                float3 worldNormal : NORMAL;
                // 世界空间下顶点
                float3 worldPos : TEXCOORD0;
                // 世界空间下的反射向量
                float3 worldRefl : TEXCOORD1;
                // 阴影
                SHADOW_COORDS(2)
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // 计算反射光向量
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                // 世界空间下的顶点坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // 计算视角方向 内部计算是用摄像机位置-目标世界坐标位置
                fixed3 worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                // 计算反射向量
                o.worldRefl = reflect(-worldViewDir, o.worldNormal);
                // 阴影相关处理
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 漫反射光照计算
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                // 漫反射颜色
                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(normalize(i.worldNormal), worldLightDir));
                // 对立方体纹理利用对应的反射向量进行采样
                fixed3 cubemapColor = texCUBE(_Cube, i.worldRefl).rgb * _ReflectColor.rgb;
                // 阴影衰减
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                // 利用lerp在漫反射颜色和反射颜色间进行差值
                fixed3 color = UNITY_LIGHTMODEL_AMBIENT.rgb + lerp(diffuse, cubemapColor, _Reflectivity) * atten;
                return fixed4(color, 1);
            }
            ENDCG
        }
    }
    FallBack "Reflective/VertexLit"
}