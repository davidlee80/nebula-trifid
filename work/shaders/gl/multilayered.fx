//------------------------------------------------------------------------------
//  multilayered.fx
//  (C) 2012 Gustav Sterbrant
//------------------------------------------------------------------------------

#include "lib/std.fxh"
#include "lib/util.fxh"
#include "lib/shared.fxh"
#include "lib/techniques.fxh"
#include "lib/defaultsamplers.fxh"
#include "lib/shadowbase.fxh"
#include "lib/geometrybase.fxh"

sampler2D DiffuseMap2;
sampler2D DiffuseMap3;
sampler2D SpecularMap2;
sampler2D SpecularMap3;
sampler2D EmissiveMap2;
sampler2D EmissiveMap3;
sampler2D NormalMap2;
sampler2D NormalMap3;
sampler2D RoughnessMap2;
sampler2D RoughnessMap3;

sampler2D DisplacementMap2;
sampler2D DisplacementMap3;

samplerstate MLPSampler
{
	Samplers = { DiffuseMap2, DiffuseMap3, SpecularMap2, 
		     SpecularMap3, EmissiveMap2, EmissiveMap3, 
		     NormalMap2, NormalMap3, RoughnessMap2,  
		     RoughnessMap3, DisplacementMap2, DisplacementMap3};
	AddressU = Wrap;
	AddressV = Wrap;
	Filter = MinMagMipLinear;
};

state MLPState
{
	CullMode = Back;
};

//------------------------------------------------------------------------------
/**
	Used for multi-layered painting
*/
shader
void
vsColored(in vec3 position,
	in vec3 normal,
	in vec2 uv,
	in vec4 color,
	in vec3 tangent,
	in vec3 binormal,
	out vec3 ViewSpacePos,
	out vec3 Tangent,
	out vec3 Normal,
	out vec3 Binormal,
	out vec2 UV,
	out vec4 Color,
	out vec3 WorldViewVec) 
{
	vec4 modelSpace = Model * vec4(position, 1);
	gl_Position = ViewProjection * modelSpace;
	UV = vec2(uv.x * NumXTiles, uv.y * NumYTiles);
	Color = color;
	mat4 modelView = View * Model;
	
	ViewSpacePos = (modelView * vec4(position, 1)).xyz;
	Tangent = (modelView * vec4(tangent, 0)).xyz;
	Normal = (modelView * vec4(normal, 0)).xyz;
	Binormal = (modelView * vec4(binormal, 0)).xyz;
	WorldViewVec = modelSpace.xyz - EyePos.xyz;
}

//------------------------------------------------------------------------------
/**
	Used for multi-layered painting
*/
shader
void
vsColoredShadow(in vec3 position,
	in vec3 normal,
	in vec2 uv,
	in vec4 color,
	in vec3 tangent,
	in vec3 binormal,
	out vec2 UV,
	out vec4 ProjPos) 
{
	vec4 pos = LightViewProjection * Model * vec4(position, 1);
	gl_Position = pos;
	ProjPos = pos;
	UV = vec2(uv.x * NumXTiles, uv.y * NumYTiles);
}

//------------------------------------------------------------------------------
/**
	Used for multi-layered painting
*/
shader
void
vsColoredCSM(in vec3 position,
	in vec3 normal,
	in vec2 uv,
	in vec4 color,
	in vec3 tangent,
	in vec3 binormal,
	out vec2 UV,
	out vec4 ProjPos,
	out int Instance) 
{
	ProjPos = ViewMatrixArray[gl_InstanceID] * Model * vec4(position, 1);
	UV = vec2(uv.x * NumXTiles, uv.y * NumYTiles);
	Instance = gl_InstanceID;
}

//------------------------------------------------------------------------------
/**
	Used for multi-layered painting
*/
shader
void
vsColoredTessellated(in vec3 position,
	in vec3 normal,
	in vec2 uv,
	in vec4 color,
	in vec3 tangent,
	in vec3 binormal,
	out vec3 Tangent,
	out vec3 Normal,
	out vec4 Position,
	out vec3 Binormal,
	out vec2 UV,
	out vec4 Color,
	out float Distance) 
{	
	Position = Model * vec4(position, 1);
	UV = uv;
	Color = color; 
	
	Tangent  = (Model * vec4(tangent, 0)).xyz;
	Normal   = (Model * vec4(normal, 0)).xyz;
	Binormal = (Model * vec4(binormal, 0)).xyz;
	
	float vertexDistance = distance( Position.xyz, EyePos.xyz );
	Distance = 1.0 - clamp( ( (vertexDistance - MinDistance) / (MaxDistance - MinDistance) ), 0.0, 1.0 - 1.0/TessellationFactor);
}

