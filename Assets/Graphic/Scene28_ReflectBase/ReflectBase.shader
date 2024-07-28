Shader "Study/ReflectBase"
{
    Properties
    {
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

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            samplerCUBE _Cube;
            float _Reflectivity;

            struct v2f
            {
                float4 pos : SV_POSITION;
                // 世界空间下的反射向量
                float3 worldRefl : TEXCOORD0;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // 计算反射光向量
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                // 世界空间下的顶点坐标
                fixed3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // 计算视角方向 内部计算是用摄像机位置-目标世界坐标位置
                fixed3 worldViewDir = UnityWorldSpaceViewDir(worldPos);
                // 计算反射向量
                o.worldRefl = reflect(-worldViewDir, worldNormal);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 对立方体纹理利用对应的反射向量进行采样
                fixed4 cubemapColor = texCUBE(_Cube, i.worldRefl);
                return cubemapColor * _Reflectivity;
            }
            
            ENDCG
        }
    }
}