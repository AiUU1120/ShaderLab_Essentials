Shader "Study/RefractWithDiffuse"
{
    Properties
    {
        // 折射率比值
        _RefractRadio("RefractRadio", Range(0.1, 1)) = 0.5
        // 漫反射颜色
        _Color("Color", Color) = (1, 1, 1, 1)
        // 折射颜色
        _RefractColor("RefractColor", Color) = (1, 1, 1, 1)
        // 立方体纹理贴图
        _Cube("Cubemap", Cube) = ""{}
        // 折射程度
        _RefractLevel("RefractLevel", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "Queue" = "Geometry"
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
            fixed4 _RefractColor;
            samplerCUBE _Cube;
            fixed _RefractRadio;
            fixed _RefractLevel;

            struct v2f
            {
                float4 pos :SV_POSITION;
                // 世界空间下法线
                float3 worldNormal : NORMAL;
                // 世界空间下顶点
                float3 worldPos : TEXCOORD0;
                // 折射向量
                float3 worldRefr : TEXCOORD1;
                // 阴影
                SHADOW_COORDS(2)
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                // 计算折射向量
                o.worldRefr = refract(-normalize(worldViewDir), normalize(o.worldNormal),
                                      _RefractRadio);
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
                // 立方体纹理采样
                fixed3 cubemapColor = texCUBE(_Cube, i.worldRefr).rgb * _RefractColor.rgb;
                // 阴影衰减
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                // 利用lerp在漫反射颜色和反射颜色间进行差值
                fixed3 color = UNITY_LIGHTMODEL_AMBIENT.rgb + lerp(diffuse, cubemapColor, _RefractLevel) * atten;
                return fixed4(color, 1);
            }
            ENDCG
        }
    }
    FallBack "Reflective/VertexLit"
}