//------------------------------------------------------------------------------
/**
	Used for multi-layered painting
*/
shader
void
vsColoredShadowTessellated(in vec3 position,
	in vec3 normal,
	in vec2 uv,
	in vec4 color,
	in vec3 tangent,
	in vec3 binormal,
	out vec3 Normal,
	out vec4 Position,
	out vec2 UV,
	out vec4 Color,
	out int Instance,
	out float Distance) 
{	
	Position = Model * vec4(position, 1);
	UV = uv;
	Color = color; 
	
	Normal   = (Model * vec4(normal, 0)).xyz;
	
	float vertexDistance = distance( Position.xyz, EyePos.xyz );
	Distance = 1.0 - clamp( ( (vertexDistance - MinDistance) / (MaxDistance - MinDistance) ), 0.0, 1.0 - 1.0/TessellationFactor);
	Instance = gl_InstanceID;
}

//------------------------------------------------------------------------------
/**
	Used for multi-layered painting
*/
shader
void
vsColoredCSMTessellated(in vec3 position,
	in vec3 normal,
	in vec2 uv,
	in vec4 color,
	in vec3 tangent,
	in vec3 binormal,
	out vec3 Normal,
	out vec4 Position,
	out vec2 UV,
	out vec4 Color,
	out int Instance,
	out float Distance) 
{	
	Position = Model * vec4(position, 1);
	UV = uv;
	Color = color; 
	
	Normal   = (Model * vec4(normal, 0)).xyz;
	
	float vertexDistance = distance( Position.xyz, EyePos.xyz );
	Distance = 1.0 - clamp( ( (vertexDistance - MinDistance) / (MaxDistance - MinDistance) ), 0.0, 1.0 - 1.0/TessellationFactor);
	Instance = gl_InstanceID;
}

//------------------------------------------------------------------------------
/**
	Geometry shader for CSM shadow instancing.
	We copy the geometry and project into each frustum.
*/
[inputprimitive] = triangles
[outputprimitive] = triangle_strip
[maxvertexcount] = 3
shader
void 
gsMain(in vec2 uv[], in vec4 pos[], flat in int instance[], out vec2 UV, out vec4 ProjPos)
{
	gl_ViewportIndex = instance[0];
	
	// simply pass geometry straight through and set viewport
	UV = uv[0];
	ProjPos = pos[0];
	gl_Position = ProjPos;
	EmitVertex();
	
	UV = uv[1];
	ProjPos = pos[1];
	gl_Position = ProjPos;
	EmitVertex();
	
	UV = uv[2];
	ProjPos = pos[2];
	gl_Position = ProjPos;
	EmitVertex();
}


