Shader "Study/TestShader1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MyNumber ("MyNumber", Int) = 1
        _MyRange ("MyRange", Range(1, 10)) = 3
        _MyColor ("MyColor", Color) = (1, 0, 0, 1)
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 _MyColor;
            
            float4 vert(float4 v: POSITION): SV_POSITION
            {
                return UnityObjectToClipPos(v);
            }

            fixed4 frag() : SV_Target
            {
                return _MyColor;
            }
            ENDCG
        }
    }
}