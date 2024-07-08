Shader "Study/NormalTexture"
{
    Properties
    {
        // 主纹理
        _MainTex("MainTex", 2D) = ""{}
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // 映射对应纹理属性的图片颜色相关数据
            sampler2D _MainTex;
            // 映射对应纹理属性的缩放偏移数据 固定命名_ST
            float4 _MainTex_ST;

            v2f_img vert(appdata_base v)
            {
                v2f_img o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // 先缩放再偏移
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                // 另一种写法
                //TRANSFORM_UV(v.texcoord.xy, _MainTex);
                return o;
            }

            fixed4 frag(v2f_img i) : SV_Target
            {
                float4 color = tex2D(_MainTex, i.uv);
                return color;
            }
            ENDCG
        }
    }
}