//------------------------------------------------------------------------------
/**
	Pixel shader for multilayered painting
*/
shader
void
psMultilayered(in vec3 ViewSpacePos,
	in vec3 Tangent,
	in vec3 Normal,
	in vec3 Binormal,
	in vec2 UV,
	in vec4 Color,
	in vec3 WorldViewVec,
	[color0] out vec4 Albedo,
	[color1] out vec4 Normals,
	[color2] out float Depth,	
	[color3] out vec4 Specular,
	[color4] out vec4 Emissive) 
{
	vec4 blend = Color;
	
	vec4 diffColor1 = texture(DiffuseMap, UV.xy);
	vec4 diffColor2 = texture(DiffuseMap2, UV.xy);
	vec4 diffColor3 = texture(DiffuseMap3, UV.xy);
	vec4 diffColor = (diffColor1 * blend.r + diffColor2 * blend.g + diffColor3 * blend.b) * vec4(MatAlbedoIntensity.rgb, 1);
			
	vec4 specColor1 = texture(SpecularMap, UV.xy);
	vec4 specColor2 = texture(SpecularMap2, UV.xy);
	vec4 specColor3 = texture(SpecularMap3, UV.xy);	
	vec4 specColor = (specColor1 * blend.r + specColor2 * blend.g + specColor3 * blend.b) * MatSpecularIntensity;	
	
	float roughness1 = texture(RoughnessMap, UV.xy).r;
	float roughness2 = texture(RoughnessMap2, UV.xy).r;
	float roughness3 = texture(RoughnessMap3, UV.xy).r;
	float roughness = (roughness1 * blend.r + roughness2 * blend.g + roughness3 * blend.b) * MatRoughnessIntensity;
	
	vec4 normals1 = texture(NormalMap, UV);
	vec4 normals2 = texture(NormalMap2, UV);
	vec4 normals3 = texture(NormalMap3, UV);
	vec4 normals = normals1 * blend.r + normals2 * blend.g + normals3 * blend.b;
	vec3 bumpNormal = normalize(calcBump(Tangent, Binormal, Normal, normals));

	mat2x3 env = calcEnv(specColor, bumpNormal, ViewSpacePos, WorldViewVec, roughness);
	vec4 spec = calcSpec(specColor.rgb, roughness);
	vec4 albedo = calcColor(diffColor, vec4(1), spec, AlphaBlendFactor);	
	vec4 emissive = vec4((env[0] * albedo.rgb + env[1]), 1);

	Specular = spec;
	Albedo = albedo;
	Emissive = emissive;
	Depth = calcDepth(ViewSpacePos);
	Normals = PackViewSpaceNormal(bumpNormal);
}

//------------------------------------------------------------------------------
/**
*/
[inputvertices] = 3
[outputvertices] = 6
shader
void 
hsDefault(in vec3 tangent[],
		  in vec3 normal[],
		  in vec4 position[],
		  in vec3 binormal[],
		  in vec2 uv[],
		  in vec4 color[],
		  in float distance[],
		  out vec3 Tangent[],
		  out vec3 Normal[],
		  out vec4 Position[],
		  out vec3 Binormal[],
		  out vec2 UV[],
		  out vec4 Color[]
#if PN_TRIANGLES
,
		  patch out vec3 f3B210,
		  patch out vec3 f3B120,
		  patch out vec3 f3B021,
		  patch out vec3 f3B012,
		  patch out vec3 f3B102,
		  patch out vec3 f3B201,
		  patch out vec3 f3B111
#endif
		  )
{
	Tangent[gl_InvocationID] 	= tangent[gl_InvocationID];
	Normal[gl_InvocationID] 	= normal[gl_InvocationID];
	Position[gl_InvocationID]	= position[gl_InvocationID];
	Binormal[gl_InvocationID] 	= binormal[gl_InvocationID];
	UV[gl_InvocationID]			= uv[gl_InvocationID];
	Color[gl_InvocationID]		= color[gl_InvocationID];	
	
	// perform per-patch operation
	if (gl_InvocationID == 0)
	{
		vec4 EdgeTessFactors;
		EdgeTessFactors.x = 0.5 * (distance[1] + distance[2]);
		EdgeTessFactors.y = 0.5 * (distance[2] + distance[0]);
		EdgeTessFactors.z = 0.5 * (distance[0] + distance[1]);
		EdgeTessFactors *= TessellationFactor;
	
#if PN_TRIANGLES
		// compute the cubic geometry control points
		// edge control points
		f3B210 = ( ( 2.0f * position[0] ) + position[1] - ( dot( ( position[1] - position[0] ), normal[0] ) * normal[0] ) ) / 3.0f;
		f3B120 = ( ( 2.0f * position[1] ) + position[0] - ( dot( ( position[0] - position[1] ), normal[1] ) * normal[1] ) ) / 3.0f;
		f3B021 = ( ( 2.0f * position[1] ) + position[2] - ( dot( ( position[2] - position[1] ), normal[1] ) * normal[1] ) ) / 3.0f;
		f3B012 = ( ( 2.0f * position[2] ) + position[1] - ( dot( ( position[1] - position[2] ), normal[2] ) * normal[2] ) ) / 3.0f;
		f3B102 = ( ( 2.0f * position[2] ) + position[0] - ( dot( ( position[0] - position[2] ), normal[2] ) * normal[2] ) ) / 3.0f;
		f3B201 = ( ( 2.0f * position[0] ) + position[2] - ( dot( ( position[2] - position[0] ), normal[0] ) * normal[0] ) ) / 3.0f;
		// center control point
		vec3 f3E = ( f3B210 + f3B120 + f3B021 + f3B012 + f3B102 + f3B201 ) / 6.0f;
		vec3 f3V = ( indata[0].Position + indata[1].Position + indata[2].Position ) / 3.0f;
		f3B111 = f3E + ( ( f3E - f3V ) / 2.0f );
#endif

		gl_TessLevelOuter[0] = EdgeTessFactors.x;
		gl_TessLevelOuter[1] = EdgeTessFactors.y;
		gl_TessLevelOuter[2] = EdgeTessFactors.z;
		gl_TessLevelInner[0] = (gl_TessLevelOuter[0] + gl_TessLevelOuter[1] + gl_TessLevelOuter[2]) / 3;
	}
}

