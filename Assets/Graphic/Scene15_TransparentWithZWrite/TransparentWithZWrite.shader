Shader "Study/TransparentWithZWrite"
{
    Properties
    {
        // 主纹理
        _MainTex("MainTex", 2D) = ""{}
        // 漫反射颜色
        _MainColor("MainColor", Color) = (1, 1, 1, 1)
        // 高光反射颜色
        _SpecularColor("SpecularColor", Color) = (1,1,1,1)
        // 光泽度
        _SpecularLevel("SpecularLevel", Range(0, 255)) = 15
        // 透明度
        _AlphaScale("AlphaScale", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags
        {
            "Queue" = "AlphaTest"
            "IgnoreProjector" = "True"
            "RenderType" = "TransparentCutout"
        }

        // 该Pass进行深度写入但不输出颜色
        Pass
        {
            ZWrite On
            ColorMask 0
        }

        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            // 处理半透明效果要关闭深度写入
            Zwrite off
            // 将混合因子设为半透明效果的搭配
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            // 纹理贴图对应的成员
            sampler2D _MainTex;
            float4 _MainTex_ST;
            // 材质漫反射颜色、高光反射颜色、光泽度
            fixed4 _MainColor;
            fixed4 _SpecularColor;
            float _SpecularLevel;
            fixed _AlphaScale;

            // 顶点着色器传递给片元着色器的内容
            struct v2f
            {
                // 裁剪空间下的顶点坐标信息
                float4 pos: SV_POSITION;
                // uv坐标
                float2 uv : TEXCOORD0;
                // 世界空间下的法线信息
                fixed3 wNormal : NORMAL;
                // 世界空间下的顶点坐标
                float3 wPos : TEXCOORD1;
            };

            // 计算兰伯特光照模型
            fixed3 getLamebrtColor(in float3 normal, in float3 albedo)
            {
                // 获取归一化的光源方向
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                fixed3 color = _LightColor0.rgb * albedo * max(0, dot(normal, lightDir));
                return color;
            }

            // 计算Phong式高光反射
            fixed3 getBlinnPhongSpecularColor(in float3 wVertexPos, in float3 wNormal)
            {
                // 获取标准化观察方向向量
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - wVertexPos);
                // 获取标准化光方向向量
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                // 计算世界空间下的法线向量
                float3 normal = UnityObjectToWorldNormal(wNormal);
                // 计算半角向量
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
                // uv坐标运算
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                // 世界空间下的法线
                o.wNormal = UnityObjectToWorldNormal(v.normal);
                // 世界空间下的顶点坐标
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 取出纹理颜色
                fixed4 texColor = tex2D(_MainTex, i.uv);
                // 漫反射材质颜色与纹理颜色叠加
                fixed3 albedo = texColor.rgb * _MainColor.rgb;
                // 计算兰伯特光照模型颜色
                fixed3 lambertColor = getLamebrtColor(i.wNormal, albedo);
                // 计算Phong式高光反射颜色
                fixed3 blinnPhongSpecularColor = getBlinnPhongSpecularColor(i.wPos, i.wNormal);
                fixed3 color = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo + lambertColor + blinnPhongSpecularColor;
                return fixed4(color.rgb, texColor.a * _AlphaScale);
            }
            ENDCG
        }
    }
}