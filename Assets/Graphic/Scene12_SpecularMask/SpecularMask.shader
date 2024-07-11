// 高光遮罩纹理结合切线空间下法线纹理
Shader "Study/SpecularMask"
{
    Properties
    {
        _MainColor("MainColor", Color) = (1, 1, 1, 1)
        // 高光反射颜色
        _SpecularColor("SpecularColor", Color) = (1,1,1,1)
        // 光泽度
        _SpecularLevel("SpecularLevel", Range(0, 20)) = 0.5
        // 主纹理
        _MainTex("MainTex", 2D) = ""{}
        // 高光遮罩纹理
        _SpecularMask("SpecularMask", 2D) = ""{}
        // 遮罩系数
        _SpecularMaskLevel("SpecularMaskLevel", Float) = 1
        // 凹凸纹理
        _BumpMap("BumpMap", 2D) = ""{}
        // 凹凸程度
        _BumpScale("BumpScale", Range(0, 1)) = 1
    }
    SubShader
    {
        Pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct v2f
            {
                float4 pos: SV_POSITION;
                float4 uv : TEXCOORD0;
                // 光的方向 相对于切线空间下
                float3 lightDir : TEXCOORD1;
                // 视角方向 相对于切线空间下
                float3 viewDir : TEXCOORD2;
            };

            float4 _MainColor;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            sampler2D _SpecularMask;
            float4 _SpecularMask_ST;
            float _SpecularMaskLevel;
            float4 _SpecularColor;
            fixed _SpecularLevel;

            v2f vert(appdata_full v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // 计算纹理的缩放偏移
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                // 在顶点着色器中得到模型空间到切线空间的转换矩阵
                // 计算副切线 = 切线与法线叉乘
                float3 binormal = cross(normalize(v.tangent), normalize(v.normal)) * v.tangent.w;
                // 转换矩阵
                float3x3 rotation = float3x3(v.tangent.xyz,
                                             binormal,
                                             v.normal);
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 通过纹理采样函数取出法线纹理贴图中的数据
                float4 packedNormal = tex2D(_BumpMap, i.uv.zw);
                // 将取出来的法线数据进行逆运算并进行解压缩运算 最终得到切线空间下的法线数据
                float3 tangentNormal = UnpackNormal(packedNormal);
                tangentNormal *= _BumpScale;
                // 漫反射材质颜色与纹理颜色叠加
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _MainColor.rgb;
                // 计算兰伯特光照模型颜色
                fixed3 lambertColor = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, normalize(i.lightDir)));
                // 计算半角向量
                float3 halfAngle = normalize(normalize(i.lightDir) + normalize(i.viewDir));
                // 计算高光遮罩纹理值
                fixed specularMaskNum = tex2D(_SpecularMask, i.uv.xy).r * _SpecularMaskLevel;
                // 计算Phong式高光反射颜色
                fixed3 blinnPhongSpecularColor = _LightColor0.rgb * _SpecularColor.rgb * pow(
                    max(0, dot(tangentNormal, halfAngle)), _SpecularLevel) * specularMaskNum;
                fixed3 color = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo + lambertColor + blinnPhongSpecularColor;
                return fixed4(color.rgb, 1);
            }
            ENDCG
        }
    }
}