//------------------------------------------------------------------------------
/**
*/
[inputvertices] = 3
[outputvertices] = 6
shader
void 
hsShadowMLP(
		in vec3 normal[],
		in vec4 position[],
		in vec2 uv[],
		in vec4 color[],
		flat in int instance[],
		in float distance[],
		out vec3 Normal[],
		out vec4 Position[],
		out vec2 UV[],
		out vec4 Color[],
		flat out int Instance[]
		#if PN_TRIANGLES
,
		  patch out vec3 f3B210,
		  patch out vec3 f3B120,
		  patch out vec3 f3B021,
		  patch out vec3 f3B012,
		  patch out vec3 f3B102,
		  patch out vec3 f3B201,
		  patch out vec3 f3B111
#endif
		  )
{
	Normal[gl_InvocationID] 	= normal[gl_InvocationID];
	Position[gl_InvocationID]	= position[gl_InvocationID];
	UV[gl_InvocationID]			= uv[gl_InvocationID];
	Color[gl_InvocationID]		= color[gl_InvocationID];	
	Instance[gl_InvocationID]	= instance[gl_InvocationID];
	
	// perform per-patch operation
	if (gl_InvocationID == 0)
	{
		vec4 EdgeTessFactors;
		EdgeTessFactors.x = 0.5 * (distance[1] + distance[2]);
		EdgeTessFactors.y = 0.5 * (distance[2] + distance[0]);
		EdgeTessFactors.z = 0.5 * (distance[0] + distance[1]);
		EdgeTessFactors *= TessellationFactor;
		
#if PN_TRIANGLES
		// compute the cubic geometry control points
		// edge control points
		f3B210 = ( ( 2.0f * position[0] ) + position[1] - ( dot( ( position[1] - position[0] ), normal[0] ) * normal[0] ) ) / 3.0f;
		f3B120 = ( ( 2.0f * position[1] ) + position[0] - ( dot( ( position[0] - position[1] ), normal[1] ) * normal[1] ) ) / 3.0f;
		f3B021 = ( ( 2.0f * position[1] ) + position[2] - ( dot( ( position[2] - position[1] ), normal[1] ) * normal[1] ) ) / 3.0f;
		f3B012 = ( ( 2.0f * position[2] ) + position[1] - ( dot( ( position[1] - position[2] ), normal[2] ) * normal[2] ) ) / 3.0f;
		f3B102 = ( ( 2.0f * position[2] ) + position[0] - ( dot( ( position[0] - position[2] ), normal[2] ) * normal[2] ) ) / 3.0f;
		f3B201 = ( ( 2.0f * position[0] ) + position[2] - ( dot( ( position[2] - position[0] ), normal[0] ) * normal[0] ) ) / 3.0f;
		// center control point
		vec3 f3E = ( f3B210 + f3B120 + f3B021 + f3B012 + f3B102 + f3B201 ) / 6.0f;
		vec3 f3V = ( indata[0].Position + indata[1].Position + indata[2].Position ) / 3.0f;
		f3B111 = f3E + ( ( f3E - f3V ) / 2.0f );
#endif

		gl_TessLevelOuter[0] = EdgeTessFactors.x;
		gl_TessLevelOuter[1] = EdgeTessFactors.y;
		gl_TessLevelOuter[2] = EdgeTessFactors.z;
		gl_TessLevelInner[0] = (gl_TessLevelOuter[0] + gl_TessLevelOuter[1] + gl_TessLevelOuter[2]) / 3;
	}
}

