Shader "Unlit/DrawVoxelCubesTransparency"
{
	Properties
	{

	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }

		Alphatest Greater 0
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask RGB

		Pass
		{
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom
			#include "UnityCG.cginc"

			//RWTexture3D<float> gVoxelList : register (u1);
			Texture3D<float> gVoxelList;
			float3 voxelDim;
			float4x4 toMVP;

			struct GS_OUT
			{
				float4 Pos	: SV_Position;
				nointerpolation float3 voxelPos : TEXCOORD0;
			};

			struct VS_OUT
			{
				float4 pos : POSITION;
				nointerpolation float3 voxelPos : TEXCOORD0;
			};

			VS_OUT vert (uint i :  SV_VertexID) : POSITION
			{
				float xCells = voxelDim.x, yCells = voxelDim.y, zCells = voxelDim.z;

				float x = i % xCells;
				float y = ((i / xCells) % yCells);
				float z = i / (xCells * yCells);

				uint3 pos = uint3(x, y, z);
				float content = gVoxelList[pos];
				VS_OUT o;
				o.pos = float4(pos, content);
				o.voxelPos = pos;
				return o;
			}

			[maxvertexcount(24)]
			void geom(point VS_OUT input[1], inout TriangleStream<GS_OUT> triStream)
			{
				if (input[0].pos.w > 0.01f)
				{
					const float3 boxOffset[24] =
					{
						1, -1, 1,
						1, 1, 1,
						-1, -1, 1,
						-1, 1, 1,

						-1, 1, 1,
						-1, 1, -1,
						-1, -1, 1,
						-1, -1, -1,

						1, 1, -1,
						1, 1, 1,
						1, -1, -1,
						1, -1, 1,

						-1, 1, -1,
						1, 1, -1,
						-1, -1, -1,
						1, -1, -1,

						1, 1, 1,
						1, 1, -1,
						-1, 1, 1,
						-1, 1, -1,

						-1, -1, -1,
						1, -1, -1,
						-1, -1, 1,
						1, -1, 1
					};

					// Generate vertexes for six faces.
					for (int i = 0; i < 6; i++)
					{
						// Generate four vertexes for a face.
						for (int j = 0; j < 4; j++)
						{
							GS_OUT outGS;
							// Create cube vertexes with boxOffset array.
							float3 vertex = input[0].pos.xyz + boxOffset[i * 4 + j] * 0.5f;
							// Output both geometry data for rendering a cube and voxel data for visualization.
							vertex /= voxelDim;

							outGS.Pos = mul(toMVP,float4(vertex, 1));
							outGS.voxelPos = input[0].voxelPos;
							triStream.Append(outGS);

						}
						triStream.RestartStrip();
					}
				}
			}
			
			fixed4 frag (GS_OUT i) : SV_Target
			{
				float m = gVoxelList[i.voxelPos];


				//float4 src = saturate(lerp(float4(0, -1.41, -3, 0), float4(1.41, 1.41, 1, 0), m / 3));
				//src = ((src - 0.2) * 2);
				return m / 3;

				//return v;// saturate(lerp(float4(0, -1.41, -3, -0.4), float4(1.41, 1.41, 1, 1.41), v));
			}

			ENDCG
		}
	}
}
