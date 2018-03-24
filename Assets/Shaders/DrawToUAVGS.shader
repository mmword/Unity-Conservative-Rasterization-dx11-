Shader "Unlit/DrawToUAVGS"
{
	Properties
	{

	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		ZWrite off
		Cull off

		CGINCLUDE

		#include "UnityCG.cginc"

		float4x4 toCube;
		float3 voxelDim;
		RWTexture3D<float> uavTex : register (u1);

		ENDCG

		Pass // draw gs
		{
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom

			struct VS_IN
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct VS_OUT
			{
				float4 posW : POSITION;
				float3 norW : TEXCOORD0;
				float3 posCube : TEXCOORD1;
			};

			struct GS_OUT
			{
				float4 Pos   : SV_POSITION;
				float3 posCube : TEXCOORD0;
			};

			VS_OUT vert(VS_IN v)
			{
				//UNITY_SETUP_INSTANCE_ID(v);

				VS_OUT o;
				o.posW = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1));
				//o.posV = mul(UNITY_MATRIX_MV, float4(v.vertex.xyz, 1));
				o.norW = mul(unity_ObjectToWorld, float4(v.normal, 0)).xyz;

				//o.vertex = UnityObjectToClipPos(v.vertex);
				float4 wPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1));
				o.posCube = (mul(toCube, wPos).xyz) * voxelDim;

				return o;
			}

			[maxvertexcount(3)]
			void geom(triangle VS_OUT input[3], inout TriangleStream<GS_OUT> triStream)
			{
				// Initial data.
				float3 newPos[3];
				float3 centerPos = float3(0, 0, 0);
				float3 normal = float3(0, 0, 0);

				float4x4 gRot = { 1.f, 0.f, 0.f, 0.f,0.f, 1.f, 0.f, 0.f,0.f, 0.f, 1.f, 0.f,0.f, 0.f, 0.f, 1.f };

				// Find the center of triangle.
				for (int j = 0; j < 3; j++)
				{
					normal += input[j].norW;
					centerPos += input[j].posW.xyz;

				}
				centerPos /= 3;
				normal /= 3;

				// Rasterizing triangles may clip some parts of a triangle or even an entire triangle.
				// To make sure that every triangle is complete, the shader transform triangles.
				// Rotate triangle to be opposite with view direction to avoid clipping problem.

				// Use float3(0,0,1) as view direction,
				// find the orthogonal direction of this triangle,
				float eye_angle = dot(normal, float3(0, 0, 1));
				float3 v = cross(normal, float3(0, 0, 1));
				v = normalize(v);

				// Make sure v is not float3(0,0,0),
				if (dot(v, v) > 0) {

					// Create a rotation matrix to rotate the triangle to the opposite with view direction.
					float cost = eye_angle, sint = pow(1 - eye_angle*eye_angle, 0.5f), one_sub_cost = 1 - cost;
					float4x4 RotToCam = { v.x * v.x * one_sub_cost + cost, v.x * v.y * one_sub_cost + v.z * sint, v.x * v.z * one_sub_cost - v.y * sint, 0, \
						v.x * v.y * one_sub_cost - v.z * sint, v.y * v.y * one_sub_cost + cost, v.y * v.z * one_sub_cost + v.x * sint, 0, \
						v.x * v.z * one_sub_cost + v.y * sint, v.y * v.z * one_sub_cost - v.x * sint, v.z * v.z * one_sub_cost + cost, 0, \
						0, 0, 0, 1 };
					gRot = RotToCam;
				}

				// Apply rotation.
				for (int k = 0; k < 3; k++)
				{
					newPos[k] = input[k].posW.xyz - centerPos;
					newPos[k] = mul(gRot, float4(newPos[k], 1.0f)).xyz;
				}

				// Build a bounding box of this triangle in order to control the density of pixels that a triangle can produce.
				float minX = min(min(newPos[0].x, newPos[1].x), newPos[2].x);
				float maxX = max(max(newPos[0].x, newPos[1].x), newPos[2].x);
				float minY = min(min(newPos[0].y, newPos[1].y), newPos[2].y);
				float maxY = max(max(newPos[0].y, newPos[1].y), newPos[2].y);

				float2 RasterSize = (2 / float2(maxX - minX, maxY - minY));

				// Apply orthogonal projection.
				for (int i = 0; i < 3; i++)
				{
					GS_OUT output;
					// Transform x,y to [-1,1].
					newPos[i].xy = (newPos[i].xy - float2(minX, minY))  * RasterSize.xy - 1;
					output.Pos = float4(newPos[i].xy, 1, 1);
					//output.posV = input[i].posV;	// Assign view-space voxel positions.
					//output.norW = input[i].norW;
					output.posCube = input[i].posCube;
					triStream.Append(output);
				}

				triStream.RestartStrip();
			}

			fixed4 frag(GS_OUT pIn) : SV_Target
			{
				uavTex[pIn.posCube] = 1;
				return 0;
			}
			ENDCG
		}

		Pass // draw vs
		{
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 cubePos : TEXCOORD0;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				float4 wPos = mul(unity_ObjectToWorld,float4(v.vertex.xyz,1));
				o.cubePos = mul(toCube, wPos).xyz * voxelDim;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				uavTex[i.cubePos] = 1;
				return 0;
			}

			ENDCG
		}

		Pass // clear all
		{
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert_cl
			#pragma fragment frag_cl

			struct VS_OUT_CL
			{
				float4 pos : SV_POSITION;
				nointerpolation float3 voxelPos : TEXCOORD0;
			};

			VS_OUT_CL vert_cl(uint i :  SV_VertexID)
			{
				float xCells = voxelDim.x, yCells = voxelDim.y, zCells = voxelDim.z;

				float x = i % xCells;
				float y = ((i / xCells) % yCells);
				float z = i / (xCells * yCells);

				uint3 pos = uint3(x, y, z);
				//float content = gVoxelList[pos];
				VS_OUT_CL o;
				o.pos = 0;// mul(toMVP, float4(pos, 1));  //UnityObjectToClipPos(float4(pos, 1));
				o.voxelPos = pos;
				return o;
			}

			fixed4 frag_cl(VS_OUT_CL i) : SV_Target
			{
				uavTex[i.voxelPos] = 0;
				return 0;
			}

			ENDCG
		}

	}
}