//------------------------------------------------------------------------------
/**
*/
[inputvertices] = 6
[winding] = ccw
[topology] = triangle
[partition] = odd
shader
void
dsDefault(
	in vec3 tangent[],
	in vec3 normal[],
	in vec4 position[],
	in vec3 binormal[],
	in vec2 uv[],
	in vec4 color[],
	out vec3 ViewSpacePos, 
	out vec3 Tangent, 
	out vec3 Normal, 
	out vec3 Binormal, 
	out vec2 UV,
	out vec4 Color
#if PN_TRIANGLES
	,
	patch in vec3 f3B210,
	patch in vec3 f3B120,
	patch in vec3 f3B021,
	patch in vec3 f3B012,
	patch in vec3 f3B102,
	patch in vec3 f3B201,
	patch in vec3 f3B111
#endif
	)
{
	// The barycentric coordinates
	float fU = gl_TessCoord.z;
	float fV = gl_TessCoord.x;
	float fW = gl_TessCoord.y;
	
	// Precompute squares and squares * 3 
	float fUU = fU * fU;
	float fVV = fV * fV;
	float fWW = fW * fW;
	float fUU3 = fUU * 3.0f;
	float fVV3 = fVV * 3.0f;
	float fWW3 = fWW * 3.0f;
	
#ifdef PN_TRIANGLES
	// Compute position from cubic control points and barycentric coords
	vec3 Position = position[0] * fWW * fW + position[1] * fUU * fU + position[2] * fVV * fV +
					  f3B210 * fWW3 * fU + f3B120 * fW * fUU3 + f3B201 * fWW3 * fV + f3B021 * fUU3 * fV +
					  f3B102 * fW * fVV3 + f3B012 * fU * fVV3 + f3B111 * 6.0f * fW * fU * fV;
#else
	vec3 Position = gl_TessCoord.x * position[0].xyz + gl_TessCoord.y * position[1].xyz + gl_TessCoord.z * position[2].xyz;
#endif
	
	Color = gl_TessCoord.x * color[0] + gl_TessCoord.y * color[1] + gl_TessCoord.z * color[2];
	UV = gl_TessCoord.x * uv[0] + gl_TessCoord.y * uv[1] + gl_TessCoord.z * uv[2];
	float height1 = 2.0f * length(textureLod(DisplacementMap, UV, 0)) - 1.0f;
	float height2 = 2.0f * length(textureLod(DisplacementMap2, UV, 0)) - 1.0f;
	float height3 = 2.0f * length(textureLod(DisplacementMap3, UV, 0)) - 1.0f;
	float height = height1 * Color.r + height2 * Color.g + height3 * Color.b;
	
	float Height = 2.0f * height - 1.0f;
	Normal = gl_TessCoord.x * normal[0] + gl_TessCoord.y * normal[1] + gl_TessCoord.z * normal[2];
	vec3 VectorNormalized = normalize( Normal );
	
	Position += VectorNormalized.xyz * HeightScale * SceneScale * Height;
	
	gl_Position = vec4(Position, 1);
	ViewSpacePos = (View * gl_Position).xyz;
	gl_Position = ViewProjection * gl_Position;
	
	Normal = (View * vec4(Normal, 0)).xyz;
	Binormal = gl_TessCoord.x * binormal[0] + gl_TessCoord.y * binormal[1] + gl_TessCoord.z * binormal[2];
	Binormal = (View * vec4(Binormal, 0)).xyz;
	Tangent = gl_TessCoord.x * tangent[0] + gl_TessCoord.y * tangent[1] + gl_TessCoord.z * tangent[2];
	Tangent = (View * vec4(Tangent, 0)).xyz;
}

