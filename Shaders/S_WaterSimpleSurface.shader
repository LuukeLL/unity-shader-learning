Shader "Custom/S_WaterSimpleSurface" {
Properties {
    _WaterColor ("Water Color", Color) = (1, 1, 1, 1)
    _FoamColor ("Foam Color", Color) = (1, 1, 1, 1)
    _FoamMultiply ("Foam Multiplier", Range(1.0, 5.0)) = 1.0
    _ShoreColor ("Shore Color", Color) = (1, 1, 1, 1)
    _ShoreFactor ("Shore Factor", Range(0.01,3.0)) = 1.0

	_WaveSpeed("Wave Speed", float) = 1.0
	_WaveAmp("Wave Amp", float) = 0.2

    _NoiseTex ("NoiseTex (RGB)", 2D) = "white" {}
    _FoamTex("Foam Texture", 2D) = "white" {}
    _ShoreTex("Shore Texture", 2D) = "white" {}

    _Glossiness ("Smoothness", Range(0,1)) = 0.5
    _Metallic ("Metallic", Range(0,1)) = 0.0

   


    }
    SubShader {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 200
       
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard vertex:vert alpha:fade nolightmap
 
        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
 

        
 
        struct Input {
            float2 uv_FoamTex;
       
            float4 screenPos;
            float eyeDepth;
            float3 localPos;
        };
 

 		// For reading the DepthBuffer
 		// Must NOT! be in the Properties
        sampler2D _CameraDepthTexture;
        float4 _CameraDepthTexture_TexelSize;

        sampler2D _NoiseTex;
        float _WaveSpeed;
        float _WaveAmp;

 
        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);

            // Get the eyeDepth into the output
            COMPUTE_EYEDEPTH(o.eyeDepth);
           
           	// Load the NoiseTexture and modify y and x vertex coordinates
			float noiseSample = tex2Dlod(_NoiseTex, float4(v.texcoord.xy, 0, 0));

			v.vertex.y += sin(_Time * _WaveSpeed * noiseSample) *_WaveAmp;
			v.vertex.x += cos(_Time * _WaveSpeed * noiseSample) *_WaveAmp;

			// Write the modified local position to the output
			o.localPos = v.vertex.xyz;
        }


 
        fixed4 _WaterColor;
        fixed4 _FoamColor;
        fixed4 _ShoreColor;
        float _ShoreFactor;
        float _FoamMultiply;
        sampler2D _FoamTex;
        sampler2D _ShoreTex;

        half _Glossiness;
        half _Metallic;

        void surf (Input IN, inout SurfaceOutputStandard o) {

			// Texture for the Shore-Effect
            fixed4 foam = tex2D(_FoamTex, IN.uv_FoamTex);

            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;

            // Calculate the correct Depth-Value 
            float rawZ = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos));
            float sceneZ = LinearEyeDepth(rawZ);
            float partZ = IN.eyeDepth;
 
            float fade = 1.0;
            if ( rawZ > 0.0 ){ // Check if the depth-buffer exists
                fade = saturate(_ShoreFactor * (sceneZ - partZ));
            }

            float4 shoreRamp = float4(tex2D(_ShoreTex, float2(fade, 0.5)).rgb, 1.0);

            float3 foamCol = _FoamColor * lerp(0, foam.a, IN.localPos.y * _FoamMultiply) + _WaterColor * (1 - lerp(0, foam.a, IN.localPos.y));
            float3 shoreCol =  _ShoreColor * (1-fade) * shoreRamp.rgb;

            o.Albedo.rgb = _WaterColor + foamCol + shoreCol;

            o.Alpha = 1.0;
        }
        ENDCG
    }
}
