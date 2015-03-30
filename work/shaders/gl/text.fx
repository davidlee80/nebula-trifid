//------------------------------------------------------------------------------
//  text.fx
//
//	Basic text shader
//
//  (C) 2013 Gustav Sterbrant
//------------------------------------------------------------------------------

#include "lib/std.fxh"
#include "lib/techniques.fxh"

/// Declaring used textures
sampler2D Texture;
mat4 TextProjectionModel;

samplerstate TextureSampler
{
	Samplers = { Texture };
	Filter = Point;
};


state TextState
{
	BlendEnabled[0] = true;
	SrcBlend[0] = SrcAlpha;
	DstBlend[0] = OneMinusSrcAlpha;
	DepthWrite = false;
	DepthEnabled = false;
	CullMode = None;
};

//------------------------------------------------------------------------------
/**
*/
shader
void
vsMain(in vec2 position,
	in vec2 uv,
	in vec4 color,
	out vec2 UV,
	out vec4 Color) 
{
	vec4 pos = vec4(position, 0, 1);	
	gl_Position = TextProjectionModel * pos;
	Color = color;
	UV = uv;
}

//------------------------------------------------------------------------------
/**
*/
shader
void
psMain(
	in vec2 UV,
	in vec4 Color,
	[color0] out vec4 FinalColor) 
{
	vec4 texColor = vec4(texture(Texture, UV).r);
	FinalColor = texColor * Color;
}

//------------------------------------------------------------------------------
/**
*/
SimpleTechnique(Default, "Static", vsMain(), psMain(), TextState);