//------------------------------------------------------------------------------
/**
*/
[inputvertices] = 6
[winding] = ccw
[topology] = triangle
[partition] = odd
shader
void
dsShadowMLP(
	in vec3 normal[],
	in vec4 position[],
	in vec2 uv[],
	in vec4 color[],
	flat in int instance[],
	out vec2 UV,
	out vec4 ProjPos,
	out vec3 Normal,
	out vec4 Color,
	flat out int Instance
#if PN_TRIANGLES
	,
	patch in vec3 f3B210,
	patch in vec3 f3B120,
	patch in vec3 f3B021,
	patch in vec3 f3B012,
	patch in vec3 f3B102,
	patch in vec3 f3B201,
	patch in vec3 f3B111
#endif
	)
{
	// The barycentric coordinates
	float fU = gl_TessCoord.z;
	float fV = gl_TessCoord.x;
	float fW = gl_TessCoord.y;
	
	// Precompute squares and squares * 3 
	float fUU = fU * fU;
	float fVV = fV * fV;
	float fWW = fW * fW;
	float fUU3 = fUU * 3.0f;
	float fVV3 = fVV * 3.0f;
	float fWW3 = fWW * 3.0f;
	
#ifdef PN_TRIANGLES
	// Compute position from cubic control points and barycentric coords
	vec3 Position = position[0] * fWW * fW + position[1] * fUU * fU + position[2] * fVV * fV +
					  f3B210 * fWW3 * fU + f3B120 * fW * fUU3 + f3B201 * fWW3 * fV + f3B021 * fUU3 * fV +
					  f3B102 * fW * fVV3 + f3B012 * fU * fVV3 + f3B111 * 6.0f * fW * fU * fV;
#else
	vec3 Position = gl_TessCoord.x * position[0].xyz + gl_TessCoord.y * position[1].xyz + gl_TessCoord.z * position[2].xyz;
#endif
	
	Color = gl_TessCoord.x * color[0] + gl_TessCoord.y * color[1] + gl_TessCoord.z * color[2];
	UV = gl_TessCoord.x * uv[0] + gl_TessCoord.y * uv[1] + gl_TessCoord.z * uv[2];
	float height1 = 2.0f * length(textureLod(DisplacementMap, UV, 0)) - 1.0f;
	float height2 = 2.0f * length(textureLod(DisplacementMap2, UV, 0)) - 1.0f;
	float height3 = 2.0f * length(textureLod(DisplacementMap3, UV, 0)) - 1.0f;
	float height = height1 * Color.r + height2 * Color.g + height3 * Color.b;
	
	float Height = 2.0f * height - 1.0f;
	Normal = gl_TessCoord.x * normal[0] + gl_TessCoord.y * normal[1] + gl_TessCoord.z * normal[2];
	vec3 VectorNormalized = normalize( Normal );
	
	Position += VectorNormalized.xyz * HeightScale * SceneScale * Height;
	
	vec4 pos = ViewMatrixArray[instance[0]] * vec4(Position, 1);
	gl_Position = pos;
	ProjPos = pos;
	Instance = instance[0];
}

//------------------------------------------------------------------------------
/**
	Simple placeholder shadow mapping shader. 
	This allows us to plug in our tessellated techniques into this one.
*/
shader
void 
psMultilayeredShadowVSM(in vec2 UV,
	in vec4 ProjPos,
	[color0] out vec2 ShadowColor)
{
	float depth = ProjPos.z / ProjPos.w;
	float moment1 = depth;
	float moment2 = depth * depth;
	
	// Adjusting moments (this is sort of bias per pixel) using derivative
	float dx = dFdx(depth);
	float dy = dFdy(depth);
	moment2 += 0.25f*(dx*dx+dy*dy);
	
	ShadowColor = vec2(moment1, moment2);
}

//------------------------------------------------------------------------------
/**
*/
SimpleTechnique(MLP, "Static", vsColored(), psMultilayered(
		calcColor = SimpleColor,
		calcBump = NormalMapFunctor,
		calcSpec = NonReflectiveSpecularFunctor,
		calcDepth = ViewSpaceDepthFunctor,
		calcEnv = PBR), MLPState);
		
SimpleTechnique(MLPShadow, "Spot|Static", vsColoredShadow(), psShadow(), ShadowState);
GeometryTechnique(MLPCSM, "Global|Static", vsColoredCSM(), psVSM(), gsMain(), ShadowStateCSM);
//TessellationTechnique(MLPTessellated, "Static|Tessellated|Colored", vsColoredTessellated(), psMultilayered(), hsDefault(), dsDefault(), MLPState);
//FullTechnique(MLPTessellatedShadow, "Static|Tessellated|Colored|Shadow", vsColoredCSMTessellated(), psMultilayeredShadowVSM(), hsShadowMLP(), dsShadowMLP(), gsMain(), MLPState);
//TessellationTechnique(MLPTessellatedCSM, "Static|Tessellated|Colored|CSM", vsColoredShadowTessellated(), psMultilayeredShadowVSM(), hsShadowMLP(), dsShadowMLP(), MLPState);
