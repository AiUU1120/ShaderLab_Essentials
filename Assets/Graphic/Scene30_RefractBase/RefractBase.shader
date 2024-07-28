Shader "Study/RefractBase"
{
    Properties
    {
        // 介质A折射率
        _RefractiveIndexA("RefractiveIndexA", Range(1, 2)) = 1
        // 戒指B折射率
        _RefractiveIndexB("RefractiveIndexB", Range(1, 2)) = 1
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
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            samplerCUBE _Cube;
            fixed _RefractiveIndexA;
            fixed _RefractiveIndexB;
            fixed _RefractLevel;

            struct v2f
            {
                float4 pos :SV_POSITION;
                // 折射向量
                float3 worldRefr : TEXCOORD0;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldViewDir = UnityWorldSpaceViewDir(worldPos);
                // 计算折射向量
                o.worldRefr = refract(-normalize(worldViewDir), normalize(worldNormal),
                                      _RefractiveIndexA / _RefractiveIndexB);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 立方体纹理采样
                fixed4 cubemapColor = texCUBE(_Cube, i.worldRefr);
                return cubemapColor * _RefractLevel;
            }
            ENDCG
        }
    }
}